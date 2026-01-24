"""T042: Session management for the persistent memory system.

Provides session ID generation and source tool detection for
associating memory entries with their capture context.
"""

from __future__ import annotations

import os
import uuid


def generate_session_id() -> str:
    """Generate a new UUID4 session identifier.

    Returns:
        A string representation of a UUID4, suitable for grouping
        memory entries captured in the same session.
    """
    return str(uuid.uuid4())


def get_source_tool() -> str:
    """Read the source tool identifier from the environment.

    Reads the MEMORY_SOURCE_TOOL environment variable. Falls back to
    "unknown" if unset or empty.

    Returns:
        One of the allowed source tool identifiers, or "unknown" as default.
    """
    value = os.environ.get("MEMORY_SOURCE_TOOL", "").strip()
    if not value:
        return "unknown"
    return value
