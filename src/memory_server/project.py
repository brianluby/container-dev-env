"""T013/T052: Project ID hashing and path scoping for the persistent memory system.

Provides deterministic project identification by generating a 16-character
hexadecimal identifier from a workspace path. The identifier is derived from
a SHA-256 hash of the canonical absolute path (symlinks resolved, normalized,
trailing slashes removed).

Also provides scoped database path resolution for per-project isolation.
"""

from __future__ import annotations

import hashlib
from pathlib import Path


def generate_project_id(workspace_path: str) -> str:
    """Generate a deterministic 16-character hex project ID from a workspace path.

    The path is first resolved to its canonical absolute form:
    - Symlinks are resolved to their real targets
    - Relative components (../, ./) are normalized
    - Trailing slashes are removed
    - The resulting canonical path is encoded as UTF-8 bytes

    A SHA-256 hash is computed over the canonical path bytes, and the first
    16 hex characters of the digest are returned as the project ID.

    Args:
        workspace_path: The workspace directory path (absolute or relative,
            may contain symlinks, trailing slashes, or relative components).

    Returns:
        A 16-character lowercase hexadecimal string uniquely identifying the project.

    Examples:
        >>> generate_project_id("/home/user/project")
        'a1b2c3d4e5f67890'  # example output
        >>> generate_project_id("/home/user/project/")  # same as above
        'a1b2c3d4e5f67890'
    """
    canonical = _canonicalize_path(workspace_path)
    digest = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    return digest[:16]


def get_db_path(base_path: str, project_id: str) -> str:
    """Resolve the scoped database file path for a project.

    Returns a path under base_path/projects/<project_id>/memory.db.
    Creates the parent directories on first use.

    Args:
        base_path: Base directory for all memory databases.
        project_id: The 16-character hex project identifier.

    Returns:
        Absolute path string to the project's SQLite database file.

    Examples:
        >>> get_db_path("/data/memory", "a1b2c3d4e5f67890")
        '/data/memory/projects/a1b2c3d4e5f67890/memory.db'
    """
    db_file = Path(base_path) / "projects" / project_id / "memory.db"
    db_file.parent.mkdir(parents=True, exist_ok=True)
    return str(db_file)


def _canonicalize_path(workspace_path: str) -> str:
    """Resolve a workspace path to its canonical absolute form.

    Handles symlink resolution, relative component normalization,
    and trailing slash removal.

    Args:
        workspace_path: Raw workspace path string.

    Returns:
        The canonical absolute path as a string.
    """
    # Strip trailing slashes before resolution to handle edge cases like "///"
    stripped = workspace_path.rstrip("/")
    # Preserve root path which would become empty string after stripping
    if not stripped:
        stripped = "/"
    # Path.resolve() handles symlinks, .., and . components, and makes absolute
    resolved = Path(stripped).resolve()
    return str(resolved)
