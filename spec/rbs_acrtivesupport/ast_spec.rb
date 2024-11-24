# frozen_string_literal: true

require "rbs_activesupport"

RSpec.describe RbsActivesupport::AST do
  include described_class

  describe ".eval_node" do
    subject { eval_node(node) }

    let(:ast) { RubyVM::AbstractSyntaxTree.parse(code) }
    let(:node) { ast.children[2] }

    context "When a nil value given" do
      let(:node) { nil }

      it { is_expected.to eq nil }
    end

    context "When the node is an integer literal" do
      let(:code)  { "1" }

      it { is_expected.to eq 1 }
    end

    context "When the node is a float literal" do
      let(:code)  { "1.1" }

      it { is_expected.to eq 1.1 }
    end

    context "When the node is a symbol literal" do
      let(:code)  { ":symbol" }

      it { is_expected.to eq :symbol }
    end

    context "When the node is a string literal" do
      let(:code)  { "'string'" }

      it { is_expected.to eq "string" }
    end

    context "When the node is a true literal" do
      let(:code)  { "true" }

      it { is_expected.to eq true }
    end

    context "When the node is a false literal" do
      let(:code)  { "false" }

      it { is_expected.to eq false }
    end

    context "When the node is a nil" do
      let(:code)  { "nil" }

      it { is_expected.to eq nil }
    end

    context "When the node is an empty hash literal" do
      let(:code)  { "{}" }

      it { is_expected.to eq({}) }
    end

    context "When the node is a hash literal" do
      let(:code)  { "{ key1: 1, key2: 2 }" }

      it { is_expected.to eq({ key1: 1, key2: 2 }) }
    end

    context "When the node is an empty array literal" do
      let(:code)  { "[]" }

      it { is_expected.to eq [] }
    end

    context "When the node is an array literal" do
      let(:code)  { "[1, 2, 3]" }

      it { is_expected.to eq [1, 2, 3] }
    end

    context "When the node is a constant (CONST)" do
      let(:code)  { "CONST" }

      it { is_expected.to eq RBS::Namespace.parse("CONST") }
    end

    context "When the node is a constant (COLON2)" do
      let(:code)  { "CONST::CONST" }

      it { is_expected.to eq RBS::Namespace.parse("CONST::CONST") }
    end

    context "When the node is a constant (COLON3)" do
      let(:code)  { "::CONST::CONST" }

      it { is_expected.to eq RBS::Namespace.parse("::CONST::CONST") }
    end

    context "When the node is a method call" do
      let(:code)  { "Object.new" }

      it { is_expected.to be_a RubyVM::AbstractSyntaxTree::Node }
    end

    context "When the node is a method call with a block" do
      let(:code)  { "Object.new { }" }

      it { is_expected.to be_a RubyVM::AbstractSyntaxTree::Node }
    end
  end
end
