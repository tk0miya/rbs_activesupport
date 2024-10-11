# frozen_string_literal: true

module RbsActivesupport
  class ClassAttribute
    attr_reader :name #: Symbol
    attr_reader :options #: Hash[untyped, untyped]

    # @rbs name: Symbol
    # @rbs options: Hash[untyped, untyped]
    def initialize(name, options) #: void
      @name = name
      @options = options
    end

    def type #: String
      # @type var trailng_comment: String?
      trailing_comment = options[:trailing_comment]
      if trailing_comment&.start_with?("#:")
        trailing_comment[2..].strip
      elsif default?
        default_type
      else
        "untyped"
      end
    end

    def instance_accessor? #: bool
      options.fetch(:instance_accessor, true)
    end

    def instance_reader? #: bool
      options.fetch(:instance_reader, instance_accessor?)
    end

    def instance_writer? #: bool
      options.fetch(:instance_writer, instance_accessor?)
    end

    def instance_predicate? #: bool
      options.fetch(:instance_predicate, true)
    end

    def default? #: boolish
      options.fetch(:default, nil)
    end

    def default_type #: String
      default = options.fetch(:default, nil)
      RbsActivesupport::Types.guess_type(default)
    end

    def public? #: bool
      !private?
    end

    def private? #: bool
      options.fetch(:private, false)
    end

    def included? #: bool
      options.fetch(:included, false)
    end
  end
end
