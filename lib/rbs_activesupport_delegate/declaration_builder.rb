# frozen_string_literal: true

module RbsActivesupportDelegate
  class DeclarationBuilder
    include AST

    attr_reader :method_searcher

    def initialize(method_searcher)
      @method_searcher = method_searcher
    end

    def build(namespace, method_calls)
      public_decls, private_decls = build_method_calls(namespace, method_calls).partition(&:public?)
      [public_decls.map(&method(:render)), private_decls.map(&method(:render))] # steep:ignore BlockTypeMismatch
    end

    private

    def build_method_calls(namespace, method_calls)
      method_calls.flat_map do |method_call|
        case method_call.name
        when :delegate
          build_delegate(namespace, method_call)
        end
      end
    end

    def build_delegate(namespace, method_call)
      methods, options = eval_args_with_options(method_call.args)
      options[:private] = true if method_call.private?
      methods.map do |method|
        Delegate.new(namespace, method, options)
      end
    end

    def render(decl)
      case decl
      when Delegate
        render_delegate(decl)
      end
    end

    def render_delegate(decl)
      method_types = method_searcher.method_types_for(decl)

      "def #{decl.method_name}: #{method_types.join(" | ")}"
    end
  end
end
