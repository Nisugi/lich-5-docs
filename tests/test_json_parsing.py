"""
Tests for JSON parsing functionality in generate_docs.py.

Tests the extract_comments_json method which handles various
JSON formats returned by LLMs, including:
- Valid JSON arrays
- Wrapped {"comments": [...]} format
- JSON in code blocks
- Invalid escape sequences
- String concatenation cleanup
"""

import pytest
import json


class TestExtractCommentsJson:
    """Test the extract_comments_json method."""

    def test_valid_json_array(self, generator_instance, valid_json_response):
        """Test parsing a valid JSON array."""
        comments = generator_instance.extract_comments_json(valid_json_response)

        assert comments is not None
        assert len(comments) == 2
        assert comments[0]['anchor'] == 'class Calculator'
        assert comments[1]['anchor'] == 'def initialize'

    def test_wrapped_json_format(self, generator_instance, wrapped_json_response):
        """Test parsing JSON wrapped in {"comments": [...]} format."""
        comments = generator_instance.extract_comments_json(wrapped_json_response)

        assert comments is not None
        assert len(comments) == 1
        assert comments[0]['anchor'] == 'class Calculator'

    def test_json_in_code_block(self, generator_instance, json_in_code_block):
        """Test extracting JSON from markdown code block."""
        comments = generator_instance.extract_comments_json(json_in_code_block)

        assert comments is not None
        assert len(comments) == 1
        assert comments[0]['anchor'] == 'def add'

    def test_empty_json_array(self, generator_instance, empty_json_response):
        """Test that empty array is valid (nothing to document)."""
        comments = generator_instance.extract_comments_json(empty_json_response)

        assert comments is not None
        assert len(comments) == 0

    def test_direct_json_parse_first(self, generator_instance):
        """Test that direct JSON parse is attempted first (Strategy 0)."""
        # Structured output format - should be parsed directly
        response = '{"comments": [{"line_number": 1, "anchor": "class Test", "indent": 0, "comment": "# Test"}]}'
        comments = generator_instance.extract_comments_json(response)

        assert comments is not None
        assert len(comments) == 1

    def test_invalid_json_returns_none(self, generator_instance):
        """Test that completely invalid input returns None."""
        invalid = "This is not JSON at all, just random text."
        comments = generator_instance.extract_comments_json(invalid)

        assert comments is None


class TestSanitizeJsonEscapes:
    """Test the sanitize_json_escapes method."""

    def test_valid_escapes_preserved(self, generator_instance):
        """Test that valid JSON escapes are preserved."""
        text = r'{"text": "line1\nline2\ttabbed\"quoted\\"}'
        result = generator_instance.sanitize_json_escapes(text)

        # Should be parseable
        parsed = json.loads(result)
        assert 'line1\nline2' in parsed['text']

    def test_invalid_regex_escapes_fixed(self, generator_instance):
        """Test that invalid regex escapes like \\d, \\s are fixed."""
        # Raw string with invalid \d escape
        text = r'{"pattern": "matches \d+ digits"}'
        result = generator_instance.sanitize_json_escapes(text)

        # Should be parseable after sanitization
        parsed = json.loads(result)
        assert 'd+' in parsed['pattern']

    def test_invalid_word_escapes_fixed(self, generator_instance):
        """Test that \\w, \\s, \\b are fixed."""
        text = r'{"regex": "\w+\s*\b"}'
        result = generator_instance.sanitize_json_escapes(text)

        # Should not raise
        parsed = json.loads(result)
        assert parsed is not None

    def test_unicode_escapes_preserved(self, generator_instance):
        """Test that valid \\uXXXX escapes are preserved."""
        text = r'{"emoji": "\u2764"}'
        result = generator_instance.sanitize_json_escapes(text)

        parsed = json.loads(result)
        assert parsed['emoji'] == '\u2764'

    def test_invalid_unicode_fixed(self, generator_instance):
        """Test that invalid \\uXXX (incomplete) is fixed."""
        text = r'{"bad": "\u12"}'  # Invalid - only 2 hex digits
        result = generator_instance.sanitize_json_escapes(text)

        # Should be parseable after fix
        parsed = json.loads(result)
        assert parsed is not None


class TestCleanJsonConcatenation:
    """Test the clean_json_concatenation method."""

    def test_simple_concatenation(self, generator_instance):
        """Test cleaning simple string concatenation."""
        text = '"hello" + "world"'
        result = generator_instance.clean_json_concatenation(text)

        assert result == '"helloworld"'

    def test_multiline_concatenation(self, generator_instance):
        """Test cleaning multiline concatenation."""
        text = '''"line1"
            + "line2"
            + "line3"'''
        result = generator_instance.clean_json_concatenation(text)

        assert result == '"line1line2line3"'

    def test_no_concatenation(self, generator_instance):
        """Test that text without concatenation is unchanged."""
        text = '{"key": "value"}'
        result = generator_instance.clean_json_concatenation(text)

        assert result == text

    def test_concatenation_in_json_array(self, generator_instance):
        """Test cleaning concatenation within JSON structure."""
        text = '''[{"comment": "# Line 1"
            + "\\n# Line 2"}]'''
        result = generator_instance.clean_json_concatenation(text)

        # Should combine strings
        assert '"# Line 1\\n# Line 2"' in result or '"# Line 1\n# Line 2"' in result


class TestJsonParsingEdgeCases:
    """Test edge cases in JSON parsing."""

    def test_json_with_comments_key(self, generator_instance):
        """Test parsing response where 'comments' is the key."""
        response = '''{"comments": [
            {"line_number": 5, "anchor": "def method", "indent": 2, "comment": "# Doc"}
        ]}'''
        comments = generator_instance.extract_comments_json(response)

        assert len(comments) == 1
        assert comments[0]['line_number'] == 5

    def test_json_with_extra_whitespace(self, generator_instance):
        """Test parsing JSON with extra whitespace."""
        response = '''

        [
            {
                "line_number" : 1 ,
                "anchor" : "class Test" ,
                "indent" : 0 ,
                "comment" : "# Test"
            }
        ]

        '''
        comments = generator_instance.extract_comments_json(response)

        assert comments is not None
        assert len(comments) == 1

    def test_json_with_trailing_content(self, generator_instance):
        """Test parsing JSON with trailing non-JSON content."""
        response = '''[{"line_number": 1, "anchor": "class A", "indent": 0, "comment": "# A"}]

Let me know if you need any changes!'''
        comments = generator_instance.extract_comments_json(response)

        assert comments is not None
        assert len(comments) == 1

    def test_empty_comments_array_valid(self, generator_instance):
        """Test that empty comments array is valid."""
        response = '{"comments": []}'
        comments = generator_instance.extract_comments_json(response)

        assert comments is not None
        assert len(comments) == 0

    def test_newlines_in_comment_preserved(self, generator_instance):
        """Test that newlines in comments are preserved."""
        response = '''[{
            "line_number": 1,
            "anchor": "def method",
            "indent": 2,
            "comment": "# First line\\n# Second line\\n# Third line"
        }]'''
        comments = generator_instance.extract_comments_json(response)

        assert comments is not None
        assert '\\n' in comments[0]['comment'] or '\n' in comments[0]['comment']
