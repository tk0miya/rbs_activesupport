# frozen_string_literal: true

require "rbs_activesupport"

RSpec.describe RbsActivesupport::Types do
  describe "#guess_type" do
    subject { described_class.guess_type(obj) }

    context "when obj is nil" do
      let(:obj) { nil }

      it { is_expected.to eq("nil") }
    end

    context "when obj is Integer" do
      let(:obj) { 42 }

      it { is_expected.to eq("::Integer") }
    end

    context "when obj is Float" do
      let(:obj) { 42.0 }

      it { is_expected.to eq("::Float") }
    end

    context "when obj is Symbol" do
      let(:obj) { :symbol }

      it { is_expected.to eq("::Symbol") }
    end

    context "when obj is String" do
      let(:obj) { "string" }

      it { is_expected.to eq("::String") }
    end

    context "when obj is true" do
      let(:obj) { true }

      it { is_expected.to eq("bool") }
    end

    context "when obj is false" do
      let(:obj) { false }

      it { is_expected.to eq("bool") }
    end

    context "when obj is Array" do
      context "when the array is empty" do
        let(:obj) { [] }

        it { is_expected.to eq("::Array[untyped]") }
      end

      context "when the array contains untyped elements" do
        let(:obj) { [Object.new] }

        it { is_expected.to eq("::Array[untyped]") }
      end

      context "when the array contains elements of different types" do
        let(:obj) { [1, "string"] }

        it { is_expected.to eq("::Array[::Integer | ::String]") }
      end
    end

    context "when obj is Hash" do
      context "when the hash is empty" do
        let(:obj) { {} }

        it { is_expected.to eq("::Hash[untyped, untyped]") }
      end

      context "when the hash contains untyped keys" do
        let(:obj) { { Object.new => 1 } }

        it { is_expected.to eq("::Hash[untyped, ::Integer]") }
      end

      context "when the hash contains kyes of different types" do
        let(:obj) { { 1 => 1, "string" => 2 } }

        it { is_expected.to eq("::Hash[::Integer | ::String, ::Integer]") }
      end

      context "when the hash contains untyped values" do
        let(:obj) { { 1 => Object.new } }

        it { is_expected.to eq("::Hash[::Integer, untyped]") }
      end

      context "when the hash contains values of different types" do
        let(:obj) { { 1 => 1, 2 => "string" } }

        it { is_expected.to eq("::Hash[::Integer, ::Integer | ::String]") }
      end
    end

    context "when obj is an instance of a custom class" do
      let(:obj) { Object.new }

      it { is_expected.to eq("untyped") }
    end
  end
end
