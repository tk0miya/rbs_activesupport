# frozen_string_literal: true

module IncludeeModule
  module ClassMethods
  end

  module SubModule
  end

  extend ActiveSupport::Concern

  include SubModule
end

module NestedIncludeModule
  extend ActiveSupport::Concern

  include IncludeeModule
end
