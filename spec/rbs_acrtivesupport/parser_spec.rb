# frozen_string_literal: true

require "rbs_activesupport"

RSpec.describe RbsActivesupport::Parser do
  include RbsActivesupport::AST

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

          class Baz
            included do
              class_attribute :foo
            end
          end
        RUBY
      end

      it "collects class_attribute calls" do
        subject
        expect(parser.method_calls.size).to eq 3

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 2
        expect(method_calls[0].name).to eq :class_attribute
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, nil]
        expect(method_calls[1].name).to eq :class_attribute
        expect(method_calls[1].private?).to be_falsey
        expect(method_calls[1].included).to be_falsey
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
        expect(method_calls[0].included).to be_falsy
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]

        context, method_calls = parser.method_calls.to_a[2]
        expect(context.path).to eq [:Baz]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :class_attribute
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_truthy
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

          class Baz
            included do
              delegate :foo, to: :bar
            end
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
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, { to: :bar }, nil]
        expect(method_calls[1].name).to eq :delegate
        expect(method_calls[1].private?).to be_falsey
        expect(method_calls[1].included).to be_falsey
        expect(eval_node(method_calls[1].args)).to eq [:baz, :qux, { to: :quux, prefix: true }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :delegate
        expect(method_calls[0].private?).to be_truthy
        expect(method_calls[0].included).to be_falsey
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

          class Baz
            included do
              cattr_accessor :foo
            end
          end
        RUBY
      end

      it "collects cattr_accessor calls" do
        subject
        expect(parser.method_calls.size).to eq 3

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_accessor
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, { instance_accessor: false }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_accessor
        expect(method_calls[0].private?).to be_truthy
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]

        context, method_calls = parser.method_calls.to_a[2]
        expect(context.path).to eq [:Baz]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_accessor
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_truthy
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

          module Baz
            included do
              mattr_accessor :foo
            end
          end
        RUBY
      end

      it "collects mattr_accessor calls" do
        subject
        expect(parser.method_calls.size).to eq 3

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_accessor
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, { instance_accessor: false }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_accessor
        expect(method_calls[0].private?).to be_truthy
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]

        context, method_calls = parser.method_calls.to_a[2]
        expect(context.path).to eq [:Baz]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_accessor
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_truthy
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

          class Baz
            included do
              cattr_reader :foo
            end
          end
        RUBY
      end

      it "collects cattr_reader calls" do
        subject
        expect(parser.method_calls.size).to eq 3

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_reader
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, { instance_reader: false }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_reader
        expect(method_calls[0].private?).to be_truthy
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]

        context, method_calls = parser.method_calls.to_a[2]
        expect(context.path).to eq [:Baz]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_reader
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_truthy
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

          module Baz
            included do
              mattr_reader :foo
            end
          end
        RUBY
      end

      it "collects mattr_reader calls" do
        subject
        expect(parser.method_calls.size).to eq 3

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_reader
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, { instance_reader: false }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_reader
        expect(method_calls[0].private?).to be_truthy
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]

        context, method_calls = parser.method_calls.to_a[2]
        expect(context.path).to eq [:Baz]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_reader
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_truthy
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

          class Baz
            included do
              cattr_writer :foo
            end
          end
        RUBY
      end

      it "collects cattr_writer calls" do
        subject
        expect(parser.method_calls.size).to eq 3

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_writer
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, { instance_writer: false }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_writer
        expect(method_calls[0].private?).to be_truthy
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]

        context, method_calls = parser.method_calls.to_a[2]
        expect(context.path).to eq [:Baz]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :cattr_writer
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_truthy
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

          module Baz
            included do
              mattr_writer :foo
            end
          end
        RUBY
      end

      it "collects mattr_writer calls" do
        subject
        expect(parser.method_calls.size).to eq 3

        context, method_calls = parser.method_calls.to_a[0]
        expect(context.path).to eq [:Foo]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_writer
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, :bar, { instance_writer: false }, nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_writer
        expect(method_calls[0].private?).to be_truthy
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]

        context, method_calls = parser.method_calls.to_a[2]
        expect(context.path).to eq [:Baz]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :mattr_writer
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_truthy
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

          module Baz
            included do
              include Bar, Baz
            end
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
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [RBS::Namespace.parse("Bar"), nil]
        expect(method_calls[1].name).to eq :include
        expect(method_calls[1].private?).to be_falsey
        expect(method_calls[1].included).to be_falsey
        expect(eval_node(method_calls[1].args)).to eq [RBS::Namespace.parse("Bar::Baz"), nil]
        expect(method_calls[2].name).to eq :include
        expect(method_calls[2].private?).to be_falsey
        expect(method_calls[2].included).to be_falsey
        expect(eval_node(method_calls[2].args)).to eq [RBS::Namespace.parse("::Bar::Baz::Qux"), nil]

        context, method_calls = parser.method_calls.to_a[1]
        expect(context.path).to eq [:Bar]

        expect(method_calls.size).to eq 1
        expect(method_calls[0].name).to eq :include
        expect(method_calls[0].private?).to be_falsey
        expect(method_calls[0].included).to be_falsey
        expect(eval_node(method_calls[0].args)).to eq [RBS::Namespace.parse("Bar"), RBS::Namespace.parse("Baz"), nil]
      end
    end

    context "When the code contains trailing comments" do
      let(:code) do
        <<~RUBY
          class Foo
            class_attribute :foo  #: Integer
            class_attribute :bar  #: String
            class_attribute :baz
          end
        RUBY
      end

      it "collects trailing comments" do
        subject
        expect(parser.method_calls.size).to eq 1

        _, method_calls = parser.method_calls.to_a[0]
        expect(method_calls.size).to eq 3
        expect(method_calls[0].name).to eq :class_attribute
        expect(eval_node(method_calls[0].args)).to eq [:foo, nil]
        expect(method_calls[0].trailing_comment).to eq "#: Integer"

        expect(method_calls[1].name).to eq :class_attribute
        expect(eval_node(method_calls[1].args)).to eq [:bar, nil]
        expect(method_calls[1].trailing_comment).to eq "#: String"

        expect(method_calls[2].name).to eq :class_attribute
        expect(eval_node(method_calls[2].args)).to eq [:baz, nil]
        expect(method_calls[2].trailing_comment).to eq nil
      end
    end

    context "When the definitions are declared inside method definition" do
      let(:code) do
        <<~RUBY
          class Foo
            def self.foo
              class_attribute :foo  #: Integer
              delegate :bar, to: :baz
              include ActiveSupport::Concern
            end
          end
        RUBY
      end

      it "collects trailing comments" do
        subject
        expect(parser.method_calls.size).to eq 0
      end
    end
  end
end
