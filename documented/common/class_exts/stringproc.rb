
module Lich
  module Common
    # Represents a processor for string evaluations.
    # This class allows for the evaluation of a string as Ruby code.
    # @example Creating a StringProc instance
    #   sp = StringProc.new("1 + 1")
    class StringProc
      # Initializes a new StringProc instance.
      # @param string [String] The string to be processed.
      # @return [StringProc]
      def initialize(string)
        @string = string
      end

      # Checks if the object is of a certain type.
      # @param type [Class] The class to check against.
      # @return [Boolean] True if the object is of the specified type.
      # @example Checking type
      #   sp.kind_of?(Proc)
      def kind_of?(type)
        Proc.new {}.kind_of? type
      end

      # Returns the class of the object.
      # @return [Class] The Proc class.
      def class
        Proc
      end

      # Evaluates the stored string as Ruby code.
      # @param args [Array] Additional arguments for the proc.
      # @return [Object] The result of the evaluated string.
      # @example Calling the StringProc
      #   result = sp.call
      def call(*_a)
        proc { eval(@string) }.call
      end

      # Dumps the string representation of the object.
      # @param _d [nil] Optional parameter (not used).
      # @return [String] The string representation.
      def _dump(_d = nil)
        @string
      end

      # Returns a string representation of the object for inspection.
      # @return [String] A string describing the StringProc instance.
      def inspect
        "StringProc.new(#{@string.inspect})"
      end

      # Converts the StringProc instance to JSON format.
      # @param args [Array] Additional arguments for JSON conversion.
      # @return [String] The JSON representation of the StringProc.
      def to_json(*args)
        ";e #{_dump}".to_json(args)
      end

      # Loads a StringProc instance from a string.
      # @param string [String] The string to load.
      # @return [StringProc] A new StringProc instance.
      def StringProc._load(string)
        StringProc.new(string)
      end
    end
  end
end
