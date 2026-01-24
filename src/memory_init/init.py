"""T027: Strategic memory initialization logic.

Provides the init_memory function that creates the .memory/ directory
structure with template files, .memoryrc configuration, and .gitignore.
"""

from __future__ import annotations

import shutil
from pathlib import Path

# Template files shipped with the package
_TEMPLATES_DIR = Path(__file__).parent / "templates"

# Names of template markdown files to copy
TEMPLATE_FILES = [
    "goals.md",
    "architecture.md",
    "patterns.md",
    "technology.md",
    "status.md",
]

# Default .memoryrc content (YAML format)
_MEMORYRC_CONTENT = """\
retention_days: 30
max_size_mb: 500
excluded_patterns:
  - "*.key"
  - "*.pem"
  - "*password*"
  - "*secret*"
  - "*token*"
"""

# Default .memory/.gitignore content
_GITIGNORE_CONTENT = """\
# Strategic memory files are version-controlled
!*.md
!.memoryrc

# Tactical memory excluded from version control
*.db
*.db-wal
*.db-shm
"""


def init_memory(workspace: str, force: bool = False) -> dict[str, list[str]]:
    """Initialize the .memory/ directory with template files.

    Creates the .memory/ directory in the given workspace, copies template
    markdown files, generates a .memoryrc configuration file, and creates
    a .gitignore for the directory.

    Args:
        workspace: Path to the target workspace directory.
        force: If True, overwrite existing files. If False (default),
               skip files that already exist.

    Returns:
        A dict with two keys:
            - "created": list of filenames that were created
            - "skipped": list of filenames that were skipped (already existed)

    Raises:
        FileNotFoundError: If the workspace path does not exist.
        NotADirectoryError: If the workspace path is not a directory.
        PermissionError: If the workspace is not writable.
    """
    workspace_path = Path(workspace)

    if not workspace_path.exists():
        msg = f"Workspace path does not exist: {workspace}"
        raise FileNotFoundError(msg)

    if not workspace_path.is_dir():
        msg = f"Workspace path is not a directory: {workspace}"
        raise NotADirectoryError(msg)

    memory_dir = workspace_path / ".memory"
    memory_dir.mkdir(exist_ok=True)

    created: list[str] = []
    skipped: list[str] = []

    # Copy template markdown files
    for filename in TEMPLATE_FILES:
        dest = memory_dir / filename
        if dest.exists() and not force:
            skipped.append(filename)
        else:
            source = _TEMPLATES_DIR / filename
            shutil.copy2(str(source), str(dest))
            created.append(filename)

    # Generate .memoryrc
    memoryrc_dest = memory_dir / ".memoryrc"
    if memoryrc_dest.exists() and not force:
        skipped.append(".memoryrc")
    else:
        memoryrc_dest.write_text(_MEMORYRC_CONTENT)
        created.append(".memoryrc")

    # Generate .gitignore
    gitignore_dest = memory_dir / ".gitignore"
    if gitignore_dest.exists() and not force:
        skipped.append(".gitignore")
    else:
        gitignore_dest.write_text(_GITIGNORE_CONTENT)
        created.append(".gitignore")

    return {"created": created, "skipped": skipped}
