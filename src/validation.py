"""
YARD Validation Module

Pre-save validation of generated YARD documentation to catch errors early.
Runs `yard stats` on content before saving to ensure valid syntax.
"""

import os
import subprocess
import tempfile
import logging
import re
from dataclasses import dataclass, field
from typing import List, Optional
from pathlib import Path

# Import config for timeout settings
try:
    from config import get_config
    HAS_CONFIG = True
except ImportError:
    HAS_CONFIG = False

logger = logging.getLogger(__name__)


def _get_validation_timeout() -> int:
    """Get validation timeout from config or use default."""
    if HAS_CONFIG:
        try:
            config = get_config()
            return config.timeouts.yard_stats
        except Exception:
            pass
    return 30  # Default 30 seconds


def _get_validation_enabled() -> bool:
    """Check if pre-save validation is enabled."""
    if HAS_CONFIG:
        try:
            config = get_config()
            return config.validation.pre_save_enabled
        except Exception:
            pass
    return True  # Default to enabled


def _get_retry_on_failure() -> bool:
    """Check if retry on validation failure is enabled."""
    if HAS_CONFIG:
        try:
            config = get_config()
            return config.validation.retry_on_failure
        except Exception:
            pass
    return True  # Default to enabled


@dataclass
class ValidationWarning:
    """Represents a single validation warning from YARD."""
    file: str
    line: Optional[int]
    message: str
    warning_type: str = "warning"  # warning, error, undocumented


@dataclass
class ValidationResult:
    """Result of YARD validation on a file."""
    valid: bool
    warnings: List[ValidationWarning] = field(default_factory=list)
    errors: List[ValidationWarning] = field(default_factory=list)
    undocumented_count: int = 0
    documented_percent: float = 100.0
    raw_output: str = ""

    @property
    def has_errors(self) -> bool:
        """Check if there are any errors (not just warnings)."""
        return len(self.errors) > 0

    @property
    def has_warnings(self) -> bool:
        """Check if there are any warnings."""
        return len(self.warnings) > 0

    @property
    def total_issues(self) -> int:
        """Total number of issues (warnings + errors)."""
        return len(self.warnings) + len(self.errors)


class YARDValidator:
    """
    Validates Ruby code with YARD documentation.

    Runs `yard stats` on content to check for:
    - Syntax errors in YARD tags
    - Missing documentation
    - Invalid @param names
    - Malformed @return types
    """

    def __init__(self):
        """Initialize the validator."""
        self._yard_available = None

    def is_yard_available(self) -> bool:
        """Check if YARD is installed and available."""
        if self._yard_available is not None:
            return self._yard_available

        try:
            result = subprocess.run(
                ['yard', '--version'],
                capture_output=True,
                text=True,
                timeout=10
            )
            self._yard_available = result.returncode == 0
            if self._yard_available:
                logger.debug(f"YARD version: {result.stdout.strip()}")
            else:
                logger.warning("YARD command failed")
        except FileNotFoundError:
            logger.warning("YARD is not installed. Validation will be skipped.")
            self._yard_available = False
        except subprocess.TimeoutExpired:
            logger.warning("YARD version check timed out")
            self._yard_available = False

        return self._yard_available

    def validate_content(self, content: str, filename: str = "temp.rb") -> ValidationResult:
        """
        Validate Ruby content with YARD documentation.

        Args:
            content: Ruby source code with YARD documentation
            filename: Original filename (for error messages)

        Returns:
            ValidationResult with validation status and any warnings/errors
        """
        # Check if validation is enabled
        if not _get_validation_enabled():
            logger.debug("Pre-save validation is disabled")
            return ValidationResult(valid=True)

        # Check if YARD is available
        if not self.is_yard_available():
            logger.warning("YARD not available, skipping validation")
            return ValidationResult(valid=True, raw_output="YARD not available")

        # Write content to temporary file
        temp_dir = None
        try:
            temp_dir = tempfile.mkdtemp(prefix="yard_validate_")
            temp_file = Path(temp_dir) / filename
            temp_file.write_text(content, encoding='utf-8')

            # Run yard stats on the temp file
            timeout = _get_validation_timeout()
            result = subprocess.run(
                ['yard', 'stats', '--list-undoc', str(temp_file)],
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=temp_dir
            )

            raw_output = result.stdout + result.stderr

            # Parse the output
            return self._parse_yard_output(raw_output, filename)

        except subprocess.TimeoutExpired:
            logger.error(f"YARD validation timed out for {filename}")
            return ValidationResult(
                valid=False,
                errors=[ValidationWarning(
                    file=filename,
                    line=None,
                    message="YARD validation timed out",
                    warning_type="error"
                )],
                raw_output="Timeout"
            )
        except Exception as e:
            logger.error(f"Error validating {filename}: {e}")
            return ValidationResult(
                valid=False,
                errors=[ValidationWarning(
                    file=filename,
                    line=None,
                    message=str(e),
                    warning_type="error"
                )],
                raw_output=str(e)
            )
        finally:
            # Clean up temp directory
            if temp_dir and os.path.exists(temp_dir):
                try:
                    import shutil
                    shutil.rmtree(temp_dir)
                except Exception:
                    pass

    def validate_file(self, file_path: Path) -> ValidationResult:
        """
        Validate an existing Ruby file with YARD documentation.

        Args:
            file_path: Path to the Ruby file

        Returns:
            ValidationResult with validation status and any warnings/errors
        """
        if not file_path.exists():
            return ValidationResult(
                valid=False,
                errors=[ValidationWarning(
                    file=str(file_path),
                    line=None,
                    message="File not found",
                    warning_type="error"
                )]
            )

        content = file_path.read_text(encoding='utf-8')
        return self.validate_content(content, file_path.name)

    def _parse_yard_output(self, output: str, filename: str) -> ValidationResult:
        """
        Parse YARD stats output to extract warnings and errors.

        Args:
            output: Raw output from yard stats command
            filename: Original filename for context

        Returns:
            ValidationResult with parsed warnings/errors
        """
        warnings = []
        errors = []
        undocumented_count = 0
        documented_percent = 100.0

        lines = output.split('\n')

        for line in lines:
            line = line.strip()
            if not line:
                continue

            # Parse undocumented items
            # Format: "Undocumented Objects:" followed by list
            if 'undocumented' in line.lower():
                # Try to extract count from lines like "10 undocumented objects"
                match = re.search(r'(\d+)\s+undocumented', line.lower())
                if match:
                    undocumented_count = int(match.group(1))

            # Parse documentation percentage
            # Format: "100.00% documented"
            match = re.search(r'([\d.]+)%\s*documented', line)
            if match:
                documented_percent = float(match.group(1))

            # Parse warnings (format: "filename:line: warning message")
            warn_match = re.match(r'(.+?):(\d+):\s*(.+)', line)
            if warn_match:
                warn_file, warn_line, message = warn_match.groups()
                warning = ValidationWarning(
                    file=warn_file,
                    line=int(warn_line),
                    message=message,
                    warning_type="warning"
                )

                # Check if it's an error vs warning
                if 'error' in message.lower() or 'invalid' in message.lower():
                    warning.warning_type = "error"
                    errors.append(warning)
                else:
                    warnings.append(warning)

            # Parse syntax errors
            if 'syntax error' in line.lower() or 'parse error' in line.lower():
                errors.append(ValidationWarning(
                    file=filename,
                    line=None,
                    message=line,
                    warning_type="error"
                ))

            # Parse YARD-specific errors
            if '@param' in line and ('unknown' in line.lower() or 'invalid' in line.lower()):
                errors.append(ValidationWarning(
                    file=filename,
                    line=None,
                    message=line,
                    warning_type="error"
                ))

        # Determine if valid
        # Valid if no errors and documented_percent is reasonable (>= 0)
        valid = len(errors) == 0

        return ValidationResult(
            valid=valid,
            warnings=warnings,
            errors=errors,
            undocumented_count=undocumented_count,
            documented_percent=documented_percent,
            raw_output=output
        )


def get_validator() -> YARDValidator:
    """Get a YARDValidator instance."""
    return YARDValidator()
