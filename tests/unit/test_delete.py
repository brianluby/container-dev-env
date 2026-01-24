"""T057: Tests for the delete_memory MCP tool.

Tests validate successful deletion, not_found for unknown IDs,
and that embeddings are also removed from the vec0 table.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from pathlib import Path
from unittest.mock import MagicMock

import pytest

from memory_server.config import MemoryConfig
from memory_server.server import delete_memory, init_server
from memory_server.storage import MemoryStorage

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def db_path(tmp_path: Path) -> Path:
    """Provide a temporary database file path."""
    return tmp_path / "test_delete.db"


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
    return "delete_test_1234"


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


def _insert_entry_with_embedding(
    storage: MemoryStorage,
    project_id: str,
) -> str:
    """Helper to insert a test entry with an embedding."""
    entry_id = str(uuid.uuid4())
    entry = {
        "id": entry_id,
        "project_id": project_id,
        "content": f"Delete test entry {entry_id[:8]}",
        "source_tool": "claude-code",
        "session_id": "delete-session",
        "entry_type": "observation",
        "tags": None,
        "created_at": datetime.now(tz=UTC).isoformat(),
        "accessed_at": None,
    }
    storage.insert_entry(entry)
    storage.insert_embedding(entry_id, [0.5] * 384)
    return entry_id


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


class TestDeleteMemory:
    """Tests for the delete_memory tool."""

    @pytest.mark.asyncio
    async def test_existing_entry_deleted_successfully(
        self, storage: MemoryStorage, project_id: str
    ) -> None:
        """Deleting an existing entry returns status=deleted."""
        entry_id = _insert_entry_with_embedding(storage, project_id)

        result = await delete_memory(entry_id)
        assert result["status"] == "deleted"
        assert entry_id in result["message"]

        # Entry should no longer exist
        assert storage.get_entry(entry_id) is None

    @pytest.mark.asyncio
    async def test_not_found_for_unknown_id(self) -> None:
        """Deleting a non-existent ID returns status=not_found."""
        fake_id = str(uuid.uuid4())
        result = await delete_memory(fake_id)
        assert result["status"] == "not_found"

    @pytest.mark.asyncio
    async def test_embedding_also_removed(self, storage: MemoryStorage, project_id: str) -> None:
        """Embedding is removed from vec0 table when entry is deleted."""
        entry_id = _insert_entry_with_embedding(storage, project_id)

        # Verify embedding exists before delete
        results_before = storage.search_similar([0.5] * 384, limit=10)
        entry_ids_before = [r["entry_id"] for r in results_before]
        assert entry_id in entry_ids_before

        # Delete the entry
        await delete_memory(entry_id)

        # Verify embedding is gone
        results_after = storage.search_similar([0.5] * 384, limit=10)
        entry_ids_after = [r["entry_id"] for r in results_after]
        assert entry_id not in entry_ids_after

    @pytest.mark.asyncio
    async def test_storage_unavailable_returns_error(
        self, config: MemoryConfig, project_id: str
    ) -> None:
        """When storage is unavailable, returns error status."""
        init_server(
            storage=None,  # type: ignore[arg-type]
            embedding_service=None,
            project_id=project_id,
            config=config,
        )
        result = await delete_memory(str(uuid.uuid4()))
        assert result["status"] == "error"

    @pytest.mark.asyncio
    async def test_delete_does_not_affect_other_entries(
        self, storage: MemoryStorage, project_id: str
    ) -> None:
        """Deleting one entry does not affect other entries."""
        entry_id_1 = _insert_entry_with_embedding(storage, project_id)
        entry_id_2 = _insert_entry_with_embedding(storage, project_id)

        await delete_memory(entry_id_1)

        # Entry 2 should still exist
        assert storage.get_entry(entry_id_2) is not None
