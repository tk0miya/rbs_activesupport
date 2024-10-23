# frozen_string_literal: true

module RbsActivesupport
  class DeclarationBuilder
    # @rbs! type t = AttributeAccessor | ClassAttribute | Delegate | Include

    include AST

    attr_reader :method_searcher #: MethodSearcher

    # @rbs method_searcher: MethodSearcher
    def initialize(method_searcher) #: void
      @method_searcher = method_searcher
    end

    # @rbs namespace: RBS::Namespace
    # @rbs method_calls: Array[Parser::MethodCall]
    def build(namespace, method_calls) #: [Array[String], Array[String]]
      public_decls, private_decls = build_method_calls(namespace, method_calls).partition(&:public?)
      [public_decls.map(&method(:render)), private_decls.map(&method(:render))] # steep:ignore BlockTypeMismatch
    end

    private

    # @rbs namespace: RBS::Namespace
    # @rbs method_calls: Array[Parser::MethodCall]
    def build_method_calls(namespace, method_calls) #: Array[t]
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

    # @rbs method_call: Parser::MethodCall
    def build_attribute_accessor(method_call) #: Array[AttributeAccessor]
      methods, options = eval_args_with_options(method_call.args)
      options[:singleton_reader] = false if %i[cattr_writer mattr_writer].include?(method_call.name)
      options[:singleton_writer] = false if %i[cattr_reader mattr_reader].include?(method_call.name)
      options[:instance_reader] = false if %i[cattr_writer mattr_writer].include?(method_call.name)
      options[:instance_writer] = false if %i[cattr_reader mattr_reader].include?(method_call.name)
      options[:private] = true if method_call.private?
      options[:included] = method_call.included
      options[:trailing_comment] = method_call.trailing_comment
      methods.map do |method|
        AttributeAccessor.new(method, options)
      end
    end

    # @rbs method_call: Parser::MethodCall
    def build_class_attribute(method_call) #: Array[ClassAttribute]
      methods, options = eval_args_with_options(method_call.args)
      options[:private] = true if method_call.private?
      options[:included] = method_call.included
      options[:trailing_comment] = method_call.trailing_comment
      methods.map do |method|
        ClassAttribute.new(method, options)
      end
    end

    # @rbs namespace: RBS::Namespace
    # @rbs method_call: Parser::MethodCall
    def build_delegate(namespace, method_call) #: Array[Delegate]
      methods, options = eval_args_with_options(method_call.args)
      options[:private] = true if method_call.private?
      methods.map do |method|
        Delegate.new(namespace, method, options)
      end
    end

    # @rbs namespace: RBS::Namespace
    # @rbs method_call: Parser::MethodCall
    def build_include(namespace, method_call) #: Array[t]
      module_paths = eval_include_args(method_call.args)
      module_paths.flat_map do |module_path|
        include = Include.new(namespace, module_path, { private: method_call.private? })
        ([include] +
         build_method_calls(namespace, include.nested_includes) +
         build_method_calls(namespace, include.method_calls_in_included_block))
      end
    end

    # @rbs decl: t
    def render(decl) #: String
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

    # @rbs decl: AttributeAccessor
    def render_attribute_accessor(decl) #: String
      methods = []
      methods << "def self.#{decl.name}: () -> (#{decl.type})" if decl.singleton_reader?
      methods << "def self.#{decl.name}=: (#{decl.type}) -> (#{decl.type})" if decl.singleton_writer?
      methods << "def #{decl.name}: () -> (#{decl.type})" if decl.instance_reader?
      methods << "def #{decl.name}=: (#{decl.type}) -> (#{decl.type})" if decl.instance_writer?
      methods.join("\n")
    end

    # @rbs decl: ClassAttribute
    def render_class_attribute(decl) #: String
      methods = []
      methods << "def self.#{decl.name}: () -> (#{decl.type})"
      methods << "def self.#{decl.name}=: (#{decl.type}) -> (#{decl.type})"
      methods << "def self.#{decl.name}?: () -> bool" if decl.instance_predicate?
      methods << "def #{decl.name}: () -> (#{decl.type})" if decl.instance_reader?
      methods << "def #{decl.name}=: (#{decl.type}) -> (#{decl.type})" if decl.instance_writer?
      methods << "def #{decl.name}?: () -> bool" if decl.instance_predicate? && decl.instance_reader?
      methods.join("\n")
    end

    # @rbs decl: Delegate
    def render_delegate(decl) #: String
      method_types = method_searcher.method_types_for(decl)

      "def #{decl.method_name}: #{method_types.join(" | ")}"
    end

    # @rbs decl: Include
    def render_include(decl) #: String
      module_name = decl.module_name || decl.module_path
      if decl.concern? && decl.classmethods?
        <<~RBS
          include #{module_name.to_s.delete_suffix("::")}
          extend #{module_name}ClassMethods
        RBS
      else
        "include #{module_name.to_s.delete_suffix("::")}"
      end
    end
  end
end
