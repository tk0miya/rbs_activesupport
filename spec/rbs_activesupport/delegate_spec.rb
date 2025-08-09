# frozen_string_literal: true

require "rbs"
require "rbs_activesupport"

RSpec.describe RbsActivesupport::Delegate do
  describe "#to" do
    subject { delegate.to }

    let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :baz) }

    it { is_expected.to eq :baz }
  end

  describe "#method_name" do
    context "when prefix is true" do
      subject { delegate.method_name }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar, prefix: true) }

      it { is_expected.to eq :bar_foo }
    end

    context "when prefix is a string" do
      subject { delegate.method_name }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar, prefix: "baz") }

      it { is_expected.to eq :baz_foo }
    end

    context "when prefix is a symbol" do
      subject { delegate.method_name }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar, prefix: :baz) }

      it { is_expected.to eq :baz_foo }
    end

    context "when prefix is nil" do
      subject { delegate.method_name }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar) }

      it { is_expected.to eq :foo }
    end
  end

  describe "#private?" do
    context "when private option is true" do
      subject { delegate.private? }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar, private: true) }

      it { is_expected.to be true }
    end

    context "when private option is false" do
      subject { delegate.private? }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar, private: false) }

      it { is_expected.to be false }
    end

    context "when private option is not given" do
      subject { delegate.private? }

      let(:delegate) { described_class.new(RBS::Namespace.root, :foo, to: :bar) }

      it { is_expected.to be false }
    end
  end
end
