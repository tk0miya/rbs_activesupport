# frozen_string_literal: true

module RbsActivesupport
  class ClassAttribute
    attr_reader :name, :options

    def initialize(name, options)
      @name = name
      @options = options
    end

    def type
      # @type var trailng_comment: String?
      trailing_comment = options[:trailing_comment]
      if trailing_comment&.start_with?("#:")
        trailing_comment[2..].strip
      else
        "untyped"
      end
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

    def instance_predicate?
      options.fetch(:instance_predicate, true)
    end

    def public?
      !private?
    end

    def private?
      options.fetch(:private, false)
    end
  end
end
