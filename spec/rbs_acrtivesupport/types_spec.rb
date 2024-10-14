# frozen_string_literal: true

require "rbs_activesupport"

RSpec.describe RbsActivesupport::Types do
  describe "#guess_type" do
    subject { described_class.guess_type(obj) }

    context "When obj is nil" do
      let(:obj) { nil }

      it { is_expected.to eq("nil") }
    end

    context "When obj is Integer" do
      let(:obj) { 42 }

      it { is_expected.to eq("Integer") }
    end

    context "When obj is Float" do
      let(:obj) { 42.0 }

      it { is_expected.to eq("Float") }
    end

    context "When obj is Symbol" do
      let(:obj) { :symbol }

      it { is_expected.to eq("Symbol") }
    end

    context "When obj is String" do
      let(:obj) { "string" }

      it { is_expected.to eq("String") }
    end

    context "When obj is true" do
      let(:obj) { true }

      it { is_expected.to eq("bool") }
    end

    context "When obj is false" do
      let(:obj) { false }

      it { is_expected.to eq("bool") }
    end

    context "When obj is Array" do
      context "When the array is empty" do
        let(:obj) { [] }

        it { is_expected.to eq("Array[untyped]") }
      end

      context "When the array contains untyped elements" do
        let(:obj) { [Object.new] }

        it { is_expected.to eq("Array[untyped]") }
      end

      context "When the array contains elements of different types" do
        let(:obj) { [1, "string"] }

        it { is_expected.to eq("Array[Integer | String]") }
      end
    end

    context "When obj is Hash" do
      context "When the hash is empty" do
        let(:obj) { {} }

        it { is_expected.to eq("Hash[untyped, untyped]") }
      end

      context "When the hash contains untyped keys" do
        let(:obj) { { Object.new => 1 } }

        it { is_expected.to eq("Hash[untyped, Integer]") }
      end

      context "When the hash contains kyes of different types" do
        let(:obj) { { 1 => 1, "string" => 2 } }

        it { is_expected.to eq("Hash[Integer | String, Integer]") }
      end

      context "When the hash contains untyped values" do
        let(:obj) { { 1 => Object.new } }

        it { is_expected.to eq("Hash[Integer, untyped]") }
      end

      context "When the hash contains values of different types" do
        let(:obj) { { 1 => 1, 2 => "string" } }

        it { is_expected.to eq("Hash[Integer, Integer | String]") }
      end
    end

    context "When obj is an instance of a custom class" do
      let(:obj) { Object.new }

      it { is_expected.to eq("untyped") }
    end
  end
end
