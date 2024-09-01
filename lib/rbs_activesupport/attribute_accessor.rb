# frozen_string_literal: true

module RbsActivesupport
  class AttributeAccessor
    attr_reader :name, :options

    def initialize(name, options)
      @name = name
      @options = options
    end

    def singleton_reader?
      options.fetch(:singleton_reader, true)
    end

    def singleton_writer?
      options.fetch(:singleton_writer, true)
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
