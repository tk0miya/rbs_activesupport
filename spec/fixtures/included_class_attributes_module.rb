# frozen_string_literal: true

module IncludedClassAttributesModule
  extend ActiveSupport::Concern

  included do
    class_attribute :foo
  end
end
