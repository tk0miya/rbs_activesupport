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

    # @rbs node: untyped
    def eval_node(node) #: untyped  # rubocop:disable Metrics/PerceivedComplexity
      case node
      when nil
        nil
      when Symbol, Hash, RBS::Namespace # Only for debug use
        node
      when Array
        node.map { eval_node(_1) }
      when RubyVM::AbstractSyntaxTree::Node
        case node.type
        when :LIT, :STR, :SYM, :INTEGER, :FLOAT
          node.children.first
        when :HASH
          children = node.children.first&.children
          if children
            items = children.compact.map { eval_node(_1) }
            Hash[*items]
          else
            {}
          end
        when :ZLIST
          []
        when :LIST
          node.children[...-1]&.map { eval_node(_1) }
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
        when :CALL, :ITER
          node
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
