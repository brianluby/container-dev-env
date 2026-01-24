"""T050: Integration tests for memory isolation per project.

Tests verify that different project IDs get isolated memory storage,
and that entries from one project are not visible to another.
"""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

import pytest

from memory_server.config import MemoryConfig
from memory_server.project import generate_project_id, get_db_path
from memory_server.server import init_server, list_memories, search_memories, store_memory
from memory_server.storage import MemoryStorage

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def base_path(tmp_path: Path) -> Path:
    """Provide a base directory for test databases."""
    return tmp_path / "memory-data"


@pytest.fixture
def config() -> MemoryConfig:
    """Create a default test configuration."""
    return MemoryConfig(workspace_path="/tmp/test-workspace")


@pytest.fixture
def mock_embedding_service() -> MagicMock:
    """Create a mock embedding service."""
    service = MagicMock()
    service.embed_text.return_value = [0.5] * 384
    return service


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestProjectIsolation:
    """Test that entries are isolated between projects."""

    @pytest.mark.asyncio
    async def test_store_in_project_a_not_visible_in_project_b(
        self,
        base_path: Path,
        config: MemoryConfig,
        mock_embedding_service: MagicMock,
    ) -> None:
        """Entry stored in project A is not visible from project B."""
        project_a = "aaaa111122223333"
        project_b = "bbbb444455556666"

        # Store in project A
        db_path_a = get_db_path(str(base_path), project_a)
        storage_a = MemoryStorage(db_path_a)
        init_server(
            storage=storage_a,
            embedding_service=mock_embedding_service,
            project_id=project_a,
            config=config,
        )
        result = await store_memory(
            content="Secret from project A",
            entry_type="decision",
        )
        assert result["status"] == "stored"
        assert result["id"]  # Verify ID was generated

        # Switch to project B
        db_path_b = get_db_path(str(base_path), project_b)
        storage_b = MemoryStorage(db_path_b)
        init_server(
            storage=storage_b,
            embedding_service=mock_embedding_service,
            project_id=project_b,
            config=config,
        )

        # Query from project B should return empty
        list_result = await list_memories(limit=100)
        assert list_result["total_count"] == 0
        assert list_result["entries"] == []

        # Search from project B should return empty
        search_result = await search_memories(query="secret project A", min_score=0.0)
        assert search_result["total_matches"] == 0

        storage_a.close()
        storage_b.close()

    @pytest.mark.asyncio
    async def test_query_from_own_project_returns_entry(
        self,
        base_path: Path,
        config: MemoryConfig,
        mock_embedding_service: MagicMock,
    ) -> None:
        """Entry stored in project A is visible when querying from project A."""
        project_a = "aaaa111122223333"

        db_path_a = get_db_path(str(base_path), project_a)
        storage_a = MemoryStorage(db_path_a)
        init_server(
            storage=storage_a,
            embedding_service=mock_embedding_service,
            project_id=project_a,
            config=config,
        )

        result = await store_memory(
            content="Visible entry in project A",
            entry_type="observation",
        )
        assert result["status"] == "stored"

        # List from same project should find it
        list_result = await list_memories(limit=100)
        assert list_result["total_count"] == 1
        assert list_result["entries"][0]["content"] == "Visible entry in project A"

        storage_a.close()

    def test_different_workspaces_get_different_db_files(self, base_path: Path) -> None:
        """Different workspace paths produce different database file paths."""
        project_a = generate_project_id("/workspace/project-alpha")
        project_b = generate_project_id("/workspace/project-beta")

        db_path_a = get_db_path(str(base_path), project_a)
        db_path_b = get_db_path(str(base_path), project_b)

        assert db_path_a != db_path_b
        assert project_a in db_path_a
        assert project_b in db_path_b
