# frozen_string_literal: true

require "rbs_activesupport_delegate"

RSpec.describe RbsActivesupportDelegate::Parser do
  include RbsActivesupportDelegate::AST

  describe "#parse" do
    subject { parser.parse(code) }

    let(:parser) { described_class.new }
    let(:code) do
      <<~RUBY
        class Foo
          delegate :foo, to: :bar
          delegate :baz, :qux, to: :quux, prefix: true
        end

        class Bar
          private

          delegate :foo, to: :bar
        end
      RUBY
    end

    it "collects delegate calls" do
      subject
      expect(parser.delegates.size).to eq 2

      context, method_calls = parser.delegates.to_a[0]
      expect(context.path).to eq [:Foo]

      expect(method_calls.size).to eq 2
      expect(method_calls[0].private?).to be_falsey
      expect(eval_node(method_calls[0].args)).to eq [:foo, { to: :bar }, nil]
      expect(method_calls[1].private?).to be_falsey
      expect(eval_node(method_calls[1].args)).to eq [:baz, :qux, { to: :quux, prefix: true }, nil]

      context, method_calls = parser.delegates.to_a[1]
      expect(context.path).to eq [:Bar]

      expect(method_calls.size).to eq 1
      expect(method_calls[0].private?).to be_truthy
      expect(eval_node(method_calls[0].args)).to eq [:foo, { to: :bar }, nil]
    end
  end
end
