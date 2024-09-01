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
        when :cattr_accessor, :mattr_accessor, :cattr_reader, :mattr_reader, :cattr_writer, :mattr_writer
          build_attribute_accessor(method_call)
        when :include
          build_include(namespace, method_call)
        end
      rescue StandardError => e
        puts "ERROR: #{namespace}:#{method_call.name}: Failed to build method calls: #{e}"
        nil
      end.compact
    end

    def build_attribute_accessor(method_call)
      methods, options = eval_args_with_options(method_call.args)
      options[:singleton_reader] = false if %i[cattr_writer mattr_writer].include?(method_call.name)
      options[:singleton_writer] = false if %i[cattr_reader mattr_reader].include?(method_call.name)
      options[:instance_reader] = false if %i[cattr_writer mattr_writer].include?(method_call.name)
      options[:instance_writer] = false if %i[cattr_reader mattr_reader].include?(method_call.name)
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

    def build_include(namespace, method_call)
      module_paths = eval_args(method_call.args)
      module_paths.map do |module_path|
        Include.new(namespace, module_path, { private: method_call.private? })
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
      when Include
        render_include(decl)
      end
    end

    def render_attribute_accessor(decl)
      methods = []
      methods << "def self.#{decl.name}: () -> untyped" if decl.singleton_reader?
      methods << "def self.#{decl.name}=: (untyped) -> untyped" if decl.singleton_writer?
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

    def render_include(decl)
      if decl.concern? && decl.classmethods?
        <<~RBS
          include #{decl.argument.to_s.delete_suffix("::")}
          extend #{decl.argument}ClassMethods
        RBS
      else
        "include #{decl.argument.to_s.delete_suffix("::")}"
      end
    end
  end
end
