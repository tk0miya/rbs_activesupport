# frozen_string_literal: true

module IncludeeModule
  extend ActiveSupport::Concern

  module ClassMethods
  end
end

module NestedIncludeModule
  extend ActiveSupport::Concern

  include IncludeeModule
end
