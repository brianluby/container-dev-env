"""T044: Tests for the search_memories MCP tool.

Tests validate semantic search behavior including score ordering,
min_score filtering, entry_type filtering, and empty results.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from pathlib import Path
from unittest.mock import MagicMock

import pytest

from memory_server.config import MemoryConfig
from memory_server.server import init_server, search_memories
from memory_server.storage import MemoryStorage

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def db_path(tmp_path: Path) -> Path:
    """Provide a temporary database file path."""
    return tmp_path / "test_search.db"


@pytest.fixture
def storage(db_path: Path) -> MemoryStorage:
    """Create a MemoryStorage instance with a temporary database."""
    return MemoryStorage(str(db_path))


@pytest.fixture
def mock_embedding_service() -> MagicMock:
    """Create a mock embedding service with configurable behavior."""
    service = MagicMock()
    # Default: return a vector close to [0.5]*384
    service.embed_text.return_value = [0.5] * 384
    return service


@pytest.fixture
def config() -> MemoryConfig:
    """Create a default test configuration."""
    return MemoryConfig(workspace_path="/tmp/test-workspace")


@pytest.fixture
def project_id() -> str:
    """Consistent project ID for tests."""
    return "search_test_12345"


@pytest.fixture(autouse=True)
def setup_server(
    storage: MemoryStorage,
    mock_embedding_service: MagicMock,
    config: MemoryConfig,
    project_id: str,
) -> None:
    """Initialize server state before each test."""
    init_server(
        storage=storage,
        embedding_service=mock_embedding_service,
        project_id=project_id,
        config=config,
    )


def _insert_entry(
    storage: MemoryStorage,
    project_id: str,
    content: str = "Test content",
    entry_type: str = "observation",
    embedding: list[float] | None = None,
) -> str:
    """Helper to insert a test entry with embedding."""
    entry_id = str(uuid.uuid4())
    entry = {
        "id": entry_id,
        "project_id": project_id,
        "content": content,
        "source_tool": "claude-code",
        "session_id": "test-session",
        "entry_type": entry_type,
        "tags": None,
        "created_at": datetime.now(tz=UTC).isoformat(),
        "accessed_at": None,
    }
    storage.insert_entry(entry)
    if embedding is not None:
        storage.insert_embedding(entry_id, embedding)
    return entry_id


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


class TestSearchMemories:
    """Tests for the search_memories tool."""

    @pytest.mark.asyncio
    async def test_matching_query_returns_results(
        self, storage: MemoryStorage, project_id: str
    ) -> None:
        """Search with matching query returns results."""
        _insert_entry(storage, project_id, "Database optimization tips", embedding=[0.5] * 384)

        result = await search_memories(query="database optimization")
        assert result["total_matches"] > 0
        assert len(result["results"]) > 0

    @pytest.mark.asyncio
    async def test_score_ordering_highest_first(
        self, storage: MemoryStorage, project_id: str, mock_embedding_service: MagicMock
    ) -> None:
        """Results are ordered by score, highest first."""
        # Insert entries with different vectors
        _insert_entry(storage, project_id, "Close match", embedding=[0.5] * 384)
        _insert_entry(storage, project_id, "Far match", embedding=[0.1] * 384)

        result = await search_memories(query="test query")
        if len(result["results"]) >= 2:
            scores = [r["score"] for r in result["results"]]
            assert scores == sorted(scores, reverse=True)

    @pytest.mark.asyncio
    async def test_min_score_filtering(self, storage: MemoryStorage, project_id: str) -> None:
        """Results below min_score are filtered out."""
        # Insert an entry with a very different vector
        _insert_entry(storage, project_id, "Distant entry", embedding=[0.9] * 384)

        result = await search_memories(query="test", min_score=0.99)
        # With a very high min_score, distant entries should be filtered
        for r in result["results"]:
            assert r["score"] >= 0.99

    @pytest.mark.asyncio
    async def test_entry_type_filtering(self, storage: MemoryStorage, project_id: str) -> None:
        """Results can be filtered by entry_type."""
        _insert_entry(
            storage, project_id, "A decision", entry_type="decision", embedding=[0.5] * 384
        )
        _insert_entry(storage, project_id, "A pattern", entry_type="pattern", embedding=[0.5] * 384)

        result = await search_memories(query="test", entry_type="decision")
        for r in result["results"]:
            assert r["entry_type"] == "decision"

    @pytest.mark.asyncio
    async def test_empty_results_when_no_matches(
        self, storage: MemoryStorage, project_id: str
    ) -> None:
        """Empty database returns no results."""
        result = await search_memories(query="nonexistent topic", min_score=0.99)
        assert result["total_matches"] == 0
        assert result["results"] == []

    @pytest.mark.asyncio
    async def test_limit_respected(self, storage: MemoryStorage, project_id: str) -> None:
        """Limit parameter caps the number of results."""
        for i in range(10):
            _insert_entry(storage, project_id, f"Entry {i}", embedding=[0.5] * 384)

        result = await search_memories(query="entry", limit=3)
        assert len(result["results"]) <= 3

    @pytest.mark.asyncio
    async def test_no_embedding_service_returns_empty(
        self, storage: MemoryStorage, config: MemoryConfig, project_id: str
    ) -> None:
        """Without embedding service, search returns empty results."""
        init_server(
            storage=storage,
            embedding_service=None,
            project_id=project_id,
            config=config,
        )
        result = await search_memories(query="test")
        assert result["results"] == []
        assert result["total_matches"] == 0
