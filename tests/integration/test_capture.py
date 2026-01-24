"""T039/T040: Integration tests for store_memory via MCP tool.

Tests verify that stored entries end up in the SQLite database with
correct fields, and that embeddings are stored in the vec0 table.
"""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

import pytest

from memory_server.config import MemoryConfig
from memory_server.server import init_server, store_memory
from memory_server.storage import MemoryStorage

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def db_path(tmp_path: Path) -> Path:
    """Provide a temporary database file path."""
    return tmp_path / "test_capture.db"


@pytest.fixture
def storage(db_path: Path) -> MemoryStorage:
    """Create a MemoryStorage instance with a temporary database."""
    return MemoryStorage(str(db_path))


@pytest.fixture
def mock_embedding_service() -> MagicMock:
    """Create a mock embedding service that returns a fixed vector."""
    service = MagicMock()
    service.embed_text.return_value = [0.5] * 384
    return service


@pytest.fixture
def config() -> MemoryConfig:
    """Create a default test configuration."""
    return MemoryConfig(workspace_path="/tmp/test-workspace")


@pytest.fixture(autouse=True)
def setup_server(
    storage: MemoryStorage,
    mock_embedding_service: MagicMock,
    config: MemoryConfig,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Initialize server state before each test."""
    monkeypatch.setenv("MEMORY_SOURCE_TOOL", "claude-code")
    init_server(
        storage=storage,
        embedding_service=mock_embedding_service,
        project_id="abcdef0123456789",
        config=config,
    )


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestStoreViaMcp:
    """Test store_memory stores entries correctly in SQLite."""

    @pytest.mark.asyncio
    async def test_store_and_verify_in_sqlite(self, storage: MemoryStorage) -> None:
        """Stored entry appears in SQLite with correct fields."""
        result = await store_memory(
            content="Always validate input before processing",
            entry_type="decision",
            tags=["security", "validation"],
        )
        assert result["status"] == "stored"

        entry = storage.get_entry(result["id"])
        assert entry is not None
        assert entry["content"] == "Always validate input before processing"
        assert entry["entry_type"] == "decision"
        assert entry["project_id"] == "abcdef0123456789"
        assert entry["tags"] == ["security", "validation"]
        assert entry["created_at"] is not None
        assert entry["session_id"] != ""

    @pytest.mark.asyncio
    async def test_embedding_stored_in_vec0(
        self, storage: MemoryStorage, mock_embedding_service: MagicMock
    ) -> None:
        """Embedding is stored in the vec0 table after storing an entry."""
        result = await store_memory(
            content="Use vector search for semantic matching",
            entry_type="pattern",
        )
        # Search should find the entry
        results = storage.search_similar([0.5] * 384, limit=1)
        assert len(results) >= 1
        assert results[0]["entry_id"] == result["id"]

    @pytest.mark.asyncio
    async def test_entry_has_correct_source_tool(self, storage: MemoryStorage) -> None:
        """Entry has the source_tool from environment variable."""
        result = await store_memory(
            content="Test source tool",
            entry_type="observation",
        )
        entry = storage.get_entry(result["id"])
        assert entry is not None
        assert entry["source_tool"] == "claude-code"

    @pytest.mark.asyncio
    async def test_entry_has_correct_project_id(self, storage: MemoryStorage) -> None:
        """Entry has the configured project_id."""
        result = await store_memory(
            content="Test project id",
            entry_type="context",
        )
        entry = storage.get_entry(result["id"])
        assert entry is not None
        assert entry["project_id"] == "abcdef0123456789"

    @pytest.mark.asyncio
    async def test_entry_has_session_id(self, storage: MemoryStorage) -> None:
        """Entry has a session_id that is a valid UUID."""
        import uuid

        result = await store_memory(content="Test session", entry_type="decision")
        entry = storage.get_entry(result["id"])
        assert entry is not None
        # session_id should be a valid UUID
        uuid.UUID(entry["session_id"])
