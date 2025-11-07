# Carve out from lich.rbw
# extension to StringProc class 2024-06-13

module Lich
  module Common
    # Represents a String processing object that can evaluate a string as a Ruby expression.
    # This class allows for the creation of callable objects that encapsulate a string and can execute it.
    # @example Creating a StringProc and calling it
    #   sp = Lich::Common::StringProc.new('1 + 1')
    #   sp.call # => 2
    class StringProc
      # Initializes a new StringProc object.
      # @param string [String] The string to be processed and evaluated.
      # @return [StringProc]
      def initialize(string)
        @string = string
      end

      # Checks if the StringProc is of a certain type.
      # @param type [Class] The class to check against.
      # @return [Boolean] Returns true if the StringProc is of the specified type.
      # @example Checking the type
      #   sp.kind_of?(Proc) # => true
      def kind_of?(type)
        Proc.new {}.kind_of? type
      end

      # Returns the class of the StringProc.
      # @return [Class] The Proc class.
      def class
        Proc
      end

      # Evaluates the stored string as Ruby code and returns the result.
      # @return [Object] The result of the evaluated string.
      # @example Calling the StringProc
      #   sp = Lich::Common::StringProc.new('2 + 2')
      #   sp.call # => 4
      def call(*_a)
        proc { eval(@string) }.call
      end

      # Dumps the string representation of the StringProc.
      # @param _d [nil] Optional parameter (not used).
      # @return [String] The string stored in the StringProc.
      def _dump(_d = nil)
        @string
      end

      # Returns a string representation of the StringProc object.
      # @return [String] A string that describes the StringProc.
      def inspect
        "StringProc.new(#{@string.inspect})"
      end

      # Converts the StringProc to a JSON representation.
      # @param args [Array] Optional arguments for JSON conversion.
      # @return [String] The JSON representation of the StringProc.
      # @example Converting to JSON
      #   sp.to_json # => ';e "your_string"'
      def to_json(*args)
        ";e #{_dump}".to_json(args)
      end

      # Loads a StringProc from a string representation.
      # @param string [String] The string to load into a StringProc.
      # @return [StringProc] A new StringProc object initialized with the given string.
      def StringProc._load(string)
        StringProc.new(string)
      end
    end
  end
end
