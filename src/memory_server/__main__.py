"""T018/T054/T061: Entry point for the persistent memory MCP server.

Reads configuration from environment variables, sets up logging,
initializes storage with project-scoped database path, runs initial
pruning, and starts the MCP server over stdio transport.

Usage:
    python -m memory_server

Environment variables:
    MEMORY_DB_PATH: Base path for SQLite database files.
    MEMORY_WORKSPACE: Path to the workspace root for project identification.
    MEMORY_SOURCE_TOOL: Source tool identifier (e.g., "claude-code", "opencode").
    MEMORY_LOG_LEVEL: Logging level (DEBUG, INFO, WARNING, ERROR). Default: INFO.
    MEMORY_RETENTION_DAYS: Number of days to retain entries (1-365). Default: 30.
    MEMORY_MAX_SIZE_MB: Maximum database size in MB (50-2000). Default: 500.
"""

from __future__ import annotations

import logging
import os
import sys

from memory_server import logger, set_log_context
from memory_server.config import MemoryConfig
from memory_server.project import generate_project_id, get_db_path
from memory_server.retention import run_pruning
from memory_server.server import init_server, mcp
from memory_server.storage import MemoryStorage


def _parse_env_int(name: str, default: int) -> int:
    """Parse an integer from an environment variable with a fallback default.

    Args:
        name: Environment variable name.
        default: Default value if the variable is unset or empty.

    Returns:
        Parsed integer value.

    Raises:
        SystemExit: If the value is present but not a valid integer.
    """
    raw = os.environ.get(name, "").strip()
    if not raw:
        return default
    try:
        return int(raw)
    except ValueError:
        logger.error("Invalid value for %s: %r (expected integer)", name, raw)
        sys.exit(1)


def _resolve_log_level(level_str: str) -> int:
    """Resolve a log level string to the corresponding logging constant.

    Args:
        level_str: Case-insensitive log level name (e.g., "DEBUG", "info").

    Returns:
        Numeric logging level.

    Raises:
        SystemExit: If the level string is not a recognized log level.
    """
    numeric_level = logging.getLevelName(level_str.upper())
    if not isinstance(numeric_level, int):
        logger.error("Invalid MEMORY_LOG_LEVEL: %r", level_str)
        sys.exit(1)
    return numeric_level


def main() -> None:
    """Parse environment, configure logging, and start the MCP server."""
    # -----------------------------------------------------------------------
    # Read environment variables
    # -----------------------------------------------------------------------
    db_base_path = os.environ.get("MEMORY_DB_PATH", "")
    workspace = os.environ.get("MEMORY_WORKSPACE", "")
    log_level_str = os.environ.get("MEMORY_LOG_LEVEL", "INFO")
    retention_days = _parse_env_int("MEMORY_RETENTION_DAYS", 30)
    max_size_mb = _parse_env_int("MEMORY_MAX_SIZE_MB", 500)

    # -----------------------------------------------------------------------
    # Configure logging (all output to stderr; stdout is MCP JSON-RPC)
    # -----------------------------------------------------------------------
    log_level = _resolve_log_level(log_level_str)
    logger.setLevel(log_level)

    logger.info("Starting memory MCP server")

    # -----------------------------------------------------------------------
    # Resolve workspace and project ID
    # -----------------------------------------------------------------------
    if not workspace:
        workspace = os.getcwd()
        logger.info("MEMORY_WORKSPACE not set; using cwd: %s", workspace)

    project_id = generate_project_id(workspace)
    set_log_context(project_id=project_id)
    logger.info("Resolved project_id=%s from workspace=%s", project_id, workspace)

    # -----------------------------------------------------------------------
    # Resolve database path (scoped by project)
    # -----------------------------------------------------------------------
    if not db_base_path:
        db_base_path = os.path.join(
            os.environ.get("HOME", "/tmp"),
            ".local",
            "share",
            "memory-server",
        )
        logger.info("MEMORY_DB_PATH not set; using default: %s", db_base_path)

    db_path = get_db_path(db_base_path, project_id)
    logger.info("Database path: %s", db_path)

    # -----------------------------------------------------------------------
    # T065: Verify volume is mounted / path is writable
    # -----------------------------------------------------------------------
    db_dir = os.path.dirname(db_path)
    os.makedirs(db_dir, exist_ok=True)
    _probe_file = os.path.join(db_dir, ".write_probe")
    try:
        with open(_probe_file, "w") as f:
            f.write("probe")
        os.remove(_probe_file)
    except OSError as exc:
        logger.error(
            "Cannot write to database directory: %s. "
            "Ensure the persistent volume is mounted correctly. "
            "Setup: docker run -v memory-data:%s ... (error: %s)",
            db_dir,
            db_base_path,
            exc,
        )
        sys.exit(1)

    # -----------------------------------------------------------------------
    # Build configuration
    # -----------------------------------------------------------------------
    config = MemoryConfig(
        retention_days=retention_days,
        max_size_mb=max_size_mb,
        log_level=log_level_str,
        workspace_path=workspace,
    )
    logger.info(
        "Configuration: retention_days=%d, max_size_mb=%d",
        config.retention_days,
        config.max_size_mb,
    )

    # -----------------------------------------------------------------------
    # Initialize storage
    # -----------------------------------------------------------------------
    storage = MemoryStorage(db_path)
    logger.info("Storage initialized at %s", db_path)

    # -----------------------------------------------------------------------
    # Initialize embeddings (graceful degradation if unavailable)
    # -----------------------------------------------------------------------
    embedding_service = None
    try:
        from memory_server.embeddings import EmbeddingService

        embedding_service = EmbeddingService()
        logger.info("Embedding service initialized")
    except Exception:
        logger.warning("Embedding service unavailable; semantic search will be disabled")

    # -----------------------------------------------------------------------
    # Initialize server state
    # -----------------------------------------------------------------------
    init_server(storage, embedding_service, project_id, config)

    # Update log context with session_id after server init
    from memory_server.server import _session_id

    set_log_context(project_id=project_id, session_id=_session_id)

    # -----------------------------------------------------------------------
    # Run initial pruning
    # -----------------------------------------------------------------------
    try:
        result = run_pruning(storage, config)
        if result["expired"] > 0 or result["oversized"] > 0:
            logger.info("Initial pruning: %s", result)
    except Exception:
        logger.warning("Initial pruning failed; continuing startup")

    # -----------------------------------------------------------------------
    # Start MCP server on stdio transport
    # -----------------------------------------------------------------------
    logger.info("Starting MCP stdio transport")
    mcp.run(transport="stdio")


if __name__ == "__main__":
    main()
