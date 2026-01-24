"""T038b: Integration tests for memory persistence across restarts.

Tests that both strategic and tactical memory data survives storage
close/reopen cycles, simulating container or session restarts.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from pathlib import Path

import pytest

from memory_server.storage import MemoryStorage
from memory_server.strategic import load_strategic_memory

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_entry(project_id: str = "test-project") -> dict:
    """Create a sample memory entry dictionary."""
    return {
        "id": str(uuid.uuid4()),
        "project_id": project_id,
        "content": f"Test memory content {uuid.uuid4().hex[:8]}",
        "source_tool": "claude-code",
        "session_id": str(uuid.uuid4()),
        "entry_type": "observation",
        "tags": ["test", "integration"],
        "created_at": datetime.now(tz=UTC).isoformat(),
        "accessed_at": None,
    }


# ---------------------------------------------------------------------------
# Strategic Memory Persistence Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestStrategicMemoryPersistence:
    """Test that strategic memory persists across loader invocations."""

    def test_strategic_files_persist_after_reload(self, tmp_path: Path) -> None:
        """Create .memory/ files, verify content is unchanged on reload."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        (memory_dir / "goals.md").write_text("# Goals\nPersistent goal.")
        (memory_dir / "architecture.md").write_text("# Arch\nMicroservices.")

        # First load
        result1 = load_strategic_memory(str(tmp_path))
        assert "Persistent goal." in result1
        assert "Microservices." in result1

        # Second load (simulates session restart)
        result2 = load_strategic_memory(str(tmp_path))
        assert result1 == result2

    def test_strategic_content_unchanged_after_multiple_reads(self, tmp_path: Path) -> None:
        """Multiple reads return identical content."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        (memory_dir / "patterns.md").write_text("# Patterns\nUse composition.")

        results = [load_strategic_memory(str(tmp_path)) for _ in range(5)]
        assert all(r == results[0] for r in results)


# ---------------------------------------------------------------------------
# Tactical Memory Persistence Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestTacticalMemoryPersistence:
    """Test tactical memory persists: insert entries, close storage, reopen, verify."""

    def test_entries_persist_after_close_and_reopen(self, tmp_path: Path) -> None:
        """Inserted entries survive storage close and reopen."""
        db_path = str(tmp_path / "test.db")
        entry = _make_entry()

        # Insert and close
        storage = MemoryStorage(db_path)
        storage.insert_entry(entry)
        storage.close()

        # Reopen and verify
        storage2 = MemoryStorage(db_path)
        retrieved = storage2.get_entry(entry["id"])
        storage2.close()

        assert retrieved is not None
        assert retrieved["id"] == entry["id"]
        assert retrieved["content"] == entry["content"]
        assert retrieved["entry_type"] == entry["entry_type"]

    def test_multiple_entries_persist(self, tmp_path: Path) -> None:
        """Multiple entries all survive close/reopen cycle."""
        db_path = str(tmp_path / "test.db")
        entries = [_make_entry() for _ in range(10)]

        # Insert all entries
        storage = MemoryStorage(db_path)
        for entry in entries:
            storage.insert_entry(entry)
        storage.close()

        # Reopen and verify all entries exist
        storage2 = MemoryStorage(db_path)
        for entry in entries:
            retrieved = storage2.get_entry(entry["id"])
            assert retrieved is not None, f"Entry {entry['id']} not found after reopen"
            assert retrieved["content"] == entry["content"]
        storage2.close()

    def test_entry_types_preserved(self, tmp_path: Path) -> None:
        """Entry types are correctly preserved across restarts."""
        db_path = str(tmp_path / "test.db")
        entry_types = ["decision", "pattern", "observation", "error", "context"]
        entries = []

        storage = MemoryStorage(db_path)
        for etype in entry_types:
            entry = _make_entry()
            entry["entry_type"] = etype
            storage.insert_entry(entry)
            entries.append(entry)
        storage.close()

        storage2 = MemoryStorage(db_path)
        for entry in entries:
            retrieved = storage2.get_entry(entry["id"])
            assert retrieved is not None
            assert retrieved["entry_type"] == entry["entry_type"]
        storage2.close()

    def test_tags_preserved_across_restart(self, tmp_path: Path) -> None:
        """Tags (JSON-serialized) are correctly preserved."""
        db_path = str(tmp_path / "test.db")
        entry = _make_entry()
        entry["tags"] = ["python", "refactoring", "performance"]

        storage = MemoryStorage(db_path)
        storage.insert_entry(entry)
        storage.close()

        storage2 = MemoryStorage(db_path)
        retrieved = storage2.get_entry(entry["id"])
        storage2.close()

        assert retrieved is not None
        assert retrieved["tags"] == ["python", "refactoring", "performance"]

    def test_embeddings_persist(self, tmp_path: Path) -> None:
        """Vector embeddings survive close/reopen cycle."""
        db_path = str(tmp_path / "test.db")
        entry = _make_entry()
        embedding = [0.1] * 384  # 384-dimensional vector

        storage = MemoryStorage(db_path)
        storage.insert_entry(entry)
        storage.insert_embedding(entry["id"], embedding)
        storage.close()

        # Reopen and search for similar
        storage2 = MemoryStorage(db_path)
        results = storage2.search_similar(embedding, limit=1)
        storage2.close()

        assert len(results) > 0
        assert results[0]["entry_id"] == entry["id"]


# ---------------------------------------------------------------------------
# Restart Cycle Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestRestartCycles:
    """Simulate 10 restart cycles verifying no data loss."""

    def test_ten_restart_cycles_no_data_loss(self, tmp_path: Path) -> None:
        """Close and reopen storage 10 times; all entries remain intact."""
        db_path = str(tmp_path / "restart_test.db")
        all_entries: list[dict] = []

        for cycle in range(10):
            storage = MemoryStorage(db_path)

            # Add a new entry each cycle
            entry = _make_entry()
            entry["content"] = f"Cycle {cycle} content"
            storage.insert_entry(entry)
            all_entries.append(entry)

            # Verify ALL previously inserted entries still exist
            for prev_entry in all_entries:
                retrieved = storage.get_entry(prev_entry["id"])
                assert retrieved is not None, (
                    f"Entry from cycle lost at cycle {cycle}: {prev_entry['id']}"
                )
                assert retrieved["content"] == prev_entry["content"]

            storage.close()

        # Final verification: reopen and check all entries one more time
        storage_final = MemoryStorage(db_path)
        for entry in all_entries:
            retrieved = storage_final.get_entry(entry["id"])
            assert retrieved is not None, f"Entry missing in final check: {entry['id']}"
            assert retrieved["content"] == entry["content"]
        storage_final.close()

        assert len(all_entries) == 10

    def test_list_entries_consistent_across_restarts(self, tmp_path: Path) -> None:
        """list_entries returns consistent results across restart cycles."""
        db_path = str(tmp_path / "list_test.db")
        project_id = "restart-project"

        # Insert 5 entries
        storage = MemoryStorage(db_path)
        for i in range(5):
            entry = _make_entry(project_id)
            entry["content"] = f"Entry {i}"
            storage.insert_entry(entry)
        storage.close()

        # Verify across 5 restart cycles
        for _ in range(5):
            storage = MemoryStorage(db_path)
            entries = storage.list_entries(project_id, limit=100)
            assert len(entries) == 5
            storage.close()

    def test_db_size_stable_across_restarts(self, tmp_path: Path) -> None:
        """Database size does not grow unexpectedly from repeated opens."""
        db_path = str(tmp_path / "size_test.db")

        # Initial creation with entry
        storage = MemoryStorage(db_path)
        entry = _make_entry()
        storage.insert_entry(entry)
        storage.close()

        # Reopen once to let WAL checkpoint and schema stabilize
        storage = MemoryStorage(db_path)
        baseline_size = storage.get_db_size()
        storage.close()

        # Reopen 10 times without adding data
        for _ in range(10):
            storage = MemoryStorage(db_path)
            storage.close()

        # Check final size (should not have grown significantly beyond baseline)
        storage = MemoryStorage(db_path)
        final_size = storage.get_db_size()
        storage.close()

        # After initial schema creation, size should remain stable.
        # Allow up to 2x growth for WAL/journal checkpointing overhead.
        assert final_size <= baseline_size * 2, (
            f"DB grew unexpectedly: {baseline_size} -> {final_size}"
        )
