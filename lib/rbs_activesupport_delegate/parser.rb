# frozen_string_literal: true

require "pathname"
require "rbs"
require "rbs/cli"
require "rbs/prototype/rb"

module RbsActivesupportDelegate
  class Parser < ::RBS::Prototype::RB
    class MethodCall
      attr_reader :name, :args

      def initialize(name, args, private)
        @name = name
        @args = args
        @private = private
      end

      def private?
        @private
      end
    end

    METHODS = %i[class_attribute delegate cattr_accessor mattr_accessor].freeze # steep:ignore IncompatibleAssignment

    alias process_orig process

    attr_reader :method_calls

    def initialize
      super
      @method_calls = Hash.new { |hash, key| hash[key] = [] }
    end

    def process(node, decls:, comments:, context:)
      case node.type
      when :FCALL, :VCALL
        args = node.children[1]&.children || []
        case node.children[0]
        when *METHODS
          @method_calls[context.namespace] << MethodCall.new(node.children[0], args, private?(decls))
        else
          process_orig(node, decls:, comments:, context:)
        end
      else
        process_orig(node, decls:, comments:, context:)
      end
    end

    def private?(decls)
      current_accessibility(decls) == private
    end
  end
end
