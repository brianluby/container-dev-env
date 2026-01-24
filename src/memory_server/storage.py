"""T015: SQLite storage layer for the persistent memory system.

Provides the MemoryStorage class that wraps all SQLite operations including
schema creation, CRUD for memory entries, vector embedding storage via
sqlite-vec, and WAL mode configuration.
"""

from __future__ import annotations

import json
import sqlite3
import struct
from pathlib import Path
from typing import Any

import sqlite_vec

from memory_server import logger

# ---------------------------------------------------------------------------
# Schema DDL
# ---------------------------------------------------------------------------

_SCHEMA_DDL = """
CREATE TABLE IF NOT EXISTS memory_entries (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    content TEXT NOT NULL CHECK(length(content) > 0 AND length(content) <= 10000),
    source_tool TEXT NOT NULL CHECK(source_tool IN (
        'claude-code', 'cline', 'continue', 'opencode', 'unknown')),
    session_id TEXT NOT NULL,
    entry_type TEXT NOT NULL CHECK(entry_type IN (
        'decision', 'pattern', 'observation', 'error', 'context')),
    tags TEXT,
    created_at TEXT NOT NULL,
    accessed_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_project_created ON memory_entries(project_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_project_type ON memory_entries(project_id, entry_type);

CREATE TABLE IF NOT EXISTS project_config (
    project_id TEXT PRIMARY KEY,
    workspace_path TEXT NOT NULL UNIQUE,
    retention_days INTEGER NOT NULL DEFAULT 30,
    max_size_mb INTEGER NOT NULL DEFAULT 500,
    created_at TEXT NOT NULL,
    last_pruned_at TEXT
);
"""

_VEC_TABLE_DDL = """
CREATE VIRTUAL TABLE IF NOT EXISTS memory_embeddings USING vec0(
    id TEXT PRIMARY KEY,
    embedding float[384]
);
"""


# ---------------------------------------------------------------------------
# MemoryStorage
# ---------------------------------------------------------------------------


class MemoryStorage:
    """SQLite-backed storage for memory entries and vector embeddings.

    Manages the database lifecycle including schema creation, WAL mode,
    sqlite-vec extension loading, and provides CRUD + similarity search.

    Args:
        db_path: Filesystem path for the SQLite database file.
    """

    def __init__(self, db_path: str) -> None:
        self._db_path = Path(db_path)
        self._db_path.parent.mkdir(parents=True, exist_ok=True)

        self._conn = self._open_connection()

        # Initialize schema (with corruption recovery)
        try:
            self._init_schema()
        except sqlite3.DatabaseError as exc:
            logger.warning(
                "Database appears corrupted (%s). Recreating: %s",
                exc,
                self._db_path,
            )
            self._conn.close()
            self._db_path.unlink(missing_ok=True)
            # Also remove WAL and SHM sidecar files
            wal_path = self._db_path.with_suffix(".db-wal")
            shm_path = self._db_path.with_suffix(".db-shm")
            wal_path.unlink(missing_ok=True)
            shm_path.unlink(missing_ok=True)
            self._conn = self._open_connection()
            self._init_schema()

    def _open_connection(self) -> sqlite3.Connection:
        """Open and configure a new SQLite connection.

        Returns:
            A configured sqlite3.Connection with WAL mode and sqlite-vec loaded.
        """
        conn = sqlite3.connect(str(self._db_path), timeout=30.0)
        conn.row_factory = sqlite3.Row

        # Enable WAL mode for concurrent read performance
        conn.execute("PRAGMA journal_mode=WAL")
        # Set busy timeout to handle concurrent access gracefully
        conn.execute("PRAGMA busy_timeout=5000")

        # Load sqlite-vec extension
        conn.enable_load_extension(True)
        sqlite_vec.load(conn)
        conn.enable_load_extension(False)

        return conn

    def _init_schema(self) -> None:
        """Create tables, indexes, and the vec0 virtual table if not present."""
        self._conn.executescript(_SCHEMA_DDL)
        # vec0 virtual table must be created separately (not inside executescript
        # with other DDL since it relies on the loaded extension)
        self._conn.execute(_VEC_TABLE_DDL.strip())
        self._conn.commit()

    # ------------------------------------------------------------------
    # CRUD Operations
    # ------------------------------------------------------------------

    def insert_entry(self, entry: dict[str, Any]) -> str:
        """Insert a memory entry into the memory_entries table.

        Args:
            entry: Dictionary containing the entry fields. Tags (if present)
                   are serialized to a JSON string for storage.

        Returns:
            The entry ID string.
        """
        tags_value: str | None = None
        if entry.get("tags") is not None:
            tags_value = json.dumps(entry["tags"])

        self._conn.execute(
            """
            INSERT INTO memory_entries (id, project_id, content, source_tool,
                                        session_id, entry_type, tags, created_at, accessed_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                entry["id"],
                entry["project_id"],
                entry["content"],
                entry["source_tool"],
                entry["session_id"],
                entry["entry_type"],
                tags_value,
                entry["created_at"],
                entry.get("accessed_at"),
            ),
        )
        self._conn.commit()
        return str(entry["id"])

    def get_entry(self, entry_id: str) -> dict[str, Any] | None:
        """Retrieve a memory entry by ID.

        Args:
            entry_id: UUID string of the entry to retrieve.

        Returns:
            A dictionary with entry fields, or None if not found.
        """
        cursor = self._conn.execute("SELECT * FROM memory_entries WHERE id = ?", (entry_id,))
        row = cursor.fetchone()
        if row is None:
            return None
        return self._row_to_dict(row)

    def list_entries(
        self,
        project_id: str,
        entry_type: str | None = None,
        limit: int = 10,
        offset: int = 0,
    ) -> list[dict[str, Any]]:
        """List memory entries for a project, optionally filtered by type.

        Args:
            project_id: The project identifier to filter by.
            entry_type: Optional entry type filter.
            limit: Maximum number of entries to return.
            offset: Number of entries to skip.

        Returns:
            A list of entry dictionaries ordered by created_at descending.
        """
        if entry_type is not None:
            cursor = self._conn.execute(
                """
                SELECT * FROM memory_entries
                WHERE project_id = ? AND entry_type = ?
                ORDER BY created_at DESC
                LIMIT ? OFFSET ?
                """,
                (project_id, entry_type, limit, offset),
            )
        else:
            cursor = self._conn.execute(
                """
                SELECT * FROM memory_entries
                WHERE project_id = ?
                ORDER BY created_at DESC
                LIMIT ? OFFSET ?
                """,
                (project_id, limit, offset),
            )
        return [self._row_to_dict(row) for row in cursor.fetchall()]

    def delete_entry(self, entry_id: str) -> bool:
        """Delete a memory entry and its associated embedding.

        Args:
            entry_id: UUID string of the entry to delete.

        Returns:
            True if the entry existed and was deleted, False otherwise.
        """
        cursor = self._conn.execute("DELETE FROM memory_entries WHERE id = ?", (entry_id,))
        # Also remove from embeddings table (ignore if not present)
        self._conn.execute("DELETE FROM memory_embeddings WHERE id = ?", (entry_id,))
        self._conn.commit()
        return cursor.rowcount > 0

    def count_entries(
        self,
        project_id: str,
        entry_type: str | None = None,
    ) -> int:
        """Count memory entries for a project, optionally filtered by type.

        Args:
            project_id: The project identifier to filter by.
            entry_type: Optional entry type filter.

        Returns:
            The count of matching entries.
        """
        if entry_type is not None:
            cursor = self._conn.execute(
                "SELECT COUNT(*) FROM memory_entries WHERE project_id = ? AND entry_type = ?",
                (project_id, entry_type),
            )
        else:
            cursor = self._conn.execute(
                "SELECT COUNT(*) FROM memory_entries WHERE project_id = ?",
                (project_id,),
            )
        result: int = cursor.fetchone()[0]
        return result

    def get_stats(self, project_id: str) -> dict[str, Any]:
        """Get statistics for a project's memory entries.

        Args:
            project_id: The project identifier.

        Returns:
            Dictionary with total_entries, oldest_entry, newest_entry,
            entries_by_type, and entries_by_tool.
        """
        total = self.count_entries(project_id)

        # Get oldest and newest timestamps
        cursor = self._conn.execute(
            "SELECT MIN(created_at), MAX(created_at) FROM memory_entries WHERE project_id = ?",
            (project_id,),
        )
        row = cursor.fetchone()
        oldest_entry = row[0] if row else None
        newest_entry = row[1] if row else None

        # Count by entry_type
        cursor = self._conn.execute(
            """
            SELECT entry_type, COUNT(*) FROM memory_entries
            WHERE project_id = ?
            GROUP BY entry_type
            """,
            (project_id,),
        )
        entries_by_type: dict[str, int] = {}
        for r in cursor.fetchall():
            entries_by_type[r[0]] = r[1]

        # Count by source_tool
        cursor = self._conn.execute(
            """
            SELECT source_tool, COUNT(*) FROM memory_entries
            WHERE project_id = ?
            GROUP BY source_tool
            """,
            (project_id,),
        )
        entries_by_tool: dict[str, int] = {}
        for r in cursor.fetchall():
            entries_by_tool[r[0]] = r[1]

        return {
            "total_entries": total,
            "oldest_entry": oldest_entry,
            "newest_entry": newest_entry,
            "entries_by_type": entries_by_type,
            "entries_by_tool": entries_by_tool,
        }

    # ------------------------------------------------------------------
    # Embedding Operations
    # ------------------------------------------------------------------

    def insert_embedding(self, entry_id: str, embedding: list[float]) -> None:
        """Insert a vector embedding for a memory entry.

        Args:
            entry_id: The ID of the associated memory entry.
            embedding: A 384-dimensional float vector.
        """
        self._conn.execute(
            "INSERT INTO memory_embeddings (id, embedding) VALUES (?, ?)",
            (entry_id, _serialize_vector(embedding)),
        )
        self._conn.commit()

    def search_similar(
        self,
        query_embedding: list[float],
        limit: int = 5,
        min_score: float = 0.3,
    ) -> list[dict[str, Any]]:
        """Search for similar entries using vector KNN via sqlite-vec.

        Args:
            query_embedding: A 384-dimensional query vector.
            limit: Maximum number of results to return.
            min_score: Minimum similarity threshold (not directly applied
                       in the vec0 query but can be post-filtered).

        Returns:
            A list of dicts with 'entry_id' and 'distance' keys, ordered
            by ascending distance (most similar first).
        """
        cursor = self._conn.execute(
            """
            SELECT id, distance
            FROM memory_embeddings
            WHERE embedding MATCH ?
            AND k = ?
            """,
            (_serialize_vector(query_embedding), limit),
        )
        results: list[dict[str, Any]] = []
        for row in cursor.fetchall():
            distance = float(row[1])
            # Convert L2 distance to a similarity score (lower distance = higher similarity)
            # Skip results below the minimum score threshold
            score = 1.0 / (1.0 + distance)
            if score >= min_score:
                results.append(
                    {
                        "entry_id": row[0],
                        "id": row[0],
                        "distance": distance,
                        "score": score,
                    }
                )
        return results

    # ------------------------------------------------------------------
    # Utility Methods
    # ------------------------------------------------------------------

    def get_db_size(self) -> int:
        """Return the database file size in bytes.

        Returns:
            File size in bytes, or 0 if the file does not exist.
        """
        if self._db_path.exists():
            return self._db_path.stat().st_size
        return 0

    def close(self) -> None:
        """Close the database connection."""
        self._conn.close()

    # ------------------------------------------------------------------
    # Internal Helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _row_to_dict(row: sqlite3.Row) -> dict[str, Any]:
        """Convert a sqlite3.Row to a plain dictionary, deserializing tags."""
        result: dict[str, Any] = dict(row)
        # Deserialize tags from JSON string back to list
        if result.get("tags") is not None:
            result["tags"] = json.loads(result["tags"])
        return result


def _serialize_vector(vector: list[float]) -> bytes:
    """Serialize a float vector to bytes for sqlite-vec storage.

    sqlite-vec expects vectors as compact binary (little-endian float32).

    Args:
        vector: List of floats to serialize.

    Returns:
        Bytes representation suitable for sqlite-vec.
    """
    return struct.pack(f"<{len(vector)}f", *vector)
