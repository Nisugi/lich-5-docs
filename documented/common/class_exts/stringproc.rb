
module Lich
  module Common
    # Represents a processor for string evaluations.
    #
    # This class allows for the evaluation of a string as Ruby code.
    # @see Lich::Common
    class StringProc
      # Initializes a new StringProc instance.
      # @param string [String] the string to be processed
      # @return [StringProc]
      def initialize(string)
        @string = string
      end

      # Checks if the object is of a given type.
      # @param type [Class] the class to check against
      # @return [Boolean] true if the object is of the specified type
      def kind_of?(type)
        Proc.new {}.kind_of? type
      end

      # Returns the class of the object.
      # @return [Class] the Proc class
      def class
        Proc
      end

      # Evaluates the stored string as Ruby code.
      # @param args [Array] optional arguments for the evaluation
      # @return [Object] the result of the evaluated string
      def call(*_a)
        proc { eval(@string) }.call
      end

      def _dump(_d = nil)
        @string
      end

      # Returns a string representation of the StringProc instance.
      # @return [String] a string describing the StringProc instance
      def inspect
        "StringProc.new(#{@string.inspect})"
      end

      # Converts the StringProc instance to JSON format.
      # @param args [Array] optional arguments for JSON conversion
      # @return [String] the JSON representation of the StringProc
      def to_json(*args)
        ";e #{_dump}".to_json(args)
      end

      # Loads a StringProc instance from a string.
      # @param string [String] the string to load
      # @return [StringProc] the loaded StringProc instance
      # @api private
      def StringProc._load(string)
        StringProc.new(string)
      end
    end
  end
end
