# frozen_string_literal: true

module RbsActivesupport
  module Types
    # @rbs!
    #   def self.guess_type: (untyped obj) -> String

    # @rbs obj: untyped
    def guess_type(obj) #: String # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      case obj
      when nil
        "nil"
      when Integer, Float, Symbol, String
        "::#{obj.class.name}" or raise
      when true, false
        "bool"
      when Array
        return "::Array[untyped]" if obj.empty?

        items = obj.map { |e| guess_type(e) }.uniq
        if items.include?("untyped")
          "::Array[untyped]"
        else
          "::Array[#{items.join(" | ")}]"
        end
      when Hash
        return "::Hash[untyped, untyped]" if obj.empty?

        keys = obj.keys.map { |e| guess_type(e) }.uniq
        values = obj.values.map { |e| guess_type(e) }.uniq
        key_type = keys.include?("untyped") ? "untyped" : keys.join(" | ")
        value_type = values.include?("untyped") ? "untyped" : values.join(" | ")
        "::Hash[#{key_type}, #{value_type}]"
      else
        "untyped"
      end
    end
    module_function :guess_type
  end
end
