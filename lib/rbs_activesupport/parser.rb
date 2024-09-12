# frozen_string_literal: true

require "pathname"
require "rbs"
require "rbs/cli"
require "rbs/prototype/rb"

module RbsActivesupport
  class Parser < ::RBS::Prototype::RB
    class MethodCall
      attr_reader :name, :args, :trailing_comment

      def initialize(name, args, private, trailing_comment: nil)
        @name = name
        @args = args
        @private = private
        @trailing_comment = trailing_comment
      end

      def private?
        @private
      end
    end

    METHODS = %i[
      class_attribute delegate cattr_accessor mattr_accessor cattr_reader mattr_reader cattr_writer mattr_writer include
    ].freeze # steep:ignore IncompatibleAssignment

    alias process_orig process

    attr_reader :comment_parser, :method_calls

    def initialize
      super
      @comment_parser = CommentParser.new
      @method_calls = Hash.new { |hash, key| hash[key] = [] }
    end

    def parse(string)
      comment_parser.parse(string)
      super
    end

    def process(node, decls:, comments:, context:)
      case node.type
      when :FCALL, :VCALL
        args = node.children[1]&.children || []
        case node.children[0]
        when *METHODS
          @method_calls[context.namespace] << MethodCall.new(node.children[0], args, private?(decls),
                                                             trailing_comment: trailing_comment_for(node))
        else
          process_orig(node, decls: decls, comments: comments, context: context)
        end
      else
        process_orig(node, decls: decls, comments: comments, context: context)
      end
    end

    def trailing_comment_for(node)
      comment_parser.trailing_comments[node.last_lineno]
    end

    def private?(decls)
      current_accessibility(decls) == private
    end
  end
end
