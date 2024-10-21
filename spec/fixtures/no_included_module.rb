# frozen_string_literal: true

module NoIncludedModule
  extend ActiveSupport::Concern

  included do
    # no calls here
  end
end
