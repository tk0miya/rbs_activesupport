# frozen_string_literal: true

require "rbs"

module RbsActivesupportDelegate
  class MethodSearcher
    attr_reader :rbs_builder

    def initialize(rbs_builder)
      @rbs_builder = rbs_builder
    end

    def method_types_for(delegate)
      delegate_to = lookup_method_types(delegate.namespace.to_type_name, delegate.to)
      return ["() -> untyped"] if delegate_to.any? { |t| t.type.return_type.is_a?(RBS::Types::Bases::Any) }

      return_types = delegate_to
                     .filter_map { |t| t.type.return_type.name } # steep:ignore NoMethod
                     .uniq
                     .flat_map { |t| lookup_method_types(t, delegate.method) }
                     .map(&:to_s)
      return_types << "() -> untyped" if return_types.empty?
      return_types
    end

    private

    def lookup_method_types(type_name, method)
      instance = rbs_builder.build_instance(type_name)
      method_def = instance.methods[method]
      return [] unless method_def

      method_def.defs.map(&:type)
    rescue StandardError
      []
    end
  end
end