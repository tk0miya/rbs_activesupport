# frozen_string_literal: true

require "rbs"
require "rbs_activesupport_delegate"

RSpec.describe RbsActivesupportDelegate::Delegate do
  describe "#to" do
    subject { delegate.to }

    let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :baz) }

    it { is_expected.to eq :baz }
  end

  describe "#method_name" do
    context "When prefix is true" do
      subject { delegate.method_name }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar, prefix: true) }

      it { is_expected.to eq :bar_foo }
    end

    context "When prefix is a string" do
      subject { delegate.method_name }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar, prefix: "baz") }

      it { is_expected.to eq :baz_foo }
    end

    context "When prefix is a symbol" do
      subject { delegate.method_name }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar, prefix: :baz) }

      it { is_expected.to eq :baz_foo }
    end

    context "When prefix is nil" do
      subject { delegate.method_name }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar) }

      it { is_expected.to eq :foo }
    end
  end

  describe "#private?" do
    context "When private option is true" do
      subject { delegate.private? }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar, private: true) }

      it { is_expected.to eq true }
    end

    context "When private option is false" do
      subject { delegate.private? }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar, private: false) }

      it { is_expected.to eq false }
    end

    context "When private option is not given" do
      subject { delegate.private? }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar) }

      it { is_expected.to eq false }
    end
  end
end
