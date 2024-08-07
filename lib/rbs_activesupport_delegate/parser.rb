# frozen_string_literal: true

require "pathname"
require "rbs"
require "rbs/cli"
require "rbs/prototype/rb"

module RbsActivesupportDelegate
  class Parser < ::RBS::Prototype::RB
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
          @delegates[context.namespace] << args
        else
          process_orig(node, decls:, comments:, context:)
        end
      else
        process_orig(node, decls:, comments:, context:)
      end
    end
  end
end
