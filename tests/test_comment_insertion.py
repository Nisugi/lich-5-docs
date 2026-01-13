"""
Tests for comment insertion functionality in generate_docs.py.

Tests the insert_comments method which handles inserting YARD
documentation comments at the correct locations in Ruby code.
"""

import pytest


class TestInsertComments:
    """Test the insert_comments method."""

    def test_insert_single_comment(self, generator_instance, sample_ruby_class):
        """Test inserting a single comment."""
        comments = [{
            'line_number': 1,
            'anchor': 'class Calculator',
            'indent': 0,
            'comment': '# Calculator class for arithmetic.'
        }]

        result = generator_instance.insert_comments(sample_ruby_class, comments)

        assert '# Calculator class for arithmetic.' in result
        # Comment should appear before class definition
        lines = result.split('\n')
        comment_idx = next(i for i, l in enumerate(lines) if '# Calculator class' in l)
        class_idx = next(i for i, l in enumerate(lines) if 'class Calculator' in l)
        assert comment_idx < class_idx

    def test_insert_multiple_comments(self, generator_instance, sample_ruby_class):
        """Test inserting multiple comments."""
        comments = [
            {
                'line_number': 1,
                'anchor': 'class Calculator',
                'indent': 0,
                'comment': '# Calculator class.'
            },
            {
                'line_number': 2,
                'anchor': 'def initialize',
                'indent': 2,
                'comment': '# Initialize method.'
            },
            {
                'line_number': 6,
                'anchor': 'def add',
                'indent': 2,
                'comment': '# Add method.'
            }
        ]

        result = generator_instance.insert_comments(sample_ruby_class, comments)

        assert '# Calculator class.' in result
        assert '# Initialize method.' in result
        assert '# Add method.' in result

    def test_indentation_preserved(self, generator_instance, sample_ruby_class):
        """Test that indentation is correctly applied."""
        comments = [{
            'line_number': 2,
            'anchor': 'def initialize',
            'indent': 2,
            'comment': '# Initialize with value.'
        }]

        result = generator_instance.insert_comments(sample_ruby_class, comments)
        lines = result.split('\n')

        # Find the comment line
        comment_line = next(l for l in lines if '# Initialize with value' in l)
        # Should have 2-space indentation
        assert comment_line.startswith('  # ')

    def test_multiline_comment(self, generator_instance, sample_ruby_class):
        """Test inserting multiline YARD comments."""
        comments = [{
            'line_number': 2,
            'anchor': 'def initialize',
            'indent': 2,
            'comment': '# Initialize the calculator.\n# @param value [Integer] initial value\n# @return [Calculator] new instance'
        }]

        result = generator_instance.insert_comments(sample_ruby_class, comments)

        assert '# Initialize the calculator.' in result
        assert '# @param value' in result
        assert '# @return [Calculator]' in result

    def test_no_duplicate_anchors(self, generator_instance, sample_ruby_class):
        """Test that duplicate anchors don't cause duplicate comments."""
        comments = [
            {
                'line_number': 6,
                'anchor': 'def add',
                'indent': 2,
                'comment': '# First add comment.'
            },
            {
                'line_number': 6,
                'anchor': 'def add',
                'indent': 2,
                'comment': '# Second add comment.'
            }
        ]

        result = generator_instance.insert_comments(sample_ruby_class, comments)

        # Only one should be inserted
        count = result.count('# First add comment.') + result.count('# Second add comment.')
        assert count == 1

    def test_empty_comments_list(self, generator_instance, sample_ruby_class):
        """Test that empty comments list returns original code."""
        result = generator_instance.insert_comments(sample_ruby_class, [])

        assert result == sample_ruby_class

    def test_insertion_order_independent(self, generator_instance, sample_ruby_class):
        """Test that comments are inserted correctly regardless of order in list."""
        # Provide comments in reverse order
        comments = [
            {
                'line_number': 10,
                'anchor': 'def result',
                'indent': 2,
                'comment': '# Return result.'
            },
            {
                'line_number': 6,
                'anchor': 'def add',
                'indent': 2,
                'comment': '# Add number.'
            },
            {
                'line_number': 1,
                'anchor': 'class Calculator',
                'indent': 0,
                'comment': '# Calculator class.'
            }
        ]

        result = generator_instance.insert_comments(sample_ruby_class, comments)
        lines = result.split('\n')

        # All comments should be present
        assert any('# Calculator class.' in l for l in lines)
        assert any('# Add number.' in l for l in lines)
        assert any('# Return result.' in l for l in lines)

        # And in correct order relative to code
        class_comment = next(i for i, l in enumerate(lines) if '# Calculator class.' in l)
        class_def = next(i for i, l in enumerate(lines) if 'class Calculator' in l)
        assert class_comment < class_def


class TestCommentInsertionEdgeCases:
    """Test edge cases in comment insertion."""

    def test_unfound_anchor_skipped(self, generator_instance, sample_ruby_class):
        """Test that comments for unfound anchors are skipped gracefully."""
        comments = [{
            'line_number': 1,
            'anchor': 'def nonexistent_method',
            'indent': 2,
            'comment': '# This should not appear.'
        }]

        result = generator_instance.insert_comments(sample_ruby_class, comments)

        assert '# This should not appear.' not in result

    def test_zero_indentation(self, generator_instance, sample_ruby_class):
        """Test comments with zero indentation."""
        comments = [{
            'line_number': 1,
            'anchor': 'class Calculator',
            'indent': 0,
            'comment': '# Top level comment.'
        }]

        result = generator_instance.insert_comments(sample_ruby_class, comments)
        lines = result.split('\n')

        comment_line = next(l for l in lines if '# Top level comment.' in l)
        # Should start at column 0
        assert comment_line == '# Top level comment.'

    def test_large_indentation(self, generator_instance):
        """Test comments with large indentation."""
        code = '''class Outer
  class Inner
    class Deep
      def method
        value
      end
    end
  end
end'''
        comments = [{
            'line_number': 4,
            'anchor': 'def method',
            'indent': 6,
            'comment': '# Deeply nested method.'
        }]

        result = generator_instance.insert_comments(code, comments)

        assert '      # Deeply nested method.' in result

    def test_preserve_existing_code(self, generator_instance, sample_ruby_class):
        """Test that original code is preserved after insertion."""
        comments = [{
            'line_number': 1,
            'anchor': 'class Calculator',
            'indent': 0,
            'comment': '# New comment.'
        }]

        result = generator_instance.insert_comments(sample_ruby_class, comments)

        # All original methods should still be present
        assert 'def initialize' in result
        assert 'def add' in result
        assert 'def subtract' in result
        assert 'def result' in result
        assert '@value' in result


class TestCommentInsertionWithYARDTags:
    """Test insertion of comments with YARD documentation tags."""

    def test_param_tag_insertion(self, generator_instance, sample_ruby_class):
        """Test inserting @param tags."""
        comments = [{
            'line_number': 6,
            'anchor': 'def add',
            'indent': 2,
            'comment': '# Add a number to the value.\n# @param n [Integer] the number to add\n# @return [Integer] the new value'
        }]

        result = generator_instance.insert_comments(sample_ruby_class, comments)

        assert '@param n [Integer]' in result
        assert '@return [Integer]' in result

    def test_example_block_insertion(self, generator_instance, sample_ruby_class):
        """Test inserting @example blocks."""
        comments = [{
            'line_number': 2,
            'anchor': 'def initialize',
            'indent': 2,
            'comment': '# Create a new calculator.\n# @example\n#   calc = Calculator.new(10)\n#   calc.value # => 10'
        }]

        result = generator_instance.insert_comments(sample_ruby_class, comments)

        assert '@example' in result
        assert 'calc = Calculator.new' in result

    def test_multiline_return_description(self, generator_instance, sample_ruby_class):
        """Test multiline @return descriptions."""
        comments = [{
            'line_number': 14,
            'anchor': 'def result',
            'indent': 2,
            'comment': '# Get the current value.\n# @return [Integer] the accumulated result\n#   after all operations'
        }]

        result = generator_instance.insert_comments(sample_ruby_class, comments)

        assert '@return [Integer]' in result
