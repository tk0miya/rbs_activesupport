# frozen_string_literal: true

module RbsActivesupport
  module AST
    # @rbs node: Array[untyped]
    def eval_include_args(node) #: Array[RBS::Namespace]
      # @type var args: Array[RBS::Namespace]
      *args, _ = eval_node(node)
      args
    end

    # @rbs node: Array[untyped]
    def eval_args_with_options(node) #: [Array[Symbol], Hash[Symbol, untyped]]
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
      when Symbol, Hash, RBS::Namespace # Only for debug use
        node
      when Array
        node.map { |e| eval_node(e) }
      when RubyVM::AbstractSyntaxTree::Node
        case node.type
        when :LIT, :STR
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
          RBS::Namespace.new(path: node.children, absolute: false)
        when :COLON2
          eval_node(node.children.first) + RBS::Namespace.new(path: [node.children.last], absolute: false)
        when :COLON3
          RBS::Namespace.new(path: node.children, absolute: true)
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
