"""
Anthropic (Claude) Provider Implementation
High-quality documentation generation using Claude models
"""

import os
import json
import logging
import time
from typing import Optional
from .base import LLMProvider, ProviderConfig

# Import config for structured output settings
try:
    from config import get_config, get_provider_config
    HAS_CONFIG = True
except ImportError:
    HAS_CONFIG = False

logger = logging.getLogger(__name__)

# Lazy import to avoid dependency issues when not using Anthropic
anthropic_client = None


def _get_structured_output_enabled() -> bool:
    """Check if structured output is enabled for Anthropic."""
    if HAS_CONFIG:
        try:
            cfg = get_provider_config('anthropic')
            return cfg.structured_output
        except Exception:
            pass
    return True  # Default to enabled


def _get_json_schema() -> dict:
    """Get the JSON schema for structured output."""
    if HAS_CONFIG:
        try:
            config = get_config()
            return config.json_schema.get('schema', {})
        except Exception:
            pass
    # Default schema
    return {
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
    }


class AnthropicProvider(LLMProvider):
    """Anthropic Claude provider for high-quality documentation generation"""

    def __init__(self, config: Optional[ProviderConfig] = None):
        # Default configuration for Claude 3 Haiku (cheapest, fastest)
        if config is None:
            config = ProviderConfig(
                name="anthropic",
                model="claude-3-haiku-20240307",  # Cheapest Claude model
                max_tokens=4096,
                temperature=0.0,
                # Rate limits for standard tier
                requests_per_minute=50,  # Conservative estimate
                requests_per_day=None,    # No daily limit (pay per use)
                # Claude 3 Haiku pricing (as of 2024)
                cost_per_1m_input=0.25,   # $0.25 per 1M input tokens
                cost_per_1m_output=1.25   # $1.25 per 1M output tokens
            )

        super().__init__(config)

        # Lazy import Anthropic
        global anthropic_client
        if anthropic_client is None:
            try:
                import anthropic
                anthropic_client = anthropic
            except ImportError:
                raise ImportError(
                    "anthropic package not installed. "
                    "Install with: pip install anthropic"
                )

        # Initialize Anthropic client
        api_key = config.api_key or os.environ.get('ANTHROPIC_API_KEY')
        if not api_key:
            raise ValueError(
                "ANTHROPIC_API_KEY not found in environment or config. "
                "Get your API key at: https://console.anthropic.com/"
            )

        self.client = anthropic_client.Anthropic(api_key=api_key)
        logger.info(f"[OK] Using Anthropic provider with {config.model}")

    def generate(self, prompt: str, system_prompt: Optional[str] = None) -> str:
        """
        Generate documentation using Claude with retry logic for rate limits

        Args:
            prompt: The user prompt
            system_prompt: Optional system prompt (used as system parameter in Claude)

        Returns:
            Generated documentation text
        """
        # Enforce rate limiting
        self._enforce_rate_limit()

        # Retry logic with exponential backoff for rate limits
        max_retries = 3
        base_delay = 5  # Start with 5 seconds

        for attempt in range(max_retries):
            try:
                # Check if structured output is enabled
                use_structured = _get_structured_output_enabled()

                # Create message with proper format for Claude
                messages = [{"role": "user", "content": prompt}]

                # Create the request
                kwargs = {
                    "model": self.config.model,
                    "max_tokens": self.config.max_tokens,
                    "temperature": self.config.temperature,
                    "messages": messages
                }

                # Add system prompt if provided
                if system_prompt:
                    kwargs["system"] = system_prompt

                if use_structured:
                    logger.info(f"Sending request to Claude ({self.request_count} total) with tool use")
                    schema = _get_json_schema()

                    # Add tool for structured output
                    kwargs["tools"] = [{
                        "name": "generate_yard_documentation",
                        "description": "Generate YARD documentation comments for Ruby code. Returns structured JSON with line numbers, anchors, indentation, and comment content.",
                        "input_schema": schema
                    }]
                    # Force the model to use the tool
                    kwargs["tool_choice"] = {"type": "tool", "name": "generate_yard_documentation"}

                    # Generate response
                    response = self.client.messages.create(**kwargs)

                    # Extract from tool use response
                    result_text = None
                    for block in response.content:
                        if block.type == "tool_use" and block.name == "generate_yard_documentation":
                            # The tool input is already parsed - convert back to JSON string
                            result_text = json.dumps(block.input)
                            break

                    if result_text is None:
                        # Fallback: try to get text response
                        for block in response.content:
                            if hasattr(block, 'text'):
                                result_text = block.text
                                break

                    if result_text is None:
                        raise Exception("No valid response from Claude tool use")
                else:
                    logger.info(f"Sending request to Claude ({self.request_count} total requests)")

                    # Generate response without tool use
                    response = self.client.messages.create(**kwargs)

                    # Extract text from response
                    result_text = response.content[0].text

                # Track usage and costs
                input_tokens = response.usage.input_tokens if hasattr(response, 'usage') else len(prompt) // 4
                output_tokens = response.usage.output_tokens if hasattr(response, 'usage') else len(result_text) // 4

                self._track_cost(prompt, result_text)

                # Log token usage
                logger.info(f"Claude response: {input_tokens} input tokens, {output_tokens} output tokens")

                return result_text

            except Exception as e:
                error_str = str(e)
                logger.error(f"Anthropic API error: {error_str}")

                # Check for rate limit errors
                if "rate_limit" in error_str.lower() or "429" in error_str:
                    if attempt < max_retries - 1:
                        # Exponential backoff: 5s, 10s, 20s
                        delay = base_delay * (2 ** attempt)
                        logger.warning(f"Rate limited. Retrying in {delay} seconds... (attempt {attempt + 1}/{max_retries})")
                        time.sleep(delay)
                        continue
                    else:
                        logger.error(f"Max retries ({max_retries}) reached. Still getting rate limited.")
                        raise Exception(
                            f"Anthropic rate limit exceeded after {max_retries} retries. "
                            f"Try reducing request frequency or upgrading your plan."
                        )

                # Re-raise other errors
                raise

    def get_info(self) -> dict:
        """Get provider information"""
        info = super().get_info()
        info.update({
            "note": "High-quality documentation using Claude models",
            "models_available": [
                "claude-3-opus-20240229",      # Most capable, most expensive
                "claude-3-sonnet-20240229",    # Balanced
                "claude-3-haiku-20240307",     # Fastest, cheapest (default)
            ],
            "advantages": [
                "Excellent code understanding",
                "High-quality documentation",
                "Good at following YARD conventions",
                "Fast response times with Haiku"
            ]
        })
        return info