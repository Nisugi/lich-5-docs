"""
Pytest configuration and fixtures for Lich 5 Documentation Generator tests.
"""

import sys
import os
from pathlib import Path

# Add src directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

import pytest


@pytest.fixture
def sample_ruby_class():
    """Simple Ruby class without documentation."""
    return '''class Calculator
  def initialize(value = 0)
    @value = value
  end

  def add(n)
    @value += n
  end

  def subtract(n)
    @value -= n
  end

  def result
    @value
  end
end
'''


@pytest.fixture
def sample_ruby_module():
    """Ruby module with class methods."""
    return '''module MathUtils
  def self.factorial(n)
    return 1 if n <= 1
    n * factorial(n - 1)
  end

  def self.fibonacci(n)
    return n if n < 2
    fibonacci(n - 1) + fibonacci(n - 2)
  end
end
'''


@pytest.fixture
def sample_documented_class():
    """Ruby class with existing YARD documentation."""
    return '''# Calculator class for basic arithmetic operations.
# @author Developer
class Calculator
  # Initialize a new calculator.
  # @param value [Integer] initial value (default: 0)
  # @return [Calculator] new calculator instance
  def initialize(value = 0)
    @value = value
  end

  # Add a number to the current value.
  # @param n [Integer] number to add
  # @return [Integer] the new value
  def add(n)
    @value += n
  end
end
'''


@pytest.fixture
def sample_complex_methods():
    """Ruby class with various method signatures."""
    return '''class ComplexClass
  attr_reader :name, :value
  attr_accessor :data
  attr_writer :secret

  CONSTANT = 42
  @@class_var = "shared"

  def initialize(name, *args, **options, &block)
    @name = name
    @args = args
    @options = options
    @block = block
  end

  def self.class_method
    @@class_var
  end

  def regular_method(param)
    param * 2
  end

  def method_with_question?
    true
  end

  def method_with_bang!
    @data = nil
  end

  def method_with_equals=(value)
    @data = value
  end

  protected

  def protected_method
    "protected"
  end

  private

  def private_method
    "private"
  end
end
'''


@pytest.fixture
def valid_json_response():
    """Valid JSON response from LLM."""
    return '''[
  {
    "line_number": 1,
    "anchor": "class Calculator",
    "indent": 0,
    "comment": "# Calculator class for basic arithmetic operations.\\n# @author System"
  },
  {
    "line_number": 2,
    "anchor": "def initialize",
    "indent": 2,
    "comment": "# Initialize the calculator.\\n# @param value [Integer] initial value\\n# @return [Calculator] new instance"
  }
]'''


@pytest.fixture
def wrapped_json_response():
    """JSON wrapped in {"comments": [...]} format."""
    return '''{
  "comments": [
    {
      "line_number": 1,
      "anchor": "class Calculator",
      "indent": 0,
      "comment": "# Calculator class."
    }
  ]
}'''


@pytest.fixture
def json_in_code_block():
    """JSON wrapped in markdown code block."""
    return '''Here is the documentation:

```json
[
  {
    "line_number": 1,
    "anchor": "def add",
    "indent": 2,
    "comment": "# Add a number.\\n# @param n [Integer] number to add"
  }
]
```

This should work correctly.'''


@pytest.fixture
def json_with_invalid_escapes():
    """JSON with invalid escape sequences (from regex in comments)."""
    return r'''[
  {
    "line_number": 1,
    "anchor": "def match_pattern",
    "indent": 2,
    "comment": "# Match pattern using regex.\n# @param str [String] string to match (e.g., \d+ for digits)\n# @return [Boolean] true if matches"
  }
]'''


@pytest.fixture
def empty_json_response():
    """Empty JSON array (valid - nothing to document)."""
    return '[]'


@pytest.fixture
def json_with_concatenation():
    """JSON with string concatenation (invalid JSON but sometimes generated)."""
    return '''[
  {
    "line_number": 1,
    "anchor": "class Test",
    "indent": 0,
    "comment": "# First line"
      + "\\n# Second line"
      + "\\n# Third line"
  }
]'''


@pytest.fixture
def sample_config():
    """Sample configuration dictionary."""
    return {
        'paths': {
            'output_dir': 'output/latest',
            'documented_dir': 'documented',
            'docs_dir': 'docs'
        },
        'processing': {
            'exclusions': ['/critranks/', '/creatures/'],
            'file_pattern': '*.rb',
            'output_structure': 'mirror'
        },
        'providers': {
            'openai': {
                'model': 'gpt-4o-mini',
                'max_tokens': 16384,
                'parallel_workers': 8
            }
        },
        'validation': {
            'pre_save_enabled': True,
            'retry_on_failure': True
        }
    }


@pytest.fixture
def temp_ruby_file(tmp_path, sample_ruby_class):
    """Create a temporary Ruby file for testing."""
    ruby_file = tmp_path / "test_class.rb"
    ruby_file.write_text(sample_ruby_class)
    return ruby_file


@pytest.fixture
def generator_instance():
    """Create a documentation generator instance with mock provider."""
    from generate_docs import Lich5DocumentationGenerator
    return Lich5DocumentationGenerator(provider_name='mock')
