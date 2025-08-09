# frozen_string_literal: true

require "rbs_activesupport"
require_relative "../fixtures/no_included_module"
require_relative "../fixtures/empty_included_module"
require_relative "../fixtures/nested_include_module"
require_relative "../fixtures/included_class_attributes_module"

RSpec.describe RbsActivesupport::Include do
  describe "#module_name" do
    subject { described_class.new(context, namespace, {}).module_name }

    let(:context) { RBS::Namespace.parse("::Foo::Bar") }
    let(:namespace) { RBS::Namespace.parse("MyConcern") }

    context "when the module is not defined" do
      it { is_expected.to be_nil }
    end

    context "when the module is defined in the same level" do
      before do
        stub_const("Foo::Bar::MyConcern", Module.new)
      end

      it { is_expected.to eq RBS::Namespace.parse("::Foo::Bar::MyConcern") }
    end

    context "when the module is defined in the above level" do
      before do
        stub_const("Foo::MyConcern", Module.new)
      end

      it { is_expected.to eq RBS::Namespace.parse("::Foo::MyConcern") }
    end

    context "when the module is defined in the top level" do
      before do
        stub_const("MyConcern", Module.new)
      end

      it { is_expected.to eq RBS::Namespace.parse("::MyConcern") }
    end
  end

  describe "#module" do
    subject { described_class.new(context, namespace, {}).module }

    let(:context) { RBS::Namespace.parse("::Foo::Bar") }
    let(:namespace) { RBS::Namespace.parse("MyConcern") }

    context "when the module is not defined" do
      it { is_expected.to be_nil }
    end

    context "when the module is defined in the same level" do
      before do
        stub_const("Foo::Bar::MyConcern", mod)
      end

      let(:mod) { Module.new }

      it { is_expected.to eq mod }
    end

    context "when the module is defined in the above level" do
      before do
        stub_const("Foo::MyConcern", mod)
      end

      let(:mod) { Module.new }

      it { is_expected.to eq mod }
    end

    context "when the module is defined in the top level" do
      before do
        stub_const("MyConcern", mod)
      end

      let(:mod) { Module.new }

      it { is_expected.to eq mod }
    end
  end

  describe "#concern?" do
    subject { described_class.new(context, namespace, {}).concern? }

    let(:context) { RBS::Namespace.root }
    let(:namespace) { RBS::Namespace.parse("MyConcern") }

    context "when the module is not defined" do
      it { is_expected.to be_falsey }
    end

    context "when the module is defined" do
      before do
        stub_const("MyConcern", mod)
      end

      context "when the module extends ActiveSupport::Concern" do
        let(:mod) { Module.new { extend ActiveSupport::Concern } }

        it { is_expected.to be true }
      end

      context "when the module does not extend ActiveSupport::Concern" do
        let(:mod) { Module.new }

        it { is_expected.to be false }
      end
    end
  end

  describe "#classmethods?" do
    subject { described_class.new(context, namespace, {}).classmethods? }

    let(:context) { RBS::Namespace.root }
    let(:namespace) { RBS::Namespace.parse("Foo") }

    context "when ClassMethods module is not defined under the namespace" do
      before do
        stub_const("Foo", Module.new)
      end

      it { is_expected.to be false }
    end

    context "when ClassMethods module is defined under the namespace" do
      before do
        stub_const("Foo", Module.new)
        stub_const("Foo::ClassMethods", Module.new)
      end

      it { is_expected.to be true }
    end
  end

  describe "#nested_includes" do
    subject { described_class.new(context, namespace, {}).nested_includes }

    let(:context) { RBS::Namespace.root }

    context "when the module not having any include calls" do
      let(:namespace) { RBS::Namespace.parse("NoIncludedModule") }

      it { is_expected.to eq [] }
    end

    context "when the module having include calls" do
      context "when the include call is not inside the included block" do
        let(:namespace) { RBS::Namespace.parse("NestedIncludeModule") }

        it "Returns the include call" do
          expect(subject.size).to eq 1
          expect(subject[0].name).to eq :include
        end
      end

      context "when the include call is inside the included block" do
        let(:namespace) { RBS::Namespace.parse("IncludedIncludeModule") }

        it { is_expected.to eq [] }
      end
    end
  end

  describe "#explicit?" do
    subject { described_class.new(context, namespace, options).explicit? }

    let(:context) { RBS::Namespace.root }
    let(:namespace) { RBS::Namespace.parse("MyConcern") }

    context "when the include is explicit" do
      let(:options) { {} }

      it { is_expected.to be true }
    end

    context "when the include is implicit" do
      let(:options) { { implicit: true } }

      it { is_expected.to be false }
    end
  end

  describe "#implicit?" do
    subject { described_class.new(context, namespace, options).implicit? }

    let(:context) { RBS::Namespace.root }
    let(:namespace) { RBS::Namespace.parse("MyConcern") }

    context "when the include is explicit" do
      let(:options) { {} }

      it { is_expected.to be false }
    end

    context "when the include is implicit" do
      let(:options) { { implicit: true } }

      it { is_expected.to be true }
    end
  end

  describe "#method_calls_in_included_block" do
    subject { described_class.new(context, namespace, {}).method_calls_in_included_block }

    let(:context) { RBS::Namespace.root }

    context "when the module not having any 'included' blocks" do
      let(:namespace) { RBS::Namespace.parse("NoIncludedModule") }

      it { is_expected.to eq [] }
    end

    context "when the module having 'included' blocks" do
      context "when the included block does not contains any definitions" do
        let(:namespace) { RBS::Namespace.parse("EmptyIncludedModule") }

        it { is_expected.to eq [] }
      end

      context "when the included block contains definitions" do
        let(:namespace) { RBS::Namespace.parse("IncludedClassAttributesModule") }

        it "Returns method_calls inside the included block" do
          expect(subject.size).to eq 1
          expect(subject[0].name).to eq :class_attribute
        end
      end
    end
  end
end
