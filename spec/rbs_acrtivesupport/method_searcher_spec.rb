# frozen_string_literal: true

require "rbs_activesupport"

RSpec.describe RbsActivesupport::MethodSearcher do
  describe "#method_types_for" do
    subject { described_class.new(rbs_builder).method_types_for(delegate) }

    let(:rbs_builder) { RBS::DefinitionBuilder.new(env:) }
    let(:env) do
      env = RBS::Environment.new

      RBS::EnvironmentLoader.new.load(env:)
      buffer, directives, decls = RBS::Parser.parse_signature(signature)
      env.add_signature(buffer:, directives:, decls:)
      env.resolve_type_names
    end

    context "When the delegated object not found" do
      let(:signature) do
        <<~RBS
          class Foo
          end
        RBS
      end
      let(:delegate) { RbsActivesupport::Delegate.new(namespace, :baz, { to: :bar }) }
      let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }

      it "Returns () -> untyped" do
        expect(subject).to eq ["() -> untyped"]
      end
    end

    context "When the delegated object found" do
      context "When the delegated object is Any" do
        let(:signature) do
          <<~RBS
            class Foo
              def bar: () -> untyped
            end
          RBS
        end
        let(:delegate) { RbsActivesupport::Delegate.new(namespace, :baz, { to: :bar }) }
        let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }

        it "Returns () -> untyped" do
          expect(subject).to eq ["() -> untyped"]
        end
      end

      context "When the delegated object has any concrete type" do
        context "When the delegated method not found" do
          let(:signature) do
            <<~RBS
              class Foo
                def bar: () -> String
              end
            RBS
          end
          let(:delegate) { RbsActivesupport::Delegate.new(namespace, :baz, { to: :bar }) }
          let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }

          it "Returns () -> untyped" do
            expect(subject).to eq ["() -> untyped"]
          end
        end

        context "When the delegated method found" do
          let(:signature) do
            <<~RBS
              class Foo
                def bar: () -> String
              end
            RBS
          end
          let(:delegate) { RbsActivesupport::Delegate.new(namespace, :size, { to: :bar }) }
          let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }

          it { is_expected.to eq ["() -> ::Integer"] }
        end

        context "When the delegated method that returns OptionalValue found" do
          let(:signature) do
            <<~RBS
              class Foo
                def bar: () -> String?
              end
            RBS
          end
          let(:delegate) { RbsActivesupport::Delegate.new(namespace, :size, { to: :bar }) }
          let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }

          it { is_expected.to eq ["() -> ::Integer"] }
        end
      end
    end
  end
end
