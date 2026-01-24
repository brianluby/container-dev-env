"""T020/T021: Tests for strategic memory initialization logic.

Tests validate template creation, idempotency behavior, --force override,
and .gitignore generation for the memory-init CLI.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from memory_init.init import init_memory

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def workspace(tmp_path: Path) -> Path:
    """Provide a temporary workspace directory."""
    return tmp_path / "project"


@pytest.fixture
def workspace_dir(workspace: Path) -> Path:
    """Provide a temporary workspace directory that already exists."""
    workspace.mkdir(parents=True)
    return workspace


EXPECTED_TEMPLATE_FILES = [
    "goals.md",
    "architecture.md",
    "patterns.md",
    "technology.md",
    "status.md",
]

EXPECTED_ALL_FILES = [*EXPECTED_TEMPLATE_FILES, ".memoryrc", ".gitignore"]


# ---------------------------------------------------------------------------
# Template Creation Tests (T020)
# ---------------------------------------------------------------------------


class TestTemplateCreation:
    """Tests for .memory/ directory and template file creation."""

    def test_creates_memory_directory(self, workspace_dir: Path) -> None:
        """init_memory creates the .memory/ directory in the workspace."""
        init_memory(str(workspace_dir))
        memory_dir = workspace_dir / ".memory"
        assert memory_dir.is_dir()

    def test_creates_all_template_files(self, workspace_dir: Path) -> None:
        """init_memory creates all 5 markdown template files."""
        init_memory(str(workspace_dir))
        memory_dir = workspace_dir / ".memory"
        for filename in EXPECTED_TEMPLATE_FILES:
            filepath = memory_dir / filename
            assert filepath.exists(), f"Missing template file: {filename}"
            assert filepath.stat().st_size > 0, f"Empty template file: {filename}"

    def test_creates_memoryrc(self, workspace_dir: Path) -> None:
        """init_memory creates a .memoryrc configuration file."""
        init_memory(str(workspace_dir))
        memoryrc = workspace_dir / ".memory" / ".memoryrc"
        assert memoryrc.exists()
        content = memoryrc.read_text()
        assert "retention_days:" in content
        assert "max_size_mb:" in content
        assert "excluded_patterns:" in content

    def test_creates_gitignore(self, workspace_dir: Path) -> None:
        """init_memory creates a .gitignore in .memory/."""
        init_memory(str(workspace_dir))
        gitignore = workspace_dir / ".memory" / ".gitignore"
        assert gitignore.exists()

    def test_returns_created_files_list(self, workspace_dir: Path) -> None:
        """init_memory returns a dict with 'created' list of files."""
        result = init_memory(str(workspace_dir))
        assert "created" in result
        assert "skipped" in result
        assert len(result["created"]) == len(EXPECTED_ALL_FILES)
        assert len(result["skipped"]) == 0

    def test_template_files_have_h1_heading(self, workspace_dir: Path) -> None:
        """Each template file starts with an H1 heading."""
        init_memory(str(workspace_dir))
        memory_dir = workspace_dir / ".memory"
        for filename in EXPECTED_TEMPLATE_FILES:
            content = (memory_dir / filename).read_text()
            assert content.startswith("# "), f"{filename} missing H1 heading"

    def test_template_files_have_security_warning(self, workspace_dir: Path) -> None:
        """Each template file contains a security warning comment."""
        init_memory(str(workspace_dir))
        memory_dir = workspace_dir / ".memory"
        for filename in EXPECTED_TEMPLATE_FILES:
            content = (memory_dir / filename).read_text()
            assert "WARNING" in content, f"{filename} missing security warning"
            assert "credentials" in content.lower() or "api keys" in content.lower(), (
                f"{filename} security warning incomplete"
            )

    def test_template_files_have_h2_sections(self, workspace_dir: Path) -> None:
        """Each template file has at least one H2 section."""
        init_memory(str(workspace_dir))
        memory_dir = workspace_dir / ".memory"
        for filename in EXPECTED_TEMPLATE_FILES:
            content = (memory_dir / filename).read_text()
            assert "\n## " in content, f"{filename} missing H2 sections"

    def test_workspace_not_found_raises(self, workspace: Path) -> None:
        """init_memory raises FileNotFoundError for nonexistent workspace."""
        with pytest.raises(FileNotFoundError):
            init_memory(str(workspace))

    def test_workspace_is_file_raises(self, tmp_path: Path) -> None:
        """init_memory raises NotADirectoryError if workspace is a file."""
        file_path = tmp_path / "not_a_dir"
        file_path.write_text("content")
        with pytest.raises(NotADirectoryError):
            init_memory(str(file_path))


# ---------------------------------------------------------------------------
# Idempotency Tests (T020)
# ---------------------------------------------------------------------------


class TestIdempotency:
    """Tests that calling init twice does not overwrite existing files."""

    def test_second_call_skips_existing(self, workspace_dir: Path) -> None:
        """Calling init_memory twice skips files that already exist."""
        init_memory(str(workspace_dir))
        result = init_memory(str(workspace_dir))
        assert len(result["skipped"]) == len(EXPECTED_ALL_FILES)
        assert len(result["created"]) == 0

    def test_existing_content_preserved(self, workspace_dir: Path) -> None:
        """Existing file content is preserved on second call."""
        init_memory(str(workspace_dir))
        goals_file = workspace_dir / ".memory" / "goals.md"
        custom_content = "# My Custom Goals\n\nThis is my content.\n"
        goals_file.write_text(custom_content)

        init_memory(str(workspace_dir))
        assert goals_file.read_text() == custom_content

    def test_partial_init_completes_missing(self, workspace_dir: Path) -> None:
        """If some files exist but others don't, init creates only missing ones."""
        memory_dir = workspace_dir / ".memory"
        memory_dir.mkdir()
        (memory_dir / "goals.md").write_text("# Goals\n")

        result = init_memory(str(workspace_dir))
        assert "goals.md" not in result["created"]
        assert "goals.md" in result["skipped"]
        # Other files should be created
        assert len(result["created"]) == len(EXPECTED_ALL_FILES) - 1


# ---------------------------------------------------------------------------
# Force Override Tests (T020)
# ---------------------------------------------------------------------------


class TestForceOverride:
    """Tests for --force behavior that overwrites existing files."""

    def test_force_overwrites_existing(self, workspace_dir: Path) -> None:
        """With force=True, existing files are overwritten with templates."""
        init_memory(str(workspace_dir))
        goals_file = workspace_dir / ".memory" / "goals.md"
        goals_file.write_text("# Custom\n")

        result = init_memory(str(workspace_dir), force=True)
        assert len(result["created"]) == len(EXPECTED_ALL_FILES)
        assert len(result["skipped"]) == 0

        # Content should be the template, not the custom content
        content = goals_file.read_text()
        assert content != "# Custom\n"
        assert content.startswith("# ")

    def test_force_returns_all_as_created(self, workspace_dir: Path) -> None:
        """With force=True, all files appear in the 'created' list."""
        init_memory(str(workspace_dir))
        result = init_memory(str(workspace_dir), force=True)
        assert len(result["created"]) == len(EXPECTED_ALL_FILES)


# ---------------------------------------------------------------------------
# .gitignore Generation Tests (T021)
# ---------------------------------------------------------------------------


class TestGitignoreGeneration:
    """Tests for .memory/.gitignore content."""

    def test_gitignore_contains_md_inclusion(self, workspace_dir: Path) -> None:
        """Generated .gitignore includes !*.md to track markdown files."""
        init_memory(str(workspace_dir))
        gitignore = workspace_dir / ".memory" / ".gitignore"
        content = gitignore.read_text()
        assert "!*.md" in content

    def test_gitignore_contains_memoryrc_inclusion(self, workspace_dir: Path) -> None:
        """Generated .gitignore includes !.memoryrc to track config."""
        init_memory(str(workspace_dir))
        gitignore = workspace_dir / ".memory" / ".gitignore"
        content = gitignore.read_text()
        assert "!.memoryrc" in content

    def test_gitignore_excludes_db_files(self, workspace_dir: Path) -> None:
        """Generated .gitignore excludes *.db, *.db-wal, *.db-shm."""
        init_memory(str(workspace_dir))
        gitignore = workspace_dir / ".memory" / ".gitignore"
        content = gitignore.read_text()
        assert "*.db" in content
        assert "*.db-wal" in content
        assert "*.db-shm" in content

    def test_gitignore_has_comments(self, workspace_dir: Path) -> None:
        """Generated .gitignore has explanatory comments."""
        init_memory(str(workspace_dir))
        gitignore = workspace_dir / ".memory" / ".gitignore"
        content = gitignore.read_text()
        # Should have at least one comment line
        comment_lines = [line for line in content.splitlines() if line.startswith("#")]
        assert len(comment_lines) >= 1


# ---------------------------------------------------------------------------
# .memoryrc Content Tests
# ---------------------------------------------------------------------------


class TestMemoryrcContent:
    """Tests for .memoryrc default configuration values."""

    def test_memoryrc_retention_days(self, workspace_dir: Path) -> None:
        """Default retention_days is 30."""
        init_memory(str(workspace_dir))
        memoryrc = workspace_dir / ".memory" / ".memoryrc"
        content = memoryrc.read_text()
        assert "retention_days: 30" in content

    def test_memoryrc_max_size(self, workspace_dir: Path) -> None:
        """Default max_size_mb is 500."""
        init_memory(str(workspace_dir))
        memoryrc = workspace_dir / ".memory" / ".memoryrc"
        content = memoryrc.read_text()
        assert "max_size_mb: 500" in content

    def test_memoryrc_excluded_patterns(self, workspace_dir: Path) -> None:
        """Excluded patterns cover common secret file patterns."""
        init_memory(str(workspace_dir))
        memoryrc = workspace_dir / ".memory" / ".memoryrc"
        content = memoryrc.read_text()
        expected_patterns = ["*.key", "*.pem", "*password*", "*secret*", "*token*"]
        for pattern in expected_patterns:
            assert pattern in content, f"Missing excluded pattern: {pattern}"
