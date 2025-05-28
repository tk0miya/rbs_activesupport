# frozen_string_literal: true

require "rbs"

module RbsActivesupport
  class MethodSearcher
    attr_reader :rbs_builder #: RBS::DefinitionBuilder

    # @rbs rbs_builder: RBS::DefinitionBuilder
    def initialize(rbs_builder) #: void
      @rbs_builder = rbs_builder
    end

    # @rbs delegate: Delegate
    def method_types_for(delegate) #: Array[String]
      delegate_to = lookup_method_types(delegate.namespace.to_type_name, delegate.to)
      return ["() -> untyped"] if delegate_to.any? { |t| t.type.return_type.is_a?(RBS::Types::Bases::Any) }

      return_types = return_type_names_for(delegate_to).uniq
                                                       .flat_map { |t| lookup_method_types(t, delegate.method) }
                                                       .map(&:to_s)
      return_types << "() -> untyped" if return_types.empty?
      return_types
    end

    private

    # @rbs delegate_to: Array[RBS::MethodType]
    def return_type_names_for(delegate_to) #: Array[RBS::TypeName]
      delegate_to.filter_map do |t|
        type_name_for(t.type.return_type)
      end
    end

    # @rbs type: RBS::Types::t
    def type_name_for(type) #: RBS::TypeName?
      case type
      when RBS::Types::Optional
        type_name_for(type.type)
      when RBS::Types::ClassSingleton, RBS::Types::ClassInstance, RBS::Types::Interface, RBS::Types::Alias
        type.name
      end
    end

    # @rbs type_name: RBS::TypeName
    # @rbs method: Symbol
    def lookup_method_types(type_name, method) #: Array[RBS::MethodType]
      instance = rbs_builder.build_instance(type_name)
      if method.start_with? "@"
        ivar_def = instance.instance_variables[method]
        return [] unless ivar_def

        method_def = build_method_def(ivar_def.type)
        [method_def]
      else
        method_def = instance.methods[method]
        return [] unless method_def

        method_def.defs.map(&:type)
      end
    rescue StandardError
      []
    end

    # @rbs return_type: RBS::Types::t
    def build_method_def(return_type) #: RBS::MethodType
      type = RBS::Types::Function.new(
        required_positionals: [],
        optional_positionals: [],
        rest_positionals: nil,
        trailing_positionals: [],
        required_keywords: {},
        optional_keywords: {},
        rest_keywords: nil,
        return_type:
      )
      RBS::MethodType.new(type_params: [], type:, block: nil, location: nil)
    end
  end
end
