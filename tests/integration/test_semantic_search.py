"""T046: Integration tests for semantic search.

Tests store entries with different topics, query with different wording,
and verify correct ranking and score ranges.

Note: These tests use a mock embedding service since the real FastEmbed
model is too heavy for unit test runs. The semantic relevance is
simulated through vector similarity.
"""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

import pytest

from memory_server.config import MemoryConfig
from memory_server.server import init_server, search_memories, store_memory
from memory_server.storage import MemoryStorage

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def db_path(tmp_path: Path) -> Path:
    """Provide a temporary database file path."""
    return tmp_path / "test_semantic.db"


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
    return "semantic_test_123"


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestSemanticSearch:
    """Integration tests for semantic search with stored entries."""

    @pytest.mark.asyncio
    async def test_different_topics_ranked_correctly(
        self, storage: MemoryStorage, config: MemoryConfig, project_id: str
    ) -> None:
        """Store entries with different topics; query ranks correct entry first."""
        # Use a mock that returns different vectors based on content
        mock_embedding = MagicMock()

        def embed_side_effect(text: str) -> list[float]:
            if "database" in text.lower() or "sql" in text.lower():
                return [0.9] * 192 + [0.1] * 192
            if "test" in text.lower() or "pytest" in text.lower():
                return [0.1] * 192 + [0.9] * 192
            return [0.5] * 384

        mock_embedding.embed_text.side_effect = embed_side_effect

        init_server(
            storage=storage,
            embedding_service=mock_embedding,
            project_id=project_id,
            config=config,
        )

        # Store entries with different topics
        await store_memory(content="Use database indexes for faster queries", entry_type="decision")
        await store_memory(content="Write pytest fixtures for test isolation", entry_type="pattern")
        await store_memory(content="General project architecture notes", entry_type="observation")
        await store_memory(content="SQL optimization with explain analyze", entry_type="decision")
        await store_memory(content="pytest parametrize for edge cases", entry_type="pattern")

        # Query about databases - should rank database entries higher
        result = await search_memories(query="database optimization", min_score=0.0)
        assert result["total_matches"] > 0

        # First result should be database-related
        if result["results"]:
            first = result["results"][0]
            assert "database" in first["content"].lower() or "sql" in first["content"].lower()

    @pytest.mark.asyncio
    async def test_scores_in_valid_range(
        self, storage: MemoryStorage, config: MemoryConfig, project_id: str
    ) -> None:
        """All relevance scores are in the 0.0-1.0 range."""
        mock_embedding = MagicMock()
        mock_embedding.embed_text.return_value = [0.5] * 384

        init_server(
            storage=storage,
            embedding_service=mock_embedding,
            project_id=project_id,
            config=config,
        )

        # Store some entries
        for i in range(5):
            await store_memory(content=f"Entry {i} about topic", entry_type="observation")

        result = await search_memories(query="topic", min_score=0.0)
        for r in result["results"]:
            assert 0.0 <= r["score"] <= 1.0, f"Score {r['score']} out of range"

    @pytest.mark.asyncio
    async def test_different_wording_finds_correct_entry(
        self, storage: MemoryStorage, config: MemoryConfig, project_id: str
    ) -> None:
        """Query with different wording still finds the semantically correct entry."""
        mock_embedding = MagicMock()

        def embed_side_effect(text: str) -> list[float]:
            # Simulate that "error" and "bug" are semantically similar
            if "error" in text.lower() or "bug" in text.lower() or "fix" in text.lower():
                return [0.8] * 384
            return [0.2] * 384

        mock_embedding.embed_text.side_effect = embed_side_effect

        init_server(
            storage=storage,
            embedding_service=mock_embedding,
            project_id=project_id,
            config=config,
        )

        await store_memory(
            content="Fixed the null pointer error in the parser",
            entry_type="error",
        )
        await store_memory(
            content="Updated documentation for API endpoints",
            entry_type="observation",
        )

        # Query with different wording
        result = await search_memories(query="bug fix in code", min_score=0.0)
        assert result["total_matches"] > 0
        # The error entry should score higher
        if len(result["results"]) >= 2:
            assert result["results"][0]["entry_type"] == "error"
