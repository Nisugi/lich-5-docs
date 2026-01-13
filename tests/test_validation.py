"""
Tests for YARD validation functionality in src/validation.py.

Tests the YARDValidator class which validates Ruby code
before saving to catch YARD syntax errors early.
"""

import pytest
from pathlib import Path


class TestYARDValidator:
    """Test the YARDValidator class."""

    def test_validator_creation(self):
        """Test creating a validator instance."""
        from validation import YARDValidator

        validator = YARDValidator()
        assert validator is not None

    def test_yard_availability_check(self):
        """Test checking if YARD is available."""
        from validation import YARDValidator

        validator = YARDValidator()
        result = validator.is_yard_available()

        # Result should be boolean
        assert isinstance(result, bool)

    def test_validate_valid_ruby(self):
        """Test validating valid Ruby code."""
        from validation import YARDValidator

        validator = YARDValidator()

        # Skip if YARD not available
        if not validator.is_yard_available():
            pytest.skip("YARD not installed")

        code = '''# Simple class
class TestClass
  # Initialize method
  # @param value [Integer] the value
  def initialize(value)
    @value = value
  end
end
'''
        result = validator.validate_content(code, "test.rb")

        assert result is not None
        assert hasattr(result, 'valid')

    def test_validate_returns_result_object(self):
        """Test that validation returns a ValidationResult."""
        from validation import YARDValidator, ValidationResult

        validator = YARDValidator()

        if not validator.is_yard_available():
            pytest.skip("YARD not installed")

        code = "class Simple\nend"
        result = validator.validate_content(code, "test.rb")

        assert isinstance(result, ValidationResult)
        assert hasattr(result, 'valid')
        assert hasattr(result, 'warnings')
        assert hasattr(result, 'errors')


class TestValidationResult:
    """Test the ValidationResult dataclass."""

    def test_validation_result_defaults(self):
        """Test ValidationResult default values."""
        from validation import ValidationResult

        result = ValidationResult(valid=True)

        assert result.valid is True
        assert result.warnings == []
        assert result.errors == []
        assert result.undocumented_count == 0
        assert result.documented_percent == 100.0

    def test_has_errors_property(self):
        """Test the has_errors property."""
        from validation import ValidationResult, ValidationWarning

        # No errors
        result = ValidationResult(valid=True)
        assert result.has_errors is False

        # With errors
        result = ValidationResult(
            valid=False,
            errors=[ValidationWarning(file="test.rb", line=1, message="error")]
        )
        assert result.has_errors is True

    def test_has_warnings_property(self):
        """Test the has_warnings property."""
        from validation import ValidationResult, ValidationWarning

        # No warnings
        result = ValidationResult(valid=True)
        assert result.has_warnings is False

        # With warnings
        result = ValidationResult(
            valid=True,
            warnings=[ValidationWarning(file="test.rb", line=1, message="warning")]
        )
        assert result.has_warnings is True

    def test_total_issues_property(self):
        """Test the total_issues property."""
        from validation import ValidationResult, ValidationWarning

        result = ValidationResult(
            valid=True,
            warnings=[
                ValidationWarning(file="test.rb", line=1, message="w1"),
                ValidationWarning(file="test.rb", line=2, message="w2"),
            ],
            errors=[
                ValidationWarning(file="test.rb", line=3, message="e1"),
            ]
        )

        assert result.total_issues == 3


class TestValidationWarning:
    """Test the ValidationWarning dataclass."""

    def test_warning_creation(self):
        """Test creating a ValidationWarning."""
        from validation import ValidationWarning

        warning = ValidationWarning(
            file="test.rb",
            line=10,
            message="Unknown tag @foo"
        )

        assert warning.file == "test.rb"
        assert warning.line == 10
        assert warning.message == "Unknown tag @foo"
        assert warning.warning_type == "warning"

    def test_warning_with_type(self):
        """Test creating a warning with specific type."""
        from validation import ValidationWarning

        warning = ValidationWarning(
            file="test.rb",
            line=5,
            message="Syntax error",
            warning_type="error"
        )

        assert warning.warning_type == "error"


class TestValidateFile:
    """Test file validation."""

    def test_validate_existing_file(self, temp_ruby_file):
        """Test validating an existing file."""
        from validation import YARDValidator

        validator = YARDValidator()

        if not validator.is_yard_available():
            pytest.skip("YARD not installed")

        result = validator.validate_file(temp_ruby_file)

        assert result is not None
        assert hasattr(result, 'valid')

    def test_validate_nonexistent_file(self):
        """Test validating a non-existent file."""
        from validation import YARDValidator

        validator = YARDValidator()
        result = validator.validate_file(Path("/nonexistent/file.rb"))

        assert result.valid is False
        assert len(result.errors) > 0
        assert "not found" in result.errors[0].message.lower()


class TestGetValidator:
    """Test the get_validator helper function."""

    def test_get_validator_returns_instance(self):
        """Test that get_validator returns a YARDValidator."""
        from validation import get_validator, YARDValidator

        validator = get_validator()

        assert isinstance(validator, YARDValidator)


class TestValidationWithConfig:
    """Test validation with configuration settings."""

    def test_validation_respects_enabled_setting(self):
        """Test that validation respects pre_save_enabled setting."""
        from validation import YARDValidator

        validator = YARDValidator()

        # This tests that validation can be skipped via config
        # The actual behavior depends on config settings
        code = "class Test\nend"
        result = validator.validate_content(code, "test.rb")

        # Should return some result (either validated or skipped)
        assert result is not None


class TestValidationEdgeCases:
    """Test edge cases in validation."""

    def test_validate_empty_content(self):
        """Test validating empty content."""
        from validation import YARDValidator

        validator = YARDValidator()

        if not validator.is_yard_available():
            pytest.skip("YARD not installed")

        result = validator.validate_content("", "empty.rb")

        assert result is not None

    def test_validate_only_comments(self):
        """Test validating file with only comments."""
        from validation import YARDValidator

        validator = YARDValidator()

        if not validator.is_yard_available():
            pytest.skip("YARD not installed")

        code = "# Just a comment\n# Another comment"
        result = validator.validate_content(code, "comments.rb")

        assert result is not None

    def test_validate_complex_yard_tags(self):
        """Test validating code with complex YARD tags."""
        from validation import YARDValidator

        validator = YARDValidator()

        if not validator.is_yard_available():
            pytest.skip("YARD not installed")

        code = '''
# Complex method documentation.
#
# @param name [String] the name parameter
# @param options [Hash] optional settings
# @option options [Boolean] :strict enable strict mode
# @option options [Integer] :timeout the timeout value
#
# @yield [result] yields the processed result
# @yieldparam result [String] the result string
#
# @return [Boolean] true on success
# @raise [ArgumentError] if name is invalid
#
# @example Basic usage
#   obj.process("test")
#
# @see OtherClass#method
# @since 1.0.0
# @author Developer
def process(name, options = {})
  yield name.upcase if block_given?
  true
end
'''
        result = validator.validate_content(code, "complex.rb")

        assert result is not None
