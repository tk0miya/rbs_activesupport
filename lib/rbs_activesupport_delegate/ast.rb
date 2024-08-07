# frozen_string_literal: true

module RbsActivesupportDelegate
  module AST
    def eval_delegate_args(args)
      # @type var methods: Array[Symbol]
      # @type var options: Hash[Symbol, untyped]
      *methods, options, _ = eval_node(args)
      [methods, options]
    end

    def eval_node(node) # rubocop:disable Metrics/CyclomaticComplexity
      case node
      when nil
        nil
      when Array
        node.map { |e| eval_node(e) }
      when RubyVM::AbstractSyntaxTree::Node
        case node.type
        when :LIT
          node.children.first
        when :HASH
          elem = node.children.first.children.compact.map { |e| eval_node(e) }
          Hash[*elem]
        when :TRUE
          true
        when :FALSE
          false
        else
          p node # for debug
          raise
        end
      else
        p node # for debug
        raise
      end
    end
  end
end
