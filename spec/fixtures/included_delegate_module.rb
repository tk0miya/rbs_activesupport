# frozen_string_literal: true

module IncludedDelegateModule
  extend ActiveSupport::Concern

  included do
    delegate :size, to: :bar
  end
end
