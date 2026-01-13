"""
Configuration Management Module

Provides centralized configuration loading from config.yaml with singleton pattern.
Supports environment variable overrides and typed access to configuration values.
"""

import os
import logging
from pathlib import Path
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any

import yaml

logger = logging.getLogger(__name__)


@dataclass
class PathsConfig:
    """Directory path configuration."""
    output_dir: str = "output/latest"
    documented_dir: str = "documented"
    docs_dir: str = "docs"
    manifest_file: str = "output/latest/manifest.json"


@dataclass
class ProcessingConfig:
    """File processing configuration."""
    exclusions: List[str] = field(default_factory=lambda: ["/critranks/", "/creatures/"])
    file_pattern: str = "*.rb"
    output_structure: str = "mirror"


@dataclass
class ProviderConfig:
    """Configuration for a single LLM provider."""
    model: str
    max_tokens: int = 4096
    temperature: float = 0.0
    parallel_workers: int = 1
    requests_per_minute: int = 60
    requests_per_day: Optional[int] = None
    cost_per_1m_input: float = 0.0
    cost_per_1m_output: float = 0.0
    structured_output: bool = True
    max_retries: int = 3
    base_retry_delay: int = 5


@dataclass
class AnchorMatchingConfig:
    """Anchor matching parameters for comment insertion."""
    line_offset: int = 5
    lookahead_lines: int = 10


@dataclass
class TimeoutsConfig:
    """Timeout values in seconds."""
    yard_version_check: int = 10
    yard_stats: int = 30
    yard_doc_build: int = 300


@dataclass
class ValidationConfig:
    """Pre-save validation settings."""
    pre_save_enabled: bool = True
    retry_on_failure: bool = True
    max_retries: int = 1
    strict_mode: bool = False


@dataclass
class Config:
    """Main configuration container."""
    paths: PathsConfig
    processing: ProcessingConfig
    providers: Dict[str, ProviderConfig]
    anchor_matching: AnchorMatchingConfig
    timeouts: TimeoutsConfig
    validation: ValidationConfig
    json_schema: Dict[str, Any]


class ConfigManager:
    """
    Singleton configuration manager.

    Loads configuration from config.yaml and provides typed access to values.
    Supports environment variable overrides for sensitive values.

    Usage:
        config = ConfigManager.get()
        print(config.providers['openai'].model)
    """

    _instance: Optional[Config] = None
    _config_path: Optional[Path] = None

    # Default config file locations to search
    DEFAULT_PATHS = [
        Path("config.yaml"),
        Path("config.yml"),
        Path(__file__).parent.parent / "config.yaml",
    ]

    @classmethod
    def load(cls, path: Optional[str] = None) -> Config:
        """
        Load configuration from YAML file.

        Args:
            path: Optional path to config file. If None, searches default locations.

        Returns:
            Loaded Config instance

        Raises:
            FileNotFoundError: If no config file found
        """
        if path:
            cls._config_path = Path(path)
        else:
            # Search default locations
            for default_path in cls.DEFAULT_PATHS:
                if default_path.exists():
                    cls._config_path = default_path
                    break

        if cls._config_path is None or not cls._config_path.exists():
            logger.warning("No config.yaml found, using defaults")
            cls._instance = cls._create_default_config()
            return cls._instance

        logger.info(f"Loading configuration from {cls._config_path}")

        with open(cls._config_path, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)

        cls._instance = cls._parse_config(data)
        return cls._instance

    @classmethod
    def get(cls) -> Config:
        """
        Get the configuration instance (loads if not already loaded).

        Returns:
            Config instance
        """
        if cls._instance is None:
            cls.load()
        return cls._instance

    @classmethod
    def reload(cls, path: Optional[str] = None) -> Config:
        """
        Force reload configuration from file.

        Args:
            path: Optional path to config file

        Returns:
            Newly loaded Config instance
        """
        cls._instance = None
        return cls.load(path)

    @classmethod
    def _parse_config(cls, data: Dict[str, Any]) -> Config:
        """Parse YAML data into typed Config object."""

        # Parse paths
        paths_data = data.get('paths', {})
        paths = PathsConfig(
            output_dir=paths_data.get('output_dir', 'output/latest'),
            documented_dir=paths_data.get('documented_dir', 'documented'),
            docs_dir=paths_data.get('docs_dir', 'docs'),
            manifest_file=paths_data.get('manifest_file', 'output/latest/manifest.json'),
        )

        # Parse processing
        processing_data = data.get('processing', {})
        processing = ProcessingConfig(
            exclusions=processing_data.get('exclusions', ['/critranks/', '/creatures/']),
            file_pattern=processing_data.get('file_pattern', '*.rb'),
            output_structure=processing_data.get('output_structure', 'mirror'),
        )

        # Parse providers
        providers = {}
        providers_data = data.get('providers', {})

        for name, provider_data in providers_data.items():
            providers[name] = ProviderConfig(
                model=provider_data.get('model', 'unknown'),
                max_tokens=provider_data.get('max_tokens', 4096),
                temperature=provider_data.get('temperature', 0.0),
                parallel_workers=provider_data.get('parallel_workers', 1),
                requests_per_minute=provider_data.get('requests_per_minute', 60),
                requests_per_day=provider_data.get('requests_per_day'),
                cost_per_1m_input=provider_data.get('cost_per_1m_input', 0.0),
                cost_per_1m_output=provider_data.get('cost_per_1m_output', 0.0),
                structured_output=provider_data.get('structured_output', True),
                max_retries=provider_data.get('max_retries', 3),
                base_retry_delay=provider_data.get('base_retry_delay', 5),
            )

        # Ensure default providers exist
        if 'openai' not in providers:
            providers['openai'] = ProviderConfig(
                model='gpt-4o-mini',
                max_tokens=16384,
                parallel_workers=8,
                requests_per_minute=400,
                cost_per_1m_input=0.15,
                cost_per_1m_output=0.60,
            )
        if 'anthropic' not in providers:
            providers['anthropic'] = ProviderConfig(
                model='claude-3-haiku-20240307',
                max_tokens=4096,
                parallel_workers=4,
                requests_per_minute=50,
                cost_per_1m_input=0.25,
                cost_per_1m_output=1.25,
            )
        if 'gemini' not in providers:
            providers['gemini'] = ProviderConfig(
                model='gemini-2.0-flash-exp',
                max_tokens=8192,
                parallel_workers=1,
                requests_per_minute=8,
                requests_per_day=150,
            )
        if 'mock' not in providers:
            providers['mock'] = ProviderConfig(
                model='mock-model',
                max_tokens=4096,
                parallel_workers=4,
                requests_per_minute=15,
                requests_per_day=1500,
                structured_output=False,
            )

        # Parse anchor matching
        anchor_data = data.get('anchor_matching', {})
        anchor_matching = AnchorMatchingConfig(
            line_offset=anchor_data.get('line_offset', 5),
            lookahead_lines=anchor_data.get('lookahead_lines', 10),
        )

        # Parse timeouts
        timeouts_data = data.get('timeouts', {})
        timeouts = TimeoutsConfig(
            yard_version_check=timeouts_data.get('yard_version_check', 10),
            yard_stats=timeouts_data.get('yard_stats', 30),
            yard_doc_build=timeouts_data.get('yard_doc_build', 300),
        )

        # Parse validation
        validation_data = data.get('validation', {})
        validation = ValidationConfig(
            pre_save_enabled=validation_data.get('pre_save_enabled', True),
            retry_on_failure=validation_data.get('retry_on_failure', True),
            max_retries=validation_data.get('max_retries', 1),
            strict_mode=validation_data.get('strict_mode', False),
        )

        # Parse JSON schema
        json_schema = data.get('json_schema', cls._default_json_schema())

        return Config(
            paths=paths,
            processing=processing,
            providers=providers,
            anchor_matching=anchor_matching,
            timeouts=timeouts,
            validation=validation,
            json_schema=json_schema,
        )

    @classmethod
    def _create_default_config(cls) -> Config:
        """Create default configuration when no file is found."""
        return cls._parse_config({})

    @classmethod
    def _default_json_schema(cls) -> Dict[str, Any]:
        """Return the default JSON schema for YARD comments."""
        return {
            "name": "yard_comments",
            "schema": {
                "type": "object",
                "properties": {
                    "comments": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "line_number": {"type": "integer"},
                                "anchor": {"type": "string"},
                                "indent": {"type": "integer"},
                                "comment": {"type": "string"},
                            },
                            "required": ["line_number", "anchor", "indent", "comment"],
                        },
                    },
                },
                "required": ["comments"],
            },
        }


def get_config() -> Config:
    """
    Convenience function to get configuration.

    Returns:
        Config instance
    """
    return ConfigManager.get()


def get_provider_config(provider_name: str) -> ProviderConfig:
    """
    Get configuration for a specific provider.

    Args:
        provider_name: Name of the provider (openai, anthropic, gemini, mock)

    Returns:
        ProviderConfig for the specified provider

    Raises:
        KeyError: If provider not found
    """
    config = ConfigManager.get()
    if provider_name not in config.providers:
        raise KeyError(f"Unknown provider: {provider_name}. Available: {list(config.providers.keys())}")
    return config.providers[provider_name]
