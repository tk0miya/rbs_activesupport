# frozen_string_literal: true

require "rbs_activesupport"
require_relative "../fixtures/included_class_attributes_module"
require_relative "../fixtures/included_delegate_module"
require_relative "../fixtures/included_include_module"
require_relative "../fixtures/nested_include_module"

RSpec.describe RbsActivesupport::DeclarationBuilder do
  describe "#build" do
    subject { described_class.new(resolver, method_searcher).build(namespace, method_calls) }

    let(:resolver) { RBS::Resolver::TypeNameResolver.new(env) }
    let(:method_searcher) { RbsActivesupport::MethodSearcher.new(rbs_builder) }
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

    context "when the method_calls contains delegate calls" do
      let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
      let(:method_calls) { method_calls_raw.map { |c| RbsActivesupport::Parser::MethodCall.new(*c) } }
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

    context "when the method_calls contains class_attribute calls" do
      let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
      let(:method_calls) { method_calls_raw.map { |c| RbsActivesupport::Parser::MethodCall.new(*c) } }

      context "when no options are passed to the class_attribute call" do
        let(:method_calls_raw) { [[:class_attribute, [:foo, :bar, nil], false]] }

        it "Returns the all of method declarations" do
          expect(subject).to eq [
            [
              ["def self.foo: () -> (untyped)",
               "def self.foo=: (untyped) -> (untyped)",
               "def self.foo?: () -> bool",
               "def foo: () -> (untyped)",
               "def foo=: (untyped) -> (untyped)",
               "def foo?: () -> bool"].join("\n"),
              ["def self.bar: () -> (untyped)",
               "def self.bar=: (untyped) -> (untyped)",
               "def self.bar?: () -> bool",
               "def bar: () -> (untyped)",
               "def bar=: (untyped) -> (untyped)",
               "def bar?: () -> bool"].join("\n")
            ],
            []
          ]
        end
      end

      context "when instance_accessor option is false" do
        let(:method_calls_raw) do
          [
            [:class_attribute, [:foo, { instance_accessor: false }, nil], false]
          ]
        end

        it "Returns the method declarations without instance_accessor" do
          expect(subject).to eq [
            [
              ["def self.foo: () -> (untyped)",
               "def self.foo=: (untyped) -> (untyped)",
               "def self.foo?: () -> bool"].join("\n")
            ],
            []
          ]
        end
      end

      context "when instance_reader option is false" do
        let(:method_calls_raw) do
          [
            [:class_attribute, [:foo, { instance_reader: false }, nil], false]
          ]
        end

        it "Returns the method declarations without instance_reader" do
          expect(subject).to eq [
            [
              ["def self.foo: () -> (untyped)",
               "def self.foo=: (untyped) -> (untyped)",
               "def self.foo?: () -> bool",
               "def foo=: (untyped) -> (untyped)"].join("\n")
            ],
            []
          ]
        end
      end

      context "when instance_writer option is false" do
        let(:method_calls_raw) do
          [
            [:class_attribute, [:foo, { instance_writer: false }, nil], false]
          ]
        end

        it "Returns the method declarations without instance_writer" do
          expect(subject).to eq [
            [
              ["def self.foo: () -> (untyped)",
               "def self.foo=: (untyped) -> (untyped)",
               "def self.foo?: () -> bool",
               "def foo: () -> (untyped)",
               "def foo?: () -> bool"].join("\n")
            ],
            []
          ]
        end
      end

      context "when instance_predicate option is false" do
        let(:method_calls_raw) do
          [
            [:class_attribute, [:foo, { instance_predicate: false }, nil], false]
          ]
        end

        it "Returns the method declarations without predicates" do
          expect(subject).to eq [
            [
              ["def self.foo: () -> (untyped)",
               "def self.foo=: (untyped) -> (untyped)",
               "def foo: () -> (untyped)",
               "def foo=: (untyped) -> (untyped)"].join("\n")
            ],
            []
          ]
        end
      end

      context "when the class_attribute call has default option" do
        let(:method_calls_raw) do
          [
            [:class_attribute, [:foo, { default: 42 }, nil], false]
          ]
        end

        it "Returns the method declarations typed as default value" do
          expect(subject).to eq [
            [
              ["def self.foo: () -> (::Integer)",
               "def self.foo=: (::Integer) -> (::Integer)",
               "def self.foo?: () -> bool",
               "def foo: () -> (::Integer)",
               "def foo=: (::Integer) -> (::Integer)",
               "def foo?: () -> bool"].join("\n")
            ],
            []
          ]
        end
      end

      context "when the class_attribute call is private" do
        let(:method_calls_raw) { [[:class_attribute, [:foo, nil], true]] }

        it "Returns the all of method declarations as private" do
          expect(subject).to eq [
            [],
            [
              ["def self.foo: () -> (untyped)",
               "def self.foo=: (untyped) -> (untyped)",
               "def self.foo?: () -> bool",
               "def foo: () -> (untyped)",
               "def foo=: (untyped) -> (untyped)",
               "def foo?: () -> bool"].join("\n")
            ]
          ]
        end
      end

      context "when the class_attribute call has trailing comment" do
        before do
          method_calls.each do |method_call|
            method_call.instance_eval { @trailing_comment = "#: String" }
          end
        end

        let(:method_calls_raw) { [[:class_attribute, [:foo, nil], true]] }

        it "Returns the method declarations with given types" do
          expect(subject).to eq [
            [],
            [
              ["def self.foo: () -> (::String)",
               "def self.foo=: (::String) -> (::String)",
               "def self.foo?: () -> bool",
               "def foo: () -> (::String)",
               "def foo=: (::String) -> (::String)",
               "def foo?: () -> bool"].join("\n")
            ]
          ]
        end
      end
    end

    context "when the method_calls contains cattr_accessor/mattr_accessor calls" do
      let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
      let(:method_calls) { method_calls_raw.map { |c| RbsActivesupport::Parser::MethodCall.new(*c) } }

      context "when no options are given" do
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
                "def self.foo: () -> (untyped)",
                "def self.foo=: (untyped) -> (untyped)",
                "def foo: () -> (untyped)",
                "def foo=: (untyped) -> (untyped)"
              ].join("\n")
            ],
            [
              [
                "def self.bar: () -> (untyped)",
                "def self.bar=: (untyped) -> (untyped)",
                "def bar: () -> (untyped)",
                "def bar=: (untyped) -> (untyped)"
              ].join("\n")
            ]
          ]
        end
      end

      context "when instance_accessor is false" do
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
                "def self.foo: () -> (untyped)",
                "def self.foo=: (untyped) -> (untyped)"
              ].join("\n")
            ],
            [
              [
                "def self.bar: () -> (untyped)",
                "def self.bar=: (untyped) -> (untyped)"
              ].join("\n")
            ]
          ]
        end
      end

      context "when instance_reader is false" do
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
                "def self.foo: () -> (untyped)",
                "def self.foo=: (untyped) -> (untyped)",
                "def foo=: (untyped) -> (untyped)"
              ].join("\n")
            ],
            [
              [
                "def self.bar: () -> (untyped)",
                "def self.bar=: (untyped) -> (untyped)",
                "def bar=: (untyped) -> (untyped)"
              ].join("\n")
            ]
          ]
        end
      end

      context "when instance_writer is false" do
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
                "def self.foo: () -> (untyped)",
                "def self.foo=: (untyped) -> (untyped)",
                "def foo: () -> (untyped)"
              ].join("\n")
            ],
            [
              [
                "def self.bar: () -> (untyped)",
                "def self.bar=: (untyped) -> (untyped)",
                "def bar: () -> (untyped)"
              ].join("\n")
            ]
          ]
        end
      end

      context "when the cattr_accessor/mattr_accessor call has default option" do
        let(:method_calls_raw) do
          [
            [:cattr_accessor, [:foo, { default: 42 }, nil], false],
            [:mattr_accessor, [:bar, { default: 42 }, nil], true]
          ]
        end

        it "Returns the declarations typed as default value" do
          expect(subject).to eq [
            [
              [
                "def self.foo: () -> (::Integer)",
                "def self.foo=: (::Integer) -> (::Integer)",
                "def foo: () -> (::Integer)",
                "def foo=: (::Integer) -> (::Integer)"
              ].join("\n")
            ],
            [
              [
                "def self.bar: () -> (::Integer)",
                "def self.bar=: (::Integer) -> (::Integer)",
                "def bar: () -> (::Integer)",
                "def bar=: (::Integer) -> (::Integer)"
              ].join("\n")
            ]
          ]
        end
      end

      context "when the cattr_accessor/mattr_accessor call has trailing comment" do
        before do
          method_calls.each do |method_call|
            method_call.instance_eval { @trailing_comment = "#: String" }
          end
        end

        let(:method_calls_raw) do
          [
            [:cattr_accessor, [:foo, {}, nil], false],
            [:mattr_accessor, [:bar, {}, nil], true]
          ]
        end

        it "Returns the method declarations with given types" do
          expect(subject).to eq [
            [
              [
                "def self.foo: () -> (::String)",
                "def self.foo=: (::String) -> (::String)",
                "def foo: () -> (::String)",
                "def foo=: (::String) -> (::String)"
              ].join("\n")
            ],
            [
              [
                "def self.bar: () -> (::String)",
                "def self.bar=: (::String) -> (::String)",
                "def bar: () -> (::String)",
                "def bar=: (::String) -> (::String)"
              ].join("\n")
            ]
          ]
        end
      end
    end

    context "when the method_calls contains cattr_reader/mattr_reader calls" do
      let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
      let(:method_calls) { method_calls_raw.map { |c| RbsActivesupport::Parser::MethodCall.new(*c) } }

      context "when no options are given" do
        let(:method_calls_raw) do
          [
            [:cattr_reader, [:foo, nil], false],
            [:mattr_reader, [:bar, nil], true]
          ]
        end

        it "Returns the declarations for delegations" do
          expect(subject).to eq [
            [
              [
                "def self.foo: () -> (untyped)",
                "def foo: () -> (untyped)"
              ].join("\n")
            ],
            [
              [
                "def self.bar: () -> (untyped)",
                "def bar: () -> (untyped)"
              ].join("\n")
            ]
          ]
        end
      end

      context "when instance_accessor is false" do
        let(:method_calls_raw) do
          [
            [:cattr_reader, [:foo, { instance_accessor: false }, nil], false],
            [:mattr_reader, [:bar, { instance_accessor: false }, nil], true]
          ]
        end

        it "Returns the declarations for delegations" do
          expect(subject).to eq [
            ["def self.foo: () -> (untyped)"],
            ["def self.bar: () -> (untyped)"]
          ]
        end
      end

      context "when instance_reader is false" do
        let(:method_calls_raw) do
          [
            [:cattr_reader, [:foo, { instance_reader: false }, nil], false],
            [:mattr_reader, [:bar, { instance_reader: false }, nil], true]
          ]
        end

        it "Returns the declarations for delegations" do
          expect(subject).to eq [
            ["def self.foo: () -> (untyped)"],
            ["def self.bar: () -> (untyped)"]
          ]
        end
      end

      context "when the cattr_reader/mattr_reader call has default option" do
        let(:method_calls_raw) do
          [
            [:cattr_reader, [:foo, { default: 42 }, nil], false],
            [:mattr_reader, [:bar, { default: 42 }, nil], true]
          ]
        end

        it "Returns the declarations typed as default value" do
          expect(subject).to eq [
            [
              [
                "def self.foo: () -> (::Integer)",
                "def foo: () -> (::Integer)"
              ].join("\n")
            ],
            [
              [
                "def self.bar: () -> (::Integer)",
                "def bar: () -> (::Integer)"
              ].join("\n")
            ]
          ]
        end
      end

      context "when the cattr_reader/mattr_reader call has trailing comment" do
        before do
          method_calls.each do |method_call|
            method_call.instance_eval { @trailing_comment = "#: String" }
          end
        end

        let(:method_calls_raw) do
          [
            [:cattr_reader, [:foo, {}, nil], false],
            [:mattr_reader, [:bar, {}, nil], true]
          ]
        end

        it "Returns the method declarations with given types" do
          expect(subject).to eq [
            [
              [
                "def self.foo: () -> (::String)",
                "def foo: () -> (::String)"
              ].join("\n")
            ],
            [
              [
                "def self.bar: () -> (::String)",
                "def bar: () -> (::String)"
              ].join("\n")
            ]
          ]
        end
      end
    end

    context "when the method_calls contains cattr_writer/mattr_writer calls" do
      let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
      let(:method_calls) { method_calls_raw.map { |c| RbsActivesupport::Parser::MethodCall.new(*c) } }

      context "when no options are given" do
        let(:method_calls_raw) do
          [
            [:cattr_writer, [:foo, nil], false],
            [:mattr_writer, [:bar, nil], true]
          ]
        end

        it "Returns the declarations for delegations" do
          expect(subject).to eq [
            [
              [
                "def self.foo=: (untyped) -> (untyped)",
                "def foo=: (untyped) -> (untyped)"
              ].join("\n")
            ],
            [
              [
                "def self.bar=: (untyped) -> (untyped)",
                "def bar=: (untyped) -> (untyped)"
              ].join("\n")
            ]
          ]
        end
      end

      context "when instance_accessor is false" do
        let(:method_calls_raw) do
          [
            [:cattr_writer, [:foo, { instance_accessor: false }, nil], false],
            [:mattr_writer, [:bar, { instance_accessor: false }, nil], true]
          ]
        end

        it "Returns the declarations for delegations" do
          expect(subject).to eq [
            ["def self.foo=: (untyped) -> (untyped)"],
            ["def self.bar=: (untyped) -> (untyped)"]
          ]
        end
      end

      context "when instance_writer is false" do
        let(:method_calls_raw) do
          [
            [:cattr_writer, [:foo, { instance_writer: false }, nil], false],
            [:mattr_writer, [:bar, { instance_writer: false }, nil], true]
          ]
        end

        it "Returns the declarations for delegations" do
          expect(subject).to eq [
            ["def self.foo=: (untyped) -> (untyped)"],
            ["def self.bar=: (untyped) -> (untyped)"]
          ]
        end
      end

      context "when the cattr_writer/mattr_writer call has default option" do
        let(:method_calls_raw) do
          [
            [:cattr_writer, [:foo, { default: 42 }, nil], false],
            [:mattr_writer, [:bar, { default: 42 }, nil], true]
          ]
        end

        it "Returns the declarations typed as default value" do
          expect(subject).to eq [
            [
              [
                "def self.foo=: (::Integer) -> (::Integer)",
                "def foo=: (::Integer) -> (::Integer)"
              ].join("\n")
            ],
            [
              [
                "def self.bar=: (::Integer) -> (::Integer)",
                "def bar=: (::Integer) -> (::Integer)"
              ].join("\n")
            ]
          ]
        end
      end

      context "when the cattr_writer/mattr_writer call has trailing comment" do
        before do
          method_calls.each do |method_call|
            method_call.instance_eval { @trailing_comment = "#: String" }
          end
        end

        let(:method_calls_raw) do
          [
            [:cattr_writer, [:foo, {}, nil], false],
            [:mattr_writer, [:bar, {}, nil], true]
          ]
        end

        it "Returns the method declarations with given types" do
          expect(subject).to eq [
            [
              [
                "def self.foo=: (::String) -> (::String)",
                "def foo=: (::String) -> (::String)"
              ].join("\n")
            ],
            [
              [
                "def self.bar=: (::String) -> (::String)",
                "def bar=: (::String) -> (::String)"
              ].join("\n")
            ]
          ]
        end
      end
    end

    context "when the method_calls contains include calls" do
      context "when the included module has ClassMethods" do
        before do
          stub_const("Foo::Bar", Module.new { extend ActiveSupport::Concern })
          stub_const("Foo::Bar::ClassMethods", Module.new)
          stub_const("Foo::Baz", Module.new { extend ActiveSupport::Concern })
          stub_const("Foo::Baz::ClassMethods", Module.new)
          stub_const("Foo::Qux", Module.new)
        end

        let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
        let(:method_calls) { method_calls_raw.map { |c| RbsActivesupport::Parser::MethodCall.new(*c) } }
        let(:method_calls_raw) do
          [
            [:include, [RBS::Namespace.parse("Bar"), nil], false],
            [:include, [RBS::Namespace.parse("Baz"), RBS::Namespace.parse("Qux"), nil], true]
          ]
        end

        it "Returns the declarations for includes" do
          expect(subject).to eq [
            ["extend ::Foo::Bar::ClassMethods"],
            ["extend ::Foo::Baz::ClassMethods"]
          ]
        end
      end

      context "when the included module has include call" do
        let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
        let(:method_calls) { method_calls_raw.map { |c| RbsActivesupport::Parser::MethodCall.new(*c) } }
        let(:method_calls_raw) do
          [
            [:include, [RBS::Namespace.parse("NestedIncludeModule"), nil], false]
          ]
        end

        it "Returns the declarations in the nested includes" do
          expect(subject).to eq [
            ["extend ::IncludeeModule::ClassMethods"],
            []
          ]
        end
      end

      context "when the included module has 'included' block" do
        context "when the included block contains class_attribute call" do
          let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
          let(:method_calls) { method_calls_raw.map { |c| RbsActivesupport::Parser::MethodCall.new(*c) } }
          let(:method_calls_raw) do
            [
              [:include, [RBS::Namespace.parse("IncludedClassAttributesModule"), nil], false]
            ]
          end

          it "Collects the declarations from the included block" do
            expect(subject).to eq [
              [
                ["def self.foo: () -> (untyped)",
                 "def self.foo=: (untyped) -> (untyped)",
                 "def self.foo?: () -> bool",
                 "def foo: () -> (untyped)",
                 "def foo=: (untyped) -> (untyped)",
                 "def foo?: () -> bool"].join("\n")
              ],
              []
            ]
          end
        end

        context "when the included block contains delegate call" do
          let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
          let(:method_calls) { method_calls_raw.map { |c| RbsActivesupport::Parser::MethodCall.new(*c) } }
          let(:method_calls_raw) do
            [
              [:delegate, [:size, :to_s, { to: :bar }, nil], false]
            ]
          end

          it "Collects the declarations from the included block" do
            expect(subject).to eq [
              [
                "def size: () -> ::Integer",
                "def to_s: () -> ::String"
              ],
              []
            ]
          end
        end

        context "when the included block contains include call" do
          let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
          let(:method_calls) { method_calls_raw.map { |c| RbsActivesupport::Parser::MethodCall.new(*c) } }
          let(:method_calls_raw) do
            [
              [:include, [RBS::Namespace.parse("IncludedIncludeModule"), nil], false]
            ]
          end

          it "Collects the declarations from the included block" do
            expect(subject).to eq [
              [
                "include ::IncludedDelegateModule",
                "def size: () -> ::Integer"
              ],
              []
            ]
          end
        end
      end

      context "when the same module was included twice" do
        let(:namespace) { RBS::Namespace.new(path: [:Foo], absolute: true) }
        let(:method_calls) { method_calls_raw.map { |c| RbsActivesupport::Parser::MethodCall.new(*c) } }
        let(:method_calls_raw) do
          [
            [:include, [RBS::Namespace.parse("IncludedIncludeModule"), nil], false],
            [:include, [RBS::Namespace.parse("IncludedIncludeModule"), nil], false]
          ]
        end

        it "Collects include call once" do
          expect(subject).to eq [
            [
              "include ::IncludedDelegateModule",
              "def size: () -> ::Integer"
            ],
            []
          ]
        end
      end
    end
  end
end
