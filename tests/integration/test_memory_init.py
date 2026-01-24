"""Integration tests for the memory-init CLI entry point.

End-to-end tests that invoke the CLI via subprocess and verify
file creation, exit codes, and output formatting.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import pytest

EXPECTED_TEMPLATE_FILES = [
    "goals.md",
    "architecture.md",
    "patterns.md",
    "technology.md",
    "status.md",
]

EXPECTED_ALL_FILES = [*EXPECTED_TEMPLATE_FILES, ".memoryrc", ".gitignore"]


def run_memory_init(*args: str, cwd: str | None = None) -> subprocess.CompletedProcess[str]:
    """Run the memory-init CLI as a subprocess."""
    cmd = [sys.executable, "-m", "memory_init", *args]
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=cwd,
        timeout=30,
    )


# ---------------------------------------------------------------------------
# End-to-End File Creation Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestEndToEndCreation:
    """End-to-end tests for memory-init file creation."""

    def test_creates_all_files_in_cwd(self, tmp_path: Path) -> None:
        """Running memory-init in a directory creates .memory/ with all files."""
        result = run_memory_init("--workspace", str(tmp_path))
        assert result.returncode == 0

        memory_dir = tmp_path / ".memory"
        assert memory_dir.is_dir()

        for filename in EXPECTED_ALL_FILES:
            filepath = memory_dir / filename
            assert filepath.exists(), f"Missing file: {filename}"

    def test_creates_in_current_directory_by_default(self, tmp_path: Path) -> None:
        """Without --workspace, init uses the current working directory."""
        result = run_memory_init(cwd=str(tmp_path))
        assert result.returncode == 0

        memory_dir = tmp_path / ".memory"
        assert memory_dir.is_dir()

    def test_second_run_is_idempotent(self, tmp_path: Path) -> None:
        """Running memory-init twice does not fail or overwrite."""
        run_memory_init("--workspace", str(tmp_path))
        result = run_memory_init("--workspace", str(tmp_path))
        assert result.returncode == 0

    def test_force_flag_overwrites(self, tmp_path: Path) -> None:
        """Running with --force overwrites existing template files."""
        run_memory_init("--workspace", str(tmp_path))

        # Modify a file
        goals_file = tmp_path / ".memory" / "goals.md"
        goals_file.write_text("# Custom\n")

        result = run_memory_init("--workspace", str(tmp_path), "--force")
        assert result.returncode == 0

        # File should be overwritten with template content
        content = goals_file.read_text()
        assert content != "# Custom\n"


# ---------------------------------------------------------------------------
# Workspace Flag Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestWorkspaceFlag:
    """Tests for the --workspace flag."""

    def test_workspace_creates_in_specified_dir(self, tmp_path: Path) -> None:
        """--workspace PATH creates .memory/ in the specified directory."""
        workspace = tmp_path / "my_project"
        workspace.mkdir()

        result = run_memory_init("--workspace", str(workspace))
        assert result.returncode == 0
        assert (workspace / ".memory").is_dir()

    def test_workspace_with_nested_path(self, tmp_path: Path) -> None:
        """--workspace works with deeply nested paths."""
        workspace = tmp_path / "a" / "b" / "c"
        workspace.mkdir(parents=True)

        result = run_memory_init("--workspace", str(workspace))
        assert result.returncode == 0
        assert (workspace / ".memory").is_dir()


# ---------------------------------------------------------------------------
# Quiet Flag Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestQuietFlag:
    """Tests for the --quiet flag."""

    def test_quiet_suppresses_output(self, tmp_path: Path) -> None:
        """--quiet produces no stdout output."""
        result = run_memory_init("--workspace", str(tmp_path), "--quiet")
        assert result.returncode == 0
        assert result.stdout.strip() == ""

    def test_without_quiet_produces_output(self, tmp_path: Path) -> None:
        """Without --quiet, stdout contains file creation info."""
        result = run_memory_init("--workspace", str(tmp_path))
        assert result.returncode == 0
        assert len(result.stdout.strip()) > 0


# ---------------------------------------------------------------------------
# Output Format Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestOutputFormat:
    """Tests for --output-format flag."""

    def test_json_output_is_valid(self, tmp_path: Path) -> None:
        """--output-format json produces valid JSON."""
        result = run_memory_init("--workspace", str(tmp_path), "--output-format", "json")
        assert result.returncode == 0

        output = json.loads(result.stdout)
        assert isinstance(output, dict)

    def test_json_output_has_created_list(self, tmp_path: Path) -> None:
        """JSON output contains a 'created' key with file list."""
        result = run_memory_init("--workspace", str(tmp_path), "--output-format", "json")
        output = json.loads(result.stdout)
        assert "created" in output
        assert isinstance(output["created"], list)
        assert len(output["created"]) == len(EXPECTED_ALL_FILES)

    def test_json_output_has_skipped_list(self, tmp_path: Path) -> None:
        """JSON output contains a 'skipped' key."""
        result = run_memory_init("--workspace", str(tmp_path), "--output-format", "json")
        output = json.loads(result.stdout)
        assert "skipped" in output
        assert isinstance(output["skipped"], list)

    def test_json_output_on_second_run(self, tmp_path: Path) -> None:
        """JSON output on second run shows files in 'skipped' list."""
        run_memory_init("--workspace", str(tmp_path))
        result = run_memory_init("--workspace", str(tmp_path), "--output-format", "json")
        output = json.loads(result.stdout)
        assert len(output["skipped"]) == len(EXPECTED_ALL_FILES)
        assert len(output["created"]) == 0

    def test_text_output_default(self, tmp_path: Path) -> None:
        """Default output format is human-readable text."""
        result = run_memory_init("--workspace", str(tmp_path))
        assert result.returncode == 0
        # Text output should not be valid JSON
        with pytest.raises(json.JSONDecodeError):
            json.loads(result.stdout)

    def test_quiet_overrides_json(self, tmp_path: Path) -> None:
        """--quiet with --output-format json still suppresses output."""
        result = run_memory_init("--workspace", str(tmp_path), "--output-format", "json", "--quiet")
        assert result.returncode == 0
        assert result.stdout.strip() == ""


# ---------------------------------------------------------------------------
# Exit Code Tests
# ---------------------------------------------------------------------------


@pytest.mark.integration
class TestExitCodes:
    """Tests for CLI exit codes."""

    def test_success_returns_zero(self, tmp_path: Path) -> None:
        """Successful initialization returns exit code 0."""
        result = run_memory_init("--workspace", str(tmp_path))
        assert result.returncode == 0

    def test_nonexistent_workspace_returns_two(self, tmp_path: Path) -> None:
        """Nonexistent workspace path returns exit code 2."""
        nonexistent = tmp_path / "does_not_exist"
        result = run_memory_init("--workspace", str(nonexistent))
        assert result.returncode == 2

    def test_error_message_on_nonexistent(self, tmp_path: Path) -> None:
        """Nonexistent workspace produces an error message on stderr."""
        nonexistent = tmp_path / "does_not_exist"
        result = run_memory_init("--workspace", str(nonexistent))
        assert result.returncode == 2
        assert "not found" in result.stderr.lower() or "does not exist" in result.stderr.lower()

    def test_json_error_on_nonexistent(self, tmp_path: Path) -> None:
        """--output-format json with nonexistent workspace produces JSON error."""
        nonexistent = tmp_path / "does_not_exist"
        result = run_memory_init("--workspace", str(nonexistent), "--output-format", "json")
        assert result.returncode == 2
        output = json.loads(result.stderr)
        assert "error" in output
