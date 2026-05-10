# Attempt to install and require kramdown, tracking if it loaded successfully
KRAMDOWN_LOADED = begin
  Lich::Util.install_gem_requirements({ 'kramdown' => false })
  require 'kramdown'
  true
rescue Gem::ConflictError => e
  # Gem version conflict - kramdown can't be activated due to dependency issues
  warn "TextStripper: Kramdown gem conflict detected (#{e.message}). Restart Lich5 to resolve."
  false
rescue LoadError => e
  # Kramdown gem not found or couldn't be loaded
  warn "TextStripper: Kramdown could not be loaded (#{e.message}). Restart Lich5 to resolve."
  false
rescue StandardError => e
  # Catch any other gem-related errors
  warn "TextStripper: Error loading kramdown (#{e.class}: #{e.message}). Restart Lich5 to resolve."
  false
end

module Lich
  # Provides utility methods for text processing in Lich
  # @example Using the TextStripper module
  #   stripped_text = Lich::Util::TextStripper.strip(html_content, Lich::Util::TextStripper::Mode::HTML)
  module Util
    # Module for stripping formatting from text
    # This module provides methods to strip HTML, XML, and Markdown formatting from text.
    # @example Stripping HTML from text
    #   plain_text = Lich::Util::TextStripper.strip(html_content, Lich::Util::TextStripper::Mode::HTML)
    module TextStripper
      module Mode
        # Strip HTML tags
        # Mode for stripping HTML tags
        HTML = :html

        # Strip XML tags
        # Mode for stripping XML tags
        XML = :xml

        # Strip Markdown/markup formatting
        # Mode for stripping Markdown/markup formatting
        MARKUP = :markup

        # Alias for MARKUP (both :markup and :markdown are accepted)
        # Alias for MARKUP (both :markup and :markdown are accepted)
        MARKDOWN = :markdown

        ALL = [HTML, XML, MARKUP, MARKDOWN].freeze

        # Validates if the given mode is a supported stripping mode
        # @param mode [Symbol, String] The mode to validate
        # @return [Boolean] True if the mode is valid, false otherwise
        def self.valid?(mode)
          ALL.include?(mode.to_sym)
        end

        # Returns a comma-separated list of valid modes
        # @return [String] A string listing all valid modes
        # @example Listing valid modes
        #   puts Lich::Util::TextStripper.list
        def self.list
          ALL.join(', ')
        end
      end

      MODE_TO_INPUT_FORMAT = {
        Mode::HTML     => 'html',
        Mode::MARKUP   => 'GFM',
        Mode::MARKDOWN => 'GFM'
      }.freeze

      # Checks if Kramdown is required for the given mode
      # @param mode [Symbol] The mode to check
      # @return [Boolean] True if Kramdown is required, false otherwise
      def self.requires_kramdown?(mode)
        MODE_TO_INPUT_FORMAT.key?(mode)
      end

      # Strips formatting from the given text based on the specified mode
      # @param text [String] The text to be stripped
      # @param mode [Symbol] The mode to use for stripping
      # @return [String] The stripped text
      # @raise [ArgumentError] If the mode is invalid
      # @example Stripping HTML
      #   plain_text = Lich::Util::TextStripper.strip(html_content, Lich::Util::TextStripper::Mode::HTML)
      def self.strip(text, mode)
        return "" if text.nil? || text.empty?

        # Validate mode BEFORE entering the rescue block
        # This allows ArgumentError to propagate to the caller as documented
        validated_mode = validate_mode(mode)

        # Check if kramdown is required and available
        if requires_kramdown?(validated_mode) && !KRAMDOWN_LOADED
          respond("Need to restart Lich5 in order to use this method.")
          return text
        end

        # Route to appropriate parsing method based on mode
        case validated_mode
        when Mode::XML
          strip_xml_with_rexml(text)
        else
          strip_with_kramdown(text, validated_mode)
        end
      rescue Kramdown::Error => e
        # Handle Kramdown parsing errors (HTML/MARKUP/MARKDOWN modes)
        log_error("Failed to parse #{validated_mode}", e)
        text
      rescue REXML::ParseException => e
        # Handle REXML parsing errors (XML mode)
        log_error("Failed to parse #{validated_mode}", e)
        text
      rescue StandardError => e
        # Catch any other unexpected errors during parsing
        log_error("Unexpected error during #{validated_mode} parsing", e)
        text
      end

      # Validates and normalizes the mode parameter
      # @param mode [Symbol, String] The mode to validate
      # @return [Symbol] The normalized mode
      # @raise [ArgumentError] If the mode is not a Symbol or String or is invalid
      def self.validate_mode(mode)
        # Ensure mode is a Symbol or String
        unless mode.is_a?(Symbol) || mode.is_a?(String)
          raise ArgumentError,
                "Mode must be a Symbol or String, got #{mode.class}"
        end

        # Normalize to symbol
        normalized_mode = mode.to_sym

        # Validate against allowed modes
        unless Mode.valid?(normalized_mode)
          raise ArgumentError,
                "Invalid mode: #{mode}. Use one of: #{Mode.list}"
        end

        normalized_mode
      end

      # Logs an error message along with the exception details
      # @param message [String] The error message to log
      # @param exception [StandardError] The exception that was raised
      def self.log_error(message, exception)
        full_message = "TextStripper: #{message} (#{exception.class}: #{exception.message}). Returning original."
        respond(full_message)
        Lich.log(full_message)
      end

      # Strips formatting from text using Kramdown
      # @param text [String] The text to be stripped
      # @param mode [Symbol] The mode to use for stripping
      # @return [String] The stripped text
      # @raise [Kramdown::Error] If Kramdown fails to parse the text
      def self.strip_with_kramdown(text, mode)
        unless KRAMDOWN_LOADED
          respond("Need to restart Lich5 in order to use this method.")
          return text
        end

        input_format = MODE_TO_INPUT_FORMAT[mode]
        doc = Kramdown::Document.new(text, input: input_format)

        # Extract plain text from the parsed document by traversing the element tree
        extract_text(doc.root).strip
      end

      # Strips XML tags from the given text
      # @param text [String] The XML text to be stripped
      # @return [String] The stripped text
      # @raise [REXML::ParseException] If there is an error parsing the XML
      def self.strip_xml_with_rexml(text)
        # Try to parse as-is first (in case it's already well-formed XML)
        begin
          doc = REXML::Document.new("<root>#{text}</root>")
        rescue REXML::ParseException
          # If parsing fails due to unescaped characters, wrap in CDATA
          doc = REXML::Document.new("<root><![CDATA[#{text}]]></root>")
        end

        # Extract all text content from the document
        extract_xml_text(doc.root).strip
      end

      def self.extract_xml_text(element)
        return '' if element.nil?

        text_parts = []

        # Iterate through all child nodes
        element.each do |node|
          case node
          when REXML::Text
            # Regular text node
            text_parts << node.value
          when REXML::CData
            # CDATA section - extract the content
            text_parts << node.value
          when REXML::Element
            # Nested element - recursively extract text
            text_parts << extract_xml_text(node)
          end
          # Ignore other node types (comments, processing instructions, etc.)
        end

        text_parts.join
      end

      def self.extract_text(element)
        return '' if element.nil?

        case element.type
        when :text
          element.value
        when :entity
          # Convert HTML entities (e.g., &nbsp; -> space)
          entity_to_char(element.value)
        when :smart_quote
          # Convert smart quotes to regular quotes
          smart_quote_to_char(element.value)
        when :codeblock, :codespan
          # Return code content as plain text
          element.value
        when :br
          # Convert line breaks to newlines
          "\n"
        when :blank
          # Blank lines become newlines
          "\n"
        else
          # For all other elements (p, div, span, etc.), recursively process children
          if element.children
            element.children.map { |child| extract_text(child) }.join
          else
            ''
          end
        end
      end

      def self.entity_to_char(entity)
        if entity.respond_to?(:char)
          entity.char
        else
          # Fallback for symbol entities
          case entity
          when :nbsp then ' '
          when :lt then '<'
          when :gt then '>'
          when :amp then '&'
          when :quot then '"'
          else entity.to_s
          end
        end
      end

      def self.smart_quote_to_char(quote_type)
        case quote_type
        when :lsquo, :rsquo then "'"
        when :ldquo, :rdquo then '"'
        else quote_type.to_s
        end
      end

      # Strips HTML tags from the given text
      # @param text [String] The HTML text to be stripped
      # @return [String] The stripped text
      # @note Kramdown must be loaded to use this method
      def self.strip_html(text)
        unless KRAMDOWN_LOADED
          respond("Need to restart Lich5 in order to use this method.")
          return text
        end

        strip_with_kramdown(text, Mode::HTML)
      end

      # Strips XML tags from the given text
      # @param text [String] The XML text to be stripped
      # @return [String] The stripped text
      def self.strip_xml(text)
        strip_xml_with_rexml(text)
      end

      # Strips Markdown/markup formatting from the given text
      # @param text [String] The text to be stripped
      # @return [String] The stripped text
      # @note Kramdown must be loaded to use this method
      def self.strip_markup(text)
        unless KRAMDOWN_LOADED
          respond("Need to restart Lich5 in order to use this method.")
          return text
        end

        strip_with_kramdown(text, Mode::MARKUP)
      end

      # Strips Markdown formatting from the given text
      # @param text [String] The Markdown text to be stripped
      # @return [String] The stripped text
      # @note Kramdown must be loaded to use this method
      def self.strip_markdown(text)
        unless KRAMDOWN_LOADED
          respond("Need to restart Lich5 in order to use this method.")
          return text
        end

        strip_with_kramdown(text, Mode::MARKDOWN)
      end
    end
  end
end
