# frozen_string_literal: true

module RbsActivesupport
  class Parser
    class CommentParser
      attr_reader :line_comments #: Hash[Integer, String]
      attr_reader :trailing_comments #: Hash[Integer, String]

      def initialize #: void
        @line_comments = {}
        @trailing_comments = {}
      end

      # @rbs string: String
      def parse(string) #: self
        # @type var code_lines: Hash[Integer, bool]
        code_lines = {}
        Ripper.lex(string).each do |(line, _), type, token, _|
          case type
          when :on_sp, :on_ignored_nl
            # ignore
          when :on_comment
            if code_lines[line]
              trailing_comments[line] = token.chomp
            else
              line_comments[line] = token.chomp
            end
            :here
          else
            code_lines[line] = true
          end
        end

        self
      end
    end
  end
end
