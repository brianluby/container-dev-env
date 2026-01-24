"""T030: Integration tests for strategic memory context loading.

Tests that the strategic memory loader correctly detects, reads, and
concatenates .memory/*.md files from a workspace directory.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from memory_server.strategic import load_strategic_memory

# ---------------------------------------------------------------------------
# Detection Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestMemoryDirectoryDetection:
    """Test that .memory/ files are detected when present in workspace."""

    def test_detects_memory_directory_with_md_files(self, tmp_path: Path) -> None:
        """Loader finds .memory/*.md files when present."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        (memory_dir / "goals.md").write_text("# Goals\nBuild something great.")
        (memory_dir / "architecture.md").write_text("# Architecture\nMicroservices.")

        result = load_strategic_memory(str(tmp_path))
        assert "# Goals" in result
        assert "Build something great." in result
        assert "# Architecture" in result
        assert "Microservices." in result

    def test_detects_single_md_file(self, tmp_path: Path) -> None:
        """Loader works with a single .md file in .memory/."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        (memory_dir / "status.md").write_text("# Status\nIn progress.")

        result = load_strategic_memory(str(tmp_path))
        assert "# Status" in result
        assert "In progress." in result

    def test_detects_all_template_files(self, tmp_path: Path) -> None:
        """Loader finds all 5 standard template files."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        template_names = [
            "goals.md",
            "architecture.md",
            "patterns.md",
            "technology.md",
            "status.md",
        ]
        for name in template_names:
            (memory_dir / name).write_text(f"# {name}\nContent for {name}")

        result = load_strategic_memory(str(tmp_path))
        for name in template_names:
            assert f"# {name}" in result
            assert f"Content for {name}" in result


# ---------------------------------------------------------------------------
# Concatenation Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestContentConcatenation:
    """Test that all .md file contents are concatenated and accessible."""

    def test_concatenates_multiple_files(self, tmp_path: Path) -> None:
        """Multiple .md files are joined into a single string."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        (memory_dir / "goals.md").write_text("Goal content here.")
        (memory_dir / "patterns.md").write_text("Pattern content here.")

        result = load_strategic_memory(str(tmp_path))
        assert "Goal content here." in result
        assert "Pattern content here." in result

    def test_includes_section_headers(self, tmp_path: Path) -> None:
        """Each file's content is preceded by a section header."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        (memory_dir / "goals.md").write_text("Goal content.")
        (memory_dir / "architecture.md").write_text("Arch content.")

        result = load_strategic_memory(str(tmp_path))
        # Section headers should include the filename
        assert "goals.md" in result
        assert "architecture.md" in result

    def test_preserves_file_content_exactly(self, tmp_path: Path) -> None:
        """File content is preserved without modification."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        content = "# Goals\n\n## Primary\n- Build the thing\n- Ship it\n\n## Secondary\n- Tests"
        (memory_dir / "goals.md").write_text(content)

        result = load_strategic_memory(str(tmp_path))
        assert content in result

    def test_result_is_string(self, tmp_path: Path) -> None:
        """The return value is always a string."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        (memory_dir / "test.md").write_text("content")

        result = load_strategic_memory(str(tmp_path))
        assert isinstance(result, str)


# ---------------------------------------------------------------------------
# Missing Directory Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestMissingDirectory:
    """Test that missing .memory/ directory doesn't cause errors."""

    def test_returns_empty_string_when_no_memory_dir(self, tmp_path: Path) -> None:
        """No .memory/ directory returns empty string without error."""
        result = load_strategic_memory(str(tmp_path))
        assert result == ""

    def test_no_exception_on_missing_directory(self, tmp_path: Path) -> None:
        """No exception is raised when .memory/ is absent."""
        # Should not raise any exception
        load_strategic_memory(str(tmp_path))

    def test_returns_empty_for_nonexistent_workspace(self, tmp_path: Path) -> None:
        """Nonexistent workspace path returns empty string."""
        nonexistent = tmp_path / "does_not_exist"
        result = load_strategic_memory(str(nonexistent))
        assert result == ""

    def test_returns_empty_for_empty_memory_dir(self, tmp_path: Path) -> None:
        """Empty .memory/ directory (no .md files) returns empty string."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()

        result = load_strategic_memory(str(tmp_path))
        assert result == ""


# ---------------------------------------------------------------------------
# File Filtering Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestFileFiltering:
    """Test that non-.md files in .memory/ are ignored."""

    def test_ignores_non_md_files(self, tmp_path: Path) -> None:
        """Files without .md extension are not included."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        (memory_dir / "goals.md").write_text("# Goals\nIncluded.")
        (memory_dir / "notes.txt").write_text("Should be ignored.")
        (memory_dir / "data.json").write_text('{"ignored": true}')

        result = load_strategic_memory(str(tmp_path))
        assert "Included." in result
        assert "Should be ignored." not in result
        assert "ignored" not in result

    def test_ignores_dotfiles(self, tmp_path: Path) -> None:
        """Dotfiles like .memoryrc are not included."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        (memory_dir / "goals.md").write_text("# Goals")
        (memory_dir / ".memoryrc").write_text("retention_days: 30")
        (memory_dir / ".gitignore").write_text("*.db")

        result = load_strategic_memory(str(tmp_path))
        assert "retention_days" not in result
        assert "*.db" not in result

    def test_ignores_subdirectory_md_files(self, tmp_path: Path) -> None:
        """Only top-level .md files in .memory/ are included (no recursion)."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        subdir = memory_dir / "subdir"
        subdir.mkdir()
        (memory_dir / "goals.md").write_text("Top-level content.")
        (subdir / "nested.md").write_text("Nested content should be ignored.")

        result = load_strategic_memory(str(tmp_path))
        assert "Top-level content." in result
        assert "Nested content should be ignored." not in result

    def test_ignores_yaml_and_db_files(self, tmp_path: Path) -> None:
        """YAML and database files are not included."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        (memory_dir / "goals.md").write_text("Included.")
        (memory_dir / "config.yaml").write_text("key: value")
        (memory_dir / "tactical.db").write_bytes(b"\x00\x01\x02")

        result = load_strategic_memory(str(tmp_path))
        assert "Included." in result
        assert "key: value" not in result


# ---------------------------------------------------------------------------
# Size Warning Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestSizeWarning:
    """Test that large strategic memory triggers a warning."""

    def test_large_content_logs_warning(
        self, tmp_path: Path, caplog: pytest.LogCaptureFixture
    ) -> None:
        """Content exceeding 500KB triggers a warning log."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        # Create content larger than 500KB
        large_content = "x" * (512 * 1024)
        (memory_dir / "large.md").write_text(large_content)

        import logging

        with caplog.at_level(logging.WARNING, logger="memory_server"):
            load_strategic_memory(str(tmp_path))

        assert any(
            "500" in record.message or "size" in record.message.lower() for record in caplog.records
        )

    def test_normal_content_no_warning(
        self, tmp_path: Path, caplog: pytest.LogCaptureFixture
    ) -> None:
        """Content under 500KB does not trigger a warning."""
        memory_dir = tmp_path / ".memory"
        memory_dir.mkdir()
        (memory_dir / "goals.md").write_text("Small content.")

        import logging

        with caplog.at_level(logging.WARNING, logger="memory_server"):
            load_strategic_memory(str(tmp_path))

        warning_records = [r for r in caplog.records if r.levelno >= logging.WARNING]
        assert len(warning_records) == 0
