# frozen_string_literal: true

require "active_support/concern"

module RbsActivesupport
  class Include
    attr_reader :context #: RBS::Namespace
    attr_reader :module_path #: Array[Symbol?]
    attr_reader :options #: Hash[Symbol, untyped]

    # @rbs context: RBS::Namespace
    # @rbs module_path: Array[Symbol?]
    # @rbs options: Hash[Symbol, untyped]
    def initialize(context, module_path, options) #: void
      @context = context
      @module_path = module_path
      @options = options
    end

    def argument #: RBS::Namespace
      if module_path.first.nil?
        RBS::Namespace.new(path: module_path[1...], absolute: true) # steep:ignore ArgumentTypeMismatch
      else
        RBS::Namespace.new(path: module_path, absolute: false) # steep:ignore ArgumentTypeMismatch
      end
    end

    # @rbs %a{pure}
    def module_name #: RBS::Namespace?
      namespace = @context

      loop do
        modname = namespace + argument
        return modname if Object.const_defined?(modname.to_s.delete_suffix("::"))

        break if namespace.empty?

        namespace = namespace.parent
      end
    end

    def concern? #: bool
      return false unless module_name

      modname = module_name.to_s.delete_suffix("::")
      return false unless Object.const_defined?(modname)

      mod = Object.const_get(modname)
      mod&.singleton_class&.include?(ActiveSupport::Concern)
    end

    def classmethods? #: bool
      return false unless module_name

      modname = module_name.append(:ClassMethods).to_s.delete_suffix("::")
      Object.const_defined?(modname)
    end

    def public? #: bool
      !private?
    end

    def private? #: bool
      options.fetch(:private, false)
    end
  end
end
