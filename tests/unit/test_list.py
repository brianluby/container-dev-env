"""T045: Tests for the list_memories MCP tool.

Tests validate chronological ordering, pagination, type filtering,
and empty database behavior.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from pathlib import Path
from unittest.mock import MagicMock

import pytest

from memory_server.config import MemoryConfig
from memory_server.server import init_server, list_memories
from memory_server.storage import MemoryStorage

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def db_path(tmp_path: Path) -> Path:
    """Provide a temporary database file path."""
    return tmp_path / "test_list.db"


@pytest.fixture
def storage(db_path: Path) -> MemoryStorage:
    """Create a MemoryStorage instance with a temporary database."""
    return MemoryStorage(str(db_path))


@pytest.fixture
def config() -> MemoryConfig:
    """Create a default test configuration."""
    return MemoryConfig(workspace_path="/tmp/test-workspace")


@pytest.fixture
def project_id() -> str:
    """Consistent project ID for tests."""
    return "list_test_1234567"


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
    content: str = "Test content",
    entry_type: str = "observation",
    created_at: str | None = None,
) -> str:
    """Helper to insert a test entry."""
    entry_id = str(uuid.uuid4())
    entry = {
        "id": entry_id,
        "project_id": project_id,
        "content": content,
        "source_tool": "claude-code",
        "session_id": "test-session",
        "entry_type": entry_type,
        "tags": None,
        "created_at": created_at or datetime.now(tz=UTC).isoformat(),
        "accessed_at": None,
    }
    storage.insert_entry(entry)
    return entry_id


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


class TestListMemories:
    """Tests for the list_memories tool."""

    @pytest.mark.asyncio
    async def test_chronological_order_newest_first(
        self, storage: MemoryStorage, project_id: str
    ) -> None:
        """Entries are returned in reverse chronological order (newest first)."""
        now = datetime.now(tz=UTC)
        _insert_entry(
            storage, project_id, "Old entry", created_at=(now - timedelta(hours=2)).isoformat()
        )
        _insert_entry(
            storage, project_id, "New entry", created_at=(now - timedelta(hours=1)).isoformat()
        )
        _insert_entry(storage, project_id, "Newest entry", created_at=now.isoformat())

        result = await list_memories(limit=10)
        entries = result["entries"]
        assert len(entries) == 3
        assert entries[0]["content"] == "Newest entry"
        assert entries[2]["content"] == "Old entry"

    @pytest.mark.asyncio
    async def test_pagination_with_offset_limit(
        self, storage: MemoryStorage, project_id: str
    ) -> None:
        """Pagination works with offset and limit."""
        now = datetime.now(tz=UTC)
        for i in range(5):
            _insert_entry(
                storage,
                project_id,
                f"Entry {i}",
                created_at=(now - timedelta(minutes=5 - i)).isoformat(),
            )

        # Get page 1 (first 2 entries)
        page1 = await list_memories(limit=2, offset=0)
        assert len(page1["entries"]) == 2
        assert page1["total_count"] == 5
        assert page1["has_more"] is True

        # Get page 2 (next 2 entries)
        page2 = await list_memories(limit=2, offset=2)
        assert len(page2["entries"]) == 2
        assert page2["has_more"] is True

        # Get page 3 (last entry)
        page3 = await list_memories(limit=2, offset=4)
        assert len(page3["entries"]) == 1
        assert page3["has_more"] is False

    @pytest.mark.asyncio
    async def test_type_filtering(self, storage: MemoryStorage, project_id: str) -> None:
        """Entries can be filtered by entry_type."""
        _insert_entry(storage, project_id, "Decision 1", entry_type="decision")
        _insert_entry(storage, project_id, "Pattern 1", entry_type="pattern")
        _insert_entry(storage, project_id, "Decision 2", entry_type="decision")

        result = await list_memories(entry_type="decision")
        assert result["total_count"] == 2
        for entry in result["entries"]:
            assert entry["entry_type"] == "decision"

    @pytest.mark.asyncio
    async def test_empty_database(self) -> None:
        """Empty database returns empty results with correct structure."""
        result = await list_memories()
        assert result["entries"] == []
        assert result["total_count"] == 0
        assert result["has_more"] is False

    @pytest.mark.asyncio
    async def test_limit_clamped_to_valid_range(
        self, storage: MemoryStorage, project_id: str
    ) -> None:
        """Limit is clamped to 1-100 range."""
        for i in range(5):
            _insert_entry(storage, project_id, f"Entry {i}")

        # Limit of 0 should be treated as 1
        result = await list_memories(limit=0)
        assert len(result["entries"]) >= 1

    @pytest.mark.asyncio
    async def test_has_more_accurate(self, storage: MemoryStorage, project_id: str) -> None:
        """has_more flag is accurate based on total count vs offset+limit."""
        for i in range(3):
            _insert_entry(storage, project_id, f"Entry {i}")

        result = await list_memories(limit=3, offset=0)
        assert result["has_more"] is False

        result = await list_memories(limit=2, offset=0)
        assert result["has_more"] is True
