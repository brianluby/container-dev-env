"""T017/T033/T041/T047/T048/T059/T060/T062: MCP server for the persistent memory system.

Defines the FastMCP server instance with:
- 5 MCP tools for tactical memory operations
- 1 MCP resource for strategic memory (memory://strategic)
- Background pruning task for retention management

Tools:
- store_memory: Store a new memory entry with automatic embedding generation.
- search_memories: Semantic search across tactical memory.
- list_memories: List recent memory entries.
- delete_memory: Delete a specific entry by ID.
- get_memory_stats: Get storage statistics.

Resources:
- memory://strategic: Returns concatenated .memory/*.md content from workspace.
"""

from __future__ import annotations

import asyncio
import os
import uuid
from datetime import UTC, datetime
from typing import Any

from mcp.server.fastmcp import FastMCP

from memory_server import logger
from memory_server.config import MemoryConfig
from memory_server.embeddings import EmbeddingService
from memory_server.retention import run_pruning
from memory_server.session import generate_session_id, get_source_tool
from memory_server.storage import MemoryStorage
from memory_server.strategic import load_strategic_memory

# ---------------------------------------------------------------------------
# Allowed values for validation
# ---------------------------------------------------------------------------

_ALLOWED_ENTRY_TYPES = {"decision", "pattern", "observation", "error", "context"}
_MAX_CONTENT_LENGTH = 10000
_MAX_TAGS = 10

# ---------------------------------------------------------------------------
# FastMCP server instance
# ---------------------------------------------------------------------------

mcp = FastMCP("memory")

logger.info("MCP server 'memory' instance created")

# ---------------------------------------------------------------------------
# Server state (initialized by __main__.py via init_server)
# ---------------------------------------------------------------------------

_storage: MemoryStorage | None = None
_embedding_service: EmbeddingService | None = None
_project_id: str = ""
_session_id: str = ""
_source_tool: str = "unknown"
_config: MemoryConfig | None = None
_pruning_task: asyncio.Task[None] | None = None


def init_server(
    storage: MemoryStorage,
    embedding_service: EmbeddingService | None,
    project_id: str,
    config: MemoryConfig,
) -> None:
    """Initialize server state with storage and embedding dependencies.

    Called from __main__.py after parsing configuration and constructing
    the storage and embedding service instances.

    Args:
        storage: Initialized MemoryStorage instance.
        embedding_service: Initialized EmbeddingService, or None if unavailable.
        project_id: The resolved project identifier.
        config: The loaded MemoryConfig.
    """
    global _storage, _embedding_service, _project_id, _session_id, _source_tool, _config
    _storage = storage
    _embedding_service = embedding_service
    _project_id = project_id
    _session_id = generate_session_id()
    _source_tool = get_source_tool()
    _config = config
    logger.info(
        "Server initialized: project_id=%s, session_id=%s, source_tool=%s",
        _project_id,
        _session_id,
        _source_tool,
    )


def start_background_pruning() -> None:
    """Start the background pruning task that runs every 6 hours.

    The task calls run_pruning() on the configured storage and config.
    Safe to call multiple times; only starts one task.
    """
    global _pruning_task
    if _pruning_task is not None:
        return

    async def _pruning_loop() -> None:
        while True:
            await asyncio.sleep(6 * 60 * 60)  # 6 hours
            if _storage is not None and _config is not None:
                try:
                    result = run_pruning(_storage, _config)
                    logger.info("Background pruning completed: %s", result)
                except Exception:
                    logger.exception("Background pruning failed")

    try:
        loop = asyncio.get_event_loop()
        _pruning_task = loop.create_task(_pruning_loop())
        logger.info("Background pruning task started (interval: 6 hours)")
    except RuntimeError:
        logger.warning("No event loop available; background pruning not started")


# ---------------------------------------------------------------------------
# Resource definitions
# ---------------------------------------------------------------------------


@mcp.resource("memory://strategic")
def get_strategic_memory() -> str:
    """Return strategic memory content from .memory/*.md files in the workspace.

    Reads the MEMORY_WORKSPACE environment variable to locate the workspace
    directory, then loads and concatenates all .md files from the .memory/
    subdirectory. Returns empty string if no strategic memory is configured.

    Returns:
        Concatenated Markdown content from all .memory/*.md files, or empty
        string if the workspace has no strategic memory files.
    """
    workspace = os.environ.get("MEMORY_WORKSPACE", "")
    if not workspace:
        logger.warning("MEMORY_WORKSPACE not set; strategic memory unavailable")
        return ""
    return load_strategic_memory(workspace)


# ---------------------------------------------------------------------------
# Tool definitions
# ---------------------------------------------------------------------------


@mcp.tool()
async def store_memory(
    content: str,
    entry_type: str,
    tags: list[str] | None = None,
) -> dict[str, str]:
    """Store a new memory entry with automatic embedding generation.

    Use this to capture decisions, patterns, observations, or errors
    from the current session.

    Args:
        content: The context to remember (max 10,000 characters).
        entry_type: Category of the memory entry. One of:
            "decision", "pattern", "observation", "error", "context".
        tags: Optional tags for organization (max 10 items).

    Returns:
        Dictionary with keys: id, status, message.
    """
    logger.debug("store_memory called: entry_type=%s, tags=%s", entry_type, tags)

    # --- Validate inputs ---
    if not content or not content.strip():
        return {"id": "", "status": "error", "message": "Content must not be empty"}

    if len(content) > _MAX_CONTENT_LENGTH:
        return {
            "id": "",
            "status": "error",
            "message": f"Content exceeds maximum length of {_MAX_CONTENT_LENGTH} characters",
        }

    if entry_type not in _ALLOWED_ENTRY_TYPES:
        return {
            "id": "",
            "status": "error",
            "message": f"Invalid entry_type: {entry_type!r}. "
            f"Must be one of: {', '.join(sorted(_ALLOWED_ENTRY_TYPES))}",
        }

    if tags is not None and len(tags) > _MAX_TAGS:
        return {
            "id": "",
            "status": "error",
            "message": f"Too many tags: {len(tags)} (maximum {_MAX_TAGS})",
        }

    # --- Check storage availability ---
    if _storage is None:
        logger.warning("Storage not initialized; cannot store memory")
        return {"id": "", "status": "error", "message": "Storage not available"}

    # --- Generate entry ---
    entry_id = str(uuid.uuid4())
    entry: dict[str, Any] = {
        "id": entry_id,
        "project_id": _project_id,
        "content": content.strip(),
        "source_tool": _source_tool,
        "session_id": _session_id,
        "entry_type": entry_type,
        "tags": tags,
        "created_at": datetime.now(tz=UTC).isoformat(),
        "accessed_at": None,
    }

    # --- Store entry ---
    try:
        _storage.insert_entry(entry)
    except Exception:
        logger.exception("Failed to store memory entry")
        return {"id": "", "status": "error", "message": "Storage write failed"}

    # --- Generate and store embedding (graceful degradation) ---
    if _embedding_service is not None:
        try:
            embedding = _embedding_service.embed_text(content)
            _storage.insert_embedding(entry_id, embedding)
        except Exception:
            # Graceful degradation: store zero vector if embedding fails
            logger.warning(
                "Embedding generation failed; storing zero vector for entry %s", entry_id
            )
            try:
                zero_vector = [0.0] * 384
                _storage.insert_embedding(entry_id, zero_vector)
            except Exception:
                logger.warning("Failed to store zero vector for entry %s", entry_id)
    else:
        # No embedding service; store zero vector
        try:
            zero_vector = [0.0] * 384
            _storage.insert_embedding(entry_id, zero_vector)
        except Exception:
            logger.warning("Failed to store zero vector for entry %s", entry_id)

    return {"id": entry_id, "status": "stored"}


@mcp.tool()
async def search_memories(
    query: str,
    limit: int = 5,
    entry_type: str | None = None,
    min_score: float = 0.3,
) -> dict[str, list[dict[str, object]] | int]:
    """Semantic search across tactical memory.

    Returns entries ranked by relevance to the query, using vector similarity.

    Args:
        query: Natural language search query.
        limit: Maximum results to return (1-50, default: 5).
        entry_type: Filter by entry type (optional). One of:
            "decision", "pattern", "observation", "error", "context".
        min_score: Minimum similarity score threshold (0.0-1.0, default: 0.3).

    Returns:
        Dictionary with keys: results (list of matching entries), total_matches (int).
    """
    logger.debug(
        "search_memories called: query=%r, limit=%d, entry_type=%s, min_score=%.2f",
        query,
        limit,
        entry_type,
        min_score,
    )

    if _storage is None:
        return {"results": [], "total_matches": 0}

    if _embedding_service is None:
        logger.warning("Embedding service not available; search will return empty results")
        return {"results": [], "total_matches": 0}

    # Clamp limit to valid range
    limit = max(1, min(50, limit))
    min_score = max(0.0, min(1.0, min_score))

    # Generate query embedding
    try:
        query_embedding = _embedding_service.embed_text(query)
    except Exception:
        logger.exception("Failed to generate query embedding")
        return {"results": [], "total_matches": 0}

    # Search for similar entries (fetch more than limit to allow for filtering)
    similar = _storage.search_similar(query_embedding, limit=limit * 2, min_score=min_score)

    # Fetch full entries and filter by project_id and entry_type
    results: list[dict[str, object]] = []
    for match in similar:
        entry = _storage.get_entry(match["entry_id"])
        if entry is None:
            continue
        if entry["project_id"] != _project_id:
            continue
        if entry_type is not None and entry["entry_type"] != entry_type:
            continue

        results.append(
            {
                "id": entry["id"],
                "content": entry["content"],
                "entry_type": entry["entry_type"],
                "score": match["score"],
                "source_tool": entry["source_tool"],
                "created_at": entry["created_at"],
                "tags": entry.get("tags"),
            }
        )

        if len(results) >= limit:
            break

    return {"results": results, "total_matches": len(results)}


@mcp.tool()
async def list_memories(
    limit: int = 10,
    entry_type: str | None = None,
    offset: int = 0,
) -> dict[str, list[dict[str, object]] | int | bool]:
    """List recent memory entries, optionally filtered by type.

    Returns entries in reverse chronological order.

    Args:
        limit: Maximum entries to return (1-100, default: 10).
        entry_type: Filter by entry type (optional). One of:
            "decision", "pattern", "observation", "error", "context".
        offset: Skip first N entries for pagination (default: 0).

    Returns:
        Dictionary with keys: entries (list), total_count (int), has_more (bool).
    """
    logger.debug(
        "list_memories called: limit=%d, entry_type=%s, offset=%d",
        limit,
        entry_type,
        offset,
    )

    if _storage is None:
        return {"entries": [], "total_count": 0, "has_more": False}

    # Clamp limit to valid range
    limit = max(1, min(100, limit))
    offset = max(0, offset)

    # Get total count for pagination
    total_count = _storage.count_entries(_project_id, entry_type=entry_type)

    # Fetch entries
    entries = _storage.list_entries(
        project_id=_project_id,
        entry_type=entry_type,
        limit=limit,
        offset=offset,
    )

    # Format entries for output
    formatted: list[dict[str, object]] = []
    for entry in entries:
        formatted.append(
            {
                "id": entry["id"],
                "content": entry["content"],
                "entry_type": entry["entry_type"],
                "source_tool": entry["source_tool"],
                "session_id": entry["session_id"],
                "created_at": entry["created_at"],
                "tags": entry.get("tags"),
            }
        )

    has_more = (offset + limit) < total_count

    return {"entries": formatted, "total_count": total_count, "has_more": has_more}


@mcp.tool()
async def delete_memory(entry_id: str) -> dict[str, str]:
    """Delete a specific memory entry by ID.

    Use this to remove accidentally captured sensitive information
    or irrelevant entries.

    Args:
        entry_id: The unique ID of the memory entry to delete.

    Returns:
        Dictionary with keys: status, message.
    """
    logger.debug("delete_memory called: id=%s", entry_id)

    if _storage is None:
        return {"status": "error", "message": "Storage not available"}

    deleted = _storage.delete_entry(entry_id)
    if deleted:
        return {"status": "deleted", "message": f"Entry {entry_id} deleted successfully"}
    return {"status": "not_found", "message": f"Entry {entry_id} not found"}


@mcp.tool()
async def get_memory_stats() -> dict[str, object]:
    """Get statistics about the memory system for the current project.

    Includes entry counts, storage usage, and retention info.

    Returns:
        Dictionary with keys: project_id, total_entries, storage_size_mb,
        oldest_entry, newest_entry, entries_by_type, entries_by_tool,
        retention_config.
    """
    logger.debug("get_memory_stats called")

    if _storage is None:
        return {
            "project_id": _project_id,
            "total_entries": 0,
            "storage_size_mb": 0.0,
            "oldest_entry": None,
            "newest_entry": None,
            "entries_by_type": {},
            "entries_by_tool": {},
            "retention_config": {},
        }

    stats = _storage.get_stats(_project_id)
    db_size_bytes = _storage.get_db_size()
    storage_size_mb = round(db_size_bytes / (1024 * 1024), 3)

    retention_config: dict[str, object] = {}
    if _config is not None:
        retention_config = {
            "retention_days": _config.retention_days,
            "max_size_mb": _config.max_size_mb,
        }

    return {
        "project_id": _project_id,
        "total_entries": stats["total_entries"],
        "storage_size_mb": storage_size_mb,
        "oldest_entry": stats["oldest_entry"],
        "newest_entry": stats["newest_entry"],
        "entries_by_type": stats["entries_by_type"],
        "entries_by_tool": stats["entries_by_tool"],
        "retention_config": retention_config,
    }
