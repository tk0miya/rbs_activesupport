# frozen_string_literal: true

require "tempfile"
require "rbs_activesupport"

class Foo
end

module Bar
end

module Baz
  extend ActiveSupport::Concern

  module ClassMethods
  end
end

RSpec.describe RbsActivesupport::Generator do
  describe ".generate" do
    subject { described_class.generate(pathname, rbs_builder) }

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
        class ::Foo
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

    context "When the target code is inside a nested class or module" do
      let(:code) do
        <<~RUBY
          class Baz
            module ClassMethods
              mattr_reader :qux #: String
            end
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          # resolve-type-names: false

          module ::Baz
            module ::Baz::ClassMethods
              def self.qux: () -> ::String

              def qux: () -> ::String
            end
          end
        RBS
      end

      it { is_expected.to eq expected }
    end

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
            class_attribute :bar  #: String
            class_attribute :baz  #: Array[Symbol]
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          # resolve-type-names: false

          class ::Foo < ::Object
            def self.bar: () -> ::String
            def self.bar=: (::String) -> ::String
            def self.bar?: () -> bool
            def bar: () -> ::String
            def bar=: (::String) -> ::String
            def bar?: () -> bool
            def self.baz: () -> ::Array[::Symbol]
            def self.baz=: (::Array[::Symbol]) -> ::Array[::Symbol]
            def self.baz?: () -> bool
            def baz: () -> ::Array[::Symbol]
            def baz=: (::Array[::Symbol]) -> ::Array[::Symbol]
            def baz?: () -> bool
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
            # resolve-type-names: false

            class ::Foo < ::Object
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
            # resolve-type-names: false

            class ::Foo < ::Object
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
            # resolve-type-names: false

            class ::Foo < ::Object
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
          class ::Foo
            cattr_accessor :bar  #: String
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          # resolve-type-names: false

          class ::Foo < ::Object
            def self.bar: () -> ::String
            def self.bar=: (::String) -> ::String
            def bar: () -> ::String
            def bar=: (::String) -> ::String
          end
        RBS
      end

      it { is_expected.to eq expected }
    end

    context "When the target code contains mattr_accessor calls" do
      let(:code) do
        <<~RUBY
          module Bar
            mattr_accessor :bar  #: String
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          # resolve-type-names: false

          module ::Bar
            def self.bar: () -> ::String

            def self.bar=: (::String) -> ::String

            def bar: () -> ::String

            def bar=: (::String) -> ::String
          end
        RBS
      end

      it { is_expected.to eq expected }
    end

    context "When the target code contains cattr_reader calls" do
      let(:code) do
        <<~RUBY
          class Foo
            cattr_reader :bar  #: String
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          # resolve-type-names: false

          class ::Foo < ::Object
            def self.bar: () -> ::String
            def bar: () -> ::String
          end
        RBS
      end

      it { is_expected.to eq expected }
    end

    context "When the target code contains mattr_reader calls" do
      let(:code) do
        <<~RUBY
          module Bar
            mattr_reader :bar  #: String
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          # resolve-type-names: false

          module ::Bar
            def self.bar: () -> ::String

            def bar: () -> ::String
          end
        RBS
      end

      it { is_expected.to eq expected }
    end

    context "When the target code contains cattr_writer calls" do
      let(:code) do
        <<~RUBY
          class Foo
            cattr_writer :bar  #: String
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          # resolve-type-names: false

          class ::Foo < ::Object
            def self.bar=: (::String) -> ::String
            def bar=: (::String) -> ::String
          end
        RBS
      end

      it { is_expected.to eq expected }
    end

    context "When the target code contains mattr_writer calls" do
      let(:code) do
        <<~RUBY
          module Bar
            mattr_writer :bar  #: String
          end
        RUBY
      end
      let(:expected) do
        <<~RBS
          # resolve-type-names: false

          module ::Bar
            def self.bar=: (::String) -> ::String

            def bar=: (::String) -> ::String
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
            # resolve-type-names: false

            class ::Foo < ::Object
              extend ::Baz::ClassMethods
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
