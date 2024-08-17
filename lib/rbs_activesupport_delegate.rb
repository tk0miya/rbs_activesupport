# frozen_string_literal: true

require_relative "rbs_activesupport_delegate/ast"
require_relative "rbs_activesupport_delegate/delegate"
require_relative "rbs_activesupport_delegate/generator"
require_relative "rbs_activesupport_delegate/method_searcher"
require_relative "rbs_activesupport_delegate/parser"
require_relative "rbs_activesupport_delegate/version"

module RbsActivesupportDelegate
  class Error < StandardError; end
  # Your code goes here...
end
