# frozen_string_literal: true

require "rbs_activesupport_delegate"

RSpec.describe RbsActivesupportDelegate::Parser do
  include RbsActivesupportDelegate::AST

  describe "#parse" do
    subject { parser.parse(code) }

    let(:parser) { described_class.new }

    context "When the code contains class_attribute calls" do
      let(:code) do
        <<~RUBY
          class Foo
            class_attribute :foo, :bar
            class_attribute :baz, instance_accessor: false, instance_reader: false, instance_writer: false, instance_predicate: false, default: nil
          end

          class Bar
            private

            class_attribute :foo
          end
        RUBY
      end

      it "collects class_attribute calls" do
        subject
        expect(parser.method_calls.size).to eq 2

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 2
        expect(method_calls[0].name).to eq :class_attribute
        expect(method_calls[0].private?).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, nil]
        expect(method_calls[1].name).to eq :class_attribute
        expect(method_calls[1].private?).to be_falsey
        expect(eval_node(method_calls[1].args)).to eq [:baz,
                                                       { instance_accessor: false,
                                                         instance_reader: false,
                                                         instance_writer: false,
                                                         instance_predicate: false,
                                                         default: nil },
                                                       nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :class_attribute
        expect(method_calls[0].private?).to be_truthy
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]
      end
    end

    context "When the code contains delegate calls" do
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
        expect(parser.method_calls.size).to eq 2

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 2
        expect(method_calls[0].name).to eq :delegate
        expect(method_calls[0].private?).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, { to: :bar }, nil]
        expect(method_calls[1].name).to eq :delegate
        expect(method_calls[1].private?).to be_falsey
        expect(eval_node(method_calls[1].args)).to eq [:baz, :qux, { to: :quux, prefix: true }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :delegate
        expect(method_calls[0].private?).to be_truthy
        expect(eval_node(method_calls[0].args)).to eq [:foo, { to: :bar }, nil]
      end
    end

    context "When the code contains cattr_accessor calls" do
      let(:code) do
        <<~RUBY
          class Foo
            cattr_accessor :foo, :bar, instance_accessor: false
          end

          class Bar
            private

            cattr_accessor :foo
          end
        RUBY
      end

      it "collects cattr_accessor calls" do
        subject
        expect(parser.method_calls.size).to eq 2

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_accessor
        expect(method_calls[0].private?).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, { instance_accessor: false }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_accessor
        expect(method_calls[0].private?).to be_truthy
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]
      end
    end

    context "When the code contains mattr_accessor calls" do
      let(:code) do
        <<~RUBY
          module Foo
            mattr_accessor :foo, :bar, instance_accessor: false
          end

          module Bar
            private

            mattr_accessor :foo
          end
        RUBY
      end

      it "collects mattr_accessor calls" do
        subject
        expect(parser.method_calls.size).to eq 2

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_accessor
        expect(method_calls[0].private?).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, { instance_accessor: false }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_accessor
        expect(method_calls[0].private?).to be_truthy
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]
      end
    end

    context "When the code contains cattr_reader calls" do
      let(:code) do
        <<~RUBY
          class Foo
            cattr_reader :foo, :bar, instance_reader: false
          end

          class Bar
            private

            cattr_reader :foo
          end
        RUBY
      end

      it "collects cattr_reader calls" do
        subject
        expect(parser.method_calls.size).to eq 2

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_reader
        expect(method_calls[0].private?).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, { instance_reader: false }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_reader
        expect(method_calls[0].private?).to be_truthy
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]
      end
    end

    context "When the code contains mattr_reader calls" do
      let(:code) do
        <<~RUBY
          module Foo
            mattr_reader :foo, :bar, instance_reader: false
          end

          module Bar
            private

            mattr_reader :foo
          end
        RUBY
      end

      it "collects mattr_reader calls" do
        subject
        expect(parser.method_calls.size).to eq 2

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_reader
        expect(method_calls[0].private?).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, { instance_reader: false }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_reader
        expect(method_calls[0].private?).to be_truthy
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]
      end
    end

    context "When the code contains cattr_writer calls" do
      let(:code) do
        <<~RUBY
          class Foo
            cattr_writer :foo, :bar, instance_writer: false
          end

          class Bar
            private

            cattr_writer :foo
          end
        RUBY
      end

      it "collects cattr_writer calls" do
        subject
        expect(parser.method_calls.size).to eq 2

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_writer
        expect(method_calls[0].private?).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, { instance_writer: false }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_writer
        expect(method_calls[0].private?).to be_truthy
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]
      end
    end

    context "When the code contains mattr_writer calls" do
      let(:code) do
        <<~RUBY
          module Foo
            mattr_writer :foo, :bar, instance_writer: false
          end

          module Bar
            private

            mattr_writer :foo
          end
        RUBY
      end

      it "collects mattr_writer calls" do
        subject
        expect(parser.method_calls.size).to eq 2

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_writer
        expect(method_calls[0].private?).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, { instance_writer: false }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_writer
        expect(method_calls[0].private?).to be_truthy
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]
      end
    end

    context "When the code contains include calls" do
      let(:code) do
        <<~RUBY
          module Foo
            include Bar
            include Bar::Baz
            include ::Bar::Baz::Qux
          end

          module Bar
            include Bar, Baz
          end
        RUBY
      end

      it "collects include calls" do
        subject
        expect(parser.method_calls.size).to eq 2

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 3
        expect(method_calls[0].name).to eq :include
        expect(method_calls[0].private?).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [[:Bar], nil]
        expect(method_calls[1].name).to eq :include
        expect(method_calls[1].private?).to be_falsey
        expect(eval_node(method_calls[1].args)).to eq [%i[Bar Baz], nil]
        expect(method_calls[2].name).to eq :include
        expect(method_calls[2].private?).to be_falsey
        expect(eval_node(method_calls[2].args)).to eq [[nil, :Bar, :Baz, :Qux], nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :include
        expect(method_calls[0].private?).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [[:Bar], [:Baz], nil]
      end
    end
  end
end
