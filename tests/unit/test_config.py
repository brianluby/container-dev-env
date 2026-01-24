"""T009: Tests for config parsing in memory_server.config.

Tests validate loading of .memoryrc YAML files, application of defaults,
and environment variable overrides for the memory server configuration.
"""

from __future__ import annotations

import os
from pathlib import Path
from unittest.mock import patch

import pytest

from memory_server.config import MemoryConfig, load_config

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def workspace_with_memoryrc(tmp_path: Path) -> Path:
    """Create a workspace directory with a .memoryrc YAML config file."""
    memoryrc = tmp_path / ".memoryrc"
    memoryrc.write_text("retention_days: 60\nmax_size_mb: 1000\nlog_level: DEBUG\n")
    return tmp_path


@pytest.fixture
def workspace_without_memoryrc(tmp_path: Path) -> Path:
    """Create a workspace directory without a .memoryrc file."""
    return tmp_path


@pytest.fixture
def workspace_with_partial_config(tmp_path: Path) -> Path:
    """Create a workspace with a .memoryrc that only sets some values."""
    memoryrc = tmp_path / ".memoryrc"
    memoryrc.write_text("retention_days: 90\n")
    return tmp_path


# ---------------------------------------------------------------------------
# MemoryConfig Class Tests
# ---------------------------------------------------------------------------


class TestMemoryConfig:
    """Tests for the MemoryConfig dataclass/model."""

    def test_default_retention_days(self) -> None:
        """Default retention_days is 30."""
        config = MemoryConfig()
        assert config.retention_days == 30

    def test_default_max_size_mb(self) -> None:
        """Default max_size_mb is 500."""
        config = MemoryConfig()
        assert config.max_size_mb == 500

    def test_default_log_level(self) -> None:
        """Default log_level is INFO."""
        config = MemoryConfig()
        assert config.log_level == "INFO"

    def test_custom_values(self) -> None:
        """MemoryConfig accepts custom values."""
        config = MemoryConfig(retention_days=90, max_size_mb=1500, log_level="DEBUG")
        assert config.retention_days == 90
        assert config.max_size_mb == 1500
        assert config.log_level == "DEBUG"

    def test_retention_days_min_validation(self) -> None:
        """retention_days must be >= 1."""
        with pytest.raises(Exception):
            MemoryConfig(retention_days=0)

    def test_retention_days_max_validation(self) -> None:
        """retention_days must be <= 365."""
        with pytest.raises(Exception):
            MemoryConfig(retention_days=400)

    def test_max_size_mb_min_validation(self) -> None:
        """max_size_mb must be >= 50."""
        with pytest.raises(Exception):
            MemoryConfig(max_size_mb=10)

    def test_max_size_mb_max_validation(self) -> None:
        """max_size_mb must be <= 2000."""
        with pytest.raises(Exception):
            MemoryConfig(max_size_mb=3000)


# ---------------------------------------------------------------------------
# load_config Function Tests
# ---------------------------------------------------------------------------


class TestLoadConfig:
    """Tests for the load_config function."""

    def test_loads_memoryrc_from_workspace(self, workspace_with_memoryrc: Path) -> None:
        """Loads configuration from .memoryrc YAML in the workspace."""
        config = load_config(str(workspace_with_memoryrc))
        assert config.retention_days == 60
        assert config.max_size_mb == 1000
        assert config.log_level == "DEBUG"

    def test_applies_defaults_when_file_missing(self, workspace_without_memoryrc: Path) -> None:
        """Returns default config when no .memoryrc file exists."""
        config = load_config(str(workspace_without_memoryrc))
        assert config.retention_days == 30
        assert config.max_size_mb == 500
        assert config.log_level == "INFO"

    def test_partial_config_uses_defaults_for_missing(
        self, workspace_with_partial_config: Path
    ) -> None:
        """Partially specified config uses defaults for unset fields."""
        config = load_config(str(workspace_with_partial_config))
        assert config.retention_days == 90  # from file
        assert config.max_size_mb == 500  # default
        assert config.log_level == "INFO"  # default

    def test_env_var_overrides_retention_days(self, workspace_with_memoryrc: Path) -> None:
        """MEMORY_RETENTION_DAYS env var overrides file and defaults."""
        with patch.dict(os.environ, {"MEMORY_RETENTION_DAYS": "180"}):
            config = load_config(str(workspace_with_memoryrc))
            assert config.retention_days == 180

    def test_env_var_overrides_max_size_mb(self, workspace_with_memoryrc: Path) -> None:
        """MEMORY_MAX_SIZE_MB env var overrides file and defaults."""
        with patch.dict(os.environ, {"MEMORY_MAX_SIZE_MB": "750"}):
            config = load_config(str(workspace_with_memoryrc))
            assert config.max_size_mb == 750

    def test_env_var_overrides_log_level(self, workspace_with_memoryrc: Path) -> None:
        """MEMORY_LOG_LEVEL env var overrides file and defaults."""
        with patch.dict(os.environ, {"MEMORY_LOG_LEVEL": "WARNING"}):
            config = load_config(str(workspace_with_memoryrc))
            assert config.log_level == "WARNING"

    def test_env_vars_override_defaults_when_no_file(
        self, workspace_without_memoryrc: Path
    ) -> None:
        """Env vars work even when no .memoryrc file exists."""
        with patch.dict(
            os.environ,
            {
                "MEMORY_RETENTION_DAYS": "45",
                "MEMORY_MAX_SIZE_MB": "800",
                "MEMORY_LOG_LEVEL": "ERROR",
            },
        ):
            config = load_config(str(workspace_without_memoryrc))
            assert config.retention_days == 45
            assert config.max_size_mb == 800
            assert config.log_level == "ERROR"

    def test_invalid_env_var_retention_days(self, workspace_without_memoryrc: Path) -> None:
        """Invalid MEMORY_RETENTION_DAYS env var raises validation error."""
        with patch.dict(os.environ, {"MEMORY_RETENTION_DAYS": "0"}):
            with pytest.raises(Exception):
                load_config(str(workspace_without_memoryrc))

    def test_env_var_non_numeric_retention_days(self, workspace_without_memoryrc: Path) -> None:
        """Non-numeric MEMORY_RETENTION_DAYS raises an error."""
        with patch.dict(os.environ, {"MEMORY_RETENTION_DAYS": "abc"}):
            with pytest.raises(Exception):
                load_config(str(workspace_without_memoryrc))

    def test_empty_memoryrc_uses_defaults(self, tmp_path: Path) -> None:
        """Empty .memoryrc file results in all defaults."""
        memoryrc = tmp_path / ".memoryrc"
        memoryrc.write_text("")
        config = load_config(str(tmp_path))
        assert config.retention_days == 30
        assert config.max_size_mb == 500
        assert config.log_level == "INFO"

    def test_workspace_path_stored(self, workspace_without_memoryrc: Path) -> None:
        """Config retains the workspace path it was loaded from."""
        config = load_config(str(workspace_without_memoryrc))
        assert config.workspace_path == str(workspace_without_memoryrc)
