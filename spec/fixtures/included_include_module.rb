# frozen_string_literal: true

require_relative "./included_delegate_module"

module IncludedIncludeModule
  extend ActiveSupport::Concern

  included do
    include IncludedDelegateModule
  end
end
