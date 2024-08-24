# frozen_string_literal: true

module RbsActivesupportDelegate
  class Delegate
    attr_reader :namespace, :method, :options

    def initialize(namespace, method, options)
      @namespace = namespace
      @method = method
      @options = options
    end

    def to
      options[:to]
    end

    def method_name
      case options[:prefix]
      when true
        :"#{to}_#{method}"
      when String, Symbol
        :"#{options[:prefix]}_#{method}"
      else
        method
      end
    end

    def public?
      !private?
    end

    def private?
      options.fetch(:private, false)
    end
  end
end
