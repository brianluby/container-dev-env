"""T039: Integration tests for cross-tool sharing and concurrent writes.

Tests verify that entries stored with one source_tool are accessible,
and that concurrent writes with WAL mode do not cause data corruption.
"""

from __future__ import annotations

import threading
import uuid
from datetime import UTC, datetime
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
    return tmp_path / "test_multi.db"


@pytest.fixture
def storage(db_path: Path) -> MemoryStorage:
    """Create a MemoryStorage instance with a temporary database."""
    return MemoryStorage(str(db_path))


@pytest.fixture
def mock_embedding_service() -> MagicMock:
    """Create a mock embedding service that returns a fixed vector."""
    service = MagicMock()
    service.embed_text.return_value = [0.2] * 384
    return service


@pytest.fixture
def config() -> MemoryConfig:
    """Create a default test configuration."""
    return MemoryConfig(workspace_path="/tmp/test-workspace")


# ---------------------------------------------------------------------------
# Cross-tool sharing tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestCrossToolSharing:
    """Test that entries stored by one tool are accessible."""

    @pytest.mark.asyncio
    async def test_store_with_source_tool_and_retrieve(
        self,
        storage: MemoryStorage,
        mock_embedding_service: MagicMock,
        config: MemoryConfig,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Store with source_tool=claude-code, verify entry is accessible."""
        monkeypatch.setenv("MEMORY_SOURCE_TOOL", "claude-code")
        init_server(
            storage=storage,
            embedding_service=mock_embedding_service,
            project_id="abcdef0123456789",
            config=config,
        )

        result = await store_memory(
            content="Cross-tool test entry",
            entry_type="observation",
        )
        assert result["status"] == "stored"

        # Verify entry is accessible
        entry = storage.get_entry(result["id"])
        assert entry is not None
        assert entry["source_tool"] == "claude-code"
        assert entry["content"] == "Cross-tool test entry"


# ---------------------------------------------------------------------------
# Concurrent write tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestConcurrentWrites:
    """Test concurrent writes with WAL mode for data integrity."""

    def test_concurrent_writes_no_corruption(self, db_path: Path) -> None:
        """Spawn 3 threads writing simultaneously; verify no data corruption."""
        project_id = "concurrency_test_"
        entries_per_thread = 10
        errors: list[str] = []
        written_ids: list[str] = []
        lock = threading.Lock()

        # Pre-create the database schema so threads don't race on schema init
        init_storage = MemoryStorage(str(db_path))
        init_storage.close()

        def writer(thread_idx: int) -> None:
            """Write entries from a separate storage connection."""
            try:
                import sqlite3

                conn = sqlite3.connect(str(db_path), timeout=30.0)
                conn.execute("PRAGMA busy_timeout=10000")
                conn.execute("PRAGMA journal_mode=WAL")

                for i in range(entries_per_thread):
                    entry_id = str(uuid.uuid4())
                    created_at = datetime.now(tz=UTC).isoformat()
                    conn.execute(
                        """
                        INSERT INTO memory_entries
                            (id, project_id, content, source_tool, session_id,
                             entry_type, tags, created_at, accessed_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                        (
                            entry_id,
                            project_id,
                            f"Thread {thread_idx} entry {i}",
                            "unknown",
                            f"session-thread-{thread_idx}",
                            "observation",
                            f'["thread-{thread_idx}"]',
                            created_at,
                            None,
                        ),
                    )
                    conn.commit()
                    with lock:
                        written_ids.append(entry_id)
                conn.close()
            except Exception as exc:
                with lock:
                    errors.append(f"Thread {thread_idx}: {exc}")

        # Spawn 3 threads
        threads = [threading.Thread(target=writer, args=(i,)) for i in range(3)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        # No errors should have occurred
        assert not errors, f"Concurrent write errors: {errors}"

        # All entries should be present
        assert len(written_ids) == 3 * entries_per_thread

        # Verify all entries are readable
        verify_storage = MemoryStorage(str(db_path))
        for entry_id in written_ids:
            entry = verify_storage.get_entry(entry_id)
            assert entry is not None, f"Entry {entry_id} not found after concurrent writes"
        verify_storage.close()
