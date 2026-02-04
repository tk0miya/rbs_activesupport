# frozen_string_literal: true

module RbsActivesupport
  class DeclarationBuilder
    # @rbs! type t = AttributeAccessor | ClassAttribute | Delegate | Include

    include AST

    attr_reader :resolver #: RBS::Resolver::TypeNameResolver
    attr_reader :method_searcher #: MethodSearcher
    attr_reader :processed_modules #: Array[RBS::Namespace]

    # @rbs resolver: RBS::Resolver::TypeNameResolver
    # @rbs method_searcher: MethodSearcher
    def initialize(resolver, method_searcher) #: void
      @resolver = resolver
      @method_searcher = method_searcher
      @processed_modules = []
    end

    # @rbs namespace: RBS::Namespace
    # @rbs method_calls: Array[Parser::MethodCall]
    # @rbs context: RBS::Namespace?
    def build(namespace, method_calls, context = nil) #: [Array[String], Array[String]]
      built = build_method_calls(namespace, method_calls, context)
      public_decls, private_decls = built.partition(&:public?)
      [public_decls.map { |decl| render(namespace, decl) },
       private_decls.map { |decl| render(namespace, decl) }]
    end

    private

    # @rbs namespace: RBS::Namespace
    # @rbs method_calls: Array[Parser::MethodCall]
    # @rbs context: RBS::Namespace?
    # @rbs options: Hash[Symbol, untyped]
    def build_method_calls(namespace, method_calls, context, options = {}) #: Array[t]
      method_calls.flat_map do |method_call|
        case method_call.name
        when :class_attribute
          build_class_attribute(method_call)
        when :delegate
          build_delegate(namespace, method_call)
        when :cattr_accessor, :mattr_accessor, :cattr_reader, :mattr_reader, :cattr_writer, :mattr_writer
          build_attribute_accessor(method_call)
        when :include
          # implicit include is an "include" internally (e.g. include call in the included block)
          implicit = options.fetch(:implicit_include, false)
          build_include(namespace, method_call, context, implicit:)
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
    # @rbs context: RBS::Namespace?
    # @rbs implicit: bool
    def build_include(namespace, method_call, context, implicit:) #: Array[t]  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      module_paths = eval_include_args(method_call.args)
      module_paths.delete_if do |module_path|
        unless module_path.is_a?(RBS::Namespace)
          puts "ERROR: #{namespace}:#{method_call.name}: Failed to recognize an included module: #{module_path}"
          true
        end
      end
      module_paths.filter_map do |module_path|
        include = Include.new(context || namespace, module_path, { private: method_call.private?, implicit: })

        if include.module_name
          next if processed_modules.include?(include.module_name)

          processed_modules << include.module_name
        end

        calls = [] #: Array[t]
        calls << include if include.implicit? || (include.concern? && include.classmethods?)
        calls.concat(build_method_calls(namespace, include.nested_includes, include.module_name))
        calls.concat(build_method_calls(namespace, include.method_calls_in_included_block, include.module_name,
                                        { implicit_include: true }))
        calls
      end.flatten
    end

    # @rbs namespace: RBS::Namespace
    # @rbs decl: t
    def render(namespace, decl) #: String
      case decl
      when AttributeAccessor
        render_attribute_accessor(namespace, decl)
      when ClassAttribute
        render_class_attribute(namespace, decl)
      when Delegate
        render_delegate(decl)
      when Include
        render_include(decl)
      end
    end

    # @rbs namespace: RBS::Namespace
    # @rbs decl: AttributeAccessor
    def render_attribute_accessor(namespace, decl) #: String
      type = resolve_type(namespace, decl.type)
      methods = []
      methods << "def self.#{decl.name}: () -> (#{type})" if decl.singleton_reader?
      methods << "def self.#{decl.name}=: (#{type}) -> (#{type})" if decl.singleton_writer?
      methods << "def #{decl.name}: () -> (#{type})" if decl.instance_reader?
      methods << "def #{decl.name}=: (#{type}) -> (#{type})" if decl.instance_writer?
      methods.join("\n")
    end

    # @rbs namespace: RBS::Namespace
    # @rbs decl: ClassAttribute
    def render_class_attribute(namespace, decl) #: String
      type = resolve_type(namespace, decl.type)
      methods = []
      methods << "def self.#{decl.name}: () -> (#{type})"
      methods << "def self.#{decl.name}=: (#{type}) -> (#{type})"
      methods << "def self.#{decl.name}?: () -> bool" if decl.instance_predicate?
      methods << "def #{decl.name}: () -> (#{type})" if decl.instance_reader?
      methods << "def #{decl.name}=: (#{type}) -> (#{type})" if decl.instance_writer?
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
      mods = []
      mods << "include #{module_name.to_s.delete_suffix("::")}" if decl.implicit?
      mods << "extend #{module_name}ClassMethods" if decl.concern? && decl.classmethods?
      mods.join("\n")
    end

    # @rbs namespace: RBS::Namespace
    # @rbs type: String
    def resolve_type(namespace, type) #: String
      context = context_from(namespace.to_type_name)

      typ = RBS::Parser.parse_type(type)
      if typ
        typ.map_type_name do |type_name|
          resolver.resolve(type_name, context:) || type_name.absolute!
        rescue StandardError
          # Resolver failed to resolve the type name because of a lack of type database
          # (might not have been generated yet).  It will be resolved in the next execution.
          type_name.absolute!
        end.to_s
      else
        type
      end
    end

    # @rbs type_name: RBS::TypeName
    def context_from(type_name) #: RBS::Resolver::context
      if type_name.namespace == RBS::Namespace.root
        [nil, type_name]
      else
        parent = context_from(type_name.namespace.to_type_name)
        [parent, type_name]
      end
    end
  end
end
