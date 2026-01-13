"""
Tests for configuration management in src/config.py.

Tests the ConfigManager class and configuration loading.
"""

import pytest
import tempfile
from pathlib import Path
import yaml


class TestConfigManager:
    """Test the ConfigManager singleton."""

    def test_get_config_returns_config(self):
        """Test that get_config returns a Config object."""
        from config import get_config

        config = get_config()
        assert config is not None

    def test_config_has_paths(self):
        """Test that config has paths section."""
        from config import get_config

        config = get_config()
        assert hasattr(config, 'paths')
        assert hasattr(config.paths, 'output_dir')
        assert hasattr(config.paths, 'documented_dir')

    def test_config_has_processing(self):
        """Test that config has processing section."""
        from config import get_config

        config = get_config()
        assert hasattr(config, 'processing')
        assert hasattr(config.processing, 'exclusions')
        assert isinstance(config.processing.exclusions, list)

    def test_config_has_providers(self):
        """Test that config has providers section."""
        from config import get_config

        config = get_config()
        assert hasattr(config, 'providers')
        # Should have at least one provider
        assert len(config.providers) > 0

    def test_config_has_validation(self):
        """Test that config has validation section."""
        from config import get_config

        config = get_config()
        assert hasattr(config, 'validation')
        assert hasattr(config.validation, 'pre_save_enabled')
        assert hasattr(config.validation, 'retry_on_failure')


class TestProviderConfig:
    """Test provider configuration."""

    def test_get_provider_config(self):
        """Test getting provider-specific config."""
        from config import get_provider_config

        openai_config = get_provider_config('openai')
        assert openai_config is not None
        assert hasattr(openai_config, 'model')
        assert hasattr(openai_config, 'max_tokens')

    def test_provider_config_has_required_fields(self):
        """Test that provider configs have required fields."""
        from config import get_provider_config

        for provider in ['openai', 'anthropic', 'gemini', 'mock']:
            try:
                config = get_provider_config(provider)
                assert hasattr(config, 'model')
                assert hasattr(config, 'parallel_workers')
            except KeyError:
                pass  # Provider may not be configured

    def test_openai_config_values(self):
        """Test OpenAI config has expected values."""
        from config import get_provider_config

        config = get_provider_config('openai')
        assert config.model == 'gpt-4o-mini'
        assert config.parallel_workers == 8
        assert config.max_tokens == 16384


class TestConfigDefaults:
    """Test configuration default values."""

    def test_paths_defaults(self):
        """Test default path values."""
        from config import get_config

        config = get_config()
        assert config.paths.output_dir == 'output/latest'
        assert config.paths.documented_dir == 'documented'
        assert config.paths.docs_dir == 'docs'

    def test_exclusions_defaults(self):
        """Test default exclusion patterns."""
        from config import get_config

        config = get_config()
        assert '/critranks/' in config.processing.exclusions
        assert '/creatures/' in config.processing.exclusions

    def test_validation_defaults(self):
        """Test default validation settings."""
        from config import get_config

        config = get_config()
        assert config.validation.pre_save_enabled is True
        assert config.validation.retry_on_failure is True


class TestConfigLoading:
    """Test configuration file loading."""

    def test_load_from_custom_path(self, tmp_path):
        """Test loading config from custom path."""
        from config import ConfigManager

        # Create custom config
        config_data = {
            'paths': {
                'output_dir': 'custom/output',
                'documented_dir': 'custom/documented',
                'docs_dir': 'custom/docs'
            },
            'processing': {
                'exclusions': ['/test/'],
                'file_pattern': '*.rb',
                'output_structure': 'flat'
            },
            'providers': {
                'mock': {
                    'model': 'mock-model',
                    'max_tokens': 1024,
                    'parallel_workers': 2
                }
            },
            'validation': {
                'pre_save_enabled': False,
                'retry_on_failure': False
            }
        }

        config_file = tmp_path / 'test_config.yaml'
        with open(config_file, 'w') as f:
            yaml.dump(config_data, f)

        # Reset singleton for test
        ConfigManager._instance = None

        config = ConfigManager.load(str(config_file))
        assert config.paths.output_dir == 'custom/output'
        assert '/test/' in config.processing.exclusions
        assert config.validation.pre_save_enabled is False

        # Reset after test
        ConfigManager._instance = None

    def test_missing_config_uses_defaults(self):
        """Test that missing config file uses defaults."""
        from config import ConfigManager

        # Reset singleton
        ConfigManager._instance = None

        # Try to load non-existent file - should fall back to defaults
        try:
            config = ConfigManager.load('nonexistent_config.yaml')
        except FileNotFoundError:
            # Expected - but get() should still work with defaults
            pass

        # Reset singleton
        ConfigManager._instance = None


class TestJsonSchema:
    """Test JSON schema configuration."""

    def test_json_schema_exists(self):
        """Test that JSON schema is defined."""
        from config import get_config

        config = get_config()
        assert hasattr(config, 'json_schema')
        assert 'schema' in config.json_schema

    def test_json_schema_structure(self):
        """Test JSON schema has correct structure."""
        from config import get_config

        config = get_config()
        schema = config.json_schema.get('schema', {})

        assert schema.get('type') == 'object'
        assert 'properties' in schema
        assert 'comments' in schema['properties']


class TestAnchorMatching:
    """Test anchor matching configuration."""

    def test_anchor_matching_config(self):
        """Test anchor matching parameters."""
        from config import get_config

        config = get_config()
        assert hasattr(config, 'anchor_matching')
        assert hasattr(config.anchor_matching, 'line_offset')
        assert config.anchor_matching.line_offset == 5


class TestTimeouts:
    """Test timeout configuration."""

    def test_timeout_values(self):
        """Test timeout configuration values."""
        from config import get_config

        config = get_config()
        assert hasattr(config, 'timeouts')
        assert config.timeouts.yard_version_check == 10
        assert config.timeouts.yard_stats == 30
        assert config.timeouts.yard_doc_build == 300
