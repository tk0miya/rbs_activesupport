# frozen_string_literal: true

module RbsActivesupportDelegate
  class Generator
    def self.generate(pathname, rbs_builder)
      new(pathname, rbs_builder).generate
    end

    attr_reader :pathname, :declaration_builder

    def initialize(pathname, rbs_builder)
      @pathname = pathname

      method_searcher = MethodSearcher.new(rbs_builder)
      @declaration_builder = DeclarationBuilder.new(method_searcher)
    end

    def generate
      declarations = parse_source_code
      return if declarations.empty?

      definition = declarations.map do |namespace, method_calls|
        public_decls, private_decls = declaration_builder.build(namespace, method_calls)
        <<~RBS
          #{header(namespace)}
          #{public_decls.join("\n")}

          #{"private" if private_decls.any?}

          #{private_decls.join("\n")}

          #{footer(namespace)}
        RBS
      end.join("\n")
      format(definition)
    end

    private

    def format(rbs)
      parsed = RBS::Parser.parse_signature(rbs)
      StringIO.new.tap do |out|
        RBS::Writer.new(out: out).write(parsed[1] + parsed[2])
      end.string
    end

    def parse_source_code
      parser = Parser.new
      parser.parse(pathname.read)
      parser.method_calls
    end

    def header(namespace)
      context = +""
      namespace.path.map do |mod_name|
        context += "::#{mod_name}"
        mod_object = Object.const_get(context)
        case mod_object
        when Class
          # @type var superclass: Class
          superclass = _ = mod_object.superclass
          superclass_name = superclass.name || "Object"

          "class #{mod_name} < ::#{superclass_name}"
        when Module
          "module #{mod_name}"
        else
          raise "unreachable"
        end
      end.join("\n")
    end

    def footer(namespace)
      "end\n" * namespace.path.size
    end
  end
end
