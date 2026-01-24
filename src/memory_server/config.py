"""T014: Configuration parsing for the persistent memory system.

Provides a validated MemoryConfig dataclass and a load_config function that
reads settings from a .memoryrc YAML file in the workspace, applies environment
variable overrides, and validates all values against defined constraints.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

import yaml

# ---------------------------------------------------------------------------
# Default excluded patterns (common secret/credential file patterns)
# ---------------------------------------------------------------------------

_DEFAULT_EXCLUDED_PATTERNS: list[str] = [
    "*.env",
    ".env.*",
    "*credentials*",
    "*secret*",
    "*.pem",
    "*.key",
    "*_rsa",
    "*_dsa",
    "*_ecdsa",
    "*_ed25519",
    "*.pfx",
    "*.p12",
    "id_rsa*",
    "id_dsa*",
    "id_ecdsa*",
    "id_ed25519*",
    ".aws/credentials",
    ".ssh/*",
    "*.keystore",
    "*.jks",
]


# ---------------------------------------------------------------------------
# Validation helpers
# ---------------------------------------------------------------------------


class ConfigValidationError(ValueError):
    """Raised when configuration values are outside valid ranges."""


def _validate_retention_days(value: int) -> int:
    """Validate retention_days is within 1-365 range."""
    if not (1 <= value <= 365):
        msg = f"retention_days must be between 1 and 365, got: {value}"
        raise ConfigValidationError(msg)
    return value


def _validate_max_size_mb(value: int) -> int:
    """Validate max_size_mb is within 50-2000 range."""
    if not (50 <= value <= 2000):
        msg = f"max_size_mb must be between 50 and 2000, got: {value}"
        raise ConfigValidationError(msg)
    return value


# ---------------------------------------------------------------------------
# MemoryConfig
# ---------------------------------------------------------------------------


@dataclass
class MemoryConfig:
    """Configuration for the persistent memory system.

    All fields have sensible defaults and are validated at construction time.
    Values can be loaded from a .memoryrc YAML file and overridden by
    environment variables.

    Attributes:
        retention_days: Number of days to retain memory entries (1-365).
        max_size_mb: Maximum database size in megabytes (50-2000).
        log_level: Logging level string (e.g., "INFO", "DEBUG", "WARNING").
        excluded_patterns: Glob patterns for files to exclude from memory capture.
        workspace_path: The workspace path this config was loaded from.
    """

    retention_days: int = 30
    max_size_mb: int = 500
    log_level: str = "INFO"
    excluded_patterns: list[str] = field(default_factory=lambda: list(_DEFAULT_EXCLUDED_PATTERNS))
    workspace_path: str = ""

    def __post_init__(self) -> None:
        """Validate all fields after initialization."""
        _validate_retention_days(self.retention_days)
        _validate_max_size_mb(self.max_size_mb)


# ---------------------------------------------------------------------------
# Config loading
# ---------------------------------------------------------------------------


def load_config(workspace_path: str) -> MemoryConfig:
    """Load configuration from a .memoryrc YAML file with environment overrides.

    Configuration resolution order (later overrides earlier):
    1. Built-in defaults from MemoryConfig
    2. Values from .memoryrc YAML file in workspace_path (if it exists)
    3. Environment variable overrides:
       - MEMORY_RETENTION_DAYS -> retention_days
       - MEMORY_MAX_SIZE_MB -> max_size_mb
       - MEMORY_LOG_LEVEL -> log_level

    Args:
        workspace_path: Path to the workspace directory where .memoryrc is located.

    Returns:
        A validated MemoryConfig instance.

    Raises:
        ConfigValidationError: If any value is outside its valid range.
        ValueError: If environment variables contain non-numeric values for
            numeric fields.
    """
    config_values: dict[str, int | str | list[str]] = {}

    # Step 1: Load from .memoryrc YAML file if present
    memoryrc_path = Path(workspace_path) / ".memoryrc"
    if memoryrc_path.is_file():
        file_values = _parse_memoryrc(memoryrc_path)
        config_values.update(file_values)

    # Step 2: Apply environment variable overrides
    _apply_env_overrides(config_values)

    # Step 3: Build and return the validated config
    return MemoryConfig(workspace_path=workspace_path, **config_values)  # type: ignore[arg-type]


def _parse_memoryrc(path: Path) -> dict[str, int | str | list[str]]:
    """Parse a .memoryrc YAML file and return valid configuration keys.

    Args:
        path: Path to the .memoryrc file.

    Returns:
        Dictionary of configuration values found in the file.
    """
    content = path.read_text(encoding="utf-8")
    if not content.strip():
        return {}

    data = yaml.safe_load(content)
    if not isinstance(data, dict):
        return {}

    result: dict[str, int | str | list[str]] = {}
    valid_keys = {"retention_days", "max_size_mb", "log_level", "excluded_patterns"}

    for key in valid_keys:
        if key in data:
            result[key] = data[key]

    return result


def _apply_env_overrides(config_values: dict[str, int | str | list[str]]) -> None:
    """Apply environment variable overrides to configuration values.

    Reads MEMORY_RETENTION_DAYS, MEMORY_MAX_SIZE_MB, and MEMORY_LOG_LEVEL
    from the environment and overrides values in config_values in-place.

    Args:
        config_values: Mutable dict of config values to update.

    Raises:
        ValueError: If numeric environment variables contain non-numeric values.
    """
    env_retention = os.environ.get("MEMORY_RETENTION_DAYS")
    if env_retention is not None:
        try:
            config_values["retention_days"] = int(env_retention)
        except ValueError as exc:
            msg = f"MEMORY_RETENTION_DAYS must be a valid integer, got: {env_retention!r}"
            raise ValueError(msg) from exc

    env_max_size = os.environ.get("MEMORY_MAX_SIZE_MB")
    if env_max_size is not None:
        try:
            config_values["max_size_mb"] = int(env_max_size)
        except ValueError as exc:
            msg = f"MEMORY_MAX_SIZE_MB must be a valid integer, got: {env_max_size!r}"
            raise ValueError(msg) from exc

    env_log_level = os.environ.get("MEMORY_LOG_LEVEL")
    if env_log_level is not None:
        config_values["log_level"] = env_log_level
