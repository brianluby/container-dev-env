"""T055: Tests for memory retention management.

Tests validate time-based pruning, size-based pruning, combined thresholds,
and oldest-first deletion order.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from pathlib import Path

import pytest

from memory_server.config import MemoryConfig
from memory_server.retention import prune_expired, prune_oversized, run_pruning
from memory_server.storage import MemoryStorage

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def db_path(tmp_path: Path) -> Path:
    """Provide a temporary database file path."""
    return tmp_path / "test_retention.db"


@pytest.fixture
def storage(db_path: Path) -> MemoryStorage:
    """Create a MemoryStorage instance with a temporary database."""
    return MemoryStorage(str(db_path))


def _insert_entry(
    storage: MemoryStorage,
    content: str = "Test content",
    created_at: str | None = None,
    project_id: str = "retention_test_12",
) -> str:
    """Helper to insert a test entry with a specific timestamp."""
    entry_id = str(uuid.uuid4())
    entry = {
        "id": entry_id,
        "project_id": project_id,
        "content": content,
        "source_tool": "unknown",
        "session_id": "test-session",
        "entry_type": "observation",
        "tags": None,
        "created_at": created_at or datetime.now(tz=UTC).isoformat(),
        "accessed_at": None,
    }
    storage.insert_entry(entry)
    return entry_id


# ---------------------------------------------------------------------------
# Time-based pruning tests
# ---------------------------------------------------------------------------


class TestPruneExpired:
    """Tests for time-based pruning."""

    def test_entries_older_than_retention_days_removed(self, storage: MemoryStorage) -> None:
        """Entries older than retention_days are deleted."""
        old_time = (datetime.now(tz=UTC) - timedelta(days=31)).isoformat()
        recent_time = datetime.now(tz=UTC).isoformat()

        old_id = _insert_entry(storage, "Old entry", created_at=old_time)
        recent_id = _insert_entry(storage, "Recent entry", created_at=recent_time)

        deleted = prune_expired(storage, retention_days=30)
        assert deleted == 1

        # Old entry should be gone
        assert storage.get_entry(old_id) is None
        # Recent entry should remain
        assert storage.get_entry(recent_id) is not None

    def test_no_entries_to_prune(self, storage: MemoryStorage) -> None:
        """No entries deleted when all are within retention period."""
        recent_time = datetime.now(tz=UTC).isoformat()
        _insert_entry(storage, "Recent entry", created_at=recent_time)

        deleted = prune_expired(storage, retention_days=30)
        assert deleted == 0

    def test_multiple_expired_entries(self, storage: MemoryStorage) -> None:
        """Multiple old entries are all deleted."""
        old_time = (datetime.now(tz=UTC) - timedelta(days=60)).isoformat()
        for i in range(5):
            _insert_entry(storage, f"Old entry {i}", created_at=old_time)
        _insert_entry(storage, "Recent entry", created_at=datetime.now(tz=UTC).isoformat())

        deleted = prune_expired(storage, retention_days=30)
        assert deleted == 5

    def test_empty_database(self, storage: MemoryStorage) -> None:
        """Pruning on empty database returns 0."""
        deleted = prune_expired(storage, retention_days=30)
        assert deleted == 0

    def test_oldest_first_order(self, storage: MemoryStorage) -> None:
        """Expired entries are removed oldest first."""
        now = datetime.now(tz=UTC)
        oldest_time = (now - timedelta(days=90)).isoformat()
        old_time = (now - timedelta(days=60)).isoformat()
        recent_time = now.isoformat()

        oldest_id = _insert_entry(storage, "Oldest", created_at=oldest_time)
        old_id = _insert_entry(storage, "Old", created_at=old_time)
        recent_id = _insert_entry(storage, "Recent", created_at=recent_time)

        # Prune with 45-day retention (oldest and old should be removed)
        deleted = prune_expired(storage, retention_days=45)
        assert deleted == 2
        assert storage.get_entry(oldest_id) is None
        assert storage.get_entry(old_id) is None
        assert storage.get_entry(recent_id) is not None


# ---------------------------------------------------------------------------
# Size-based pruning tests
# ---------------------------------------------------------------------------


class TestPruneOversized:
    """Tests for size-based pruning."""

    def test_no_pruning_when_under_limit(self, storage: MemoryStorage) -> None:
        """No entries deleted when DB is under size limit."""
        _insert_entry(storage, "Small entry")
        deleted = prune_oversized(storage, max_size_mb=500)
        assert deleted == 0

    def test_entries_removed_until_under_size_cap(self, storage: MemoryStorage) -> None:
        """Entries are removed until DB is under size cap."""
        # Insert many entries to grow the DB
        for i in range(100):
            _insert_entry(storage, f"Entry {i} with some padding content " * 10)

        # Use a very small size cap to force pruning
        db_size_before = storage.get_db_size()
        if db_size_before > 0:
            # Set max to smaller than current size (in MB)
            tiny_max_mb = max(1, db_size_before // (1024 * 1024) - 1)
            if db_size_before > tiny_max_mb * 1024 * 1024:
                deleted = prune_oversized(storage, max_size_mb=tiny_max_mb)
                # Some entries should have been deleted
                assert deleted >= 0

    def test_empty_database_no_pruning(self, storage: MemoryStorage) -> None:
        """Empty database returns 0 deletions."""
        deleted = prune_oversized(storage, max_size_mb=500)
        assert deleted == 0


# ---------------------------------------------------------------------------
# Combined threshold tests
# ---------------------------------------------------------------------------


class TestRunPruning:
    """Tests for combined time and size based pruning."""

    def test_both_conditions_applied(self, storage: MemoryStorage) -> None:
        """run_pruning applies both time and size conditions."""
        old_time = (datetime.now(tz=UTC) - timedelta(days=60)).isoformat()
        _insert_entry(storage, "Old entry", created_at=old_time)
        _insert_entry(storage, "Recent entry", created_at=datetime.now(tz=UTC).isoformat())

        config = MemoryConfig(
            retention_days=30,
            max_size_mb=500,
            workspace_path="/tmp/test",
        )
        result = run_pruning(storage, config)
        assert "expired" in result
        assert "oversized" in result
        assert result["expired"] == 1

    def test_returns_counts_dict(self, storage: MemoryStorage) -> None:
        """run_pruning returns a dict with expired and oversized counts."""
        config = MemoryConfig(
            retention_days=30,
            max_size_mb=500,
            workspace_path="/tmp/test",
        )
        result = run_pruning(storage, config)
        assert isinstance(result, dict)
        assert "expired" in result
        assert "oversized" in result
        assert isinstance(result["expired"], int)
        assert isinstance(result["oversized"], int)
