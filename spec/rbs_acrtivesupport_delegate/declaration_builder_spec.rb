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

    context "When the method_calls contains class_attribute calls" do
      let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
      let(:method_calls) { method_calls_raw.map { |c| RbsActivesupportDelegate::Parser::MethodCall.new(*c) } }

      context "When no options are passed to the class_attribute call" do
        let(:method_calls_raw) { [[:class_attribute, [:foo, :bar, nil], false]] }

        it "Returns the all of method declarations" do
          expect(subject).to eq [
            [
              ["def self.foo: () -> untyped",
               "def self.foo=: (untyped) -> untyped",
               "def self.foo?: () -> bool",
               "def foo: () -> untyped",
               "def foo=: (untyped) -> untyped",
               "def foo?: () -> bool"].join("\n"),
              ["def self.bar: () -> untyped",
               "def self.bar=: (untyped) -> untyped",
               "def self.bar?: () -> bool",
               "def bar: () -> untyped",
               "def bar=: (untyped) -> untyped",
               "def bar?: () -> bool"].join("\n")
            ],
            []
          ]
        end
      end

      context "When instance_accessor option is false" do
        let(:method_calls_raw) do
          [
            [:class_attribute, [:foo, { instance_accessor: false }, nil], false]
          ]
        end

        it "Returns the method declarations without instance_accessor" do
          expect(subject).to eq [
            [
              ["def self.foo: () -> untyped",
               "def self.foo=: (untyped) -> untyped",
               "def self.foo?: () -> bool"].join("\n")
            ],
            []
          ]
        end
      end

      context "When instance_reader option is false" do
        let(:method_calls_raw) do
          [
            [:class_attribute, [:foo, { instance_reader: false }, nil], false]
          ]
        end

        it "Returns the method declarations without instance_reader" do
          expect(subject).to eq [
            [
              ["def self.foo: () -> untyped",
               "def self.foo=: (untyped) -> untyped",
               "def self.foo?: () -> bool",
               "def foo=: (untyped) -> untyped"].join("\n")
            ],
            []
          ]
        end
      end

      context "When instance_writer option is false" do
        let(:method_calls_raw) do
          [
            [:class_attribute, [:foo, { instance_writer: false }, nil], false]
          ]
        end

        it "Returns the method declarations without instance_writer" do
          expect(subject).to eq [
            [
              ["def self.foo: () -> untyped",
               "def self.foo=: (untyped) -> untyped",
               "def self.foo?: () -> bool",
               "def foo: () -> untyped",
               "def foo?: () -> bool"].join("\n")
            ],
            []
          ]
        end
      end

      context "When instance_predicate option is false" do
        let(:method_calls_raw) do
          [
            [:class_attribute, [:foo, { instance_predicate: false }, nil], false]
          ]
        end

        it "Returns the method declarations without predicates" do
          expect(subject).to eq [
            [
              ["def self.foo: () -> untyped",
               "def self.foo=: (untyped) -> untyped",
               "def foo: () -> untyped",
               "def foo=: (untyped) -> untyped"].join("\n")
            ],
            []
          ]
        end
      end

      context "When the class_attribute call is private" do
        let(:method_calls_raw) { [[:class_attribute, [:foo, nil], true]] }

        it "Returns the all of method declarations as private" do
          expect(subject).to eq [
            [],
            [
              ["def self.foo: () -> untyped",
               "def self.foo=: (untyped) -> untyped",
               "def self.foo?: () -> bool",
               "def foo: () -> untyped",
               "def foo=: (untyped) -> untyped",
               "def foo?: () -> bool"].join("\n")
            ]
          ]
        end
      end
    end

    context "When the method_calls contains cattr_accessor/mattr_accessor calls" do
      let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
      let(:method_calls) { method_calls_raw.map { |c| RbsActivesupportDelegate::Parser::MethodCall.new(*c) } }

      context "When no options are given" do
        let(:method_calls_raw) do
          [
            [:cattr_accessor, [:foo, nil], false],
            [:mattr_accessor, [:bar, nil], true]
          ]
        end

        it "Returns the declarations for delegations" do
          expect(subject).to eq [
            [
              [
                "def self.foo: () -> untyped",
                "def self.foo=: (untyped) -> untyped",
                "def foo: () -> untyped",
                "def foo=: (untyped) -> untyped"
              ].join("\n")
            ],
            [
              [
                "def self.bar: () -> untyped",
                "def self.bar=: (untyped) -> untyped",
                "def bar: () -> untyped",
                "def bar=: (untyped) -> untyped"
              ].join("\n")
            ]
          ]
        end
      end

      context "When instance_accessor is false" do
        let(:method_calls_raw) do
          [
            [:cattr_accessor, [:foo, { instance_accessor: false }, nil], false],
            [:mattr_accessor, [:bar, { instance_accessor: false }, nil], true]
          ]
        end

        it "Returns the declarations for delegations" do
          expect(subject).to eq [
            [
              [
                "def self.foo: () -> untyped",
                "def self.foo=: (untyped) -> untyped"
              ].join("\n")
            ],
            [
              [
                "def self.bar: () -> untyped",
                "def self.bar=: (untyped) -> untyped"
              ].join("\n")
            ]
          ]
        end
      end

      context "When instance_reader is false" do
        let(:method_calls_raw) do
          [
            [:cattr_accessor, [:foo, { instance_reader: false }, nil], false],
            [:mattr_accessor, [:bar, { instance_reader: false }, nil], true]
          ]
        end

        it "Returns the declarations for delegations" do
          expect(subject).to eq [
            [
              [
                "def self.foo: () -> untyped",
                "def self.foo=: (untyped) -> untyped",
                "def foo=: (untyped) -> untyped"
              ].join("\n")
            ],
            [
              [
                "def self.bar: () -> untyped",
                "def self.bar=: (untyped) -> untyped",
                "def bar=: (untyped) -> untyped"
              ].join("\n")
            ]
          ]
        end
      end

      context "When instance_writer is false" do
        let(:method_calls_raw) do
          [
            [:cattr_accessor, [:foo, { instance_writer: false }, nil], false],
            [:mattr_accessor, [:bar, { instance_writer: false }, nil], true]
          ]
        end

        it "Returns the declarations for delegations" do
          expect(subject).to eq [
            [
              [
                "def self.foo: () -> untyped",
                "def self.foo=: (untyped) -> untyped",
                "def foo: () -> untyped"
              ].join("\n")
            ],
            [
              [
                "def self.bar: () -> untyped",
                "def self.bar=: (untyped) -> untyped",
                "def bar: () -> untyped"
              ].join("\n")
            ]
          ]
        end
      end
    end
  end
end
