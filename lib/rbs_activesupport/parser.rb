# frozen_string_literal: true

require "pathname"
require "rbs"
require "rbs/cli"
require "rbs/prototype/rb"

module RbsActivesupport
  class Parser < ::RBS::Prototype::RB
    class MethodCall
      attr_reader :name #: t
      attr_reader :args #: Array[RubyVM::AbstractSyntaxTree::Node]
      attr_reader :included #: bool
      attr_reader :trailing_comment #: String?

      # @rbs @private: bool

      # @rbs name: t
      # @rbs args: Array[RubyVM::AbstractSyntaxTree::Node]
      # @rbs private: bool
      # @rbs included: bool
      # @rbs trailing_comment: String?
      def initialize(name, args, private, included: false, trailing_comment: nil) #: void
        @name = name
        @args = args
        @private = private
        @included = included
        @trailing_comment = trailing_comment
      end

      def private? #: bool
        @private
      end
    end

    # @rbs!
    #   type t = :class_attribute | :delegate | :cattr_accessor | :mattr_accessor | :cattr_reader | :mattr_reader |
    #            :cattr_writer | :mattr_writer | :include

    METHODS = %i[
      class_attribute delegate cattr_accessor mattr_accessor cattr_reader mattr_reader cattr_writer mattr_writer include
    ].freeze #: Array[t] # steep:ignore IncompatibleAssignment
    INCLUDED_METHODS = %i[
      class_attribute cattr_accessor mattr_accessor cattr_reader mattr_reader cattr_writer mattr_writer
    ].freeze #: Array[Symbol]

    alias process_orig process

    attr_reader :comment_parser #: CommentParser
    attr_reader :method_calls #: Hash[RBS::Namespace, Array[MethodCall]]

    # @rbs @included: bool

    def initialize #: void
      super
      @comment_parser = CommentParser.new
      @method_calls = Hash.new { |hash, key| hash[key] = [] }
      @included = false
    end

    # @rbs string: String
    def parse(string) #: void
      comment_parser.parse(string)
      super
    end

    # @rbs override
    def process(node, decls:, comments:, context:) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      case node.type
      when :DEFN, :DEFS
        # ignore definitions inside methods
      when :FCALL, :VCALL
        args = node.children[1]&.children || []
        case node.children[0]
        when *METHODS
          return if included? && !INCLUDED_METHODS.include?(node.children[0])

          @method_calls[context.namespace] << MethodCall.new(node.children[0], args, private?(decls),
                                                             included: included?,
                                                             trailing_comment: trailing_comment_for(node))
        else
          process_orig(node, decls: decls, comments: comments, context: context)
        end
      when :ITER
        call = node.children[0]
        if call.type == :FCALL && call.children[0] == :included && !included?
          body = node.children[1].children[2]
          with_included do
            process(body, decls: decls, comments: comments, context: context)
          end
        else
          process_orig(node, decls: decls, comments: comments, context: context)
        end
      else
        process_orig(node, decls: decls, comments: comments, context: context)
      end
    end

    # @rbs node: RubyVM::AbstractSyntaxTree::Node
    def trailing_comment_for(node) #: String?
      comment_parser.trailing_comments[node.last_lineno]
    end

    # @rbs decls: Array[RBS::AST::Declarations::t | RBS::AST::Members::t]
    def private?(decls) #: bool
      current_accessibility(decls) == private
    end

    def included? #: bool
      @included
    end

    # @rbs &block: () -> void
    def with_included(&block) #: void
      @included = true
      block.call
    ensure
      @included = false
    end
  end
end
