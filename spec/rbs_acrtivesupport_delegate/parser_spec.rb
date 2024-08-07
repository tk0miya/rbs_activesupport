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
          delegate :foo, to: :bar
        end
      RUBY
    end

    it "collects delegate calls" do
      subject
      expect(parser.delegates.size).to eq 2

      context, args = parser.delegates.to_a[0]
      expect(context.path).to eq [:Foo]

      expect(args.size).to eq 2
      expect(eval_node(args[0])).to eq [:foo, { to: :bar }, nil]
      expect(eval_node(args[1])).to eq [:baz, :qux, { to: :quux, prefix: true }, nil]

      context, args = parser.delegates.to_a[1]
      expect(context.path).to eq [:Bar]

      expect(args.size).to eq 1
      expect(eval_node(args[0])).to eq [:foo, { to: :bar }, nil]
    end
  end
end
