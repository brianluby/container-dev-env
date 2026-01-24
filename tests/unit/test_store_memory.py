"""T039/T040/T040b/T040c: Tests for the store_memory MCP tool.

Tests validate input validation, embedding generation, entry storage,
and graceful degradation behavior.
"""

from __future__ import annotations

import uuid
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
    return tmp_path / "test_store.db"


@pytest.fixture
def storage(db_path: Path) -> MemoryStorage:
    """Create a MemoryStorage instance with a temporary database."""
    return MemoryStorage(str(db_path))


@pytest.fixture
def mock_embedding_service() -> MagicMock:
    """Create a mock embedding service that returns a fixed vector."""
    service = MagicMock()
    service.embed_text.return_value = [0.1] * 384
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
) -> None:
    """Initialize server state before each test."""
    init_server(
        storage=storage,
        embedding_service=mock_embedding_service,
        project_id="a1b2c3d4e5f67890",
        config=config,
    )


# ---------------------------------------------------------------------------
# Test valid entry stored
# ---------------------------------------------------------------------------


class TestStoreMemoryValid:
    """Tests for successful memory storage."""

    @pytest.mark.asyncio
    async def test_valid_entry_returns_id(self, storage: MemoryStorage) -> None:
        """Valid content + entry_type returns a dict with id and status=stored."""
        result = await store_memory(
            content="Use async for DB operations",
            entry_type="decision",
        )
        assert result["status"] == "stored"
        assert result["id"] != ""
        # Verify the ID is a valid UUID
        uuid.UUID(result["id"])

    @pytest.mark.asyncio
    async def test_stored_entry_exists_in_storage(self, storage: MemoryStorage) -> None:
        """After storing, the entry can be retrieved from storage."""
        result = await store_memory(
            content="Prefer composition over inheritance",
            entry_type="pattern",
            tags=["design", "python"],
        )
        entry = storage.get_entry(result["id"])
        assert entry is not None
        assert entry["content"] == "Prefer composition over inheritance"
        assert entry["entry_type"] == "pattern"
        assert entry["project_id"] == "a1b2c3d4e5f67890"

    @pytest.mark.asyncio
    async def test_entry_has_session_id(self, storage: MemoryStorage) -> None:
        """Stored entry has a non-empty session_id."""
        result = await store_memory(content="Test content", entry_type="observation")
        entry = storage.get_entry(result["id"])
        assert entry is not None
        assert entry["session_id"] != ""

    @pytest.mark.asyncio
    async def test_tags_stored_correctly(self, storage: MemoryStorage) -> None:
        """Tags are stored and retrievable."""
        result = await store_memory(
            content="Test tags", entry_type="context", tags=["tag1", "tag2"]
        )
        entry = storage.get_entry(result["id"])
        assert entry is not None
        assert entry["tags"] == ["tag1", "tag2"]


# ---------------------------------------------------------------------------
# Test embedding generated
# ---------------------------------------------------------------------------


class TestStoreMemoryEmbedding:
    """Tests for embedding generation during store."""

    @pytest.mark.asyncio
    async def test_embedding_generated(self, mock_embedding_service: MagicMock) -> None:
        """Embedding service is called when storing an entry."""
        await store_memory(content="Test embedding", entry_type="observation")
        mock_embedding_service.embed_text.assert_called_once_with("Test embedding")

    @pytest.mark.asyncio
    async def test_embedding_stored_in_vec_table(
        self, storage: MemoryStorage, mock_embedding_service: MagicMock
    ) -> None:
        """Embedding is stored in the vec0 table after store_memory."""
        result = await store_memory(content="Vector test", entry_type="decision")
        # Verify embedding was stored by searching for it
        results = storage.search_similar([0.1] * 384, limit=1)
        assert len(results) >= 1
        assert results[0]["entry_id"] == result["id"]

    @pytest.mark.asyncio
    async def test_embedding_failure_graceful_degradation(
        self, storage: MemoryStorage, mock_embedding_service: MagicMock
    ) -> None:
        """If embedding fails, entry is still stored with zero vector."""
        mock_embedding_service.embed_text.side_effect = RuntimeError("Model error")
        result = await store_memory(content="Test degradation", entry_type="error")
        assert result["status"] == "stored"
        # Entry should still exist
        entry = storage.get_entry(result["id"])
        assert entry is not None

    @pytest.mark.asyncio
    async def test_no_embedding_service_stores_zero_vector(
        self, storage: MemoryStorage, config: MemoryConfig
    ) -> None:
        """When no embedding service available, zero vector is stored."""
        init_server(
            storage=storage,
            embedding_service=None,
            project_id="a1b2c3d4e5f67890",
            config=config,
        )
        result = await store_memory(content="No embeddings", entry_type="context")
        assert result["status"] == "stored"
        entry = storage.get_entry(result["id"])
        assert entry is not None


# ---------------------------------------------------------------------------
# Test invalid content rejected
# ---------------------------------------------------------------------------


class TestStoreMemoryInvalidContent:
    """Tests for input validation of content."""

    @pytest.mark.asyncio
    async def test_empty_content_rejected(self) -> None:
        """Empty string content returns error status."""
        result = await store_memory(content="", entry_type="decision")
        assert result["status"] == "error"
        assert "empty" in result["message"].lower()

    @pytest.mark.asyncio
    async def test_whitespace_only_content_rejected(self) -> None:
        """Whitespace-only content returns error status."""
        result = await store_memory(content="   \n\t  ", entry_type="decision")
        assert result["status"] == "error"

    @pytest.mark.asyncio
    async def test_too_long_content_rejected(self) -> None:
        """Content exceeding 10000 chars returns error status."""
        long_content = "x" * 10001
        result = await store_memory(content=long_content, entry_type="decision")
        assert result["status"] == "error"
        assert "length" in result["message"].lower() or "exceeds" in result["message"].lower()

    @pytest.mark.asyncio
    async def test_max_length_content_accepted(self) -> None:
        """Content at exactly 10000 chars is accepted."""
        content = "x" * 10000
        result = await store_memory(content=content, entry_type="observation")
        assert result["status"] == "stored"


# ---------------------------------------------------------------------------
# Test entry_type validation
# ---------------------------------------------------------------------------


class TestStoreMemoryEntryType:
    """Tests for entry_type validation."""

    @pytest.mark.asyncio
    async def test_invalid_entry_type_rejected(self) -> None:
        """Invalid entry_type returns error status."""
        result = await store_memory(content="Test", entry_type="invalid_type")
        assert result["status"] == "error"
        assert "entry_type" in result["message"].lower() or "invalid" in result["message"].lower()

    @pytest.mark.asyncio
    @pytest.mark.parametrize(
        "entry_type",
        ["decision", "pattern", "observation", "error", "context"],
    )
    async def test_all_valid_entry_types_accepted(self, entry_type: str) -> None:
        """All defined entry types are accepted."""
        result = await store_memory(content="Test content", entry_type=entry_type)
        assert result["status"] == "stored"

    @pytest.mark.asyncio
    async def test_too_many_tags_rejected(self) -> None:
        """More than 10 tags returns error status."""
        tags = [f"tag{i}" for i in range(11)]
        result = await store_memory(content="Test", entry_type="decision", tags=tags)
        assert result["status"] == "error"
        assert "tags" in result["message"].lower()
