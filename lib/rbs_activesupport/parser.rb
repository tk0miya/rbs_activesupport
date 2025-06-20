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

    alias process_orig process

    attr_reader :comment_parser #: CommentParser
    attr_reader :method_calls #: Hash[RBS::Namespace, Array[MethodCall]]
    attr_reader :parse_included_block #: bool

    # @rbs @in_included_block: bool

    def initialize(parse_included_block: false) #: void
      super()
      @comment_parser = CommentParser.new
      @parse_included_block = parse_included_block
      @method_calls = Hash.new { |hash, key| hash[key] = [] }
      @in_included_block = false
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
          @method_calls[context.namespace] << MethodCall.new(node.children[0], args, private?(decls),
                                                             included: in_included_block?,
                                                             trailing_comment: trailing_comment_for(node))
        else
          process_orig(node, decls:, comments:, context:)
        end
      when :ITER
        call = node.children[0]
        if call.type == :FCALL && call.children[0] == :included && parse_included_block && !in_included_block?
          body = node.children[1].children[2]
          with_included_block do
            process(body, decls:, comments:, context:)
          end
        else
          process_orig(node, decls:, comments:, context:)
        end
      else
        process_orig(node, decls:, comments:, context:)
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

    def in_included_block? #: bool
      @in_included_block
    end

    # @rbs &block: () -> void
    def with_included_block(&block) #: void
      @in_included_block = true
      block.call
    ensure
      @in_included_block = false
    end
  end
end
