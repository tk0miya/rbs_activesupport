# frozen_string_literal: true

require "tempfile"
require "rbs_activesupport_delegate"

RSpec.describe RbsActivesupportDelegate::Generator do
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

    context "When the target code does not contain delegate calls" do
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
            class Foo
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
            class Foo
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
            end
          RUBY
        end
        let(:expected) do
          <<~RBS
            class Foo
              def size: () -> ::Integer

              private

              def succ: () -> ::String
            end
          RBS
        end

        it { is_expected.to eq expected }
      end
    end
  end
end