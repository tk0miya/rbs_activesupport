# frozen_string_literal: true

require "active_support/concern"

module RbsActivesupport
  class Include
    attr_reader :context, :module_path, :options

    def initialize(context, module_path, options)
      @context = context
      @module_path = module_path
      @options = options
    end

    def argument
      if module_path.first.nil?
        RBS::Namespace.new(path: module_path[1...], absolute: true) # steep:ignore ArgumentTypeMismatch
      else
        RBS::Namespace.new(path: module_path, absolute: false) # steep:ignore ArgumentTypeMismatch
      end
    end

    def module_name
      namespace = @context

      loop do
        modname = namespace + argument
        return modname if Object.const_defined?(modname.to_s.delete_suffix("::"))

        break if namespace.empty?

        namespace = namespace.parent
      end
    end

    def concern?
      return false unless module_name

      modname = module_name.to_s.delete_suffix("::")
      return false unless Object.const_defined?(modname)

      mod = Object.const_get(modname)
      mod&.singleton_class&.include?(ActiveSupport::Concern)
    end

    def classmethods?
      return false unless module_name

      modname = module_name.append(:ClassMethods).to_s.delete_suffix("::")
      Object.const_defined?(modname)
    end

    def public?
      !private?
    end

    def private?
      options.fetch(:private, false)
    end
  end
end
