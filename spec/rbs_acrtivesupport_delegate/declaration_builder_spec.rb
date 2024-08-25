# frozen_string_literal: true

require "rbs_activesupport_delegate"

RSpec.describe RbsActivesupportDelegate::DeclarationBuilder do
  describe "#build" do
    subject { described_class.new(method_searcher).build(namespace, method_calls) }

    let(:method_searcher) { RbsActivesupportDelegate::MethodSearcher.new(rbs_builder) }
    let(:rbs_builder) { RBS::DefinitionBuilder.new(env:) }
    let(:env) do
      env = RBS::Environment.new

      RBS::EnvironmentLoader.new.load(env:)
      buffer, directives, decls = RBS::Parser.parse_signature(signature)
      env.add_signature(buffer:, directives:, decls:)
      env.resolve_type_names
    end
    let(:signature) do
      <<~RBS
        class Foo
          def bar: () -> String
        end
      RBS
    end

    context "When the method_calls contains delegate calls" do
      let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
      let(:method_calls) { method_calls_raw.map { |c| RbsActivesupportDelegate::Parser::MethodCall.new(*c) } }
      let(:method_calls_raw) do
        [
          [:delegate, [:size, :to_s, { to: :bar }, nil], false],
          [:delegate, [:succ, { to: :bar }, nil], true]
        ]
      end

      it "Returns the declarations for delegations" do
        expect(subject).to eq [["def size: () -> ::Integer", "def to_s: () -> ::String"],
                               ["def succ: () -> ::String"]]
      end
    end
  end
end
