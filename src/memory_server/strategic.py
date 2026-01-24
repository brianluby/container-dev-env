"""T032: Strategic memory loader for the persistent memory system.

Loads strategic memory content from .memory/*.md files in a workspace
directory. These files contain project-level context (goals, architecture,
patterns, technology choices, current status) that AI tools should load
at session start for context continuity.
"""

from __future__ import annotations

from pathlib import Path

from memory_server import logger

# Size threshold for warning log (500KB per T066 requirement)
_SIZE_WARNING_THRESHOLD_BYTES = 500 * 1024


def load_strategic_memory(workspace_path: str) -> str:
    """Load and concatenate all .memory/*.md files from the workspace.

    Scans the .memory/ directory in the given workspace for Markdown files,
    reads each file, and concatenates them with section headers into a single
    string suitable for injection into AI tool context windows.

    Only top-level .md files in .memory/ are included; subdirectories,
    dotfiles, and non-.md files are ignored.

    Args:
        workspace_path: Path to the workspace directory containing .memory/.

    Returns:
        Combined content of all .md files as a single string with section
        headers, or an empty string if .memory/ does not exist or contains
        no .md files.
    """
    memory_dir = Path(workspace_path) / ".memory"

    if not memory_dir.is_dir():
        logger.debug("No .memory/ directory found at: %s", workspace_path)
        return ""

    # Collect only top-level .md files (no recursion, no dotfiles)
    md_files = sorted(
        f
        for f in memory_dir.iterdir()
        if f.is_file() and f.suffix == ".md" and not f.name.startswith(".")
    )

    if not md_files:
        logger.debug("No .md files found in .memory/ at: %s", workspace_path)
        return ""

    sections: list[str] = []
    for md_file in md_files:
        content = md_file.read_text(encoding="utf-8")
        header = f"--- {md_file.name} ---"
        sections.append(f"{header}\n{content}")

    combined = "\n\n".join(sections)

    # Warn if total size exceeds threshold (T066)
    total_size = len(combined.encode("utf-8"))
    if total_size > _SIZE_WARNING_THRESHOLD_BYTES:
        logger.warning(
            "Strategic memory size (%d bytes) exceeds 500KB threshold. "
            "Consider trimming .memory/ files to reduce context window usage.",
            total_size,
        )

    logger.info(
        "Loaded strategic memory: %d files, %d bytes from %s",
        len(md_files),
        total_size,
        workspace_path,
    )
    return combined
