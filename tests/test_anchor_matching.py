"""
Tests for anchor matching functionality in generate_docs.py.

Tests the soft_match_anchor and find_insertion_line methods which
handle matching LLM-provided anchors to actual lines in Ruby code.
"""

import pytest


class TestSoftMatchAnchor:
    """Test the soft_match_anchor method."""

    def test_exact_match(self, generator_instance):
        """Test exact string match."""
        line = "  def initialize(value)"
        anchor = "def initialize"

        assert generator_instance.soft_match_anchor(line, anchor) is True

    def test_class_definition(self, generator_instance):
        """Test matching class definitions."""
        test_cases = [
            ("class Calculator", "class Calculator"),
            ("class Calculator < BaseClass", "class Calculator"),
            ("class MyClass", "class MyClass < Parent"),  # Anchor has inheritance
        ]

        for line, anchor in test_cases:
            assert generator_instance.soft_match_anchor(line, anchor) is True, \
                f"Failed: line='{line}', anchor='{anchor}'"

    def test_module_definition(self, generator_instance):
        """Test matching module definitions."""
        assert generator_instance.soft_match_anchor("module MyModule", "module MyModule") is True
        assert generator_instance.soft_match_anchor("module Outer::Inner", "module Outer::Inner") is True

    def test_method_definitions(self, generator_instance):
        """Test matching various method definition styles."""
        test_cases = [
            ("  def method_name", "def method_name"),
            ("  def method_name(arg)", "def method_name"),
            ("  def method_name(arg1, arg2)", "def method_name(arg1, arg2)"),
            ("    def deep_method", "def deep_method"),
        ]

        for line, anchor in test_cases:
            assert generator_instance.soft_match_anchor(line, anchor) is True, \
                f"Failed: line='{line}', anchor='{anchor}'"

    def test_self_methods(self, generator_instance):
        """Test matching self. class methods."""
        assert generator_instance.soft_match_anchor(
            "  def self.class_method", "def self.class_method"
        ) is True
        assert generator_instance.soft_match_anchor(
            "  def self.create(name)", "def self.create"
        ) is True

    def test_classname_methods(self, generator_instance):
        """Test matching ClassName.method style (legacy syntax)."""
        # This should match the same method
        assert generator_instance.soft_match_anchor(
            "  def MyClass.legacy_method", "def MyClass.legacy_method"
        ) is True

    def test_special_method_names(self, generator_instance):
        """Test matching methods with ?, !, = suffixes."""
        assert generator_instance.soft_match_anchor("  def valid?", "def valid?") is True
        assert generator_instance.soft_match_anchor("  def reset!", "def reset!") is True
        assert generator_instance.soft_match_anchor("  def value=(v)", "def value=") is True

    def test_attribute_accessors(self, generator_instance):
        """Test matching attr_reader, attr_writer, attr_accessor."""
        assert generator_instance.soft_match_anchor(
            "  attr_reader :name", "attr_reader :name"
        ) is True
        assert generator_instance.soft_match_anchor(
            "  attr_accessor :value, :data", "attr_accessor :value"
        ) is True
        assert generator_instance.soft_match_anchor(
            "  attr_writer :secret", "attr_writer :secret"
        ) is True

    def test_constants(self, generator_instance):
        """Test matching constant definitions."""
        assert generator_instance.soft_match_anchor(
            "  CONSTANT = 42", "CONSTANT ="
        ) is True
        assert generator_instance.soft_match_anchor(
            "  MY_CONST = 'value'", "MY_CONST"
        ) is True

    def test_instance_variables(self, generator_instance):
        """Test matching instance variable assignments."""
        # Instance variables are typically not anchors, but test anyway
        assert generator_instance.soft_match_anchor(
            "    @value = value", "@value"
        ) is True

    def test_class_variables(self, generator_instance):
        """Test matching class variable assignments."""
        assert generator_instance.soft_match_anchor(
            "  @@counter = 0", "@@counter"
        ) is True

    def test_no_match(self, generator_instance):
        """Test that non-matching lines return False."""
        assert generator_instance.soft_match_anchor(
            "  def other_method", "def initialize"
        ) is False
        assert generator_instance.soft_match_anchor(
            "class OtherClass", "class Calculator"
        ) is False

    def test_whitespace_handling(self, generator_instance):
        """Test that leading/trailing whitespace is handled."""
        assert generator_instance.soft_match_anchor(
            "    def method    ", "def method"
        ) is True

    def test_case_sensitivity(self, generator_instance):
        """Test that matching is case-sensitive for Ruby."""
        # Ruby is case-sensitive
        assert generator_instance.soft_match_anchor(
            "class MyClass", "class Myclass"
        ) is False


class TestFindInsertionLine:
    """Test finding the correct line to insert comments."""

    def test_find_class_definition(self, generator_instance, sample_ruby_class):
        """Test finding a class definition line."""
        lines = sample_ruby_class.split('\n')
        anchor = "class Calculator"
        expected_line = 1  # 1-indexed

        result = generator_instance.find_insertion_line(lines, anchor, expected_line)

        # Should find it at or near expected line
        assert result is not None
        assert 'class Calculator' in lines[result]

    def test_find_method_definition(self, generator_instance, sample_ruby_class):
        """Test finding a method definition line."""
        lines = sample_ruby_class.split('\n')
        anchor = "def initialize"
        expected_line = 2

        result = generator_instance.find_insertion_line(lines, anchor, expected_line)

        assert result is not None
        assert 'def initialize' in lines[result]

    def test_line_offset_search(self, generator_instance, sample_ruby_class):
        """Test that search works within line offset range."""
        lines = sample_ruby_class.split('\n')
        anchor = "def add"
        # Give wrong expected line but within offset
        expected_line = 10  # Wrong, but should still find it

        result = generator_instance.find_insertion_line(lines, anchor, expected_line)

        assert result is not None
        assert 'def add' in lines[result]

    def test_not_found_returns_none(self, generator_instance, sample_ruby_class):
        """Test that unfound anchors return None."""
        lines = sample_ruby_class.split('\n')
        anchor = "def nonexistent_method"
        expected_line = 1

        result = generator_instance.find_insertion_line(lines, anchor, expected_line)

        assert result is None

    def test_find_attr_accessor(self, generator_instance, sample_complex_methods):
        """Test finding attr_accessor lines."""
        lines = sample_complex_methods.split('\n')
        anchor = "attr_reader :name"
        expected_line = 5

        result = generator_instance.find_insertion_line(lines, anchor, expected_line)

        assert result is not None

    def test_find_constant(self, generator_instance, sample_complex_methods):
        """Test finding constant definitions."""
        lines = sample_complex_methods.split('\n')
        anchor = "CONSTANT_VALUE"
        expected_line = 8

        result = generator_instance.find_insertion_line(lines, anchor, expected_line)

        assert result is not None


class TestAnchorMatchingIntegration:
    """Integration tests for anchor matching with real code samples."""

    def test_match_all_methods_in_simple_class(self, generator_instance, sample_ruby_class):
        """Test that all methods in simple class can be matched."""
        lines = sample_ruby_class.split('\n')
        methods = ['def initialize', 'def add', 'def subtract', 'def result']

        for method in methods:
            found = False
            for i, line in enumerate(lines):
                if generator_instance.soft_match_anchor(line, method):
                    found = True
                    break
            assert found, f"Could not find anchor: {method}"

    def test_match_complex_signatures(self, generator_instance, sample_complex_methods):
        """Test matching methods with complex signatures."""
        lines = sample_complex_methods.split('\n')

        # These anchors represent what an LLM might return
        anchors = [
            'def initialize',
            'def self.create',
            'def method_with_defaults',
            'def splat_method',
            'def keyword_method',
            'def question_method?',
            'def bang_method!',
            'def assignment_method=',
        ]

        for anchor in anchors:
            found = False
            for i, line in enumerate(lines):
                if generator_instance.soft_match_anchor(line, anchor):
                    found = True
                    break
            assert found, f"Could not find anchor: {anchor}"
