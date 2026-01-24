"""T007: Tests for Pydantic models in memory_server.models.

Tests validate construction, field constraints, defaults, and serialization
for MemoryEntry, ProjectConfig, MemoryStats, and SearchResult models.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

import pytest

from memory_server.models import (
    MemoryEntry,
    MemoryStats,
    ProjectConfig,
    SearchResult,
)

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def valid_project_id() -> str:
    """A valid 16-character hex project ID."""
    return "a1b2c3d4e5f67890"


@pytest.fixture
def valid_memory_entry_data(valid_project_id: str) -> dict:
    """Minimal valid data for constructing a MemoryEntry."""
    return {
        "id": str(uuid.uuid4()),
        "project_id": valid_project_id,
        "content": "Decided to use FastAPI for the REST layer.",
        "source_tool": "claude-code",
        "session_id": "sess-001",
        "entry_type": "decision",
        "created_at": datetime.now(tz=UTC).isoformat(),
    }


@pytest.fixture
def valid_project_config_data(valid_project_id: str) -> dict:
    """Minimal valid data for constructing a ProjectConfig."""
    return {
        "project_id": valid_project_id,
        "workspace_path": "/home/user/projects/my-app",
        "created_at": datetime.now(tz=UTC).isoformat(),
    }


# ---------------------------------------------------------------------------
# MemoryEntry Tests
# ---------------------------------------------------------------------------


class TestMemoryEntry:
    """Tests for the MemoryEntry Pydantic model."""

    def test_valid_construction(self, valid_memory_entry_data: dict) -> None:
        """MemoryEntry can be constructed with all required fields."""
        entry = MemoryEntry(**valid_memory_entry_data)
        assert entry.project_id == valid_memory_entry_data["project_id"]
        assert entry.content == valid_memory_entry_data["content"]
        assert entry.source_tool == "claude-code"
        assert entry.entry_type == "decision"

    def test_id_must_be_valid_uuid(self, valid_memory_entry_data: dict) -> None:
        """The id field must be a valid UUID string."""
        valid_memory_entry_data["id"] = "not-a-uuid"
        with pytest.raises(Exception):  # ValidationError
            MemoryEntry(**valid_memory_entry_data)

    def test_project_id_must_be_16_hex_chars(self, valid_memory_entry_data: dict) -> None:
        """project_id must be exactly 16 hexadecimal characters."""
        valid_memory_entry_data["project_id"] = "short"
        with pytest.raises(Exception):
            MemoryEntry(**valid_memory_entry_data)

        valid_memory_entry_data["project_id"] = "a" * 17  # too long
        with pytest.raises(Exception):
            MemoryEntry(**valid_memory_entry_data)

        valid_memory_entry_data["project_id"] = "ghijklmnopqrstuv"  # non-hex
        with pytest.raises(Exception):
            MemoryEntry(**valid_memory_entry_data)

    def test_content_min_length(self, valid_memory_entry_data: dict) -> None:
        """Content must be at least 1 character."""
        valid_memory_entry_data["content"] = ""
        with pytest.raises(Exception):
            MemoryEntry(**valid_memory_entry_data)

    def test_content_max_length(self, valid_memory_entry_data: dict) -> None:
        """Content must not exceed 10000 characters."""
        valid_memory_entry_data["content"] = "x" * 10001
        with pytest.raises(Exception):
            MemoryEntry(**valid_memory_entry_data)

    def test_content_at_max_length(self, valid_memory_entry_data: dict) -> None:
        """Content at exactly 10000 characters is valid."""
        valid_memory_entry_data["content"] = "x" * 10000
        entry = MemoryEntry(**valid_memory_entry_data)
        assert len(entry.content) == 10000

    def test_source_tool_valid_values(self, valid_memory_entry_data: dict) -> None:
        """source_tool accepts all defined enum values."""
        valid_tools = ["claude-code", "cline", "continue", "opencode", "unknown"]
        for tool in valid_tools:
            valid_memory_entry_data["source_tool"] = tool
            entry = MemoryEntry(**valid_memory_entry_data)
            assert entry.source_tool == tool

    def test_source_tool_invalid_value(self, valid_memory_entry_data: dict) -> None:
        """source_tool rejects values not in the enum."""
        valid_memory_entry_data["source_tool"] = "copilot"
        with pytest.raises(Exception):
            MemoryEntry(**valid_memory_entry_data)

    def test_entry_type_valid_values(self, valid_memory_entry_data: dict) -> None:
        """entry_type accepts all defined enum values."""
        valid_types = ["decision", "pattern", "observation", "error", "context"]
        for entry_type in valid_types:
            valid_memory_entry_data["entry_type"] = entry_type
            entry = MemoryEntry(**valid_memory_entry_data)
            assert entry.entry_type == entry_type

    def test_entry_type_invalid_value(self, valid_memory_entry_data: dict) -> None:
        """entry_type rejects values not in the enum."""
        valid_memory_entry_data["entry_type"] = "todo"
        with pytest.raises(Exception):
            MemoryEntry(**valid_memory_entry_data)

    def test_tags_optional_defaults_none(self, valid_memory_entry_data: dict) -> None:
        """tags defaults to None when not provided."""
        entry = MemoryEntry(**valid_memory_entry_data)
        assert entry.tags is None

    def test_tags_accepts_list(self, valid_memory_entry_data: dict) -> None:
        """tags accepts a JSON list of strings."""
        valid_memory_entry_data["tags"] = ["architecture", "fastapi"]
        entry = MemoryEntry(**valid_memory_entry_data)
        assert entry.tags == ["architecture", "fastapi"]

    def test_accessed_at_optional(self, valid_memory_entry_data: dict) -> None:
        """accessed_at is optional and defaults to None."""
        entry = MemoryEntry(**valid_memory_entry_data)
        assert entry.accessed_at is None

    def test_accessed_at_accepts_iso8601(self, valid_memory_entry_data: dict) -> None:
        """accessed_at accepts an ISO8601 datetime string."""
        now = datetime.now(tz=UTC).isoformat()
        valid_memory_entry_data["accessed_at"] = now
        entry = MemoryEntry(**valid_memory_entry_data)
        assert entry.accessed_at is not None

    def test_created_at_must_be_iso8601(self, valid_memory_entry_data: dict) -> None:
        """created_at must be a valid ISO8601 datetime string."""
        valid_memory_entry_data["created_at"] = "not-a-date"
        with pytest.raises(Exception):
            MemoryEntry(**valid_memory_entry_data)


# ---------------------------------------------------------------------------
# ProjectConfig Tests
# ---------------------------------------------------------------------------


class TestProjectConfig:
    """Tests for the ProjectConfig Pydantic model."""

    def test_valid_construction(self, valid_project_config_data: dict) -> None:
        """ProjectConfig can be constructed with required fields and defaults."""
        config = ProjectConfig(**valid_project_config_data)
        assert config.project_id == valid_project_config_data["project_id"]
        assert config.workspace_path == valid_project_config_data["workspace_path"]

    def test_retention_days_default(self, valid_project_config_data: dict) -> None:
        """retention_days defaults to 30."""
        config = ProjectConfig(**valid_project_config_data)
        assert config.retention_days == 30

    def test_retention_days_min(self, valid_project_config_data: dict) -> None:
        """retention_days must be >= 1."""
        valid_project_config_data["retention_days"] = 0
        with pytest.raises(Exception):
            ProjectConfig(**valid_project_config_data)

    def test_retention_days_max(self, valid_project_config_data: dict) -> None:
        """retention_days must be <= 365."""
        valid_project_config_data["retention_days"] = 366
        with pytest.raises(Exception):
            ProjectConfig(**valid_project_config_data)

    def test_retention_days_valid_range(self, valid_project_config_data: dict) -> None:
        """retention_days within range is accepted."""
        for days in [1, 30, 180, 365]:
            valid_project_config_data["retention_days"] = days
            config = ProjectConfig(**valid_project_config_data)
            assert config.retention_days == days

    def test_max_size_mb_default(self, valid_project_config_data: dict) -> None:
        """max_size_mb defaults to 500."""
        config = ProjectConfig(**valid_project_config_data)
        assert config.max_size_mb == 500

    def test_max_size_mb_min(self, valid_project_config_data: dict) -> None:
        """max_size_mb must be >= 50."""
        valid_project_config_data["max_size_mb"] = 49
        with pytest.raises(Exception):
            ProjectConfig(**valid_project_config_data)

    def test_max_size_mb_max(self, valid_project_config_data: dict) -> None:
        """max_size_mb must be <= 2000."""
        valid_project_config_data["max_size_mb"] = 2001
        with pytest.raises(Exception):
            ProjectConfig(**valid_project_config_data)

    def test_workspace_path_must_be_absolute(self, valid_project_config_data: dict) -> None:
        """workspace_path must be an absolute path."""
        valid_project_config_data["workspace_path"] = "relative/path"
        with pytest.raises(Exception):
            ProjectConfig(**valid_project_config_data)

    def test_last_pruned_at_optional(self, valid_project_config_data: dict) -> None:
        """last_pruned_at defaults to None."""
        config = ProjectConfig(**valid_project_config_data)
        assert config.last_pruned_at is None

    def test_project_id_must_be_16_hex(self, valid_project_config_data: dict) -> None:
        """project_id must be exactly 16 hexadecimal characters."""
        valid_project_config_data["project_id"] = "abc"
        with pytest.raises(Exception):
            ProjectConfig(**valid_project_config_data)


# ---------------------------------------------------------------------------
# MemoryStats Tests
# ---------------------------------------------------------------------------


class TestMemoryStats:
    """Tests for the MemoryStats Pydantic model."""

    def test_valid_construction(self, valid_project_id: str) -> None:
        """MemoryStats can be constructed with required fields."""
        stats = MemoryStats(
            project_id=valid_project_id,
            total_entries=42,
            storage_size_bytes=1024000,
            entries_by_type={"decision": 10, "pattern": 32},
            entries_by_tool={"claude-code": 42},
        )
        assert stats.total_entries == 42
        assert stats.storage_size_bytes == 1024000

    def test_oldest_newest_optional(self, valid_project_id: str) -> None:
        """oldest_entry and newest_entry default to None."""
        stats = MemoryStats(
            project_id=valid_project_id,
            total_entries=0,
            storage_size_bytes=0,
            entries_by_type={},
            entries_by_tool={},
        )
        assert stats.oldest_entry is None
        assert stats.newest_entry is None

    def test_entries_by_type_is_dict(self, valid_project_id: str) -> None:
        """entries_by_type must be a dict."""
        stats = MemoryStats(
            project_id=valid_project_id,
            total_entries=5,
            storage_size_bytes=500,
            entries_by_type={"decision": 3, "error": 2},
            entries_by_tool={"cline": 5},
        )
        assert isinstance(stats.entries_by_type, dict)
        assert stats.entries_by_type["decision"] == 3

    def test_entries_by_tool_is_dict(self, valid_project_id: str) -> None:
        """entries_by_tool must be a dict."""
        stats = MemoryStats(
            project_id=valid_project_id,
            total_entries=10,
            storage_size_bytes=2048,
            entries_by_type={"observation": 10},
            entries_by_tool={"opencode": 6, "continue": 4},
        )
        assert stats.entries_by_tool["opencode"] == 6
        assert stats.entries_by_tool["continue"] == 4

    def test_total_entries_non_negative(self, valid_project_id: str) -> None:
        """total_entries must be non-negative."""
        with pytest.raises(Exception):
            MemoryStats(
                project_id=valid_project_id,
                total_entries=-1,
                storage_size_bytes=0,
                entries_by_type={},
                entries_by_tool={},
            )

    def test_storage_size_bytes_non_negative(self, valid_project_id: str) -> None:
        """storage_size_bytes must be non-negative."""
        with pytest.raises(Exception):
            MemoryStats(
                project_id=valid_project_id,
                total_entries=0,
                storage_size_bytes=-100,
                entries_by_type={},
                entries_by_tool={},
            )


# ---------------------------------------------------------------------------
# SearchResult Tests
# ---------------------------------------------------------------------------


class TestSearchResult:
    """Tests for the SearchResult Pydantic model."""

    def test_valid_construction(self) -> None:
        """SearchResult can be constructed with required fields."""
        result = SearchResult(
            id=str(uuid.uuid4()),
            content="Use dependency injection for services.",
            entry_type="pattern",
            score=0.85,
            source_tool="claude-code",
            created_at=datetime.now(tz=UTC).isoformat(),
        )
        assert result.score == 0.85
        assert result.entry_type == "pattern"

    def test_score_min_boundary(self) -> None:
        """score must be >= 0.0."""
        with pytest.raises(Exception):
            SearchResult(
                id=str(uuid.uuid4()),
                content="test content",
                entry_type="decision",
                score=-0.1,
                source_tool="cline",
                created_at=datetime.now(tz=UTC).isoformat(),
            )

    def test_score_max_boundary(self) -> None:
        """score must be <= 1.0."""
        with pytest.raises(Exception):
            SearchResult(
                id=str(uuid.uuid4()),
                content="test content",
                entry_type="decision",
                score=1.1,
                source_tool="cline",
                created_at=datetime.now(tz=UTC).isoformat(),
            )

    def test_score_at_boundaries(self) -> None:
        """score at 0.0 and 1.0 are both valid."""
        for score in [0.0, 1.0]:
            result = SearchResult(
                id=str(uuid.uuid4()),
                content="boundary test",
                entry_type="observation",
                score=score,
                source_tool="opencode",
                created_at=datetime.now(tz=UTC).isoformat(),
            )
            assert result.score == score

    def test_tags_optional(self) -> None:
        """tags defaults to None when not provided."""
        result = SearchResult(
            id=str(uuid.uuid4()),
            content="no tags here",
            entry_type="context",
            score=0.5,
            source_tool="unknown",
            created_at=datetime.now(tz=UTC).isoformat(),
        )
        assert result.tags is None

    def test_tags_accepts_list(self) -> None:
        """tags accepts a list of strings."""
        result = SearchResult(
            id=str(uuid.uuid4()),
            content="tagged content",
            entry_type="error",
            score=0.7,
            source_tool="continue",
            created_at=datetime.now(tz=UTC).isoformat(),
            tags=["python", "async"],
        )
        assert result.tags == ["python", "async"]
