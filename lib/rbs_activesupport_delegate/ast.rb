# frozen_string_literal: true

module RbsActivesupportDelegate
  module AST
    def eval_args(node)
      # @type var args: Array[Array[Symbol?]]
      *args, _ = eval_node(node)
      args
    end

    def eval_args_with_options(node)
      # @type var methods: Array[Symbol]
      # @type var options: Hash[Symbol, untyped]
      *args, _ = eval_node(node)
      if args.last.is_a?(Hash)
        options = args.pop
        [args, options]
      else
        [args, {}]
      end
    end

    def eval_node(node)
      case node
      when nil
        nil
      when Symbol, Hash # Only for debug use
        node
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
        when :NIL
          nil
        when :CONST
          node.children
        when :COLON2
          eval_node(node.children.first) + [node.children.last]
        when :COLON3
          [nil, node.children.first]
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
