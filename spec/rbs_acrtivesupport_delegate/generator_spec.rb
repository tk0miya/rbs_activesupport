# frozen_string_literal: true

require "tempfile"
require "rbs_activesupport_delegate"

class Foo
end

module Bar
end

module Baz
  extend ActiveSupport::Concern

  module ClassMethods
  end
end

RSpec.describe RbsActivesupportDelegate::Generator do
  describe ".generate" do
    subject { described_class.generate(pathname, rbs_builder) }

    let(:rbs_builder) { RBS::DefinitionBuilder.new(env: env) }
    let(:env) do
      env = RBS::Environment.new

      RBS::EnvironmentLoader.new.load(env: env)
      buffer, directives, decls = RBS::Parser.parse_signature(signature)
      env.add_signature(buffer: buffer, directives: directives, decls: decls)
      env.resolve_type_names
    end
    let(:signature) do
      <<~RBS
        class Foo
          def bar: () -> String
        end
      RBS
    end
    let(:tempfile) do
      Tempfile.new.tap do |f|
        f.write(code)
        f.close
        f.open
      end
    end
    let(:pathname) { Pathname.new(tempfile.path) }

    context "When the target code does not contain any target calls" do
      let(:code) do
        <<~RUBY
          class Foo
            def bar
              "String"
            end
          end
        RUBY
      end

      it "Returns nil" do
        is_expected.to eq nil
      end
    end

    context "When the target code contains class_attribute calls" do
      let(:code) do
        <<~RUBY
          class Foo
            class_attribute :bar
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          class Foo < ::Object
            def self.bar: () -> untyped
            def self.bar=: (untyped) -> untyped
            def self.bar?: () -> bool
            def bar: () -> untyped
            def bar=: (untyped) -> untyped
            def bar?: () -> bool
          end
        RBS
      end

      it { is_expected.to eq expected }
    end

    context "When the target code contains delegate calls" do
      context "When the target code contains multiple delegates" do
        let(:code) do
          <<~RUBY
            class Foo
              delegate :size, :succ, to: :bar

              def bar
                "String"
              end
            end
          RUBY
        end
        let(:expected) do
          <<~RBS
            class Foo < ::Object
              def size: () -> ::Integer
              def succ: () -> ::String
            end
          RBS
        end

        it { is_expected.to eq expected }
      end

      context "When the target code contains prefixed delegates" do
        let(:code) do
          <<~RUBY
            class Foo
              delegate :size, :succ, to: :bar, prefix: true

              def bar
                "String"
              end
            end
          RUBY
        end
        let(:expected) do
          <<~RBS
            class Foo < ::Object
              def bar_size: () -> ::Integer
              def bar_succ: () -> ::String
            end
          RBS
        end

        it { is_expected.to eq expected }
      end

      context "When the target code contains both public and private delegates" do
        let(:code) do
          <<~RUBY
            class Foo
              delegate :size, to: :bar
              delegate :succ, to: :bar, private: true

              def bar
                "String"
              end

              private

              delegate :chomp, to: :bar
            end
          RUBY
        end
        let(:expected) do
          <<~RBS
            class Foo < ::Object
              def size: () -> ::Integer

              private

              def succ: () -> ::String
              def chomp: (?::string? separator) -> ::String
            end
          RBS
        end

        it { is_expected.to eq expected }
      end
    end

    context "When the target code contains cattr_accessor calls" do
      let(:code) do
        <<~RUBY
          class Foo
            cattr_accessor :bar
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          class Foo < ::Object
            def self.bar: () -> untyped
            def self.bar=: (untyped) -> untyped
            def bar: () -> untyped
            def bar=: (untyped) -> untyped
          end
        RBS
      end

      it { is_expected.to eq expected }
    end

    context "When the target code contains mattr_accessor calls" do
      let(:code) do
        <<~RUBY
          module Bar
            mattr_accessor :bar
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          module Bar
            def self.bar: () -> untyped

            def self.bar=: (untyped) -> untyped

            def bar: () -> untyped

            def bar=: (untyped) -> untyped
          end
        RBS
      end

      it { is_expected.to eq expected }
    end

    context "When the target code contains cattr_reader calls" do
      let(:code) do
        <<~RUBY
          class Foo
            cattr_reader :bar
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          class Foo < ::Object
            def self.bar: () -> untyped
            def bar: () -> untyped
          end
        RBS
      end

      it { is_expected.to eq expected }
    end

    context "When the target code contains mattr_reader calls" do
      let(:code) do
        <<~RUBY
          module Bar
            mattr_reader :bar
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          module Bar
            def self.bar: () -> untyped

            def bar: () -> untyped
          end
        RBS
      end

      it { is_expected.to eq expected }
    end

    context "When the target code contains cattr_writer calls" do
      let(:code) do
        <<~RUBY
          class Foo
            cattr_writer :bar
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          class Foo < ::Object
            def self.bar=: (untyped) -> untyped
            def bar=: (untyped) -> untyped
          end
        RBS
      end

      it { is_expected.to eq expected }
    end

    context "When the target code contains mattr_writer calls" do
      let(:code) do
        <<~RUBY
          module Bar
            mattr_writer :bar
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          module Bar
            def self.bar=: (untyped) -> untyped

            def bar=: (untyped) -> untyped
          end
        RBS
      end

      it { is_expected.to eq expected }
    end

    context "When the target code contains include calls" do
      context "When the included module is a concern" do
        let(:code) do
          <<~RUBY
            class Foo
              include Baz
            end
          RUBY
        end
        let(:expected) do
          <<~RBS
            class Foo < ::Object
              include Baz
              extend Baz::ClassMethods
            end
          RBS
        end

        it { is_expected.to eq expected }
      end

      context "When the included module is not a concern" do
        let(:code) do
          <<~RUBY
            class Foo
              include Unknown
            end
          RUBY
        end

        it { is_expected.to eq nil }
      end
    end
  end
end
