# frozen_string_literal: true

module RbsActivesupport
  class Delegate
    attr_reader :namespace #: RBS::Namespace
    attr_reader :method #: Symbol
    attr_reader :options #: Hash[Symbol, untyped]

    # @rbs namespace: RBS::Namespace
    # @rbs method: Symbol
    # @rbs options: Hash[Symbol, untyped]
    def initialize(namespace, method, options) #: void
      @namespace = namespace
      @method = method
      @options = options
    end

    def to #: Symbol
      options[:to]
    end

    def method_name #: Symbol
      case options[:prefix]
      when true
        :"#{to}_#{method}"
      when String, Symbol
        :"#{options[:prefix]}_#{method}"
      else
        method
      end
    end

    def public? #: bool
      !private?
    end

    def private? #: bool
      options.fetch(:private, false)
    end
  end
end
