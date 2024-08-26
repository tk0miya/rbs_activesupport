# frozen_string_literal: true

module RbsActivesupportDelegate
  class DeclarationBuilder
    include AST

    attr_reader :method_searcher

    def initialize(method_searcher)
      @method_searcher = method_searcher
    end

    def build(namespace, method_calls)
      public_decls, private_decls = build_method_calls(namespace, method_calls).partition(&:public?)
      [public_decls.map(&method(:render)), private_decls.map(&method(:render))] # steep:ignore BlockTypeMismatch
    end

    private

    def build_method_calls(namespace, method_calls)
      method_calls.flat_map do |method_call|
        case method_call.name
        when :class_attribute
          build_class_attribute(method_call)
        when :delegate
          build_delegate(namespace, method_call)
        when :cattr_accessor, :mattr_accessor
          build_attribute_accessor(method_call)
        end
      end
    end

    def build_attribute_accessor(method_call)
      methods, options = eval_args_with_options(method_call.args)
      options[:private] = true if method_call.private?
      methods.map do |method|
        AttributeAccessor.new(method, options)
      end
    end

    def build_class_attribute(method_call)
      methods, options = eval_args_with_options(method_call.args)
      options[:private] = true if method_call.private?
      methods.map do |method|
        ClassAttribute.new(method, options)
      end
    end

    def build_delegate(namespace, method_call)
      methods, options = eval_args_with_options(method_call.args)
      options[:private] = true if method_call.private?
      methods.map do |method|
        Delegate.new(namespace, method, options)
      end
    end

    def render(decl)
      case decl
      when AttributeAccessor
        render_attribute_accessor(decl)
      when ClassAttribute
        render_class_attribute(decl)
      when Delegate
        render_delegate(decl)
      end
    end

    def render_attribute_accessor(decl)
      methods = []
      methods << "def self.#{decl.name}: () -> untyped"
      methods << "def self.#{decl.name}=: (untyped) -> untyped"
      methods << "def #{decl.name}: () -> untyped" if decl.instance_reader?
      methods << "def #{decl.name}=: (untyped) -> untyped" if decl.instance_writer?
      methods.join("\n")
    end

    def render_class_attribute(decl)
      methods = []
      methods << "def self.#{decl.name}: () -> untyped"
      methods << "def self.#{decl.name}=: (untyped) -> untyped"
      methods << "def self.#{decl.name}?: () -> bool" if decl.instance_predicate?
      methods << "def #{decl.name}: () -> untyped" if decl.instance_reader?
      methods << "def #{decl.name}=: (untyped) -> untyped" if decl.instance_writer?
      methods << "def #{decl.name}?: () -> bool" if decl.instance_predicate? && decl.instance_reader?
      methods.join("\n")
    end

    def render_delegate(decl)
      method_types = method_searcher.method_types_for(decl)

      "def #{decl.method_name}: #{method_types.join(" | ")}"
    end
  end
end
