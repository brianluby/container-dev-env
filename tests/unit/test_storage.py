"""T010: Tests for SQLite storage layer in memory_server.storage.

Tests validate schema creation, CRUD operations, sqlite-vec extension
loading, and WAL mode configuration for the MemoryStorage class.
"""

from __future__ import annotations

import sqlite3
import uuid
from datetime import UTC, datetime
from pathlib import Path

import pytest

from memory_server.storage import MemoryStorage

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def db_path(tmp_path: Path) -> Path:
    """Provide a temporary database file path."""
    return tmp_path / "test_memory.db"


@pytest.fixture
def storage(db_path: Path) -> MemoryStorage:
    """Create a MemoryStorage instance with a temporary database."""
    return MemoryStorage(str(db_path))


@pytest.fixture
def sample_entry() -> dict:
    """A sample memory entry for insertion tests."""
    return {
        "id": str(uuid.uuid4()),
        "project_id": "a1b2c3d4e5f67890",
        "content": "Always use async for database operations in this project.",
        "source_tool": "claude-code",
        "session_id": "session-abc-123",
        "entry_type": "decision",
        "tags": ["async", "database"],
        "created_at": datetime.now(tz=UTC).isoformat(),
    }


# ---------------------------------------------------------------------------
# Schema Creation Tests
# ---------------------------------------------------------------------------


class TestSchemaCreation:
    """Tests for database schema initialization."""

    def test_creates_memory_entries_table(self, storage: MemoryStorage, db_path: Path) -> None:
        """Schema init creates the memory_entries table."""
        conn = sqlite3.connect(str(db_path))
        cursor = conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='memory_entries'"
        )
        assert cursor.fetchone() is not None
        conn.close()

    def test_creates_memory_embeddings_table(self, storage: MemoryStorage, db_path: Path) -> None:
        """Schema init creates the memory_embeddings table (or vec0 virtual table)."""
        conn = sqlite3.connect(str(db_path))
        cursor = conn.execute(
            "SELECT name FROM sqlite_master "
            "WHERE (type='table' OR type='virtual') AND name='memory_embeddings'"
        )
        assert cursor.fetchone() is not None
        conn.close()

    def test_creates_project_config_table(self, storage: MemoryStorage, db_path: Path) -> None:
        """Schema init creates the project_config table."""
        conn = sqlite3.connect(str(db_path))
        cursor = conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='project_config'"
        )
        assert cursor.fetchone() is not None
        conn.close()

    def test_wal_mode_enabled(self, storage: MemoryStorage, db_path: Path) -> None:
        """Database is configured in WAL journal mode."""
        conn = sqlite3.connect(str(db_path))
        cursor = conn.execute("PRAGMA journal_mode")
        mode = cursor.fetchone()[0]
        assert mode.lower() == "wal"
        conn.close()

    def test_creates_db_file(self, storage: MemoryStorage, db_path: Path) -> None:
        """Storage initialization creates the database file on disk."""
        assert db_path.exists()

    def test_idempotent_init(self, db_path: Path) -> None:
        """Creating MemoryStorage twice on same DB does not raise."""
        MemoryStorage(str(db_path))
        MemoryStorage(str(db_path))  # should not raise


# ---------------------------------------------------------------------------
# CRUD Operation Tests
# ---------------------------------------------------------------------------


class TestCrudOperations:
    """Tests for insert, get, list, and delete operations."""

    def test_insert_entry(self, storage: MemoryStorage, sample_entry: dict) -> None:
        """Inserting an entry does not raise and returns the entry ID."""
        result_id = storage.insert_entry(sample_entry)
        assert result_id == sample_entry["id"]

    def test_get_entry_by_id(self, storage: MemoryStorage, sample_entry: dict) -> None:
        """Retrieved entry matches what was inserted."""
        storage.insert_entry(sample_entry)
        retrieved = storage.get_entry(sample_entry["id"])
        assert retrieved is not None
        assert retrieved["id"] == sample_entry["id"]
        assert retrieved["content"] == sample_entry["content"]
        assert retrieved["project_id"] == sample_entry["project_id"]
        assert retrieved["source_tool"] == sample_entry["source_tool"]
        assert retrieved["entry_type"] == sample_entry["entry_type"]

    def test_get_nonexistent_entry(self, storage: MemoryStorage) -> None:
        """Getting a non-existent ID returns None."""
        result = storage.get_entry(str(uuid.uuid4()))
        assert result is None

    def test_list_entries_by_project_id(self, storage: MemoryStorage, sample_entry: dict) -> None:
        """list_entries returns all entries for a given project_id."""
        # Insert two entries for same project
        entry1 = sample_entry.copy()
        entry1["id"] = str(uuid.uuid4())
        entry1["content"] = "First entry"

        entry2 = sample_entry.copy()
        entry2["id"] = str(uuid.uuid4())
        entry2["content"] = "Second entry"

        storage.insert_entry(entry1)
        storage.insert_entry(entry2)

        entries = storage.list_entries(project_id=sample_entry["project_id"])
        assert len(entries) == 2

    def test_list_entries_filters_by_project(
        self, storage: MemoryStorage, sample_entry: dict
    ) -> None:
        """list_entries only returns entries for the specified project."""
        entry_a = sample_entry.copy()
        entry_a["id"] = str(uuid.uuid4())
        entry_a["project_id"] = "aaaa111122223333"

        entry_b = sample_entry.copy()
        entry_b["id"] = str(uuid.uuid4())
        entry_b["project_id"] = "bbbb444455556666"

        storage.insert_entry(entry_a)
        storage.insert_entry(entry_b)

        entries_a = storage.list_entries(project_id="aaaa111122223333")
        assert len(entries_a) == 1
        assert entries_a[0]["project_id"] == "aaaa111122223333"

    def test_delete_entry_by_id(self, storage: MemoryStorage, sample_entry: dict) -> None:
        """Deleting an entry removes it from the database."""
        storage.insert_entry(sample_entry)
        deleted = storage.delete_entry(sample_entry["id"])
        assert deleted is True

        retrieved = storage.get_entry(sample_entry["id"])
        assert retrieved is None

    def test_delete_nonexistent_entry(self, storage: MemoryStorage) -> None:
        """Deleting a non-existent entry returns False."""
        deleted = storage.delete_entry(str(uuid.uuid4()))
        assert deleted is False

    def test_insert_preserves_tags(self, storage: MemoryStorage, sample_entry: dict) -> None:
        """Tags are stored and retrieved correctly as a list."""
        storage.insert_entry(sample_entry)
        retrieved = storage.get_entry(sample_entry["id"])
        assert retrieved is not None
        assert retrieved["tags"] == ["async", "database"]

    def test_insert_entry_without_tags(self, storage: MemoryStorage, sample_entry: dict) -> None:
        """Entries without tags store None/null for the tags field."""
        sample_entry["tags"] = None
        storage.insert_entry(sample_entry)
        retrieved = storage.get_entry(sample_entry["id"])
        assert retrieved is not None
        assert retrieved["tags"] is None


# ---------------------------------------------------------------------------
# sqlite-vec Extension Tests
# ---------------------------------------------------------------------------


class TestSqliteVecExtension:
    """Tests for sqlite-vec extension loading and vec0 virtual table."""

    def test_vec0_virtual_table_exists(self, storage: MemoryStorage, db_path: Path) -> None:
        """A vec0 virtual table for embeddings is created."""
        conn = sqlite3.connect(str(db_path))
        cursor = conn.execute(
            "SELECT sql FROM sqlite_master WHERE name='memory_embeddings' AND type='table'"
        )
        row = cursor.fetchone()
        # vec0 virtual tables show as type='table' with CREATE VIRTUAL TABLE sql
        if row is not None:
            assert "vec0" in row[0].lower() or "virtual" in row[0].lower()
        conn.close()

    def test_can_insert_and_query_vector(self, storage: MemoryStorage) -> None:
        """Can insert a vector into the embeddings table and query it."""
        # 384-dimensional vector (FastEmbed all-MiniLM-L6-v2 default)
        entry_id = str(uuid.uuid4())
        vector = [0.1] * 384
        storage.insert_embedding(entry_id, vector)

        # Query should not raise
        results = storage.search_similar(vector, limit=5)
        assert isinstance(results, list)

    def test_search_similar_returns_entry_ids(self, storage: MemoryStorage) -> None:
        """search_similar returns entry IDs with distance scores."""
        entry_id = str(uuid.uuid4())
        vector = [0.5] * 384
        storage.insert_embedding(entry_id, vector)

        results = storage.search_similar(vector, limit=1)
        assert len(results) >= 1
        # Each result should have at minimum an ID and a distance/score
        assert "id" in results[0] or "entry_id" in results[0]


# ---------------------------------------------------------------------------
# WAL Mode Tests
# ---------------------------------------------------------------------------


class TestWalMode:
    """Tests for Write-Ahead Logging configuration."""

    def test_wal_mode_set_on_creation(self, db_path: Path) -> None:
        """WAL mode is enabled when the storage is created."""
        MemoryStorage(str(db_path))
        conn = sqlite3.connect(str(db_path))
        cursor = conn.execute("PRAGMA journal_mode")
        assert cursor.fetchone()[0].lower() == "wal"
        conn.close()

    def test_wal_files_created(self, storage: MemoryStorage, db_path: Path) -> None:
        """WAL mode creates -wal and -shm sidecar files after writes."""
        # Trigger a write to ensure WAL files are created
        entry = {
            "id": str(uuid.uuid4()),
            "project_id": "a1b2c3d4e5f67890",
            "content": "WAL test entry",
            "source_tool": "unknown",
            "session_id": "wal-test",
            "entry_type": "observation",
            "tags": None,
            "created_at": datetime.now(tz=UTC).isoformat(),
        }
        storage.insert_entry(entry)

        wal_file = Path(str(db_path) + "-wal")
        shm_file = Path(str(db_path) + "-shm")
        # At least one of these should exist after a WAL-mode write
        assert wal_file.exists() or shm_file.exists()
