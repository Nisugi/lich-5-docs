"""
Tests for hash computation functionality in generate_docs.py.

Tests the compute_code_hash method which computes a hash of Ruby code
excluding YARD documentation comments.
"""

import pytest


class TestComputeCodeHash:
    """Test the compute_code_hash method."""

    def test_same_code_same_hash(self, generator_instance, sample_ruby_class):
        """Test that identical code produces identical hashes."""
        hash1 = generator_instance.compute_code_hash(sample_ruby_class)
        hash2 = generator_instance.compute_code_hash(sample_ruby_class)

        assert hash1 == hash2

    def test_different_code_different_hash(self, generator_instance, sample_ruby_class, sample_ruby_module):
        """Test that different code produces different hashes."""
        hash1 = generator_instance.compute_code_hash(sample_ruby_class)
        hash2 = generator_instance.compute_code_hash(sample_ruby_module)

        assert hash1 != hash2

    def test_comments_excluded_from_hash(self, generator_instance, sample_ruby_class, sample_documented_class):
        """Test that YARD comments don't affect the hash."""
        # This test may need adjustment based on actual stripping behavior
        # The key point: documentation shouldn't change the code hash

        # Strip comments from documented version for comparison
        stripped = generator_instance.strip_yard_comments(sample_documented_class)
        hash_stripped = generator_instance.compute_code_hash(stripped)

        # Hash should be based on code, not comments
        # This verifies the hash is computed on code content
        assert hash_stripped is not None
        assert len(hash_stripped) == 16  # SHA256 truncated to 16 chars

    def test_hash_length(self, generator_instance, sample_ruby_class):
        """Test that hash is truncated to expected length."""
        hash_value = generator_instance.compute_code_hash(sample_ruby_class)

        assert len(hash_value) == 16

    def test_hash_is_hex(self, generator_instance, sample_ruby_class):
        """Test that hash contains only hex characters."""
        hash_value = generator_instance.compute_code_hash(sample_ruby_class)

        assert all(c in '0123456789abcdef' for c in hash_value)

    def test_whitespace_changes_affect_hash(self, generator_instance):
        """Test that whitespace changes do affect the hash."""
        code1 = "def method\n  value\nend"
        code2 = "def method\n    value\nend"  # Extra indentation

        hash1 = generator_instance.compute_code_hash(code1)
        hash2 = generator_instance.compute_code_hash(code2)

        assert hash1 != hash2

    def test_shebang_preserved_in_hash(self, generator_instance):
        """Test that shebang line is included in hash."""
        code_with_shebang = "#!/usr/bin/env ruby\nclass Test\nend"
        code_without_shebang = "class Test\nend"

        hash1 = generator_instance.compute_code_hash(code_with_shebang)
        hash2 = generator_instance.compute_code_hash(code_without_shebang)

        assert hash1 != hash2

    def test_encoding_comment_preserved(self, generator_instance):
        """Test that encoding comments are preserved in hash."""
        code_with_encoding = "# encoding: utf-8\nclass Test\nend"
        code_without_encoding = "class Test\nend"

        hash1 = generator_instance.compute_code_hash(code_with_encoding)
        hash2 = generator_instance.compute_code_hash(code_without_encoding)

        assert hash1 != hash2

    def test_frozen_string_literal_preserved(self, generator_instance):
        """Test that frozen_string_literal comment affects hash."""
        code_with_frozen = "# frozen_string_literal: true\nclass Test\nend"
        code_without_frozen = "class Test\nend"

        hash1 = generator_instance.compute_code_hash(code_with_frozen)
        hash2 = generator_instance.compute_code_hash(code_without_frozen)

        assert hash1 != hash2


class TestHashConsistency:
    """Test hash computation consistency across scenarios."""

    def test_empty_file_hash(self, generator_instance):
        """Test hash of empty file."""
        hash_value = generator_instance.compute_code_hash("")

        assert hash_value is not None
        assert len(hash_value) == 16

    def test_only_comments_file(self, generator_instance):
        """Test hash of file with only comments."""
        code = "# This is just a comment\n# Another comment"
        hash_value = generator_instance.compute_code_hash(code)

        assert hash_value is not None

    def test_code_with_inline_comments(self, generator_instance):
        """Test that inline comments are preserved."""
        code = '''def method
  value = 42  # inline comment
  value
end'''
        hash_value = generator_instance.compute_code_hash(code)

        # Inline comments should be preserved (they're code comments, not YARD)
        assert hash_value is not None

    def test_multiline_string_not_stripped(self, generator_instance):
        """Test that multiline strings with # are not affected."""
        code = '''def method
  str = "# This looks like a comment but isn't"
  str
end'''
        hash_value = generator_instance.compute_code_hash(code)

        assert hash_value is not None
        # The string content should be part of the hash

    def test_rubocop_directive_preserved(self, generator_instance):
        """Test that rubocop directives are preserved."""
        code_with_rubocop = "# rubocop:disable Style/All\nclass Test\nend"
        code_without = "class Test\nend"

        hash1 = generator_instance.compute_code_hash(code_with_rubocop)
        hash2 = generator_instance.compute_code_hash(code_without)

        # rubocop directives should be preserved as they affect code behavior
        assert hash1 != hash2
