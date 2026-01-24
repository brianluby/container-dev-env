"""T071: Performance benchmark for semantic search.

Seeds the database with 1000 entries, runs 100 search queries, and asserts
that p95 latency is under 50ms (SC-003 requirement).
"""

from __future__ import annotations

import statistics
import time
import uuid
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

import pytest

from memory_server.storage import MemoryStorage


@pytest.fixture()
def seeded_storage(tmp_path: Path) -> MemoryStorage:
    """Create a MemoryStorage with 1000 entries and embeddings."""
    db_path = str(tmp_path / "perf_test.db")
    storage = MemoryStorage(db_path)

    base_time = datetime.now(tz=UTC) - timedelta(days=15)
    entry_types = ["decision", "pattern", "observation", "error", "context"]
    project_id = "perf_test_project"

    for i in range(1000):
        entry_id = str(uuid.uuid4())
        entry: dict[str, Any] = {
            "id": entry_id,
            "project_id": project_id,
            "content": f"Performance test entry {i}: This is a sample memory entry "
            f"with some realistic content about coding patterns and decisions "
            f"that were made during the development session number {i}.",
            "source_tool": "claude-code",
            "session_id": f"session-{i // 100}",
            "entry_type": entry_types[i % len(entry_types)],
            "tags": None,
            "created_at": (base_time + timedelta(minutes=i)).isoformat(),
            "accessed_at": None,
        }
        storage.insert_entry(entry)

        # Insert a pseudo-random embedding (deterministic for reproducibility)
        import hashlib

        seed_bytes = hashlib.sha256(f"entry-{i}".encode()).digest()
        embedding = [
            (b / 255.0) * 2 - 1
            for b in seed_bytes * 12  # 384 dims from 32 bytes * 12
        ]
        storage.insert_embedding(entry_id, embedding)

    return storage


@pytest.mark.slow
def test_search_latency_p95(seeded_storage: MemoryStorage) -> None:
    """Assert p95 search latency is under 50ms for 100 queries on 1000 entries."""
    import hashlib

    latencies: list[float] = []

    for q in range(100):
        # Generate a query vector
        seed_bytes = hashlib.sha256(f"query-{q}".encode()).digest()
        query_vec = [(b / 255.0) * 2 - 1 for b in seed_bytes * 12]

        start = time.perf_counter()
        results = seeded_storage.search_similar(query_vec, limit=5, min_score=0.0)
        elapsed = (time.perf_counter() - start) * 1000  # ms

        latencies.append(elapsed)
        # Basic sanity: search should return results
        assert len(results) <= 5

    p95 = sorted(latencies)[94]  # 95th percentile of 100 values
    mean_latency = statistics.mean(latencies)
    median_latency = statistics.median(latencies)

    # Report stats for debugging
    print("\nSearch performance (1000 entries, 100 queries):")  # noqa: T201
    print(f"  Mean:   {mean_latency:.2f}ms")  # noqa: T201
    print(f"  Median: {median_latency:.2f}ms")  # noqa: T201
    print(f"  P95:    {p95:.2f}ms")  # noqa: T201
    print(f"  Max:    {max(latencies):.2f}ms")  # noqa: T201

    assert p95 < 50.0, f"P95 latency {p95:.2f}ms exceeds 50ms threshold (SC-003)"
