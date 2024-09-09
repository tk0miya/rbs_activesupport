# frozen_string_literal: true

require "rbs_activesupport"

RSpec.describe RbsActivesupport::Parser::CommentParser do
  describe "#parse" do
    subject { parser.parse(string) }

    let(:parser) { described_class.new }
    let(:string) do
      <<~RUBY
        CONST = 1 #: Integer

        # hello world
        class Foo
          attr_reader :bar #: String

          # hello world
          def baz
            baz
          end
        end
      RUBY
    end

    it "collects line comments" do
      subject
      expect(parser.line_comments).to eq({ 3 => "# hello world", 7 => "# hello world" })
    end

    it "collects trailing comments" do
      subject
      expect(parser.trailing_comments).to eq({ 1 => "#: Integer", 5 => "#: String" })
    end
  end
end
