# encoding: utf-8
# frozen_string_literal: true

# DocumentedClass provides example documentation.
#
# This class demonstrates various YARD tags and
# documentation patterns that should be stripped.
#
# @author Test Author
# @since 1.0.0
# @see https://example.com
class DocumentedClass
  # @return [String] the name attribute
  attr_reader :name

  # @return [Integer] the value attribute
  attr_accessor :value

  # Default timeout in seconds.
  # @note This is a configuration constant.
  TIMEOUT = 30

  # Initialize a new DocumentedClass instance.
  #
  # @param name [String] the name to assign
  # @param value [Integer] optional initial value (default: 0)
  # @return [DocumentedClass] a new instance
  #
  # @example Create a new instance
  #   obj = DocumentedClass.new("test", 42)
  def initialize(name, value = 0)
    @name = name
    @value = value
  end

  # Process the given data.
  #
  # @param data [String] input data to process
  # @param options [Hash] processing options
  # @option options [Boolean] :strict enable strict mode
  # @option options [Integer] :timeout override timeout
  #
  # @yield [result] yields processed result
  # @yieldparam result [String] the processed data
  #
  # @return [String] processed data
  # @raise [ArgumentError] if data is nil
  #
  # @example Basic usage
  #   obj.process("input") { |r| puts r }
  def process(data, options = {})
    raise ArgumentError, "data cannot be nil" if data.nil?
    result = data.upcase
    yield result if block_given?
    result
  end

  # Check if the instance is valid.
  # @return [Boolean] true if valid
  def valid?
    !@name.nil? && !@name.empty?
  end

  private

  # Internal helper method (should keep private comment).
  # @api private
  def internal_helper
    "helper"
  end
end
