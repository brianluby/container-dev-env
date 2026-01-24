"""T012: Pydantic v2 models for the persistent memory system.

Defines validated data structures for memory entries, project configuration,
search results, and runtime statistics. All models enforce strict constraints
matching the SQLite schema and MCP tool specifications.
"""

from __future__ import annotations

import re
import uuid as _uuid
from typing import Annotated, Literal

from pydantic import BaseModel, Field, field_validator

# ---------------------------------------------------------------------------
# Shared types
# ---------------------------------------------------------------------------

SourceTool = Literal["claude-code", "cline", "continue", "opencode", "unknown"]
EntryType = Literal["decision", "pattern", "observation", "error", "context"]

# Annotated field types for reuse
ProjectId = Annotated[str, Field(description="16 hex character project identifier")]

# ISO 8601 pattern: basic validation for datetime strings
_ISO8601_PATTERN = re.compile(
    r"^\d{4}-\d{2}-\d{2}"  # date portion
    r"[T ]"  # separator
    r"\d{2}:\d{2}:\d{2}"  # time portion
)


def _validate_iso8601(value: str) -> str:
    """Validate that a string looks like an ISO 8601 datetime."""
    if not _ISO8601_PATTERN.match(value):
        msg = f"Value must be a valid ISO 8601 datetime string, got: {value!r}"
        raise ValueError(msg)
    return value


def _validate_project_id(value: str) -> str:
    """Validate that a project_id is exactly 16 hex characters."""
    if not re.fullmatch(r"[0-9a-fA-F]{16}", value):
        msg = f"project_id must be exactly 16 hexadecimal characters, got: {value!r}"
        raise ValueError(msg)
    return value


def _validate_uuid(value: str) -> str:
    """Validate that a string is a well-formed UUID."""
    try:
        _uuid.UUID(value)
    except (ValueError, AttributeError) as exc:
        msg = f"id must be a valid UUID string, got: {value!r}"
        raise ValueError(msg) from exc
    return value


# ---------------------------------------------------------------------------
# MemoryEntry
# ---------------------------------------------------------------------------


class MemoryEntry(BaseModel):
    """A single tactical memory entry captured from an AI coding session.

    Represents the core unit of automatically captured session context,
    stored in SQLite with an associated vector embedding for semantic search.
    """

    id: str = Field(description="Unique entry identifier (UUID format)")
    project_id: ProjectId
    content: str = Field(min_length=1, max_length=10000, description="Captured context text")
    source_tool: SourceTool = Field(description="AI tool that captured this entry")
    session_id: str = Field(description="Session identifier for grouping")
    entry_type: EntryType = Field(description="Category of the memory entry")
    tags: list[str] | None = Field(default=None, description="User-defined tags")
    created_at: str = Field(description="Capture timestamp (ISO 8601)")
    accessed_at: str | None = Field(default=None, description="Last retrieval timestamp (ISO 8601)")

    @field_validator("id")
    @classmethod
    def _validate_id(cls, value: str) -> str:
        return _validate_uuid(value)

    @field_validator("project_id")
    @classmethod
    def _validate_project_id(cls, value: str) -> str:
        return _validate_project_id(value)

    @field_validator("created_at")
    @classmethod
    def _validate_created_at(cls, value: str) -> str:
        return _validate_iso8601(value)

    @field_validator("accessed_at")
    @classmethod
    def _validate_accessed_at(cls, value: str | None) -> str | None:
        if value is not None:
            return _validate_iso8601(value)
        return value


# ---------------------------------------------------------------------------
# ProjectConfig
# ---------------------------------------------------------------------------


class ProjectConfig(BaseModel):
    """Per-project configuration for memory retention and storage limits.

    Controls how long entries are kept and the maximum database size
    for a specific workspace.
    """

    project_id: ProjectId
    workspace_path: str = Field(description="Canonical absolute workspace path")
    retention_days: int = Field(
        default=30,
        ge=1,
        le=365,
        description="Time-based retention threshold in days",
    )
    max_size_mb: int = Field(
        default=500,
        ge=50,
        le=2000,
        description="Size-based retention threshold in megabytes",
    )
    created_at: str = Field(description="First initialization timestamp (ISO 8601)")
    last_pruned_at: str | None = Field(
        default=None, description="Last pruning operation timestamp (ISO 8601)"
    )

    @field_validator("project_id")
    @classmethod
    def _validate_project_id(cls, value: str) -> str:
        return _validate_project_id(value)

    @field_validator("workspace_path")
    @classmethod
    def _validate_workspace_path(cls, value: str) -> str:
        if not value.startswith("/"):
            msg = f"workspace_path must be an absolute path, got: {value!r}"
            raise ValueError(msg)
        return value

    @field_validator("created_at")
    @classmethod
    def _validate_created_at(cls, value: str) -> str:
        return _validate_iso8601(value)

    @field_validator("last_pruned_at")
    @classmethod
    def _validate_last_pruned_at(cls, value: str | None) -> str | None:
        if value is not None:
            return _validate_iso8601(value)
        return value


# ---------------------------------------------------------------------------
# MemoryStats
# ---------------------------------------------------------------------------


class MemoryStats(BaseModel):
    """Runtime statistics for the memory system, computed on demand.

    Provides an overview of storage usage and entry distribution
    for a specific project.
    """

    project_id: str = Field(description="Project identifier")
    total_entries: int = Field(ge=0, description="Count of memory entries")
    storage_size_bytes: int = Field(ge=0, description="SQLite file size in bytes")
    oldest_entry: str | None = Field(
        default=None, description="Timestamp of oldest entry (ISO 8601)"
    )
    newest_entry: str | None = Field(
        default=None, description="Timestamp of newest entry (ISO 8601)"
    )
    entries_by_type: dict[str, int] = Field(description="Count per entry_type")
    entries_by_tool: dict[str, int] = Field(description="Count per source_tool")


# ---------------------------------------------------------------------------
# SearchResult
# ---------------------------------------------------------------------------


class SearchResult(BaseModel):
    """A single result item returned by semantic search.

    Derived from MemoryEntry with an added relevance score representing
    normalized similarity (0.0 to 1.0, where 1.0 is most similar).
    """

    id: str = Field(description="Entry identifier (UUID format)")
    content: str = Field(description="Memory content text")
    entry_type: EntryType = Field(description="Category of the memory entry")
    score: float = Field(
        ge=0.0,
        le=1.0,
        description="Similarity score (0.0-1.0, normalized from L2 distance)",
    )
    source_tool: str = Field(description="AI tool that captured this entry")
    created_at: str = Field(description="Original capture timestamp (ISO 8601)")
    tags: list[str] | None = Field(default=None, description="User-defined tags")
