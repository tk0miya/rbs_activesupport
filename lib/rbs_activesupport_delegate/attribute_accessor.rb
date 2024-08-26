# frozen_string_literal: true

module RbsActivesupportDelegate
  class AttributeAccessor
    attr_reader :name, :options

    def initialize(name, options)
      @name = name
      @options = options
    end

    def instance_accessor?
      options.fetch(:instance_accessor, true)
    end

    def instance_reader?
      options.fetch(:instance_reader, instance_accessor?)
    end

    def instance_writer?
      options.fetch(:instance_writer, instance_accessor?)
    end

    def public?
      !private?
    end

    def private?
      options.fetch(:private, false)
    end
  end
end
