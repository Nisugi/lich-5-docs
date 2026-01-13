"""
Tests for YARD comment stripping functionality in generate_docs.py.

Tests the strip_yard_comments method which removes existing YARD
documentation while preserving regular code comments.
"""

import pytest


class TestStripYardComments:
    """Test the strip_yard_comments method."""

    def test_strips_param_tags(self, generator_instance):
        """Test that @param tags are stripped."""
        code = '''# @param name [String] the name
def method(name)
end'''
        result = generator_instance.strip_yard_comments(code)

        assert '@param' not in result
        assert 'def method' in result

    def test_strips_return_tags(self, generator_instance):
        """Test that @return tags are stripped."""
        code = '''# @return [Boolean] true if valid
def valid?
  true
end'''
        result = generator_instance.strip_yard_comments(code)

        assert '@return' not in result
        assert 'def valid?' in result

    def test_strips_example_blocks(self, generator_instance):
        """Test that @example blocks are stripped."""
        code = '''# @example Usage
#   obj = MyClass.new
#   obj.method
def method
end'''
        result = generator_instance.strip_yard_comments(code)

        assert '@example' not in result
        assert 'def method' in result

    def test_strips_note_tags(self, generator_instance):
        """Test that @note tags are stripped."""
        code = '''# @note This is important
def method
end'''
        result = generator_instance.strip_yard_comments(code)

        assert '@note' not in result

    def test_strips_see_tags(self, generator_instance):
        """Test that @see tags are stripped."""
        code = '''# @see OtherClass
def method
end'''
        result = generator_instance.strip_yard_comments(code)

        assert '@see' not in result

    def test_strips_yield_tags(self, generator_instance):
        """Test that @yield tags are stripped."""
        code = '''# @yield [result] the result
def method
  yield value
end'''
        result = generator_instance.strip_yard_comments(code)

        assert '@yield' not in result

    def test_preserves_shebang(self, generator_instance):
        """Test that shebang line is preserved."""
        code = '''#!/usr/bin/env ruby
# @param n [Integer] number
def method(n)
end'''
        result = generator_instance.strip_yard_comments(code)

        assert '#!/usr/bin/env ruby' in result

    def test_preserves_encoding_comment(self, generator_instance):
        """Test that encoding comments are preserved."""
        code = '''# encoding: utf-8
# @return [String] result
def method
end'''
        result = generator_instance.strip_yard_comments(code)

        assert 'encoding: utf-8' in result

    def test_preserves_frozen_string_literal(self, generator_instance):
        """Test that frozen_string_literal is preserved."""
        code = '''# frozen_string_literal: true
# @param x [Integer] input
def method(x)
end'''
        result = generator_instance.strip_yard_comments(code)

        assert 'frozen_string_literal: true' in result

    def test_preserves_rubocop_directives(self, generator_instance):
        """Test that rubocop directives are preserved."""
        code = '''# rubocop:disable Style/MethodName
# @param value [Object] the value
def BAD_method_name(value)
end
# rubocop:enable Style/MethodName'''
        result = generator_instance.strip_yard_comments(code)

        assert 'rubocop:disable' in result
        assert 'rubocop:enable' in result

    def test_preserves_inline_comments(self, generator_instance):
        """Test that inline code comments are preserved."""
        code = '''def method
  value = 42  # This is an inline comment
  value * 2   # Another inline
end'''
        result = generator_instance.strip_yard_comments(code)

        assert '# This is an inline comment' in result
        assert '# Another inline' in result


class TestStripYardCommentsEdgeCases:
    """Test edge cases in YARD comment stripping."""

    def test_strips_multiline_description(self, generator_instance):
        """Test stripping multiline YARD descriptions."""
        code = '''# This is a long description
# that spans multiple lines
# and should all be stripped.
# @author Developer
def method
end'''
        result = generator_instance.strip_yard_comments(code)

        # YARD descriptions before tags should be stripped
        assert '@author' not in result
        assert 'def method' in result

    def test_preserves_code_structure(self, generator_instance, sample_documented_class):
        """Test that code structure is preserved after stripping."""
        result = generator_instance.strip_yard_comments(sample_documented_class)

        # All class/method definitions should remain
        assert 'class DocumentedClass' in result
        assert 'def initialize' in result
        assert 'def process' in result
        assert 'def valid?' in result
        assert 'private' in result

    def test_empty_result_for_only_comments(self, generator_instance):
        """Test stripping file with only YARD comments."""
        code = '''# @param x [Integer] input
# @return [Integer] output'''
        result = generator_instance.strip_yard_comments(code)

        # Should return mostly empty but not crash
        assert result is not None

    def test_hash_in_string_not_stripped(self, generator_instance):
        """Test that # in strings is not affected."""
        code = '''def method
  str = "This # is not a comment"
  str
end'''
        result = generator_instance.strip_yard_comments(code)

        assert '"This # is not a comment"' in result

    def test_preserves_blank_lines(self, generator_instance):
        """Test that blank lines are reasonably preserved."""
        code = '''# @param x [Integer]
def method1
end

def method2
end'''
        result = generator_instance.strip_yard_comments(code)

        # Should have some structure preserved
        assert 'def method1' in result
        assert 'def method2' in result


class TestStripYardCommentsWithSampleFiles:
    """Test stripping with sample files from fixtures."""

    def test_strip_documented_class(self, generator_instance, sample_documented_class):
        """Test stripping the documented class sample."""
        result = generator_instance.strip_yard_comments(sample_documented_class)

        # YARD tags should be gone
        assert '@author' not in result
        assert '@since' not in result
        assert '@param' not in result
        assert '@return' not in result
        assert '@option' not in result
        assert '@yield' not in result
        assert '@example' not in result
        assert '@raise' not in result
        assert '@api' not in result

        # Code should remain
        assert 'class DocumentedClass' in result
        assert 'attr_reader :name' in result
        assert 'TIMEOUT = 30' in result
        assert 'def initialize' in result
        assert 'private' in result

    def test_undocumented_class_unchanged(self, generator_instance, sample_ruby_class):
        """Test that undocumented class is mostly unchanged."""
        result = generator_instance.strip_yard_comments(sample_ruby_class)

        # Structure should be identical (may have whitespace differences)
        assert 'class Calculator' in result
        assert 'def initialize' in result
        assert 'def add' in result
        assert 'def subtract' in result
        assert 'def result' in result
