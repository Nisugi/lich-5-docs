# encoding: utf-8

module TestModule
  class ComplexMethods
    attr_reader :name, :items
    attr_writer :secret
    attr_accessor :config

    CONSTANT_VALUE = 42
    @@instance_count = 0

    def initialize(name, *args, **options, &block)
      @name = name
      @args = args
      @options = options
      @block = block
      @@instance_count += 1
    end

    def self.create(name)
      new(name)
    end

    def self.count
      @@instance_count
    end

    def ComplexMethods.legacy_class_method
      "legacy syntax"
    end

    def regular_method(param)
      param.to_s
    end

    def method_with_defaults(a, b = 10, c = "default")
      [a, b, c]
    end

    def splat_method(*args)
      args.flatten
    end

    def keyword_method(required:, optional: nil)
      { required: required, optional: optional }
    end

    def double_splat_method(**kwargs)
      kwargs
    end

    def block_method(&block)
      block&.call
    end

    def combined_method(a, b = 1, *rest, key:, opt: true, **other, &blk)
      # Complex signature with all parameter types
      { a: a, b: b, rest: rest, key: key, opt: opt, other: other }
    end

    def question_method?
      true
    end

    def bang_method!
      @items = []
    end

    def assignment_method=(value)
      @config = value
    end

    def [](index)
      @items[index]
    end

    def []=(index, value)
      @items[index] = value
    end

    protected

    def protected_helper
      "protected"
    end

    private

    def private_helper
      "private"
    end
  end
end
