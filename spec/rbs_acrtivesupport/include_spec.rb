# frozen_string_literal: true

require "rbs_activesupport"

RSpec.describe RbsActivesupport::Include do
  describe "#argument" do
    subject { described_class.new(context, namespace, {}).argument }

    let(:context) { RBS::Namespace.new(path: [:Foo], absolute: true) }

    context "When module_path is absolute" do
      let(:namespace) { [nil, :Bar, :Baz] }

      it { is_expected.to eq RBS::Namespace.parse("::Bar::Baz") }
    end

    context "When module_path is relative" do
      let(:namespace) { %i[Bar Baz] }

      it { is_expected.to eq RBS::Namespace.parse("Bar::Baz") }
    end
  end

  describe "#module_name" do
    subject { described_class.new(context, namespace, {}).module_name }

    let(:context) { RBS::Namespace.new(path: %i[Foo Bar], absolute: true) }
    let(:namespace) { [:MyConcern] }

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

  describe "#concern?" do
    subject { described_class.new(context, namespace, {}).concern? }

    let(:context) { RBS::Namespace.root }
    let(:namespace) { [:MyConcern] }

    context "When the module is not defined" do
      it { is_expected.to eq false }
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
    let(:namespace) { [:Foo] }

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
end
