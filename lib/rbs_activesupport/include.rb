# frozen_string_literal: true

require "active_support/concern"

module RbsActivesupport
  class Include
    attr_reader :context #: RBS::Namespace
    attr_reader :module_path #: RBS::Namespace
    attr_reader :options #: Hash[Symbol, untyped]

    # @rbs context: RBS::Namespace
    # @rbs module_path: RBS::Namespace
    # @rbs options: Hash[Symbol, untyped]
    def initialize(context, module_path, options) #: void
      @context = context
      @module_path = module_path
      @options = options
    end

    # @rbs %a{pure}
    def module_name #: RBS::Namespace?
      namespace = @context

      loop do
        modname = namespace + module_path
        return modname if Object.const_defined?(modname.to_s.delete_suffix("::"))

        break if namespace.empty?

        namespace = namespace.parent
      end
    end

    # @rbs %a{pure}
    def module #: Module?
      return unless module_name

      modname = module_name.to_s.delete_suffix("::")
      return unless Object.const_defined?(modname)

      Object.const_get(modname)
    end

    def concern? #: boolish
      self.module&.singleton_class&.include?(ActiveSupport::Concern)
    end

    def classmethods? #: boolish
      return false unless self.module

      self.module&.const_defined?(:ClassMethods)
    end

    def explicit? #: bool
      !implicit?
    end

    def implicit? #: bool
      options.fetch(:implicit, false)
    end

    def nested_includes #: Array[Parser::MethodCall]
      return [] unless module_name
      return [] unless parser

      method_calls = parser.method_calls[module_name] || []
      method_calls.select { |call| call.name == :include && !call.included }
    end

    def method_calls_in_included_block #: Array[Parser::MethodCall]
      return [] unless module_name
      return [] unless parser

      method_calls = parser.method_calls[module_name] || []
      method_calls.select(&:included)
    end

    def public? #: bool
      !private?
    end

    def private? #: bool
      options.fetch(:private, false)
    end

    private

    # @rbs @parser: Parser

    # @rbs %a{pure}
    def parser #: Parser?
      return nil unless module_name

      @parser ||= begin
        path, = Object.const_source_location(module_name.to_s.delete_suffix("::")) #: String?
        return nil unless path && File.exist?(path)

        Parser.new(parse_included_block: true).tap do |parser|
          parser.parse(File.read(path))
        end
      end
    end
  end
end
