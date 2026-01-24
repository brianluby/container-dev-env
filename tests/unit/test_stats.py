"""T056: Tests for get_memory_stats MCP tool.

Tests validate entry counts by type and tool, storage size calculation,
and empty database behavior.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from pathlib import Path
from unittest.mock import MagicMock

import pytest

from memory_server.config import MemoryConfig
from memory_server.server import get_memory_stats, init_server
from memory_server.storage import MemoryStorage

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def db_path(tmp_path: Path) -> Path:
    """Provide a temporary database file path."""
    return tmp_path / "test_stats.db"


@pytest.fixture
def storage(db_path: Path) -> MemoryStorage:
    """Create a MemoryStorage instance with a temporary database."""
    return MemoryStorage(str(db_path))


@pytest.fixture
def config() -> MemoryConfig:
    """Create a default test configuration."""
    return MemoryConfig(
        retention_days=30,
        max_size_mb=500,
        workspace_path="/tmp/test-workspace",
    )


@pytest.fixture
def project_id() -> str:
    """Consistent project ID for tests."""
    return "stats_test_12345"


@pytest.fixture(autouse=True)
def setup_server(
    storage: MemoryStorage,
    config: MemoryConfig,
    project_id: str,
) -> None:
    """Initialize server state before each test."""
    mock_embedding = MagicMock()
    mock_embedding.embed_text.return_value = [0.1] * 384
    init_server(
        storage=storage,
        embedding_service=mock_embedding,
        project_id=project_id,
        config=config,
    )


def _insert_entry(
    storage: MemoryStorage,
    project_id: str,
    entry_type: str = "observation",
    source_tool: str = "claude-code",
) -> str:
    """Helper to insert a test entry."""
    entry_id = str(uuid.uuid4())
    entry = {
        "id": entry_id,
        "project_id": project_id,
        "content": f"Stats test entry {entry_id[:8]}",
        "source_tool": source_tool,
        "session_id": "stats-session",
        "entry_type": entry_type,
        "tags": None,
        "created_at": datetime.now(tz=UTC).isoformat(),
        "accessed_at": None,
    }
    storage.insert_entry(entry)
    return entry_id


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


class TestGetMemoryStats:
    """Tests for the get_memory_stats tool."""

    @pytest.mark.asyncio
    async def test_entry_counts_by_type(self, storage: MemoryStorage, project_id: str) -> None:
        """entries_by_type accurately counts each entry type."""
        _insert_entry(storage, project_id, entry_type="decision")
        _insert_entry(storage, project_id, entry_type="decision")
        _insert_entry(storage, project_id, entry_type="pattern")
        _insert_entry(storage, project_id, entry_type="error")

        result = await get_memory_stats()
        assert result["entries_by_type"]["decision"] == 2
        assert result["entries_by_type"]["pattern"] == 1
        assert result["entries_by_type"]["error"] == 1

    @pytest.mark.asyncio
    async def test_entry_counts_by_tool(self, storage: MemoryStorage, project_id: str) -> None:
        """entries_by_tool accurately counts each source tool."""
        _insert_entry(storage, project_id, source_tool="claude-code")
        _insert_entry(storage, project_id, source_tool="claude-code")
        _insert_entry(storage, project_id, source_tool="opencode")

        result = await get_memory_stats()
        assert result["entries_by_tool"]["claude-code"] == 2
        assert result["entries_by_tool"]["opencode"] == 1

    @pytest.mark.asyncio
    async def test_storage_size_calculation(self, storage: MemoryStorage, project_id: str) -> None:
        """storage_size_mb returns a positive number for non-empty DB."""
        _insert_entry(storage, project_id)

        result = await get_memory_stats()
        assert result["storage_size_mb"] > 0
        assert isinstance(result["storage_size_mb"], float)

    @pytest.mark.asyncio
    async def test_empty_database_returns_zeros(self) -> None:
        """Empty database returns zero counts."""
        result = await get_memory_stats()
        assert result["total_entries"] == 0
        assert result["entries_by_type"] == {}
        assert result["entries_by_tool"] == {}

    @pytest.mark.asyncio
    async def test_project_id_in_stats(self, project_id: str) -> None:
        """Stats include the correct project_id."""
        result = await get_memory_stats()
        assert result["project_id"] == project_id

    @pytest.mark.asyncio
    async def test_total_entries_accurate(self, storage: MemoryStorage, project_id: str) -> None:
        """total_entries matches actual entry count."""
        for _ in range(5):
            _insert_entry(storage, project_id)

        result = await get_memory_stats()
        assert result["total_entries"] == 5

    @pytest.mark.asyncio
    async def test_oldest_newest_entry_timestamps(
        self, storage: MemoryStorage, project_id: str
    ) -> None:
        """oldest_entry and newest_entry are populated when entries exist."""
        _insert_entry(storage, project_id)

        result = await get_memory_stats()
        assert result["oldest_entry"] is not None
        assert result["newest_entry"] is not None

    @pytest.mark.asyncio
    async def test_retention_config_included(self, config: MemoryConfig) -> None:
        """retention_config includes retention_days and max_size_mb."""
        result = await get_memory_stats()
        assert result["retention_config"]["retention_days"] == 30
        assert result["retention_config"]["max_size_mb"] == 500
