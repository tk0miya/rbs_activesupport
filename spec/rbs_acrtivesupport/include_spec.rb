# frozen_string_literal: true

require "rbs_activesupport"
require_relative "../fixtures/no_included_module"
require_relative "../fixtures/empty_included_module"
require_relative "../fixtures/included_class_attributes_module"

RSpec.describe RbsActivesupport::Include do
  describe "#module_name" do
    subject { described_class.new(context, namespace, {}).module_name }

    let(:context) { RBS::Namespace.parse("::Foo::Bar") }
    let(:namespace) { RBS::Namespace.parse("MyConcern") }

    context "When the module is not defined" do
      it { is_expected.to be nil }
    end

    context "When the module is defined in the same level" do
      before do
        stub_const("Foo::Bar::MyConcern", Module.new)
      end

      it { is_expected.to eq RBS::Namespace.parse("::Foo::Bar::MyConcern") }
    end

    context "When the module is defined in the above level" do
      before do
        stub_const("Foo::MyConcern", Module.new)
      end

      it { is_expected.to eq RBS::Namespace.parse("::Foo::MyConcern") }
    end

    context "When the module is defined in the top level" do
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

    context "When the module is not defined" do
      it { is_expected.to be nil }
    end

    context "When the module is defined in the same level" do
      before do
        stub_const("Foo::Bar::MyConcern", mod)
      end

      let(:mod) { Module.new }

      it { is_expected.to eq mod }
    end

    context "When the module is defined in the above level" do
      before do
        stub_const("Foo::MyConcern", mod)
      end

      let(:mod) { Module.new }

      it { is_expected.to eq mod }
    end

    context "When the module is defined in the top level" do
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

    context "When the module is not defined" do
      it { is_expected.to be_falsey }
    end

    context "When the module is defined" do
      before do
        stub_const("MyConcern", mod)
      end

      context "When the module extends ActiveSupport::Concern" do
        let(:mod) { Module.new { extend ActiveSupport::Concern } }

        it { is_expected.to eq true }
      end

      context "When the module does not extend ActiveSupport::Concern" do
        let(:mod) { Module.new }

        it { is_expected.to eq false }
      end
    end
  end

  describe "#classmethods?" do
    subject { described_class.new(context, namespace, {}).classmethods? }

    let(:context) { RBS::Namespace.root }
    let(:namespace) { RBS::Namespace.parse("Foo") }

    context "When ClassMethods module is not defiend under the namespace" do
      before do
        stub_const("Foo", Module.new)
      end

      it { is_expected.to eq false }
    end

    context "When ClassMethods module is defiend under the namespace" do
      before do
        stub_const("Foo", Module.new)
        stub_const("Foo::ClassMethods", Module.new)
      end

      it { is_expected.to eq true }
    end
  end

  describe "#method_calls_in_included_block" do
    subject { described_class.new(context, namespace, {}).method_calls_in_included_block }

    let(:context) { RBS::Namespace.root }

    context "When the module not having any 'included' blocks" do
      let(:namespace) { RBS::Namespace.parse("NoIncludedModule") }

      it { is_expected.to eq [] }
    end

    context "When the module having 'included' blocks" do
      context "When the included block does not contains any definitions" do
        let(:namespace) { RBS::Namespace.parse("EmptyIncludedModule") }

        it { is_expected.to eq [] }
      end

      context "When the included block contains definitions" do
        let(:namespace) { RBS::Namespace.parse("IncludedClassAttributesModule") }

        it "Returns method_calls inside the included block" do
          expect(subject.size).to eq 1
          expect(subject[0].name).to eq :class_attribute
        end
      end
    end
  end
end
