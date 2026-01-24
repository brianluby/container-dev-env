"""T058: Retention management for the persistent memory system.

Provides time-based and size-based pruning of memory entries to keep
database storage within configured limits. Entries are removed in
oldest-first order.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from memory_server import logger
from memory_server.config import MemoryConfig
from memory_server.storage import MemoryStorage


def prune_expired(storage: MemoryStorage, retention_days: int) -> int:
    """Delete memory entries older than the retention threshold.

    Removes entries whose created_at timestamp is older than
    (now - retention_days). Entries are removed in oldest-first order.

    Args:
        storage: The MemoryStorage instance to prune.
        retention_days: Number of days to retain entries.

    Returns:
        The number of entries deleted.
    """
    cutoff = datetime.now(tz=UTC) - timedelta(days=retention_days)
    cutoff_iso = cutoff.isoformat()

    # Get all expired entry IDs
    cursor = storage._conn.execute(
        """
        SELECT id FROM memory_entries
        WHERE created_at < ?
        ORDER BY created_at ASC
        """,
        (cutoff_iso,),
    )
    expired_ids = [row[0] for row in cursor.fetchall()]

    if not expired_ids:
        return 0

    # Delete entries and their embeddings
    for entry_id in expired_ids:
        storage.delete_entry(entry_id)

    logger.info("Pruned %d expired entries (older than %d days)", len(expired_ids), retention_days)
    return len(expired_ids)


def prune_oversized(storage: MemoryStorage, max_size_mb: int) -> int:
    """Delete oldest entries until database is under the size cap.

    Checks the database file size and removes entries in oldest-first
    order until the file size drops below max_size_mb.

    Args:
        storage: The MemoryStorage instance to prune.
        max_size_mb: Maximum database size in megabytes.

    Returns:
        The number of entries deleted.
    """
    max_size_bytes = max_size_mb * 1024 * 1024
    current_size = storage.get_db_size()

    if current_size <= max_size_bytes:
        return 0

    deleted_count = 0
    while current_size > max_size_bytes:
        # Get the oldest entry
        cursor = storage._conn.execute(
            """
            SELECT id FROM memory_entries
            ORDER BY created_at ASC
            LIMIT 1
            """
        )
        row = cursor.fetchone()
        if row is None:
            break  # No more entries to delete

        storage.delete_entry(row[0])
        deleted_count += 1
        current_size = storage.get_db_size()

    if deleted_count > 0:
        logger.info(
            "Pruned %d entries to reduce size below %d MB",
            deleted_count,
            max_size_mb,
        )
    return deleted_count


def run_pruning(storage: MemoryStorage, config: MemoryConfig) -> dict[str, int]:
    """Run both time-based and size-based pruning.

    Executes prune_expired first, then prune_oversized.

    Args:
        storage: The MemoryStorage instance to prune.
        config: Configuration with retention_days and max_size_mb.

    Returns:
        Dictionary with counts: {"expired": N, "oversized": M}.
    """
    expired_count = prune_expired(storage, config.retention_days)
    oversized_count = prune_oversized(storage, config.max_size_mb)

    return {"expired": expired_count, "oversized": oversized_count}
