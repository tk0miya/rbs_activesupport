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

    alias process_orig process

    attr_reader :delegates

    def initialize
      super
      @delegates = Hash.new { |hash, key| hash[key] = [] }
    end

    def process(node, decls:, comments:, context:)
      case node.type
      when :FCALL, :VCALL
        args = node.children[1]&.children || []
        case node.children[0]
        when :delegate
          @delegates[context.namespace] << MethodCall.new(node.children[0], args, private?(decls))
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
