# encoding: utf-8
# frozen_string_literal: true

# A simple calculator class for testing documentation generation.
class SimpleCalculator
  attr_reader :value
  attr_accessor :precision

  EPSILON = 0.0001

  def initialize(value = 0)
    @value = value
    @precision = 2
  end

  def add(n)
    @value += n
  end

  def subtract(n)
    @value -= n
  end

  def multiply(n)
    @value *= n
  end

  def divide(n)
    raise ArgumentError, "Cannot divide by zero" if n.zero?
    @value /= n.to_f
  end

  def reset
    @value = 0
  end

  private

  def validate_number(n)
    raise TypeError unless n.is_a?(Numeric)
  end
end
