# frozen_string_literal: true

module RbsActivesupportDelegate
  class Generator
    def self.generate(pathname, rbs_builder)
      new(pathname, rbs_builder).generate
    end

    include AST

    attr_reader :pathname, :rbs_builder

    def initialize(pathname, rbs_builder)
      @pathname = pathname
      @rbs_builder = rbs_builder
    end

    def generate
      delegates = parse_source_code
      return if delegates.empty?

      definition = delegates.map do |namespace, decls|
        private_delegates, public_delegates = decls_to_delegate(namespace, decls).partition(&:private?)
        <<~RBS
          #{header(namespace)}
          #{public_delegates.map { |d| delegate_declration(d) }.join("\n")}

          #{"private" if private_delegates.any?}

          #{private_delegates.map { |d| delegate_declration(d) }.join("\n")}

          #{footer}
        RBS
      end.join("\n")
      format(definition)
    end

    private

    def format(rbs)
      parsed = RBS::Parser.parse_signature(rbs)
      StringIO.new.tap do |out|
        RBS::Writer.new(out:).write(parsed[1] + parsed[2])
      end.string
    end

    def parse_source_code
      parser = Parser.new
      parser.parse(pathname.read)
      parser.delegates
    end

    def decls_to_delegate(namespace, decls)
      decls.flat_map do |decl|
        methods, options = eval_delegate_args(decl)
        methods.map do |method|
          Delegate.new(namespace, method, options)
        end
      end
    end

    def header(namespace)
      "class #{namespace.path.join("::")}"
    end

    def delegate_declration(delegate)
      method_types = method_searcher.method_types_for(delegate)

      "def #{delegate.method_name}: #{method_types.join(" | ")}"
    end

    def footer
      "end"
    end

    def method_searcher
      @method_searcher ||= MethodSearcher.new(rbs_builder)
    end
  end
end