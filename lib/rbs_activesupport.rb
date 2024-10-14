# frozen_string_literal: true

require_relative "rbs_activesupport/ast"
require_relative "rbs_activesupport/attribute_accessor"
require_relative "rbs_activesupport/class_attribute"
require_relative "rbs_activesupport/declaration_builder"
require_relative "rbs_activesupport/delegate"
require_relative "rbs_activesupport/generator"
require_relative "rbs_activesupport/include"
require_relative "rbs_activesupport/method_searcher"
require_relative "rbs_activesupport/parser"
require_relative "rbs_activesupport/parser/comment_parser"
require_relative "rbs_activesupport/types"
require_relative "rbs_activesupport/version"

module RbsActivesupport
  class Error < StandardError; end
  # Your code goes here...
end
