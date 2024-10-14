# frozen_string_literal: true

module EmptyIncludedModule
  extend ActiveSupport::Concern

  included do
    # no calls here
  end
end
