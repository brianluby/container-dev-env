"""T074: Contract tests for the memory-init CLI.

Validates that the memory-init CLI conforms to the contract defined in
specs/013-persistent-memory/contracts/strategic-memory-init.sh, including
flag handling, exit codes, and created file structure.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

# Path to the contract specification
_CONTRACTS_DIR = (
    Path(__file__).parent.parent.parent / "specs" / "013-persistent-memory" / "contracts"
)
_CONTRACT_PATH = _CONTRACTS_DIR / "strategic-memory-init.sh"

# Expected file structure per contract
EXPECTED_MD_FILES = [
    "goals.md",
    "architecture.md",
    "patterns.md",
    "technology.md",
    "status.md",
]
EXPECTED_CONFIG_FILE = ".memoryrc"


def run_memory_init(*args: str) -> subprocess.CompletedProcess[str]:
    """Run the memory-init CLI as a subprocess."""
    cmd = [sys.executable, "-m", "memory_init", *args]
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=30,
    )


# ---------------------------------------------------------------------------
# Contract Existence Tests
# ---------------------------------------------------------------------------


class TestContractExists:
    """Verify the contract file exists and is readable."""

    def test_contract_file_exists(self) -> None:
        """The strategic-memory-init.sh contract file exists."""
        assert _CONTRACT_PATH.exists(), f"Contract not found: {_CONTRACT_PATH}"

    def test_contract_defines_file_structure(self) -> None:
        """Contract mentions the expected file structure."""
        content = _CONTRACT_PATH.read_text(encoding="utf-8")
        assert ".memory/" in content
        assert "goals.md" in content
        assert "architecture.md" in content
        assert "patterns.md" in content
        assert "technology.md" in content
        assert "status.md" in content
        assert ".memoryrc" in content


# ---------------------------------------------------------------------------
# CLI Flag Tests
# ---------------------------------------------------------------------------


class TestCLIFlags:
    """Test CLI accepts --workspace, --force, --quiet flags."""

    def test_accepts_workspace_flag(self, tmp_path: Path) -> None:
        """CLI accepts --workspace flag without error."""
        result = run_memory_init("--workspace", str(tmp_path))
        assert result.returncode == 0

    def test_accepts_force_flag(self, tmp_path: Path) -> None:
        """CLI accepts --force flag without error."""
        result = run_memory_init("--workspace", str(tmp_path), "--force")
        assert result.returncode == 0

    def test_accepts_quiet_flag(self, tmp_path: Path) -> None:
        """CLI accepts --quiet flag and suppresses output."""
        result = run_memory_init("--workspace", str(tmp_path), "--quiet")
        assert result.returncode == 0
        assert result.stdout.strip() == ""

    def test_accepts_all_flags_together(self, tmp_path: Path) -> None:
        """CLI accepts all flags simultaneously."""
        result = run_memory_init(
            "--workspace",
            str(tmp_path),
            "--force",
            "--quiet",
        )
        assert result.returncode == 0

    def test_workspace_flag_with_nonexistent_path(self, tmp_path: Path) -> None:
        """CLI with --workspace pointing to nonexistent path exits with code 2."""
        nonexistent = tmp_path / "does_not_exist"
        result = run_memory_init("--workspace", str(nonexistent))
        assert result.returncode == 2


# ---------------------------------------------------------------------------
# Exit Code Tests
# ---------------------------------------------------------------------------


class TestExitCodes:
    """Test exit code 0 on success, 2 on nonexistent workspace."""

    def test_exit_code_zero_on_success(self, tmp_path: Path) -> None:
        """Successful initialization returns exit code 0."""
        result = run_memory_init("--workspace", str(tmp_path))
        assert result.returncode == 0

    def test_exit_code_two_on_nonexistent_workspace(self, tmp_path: Path) -> None:
        """Nonexistent workspace returns exit code 2."""
        nonexistent = tmp_path / "nope"
        result = run_memory_init("--workspace", str(nonexistent))
        assert result.returncode == 2

    def test_exit_code_zero_on_idempotent_run(self, tmp_path: Path) -> None:
        """Running twice (idempotent) still returns exit code 0."""
        run_memory_init("--workspace", str(tmp_path))
        result = run_memory_init("--workspace", str(tmp_path))
        assert result.returncode == 0


# ---------------------------------------------------------------------------
# File Structure Tests
# ---------------------------------------------------------------------------


class TestFileStructure:
    """Test created file structure matches contract (.memory/ with all 5 files + .memoryrc)."""

    def test_creates_memory_directory(self, tmp_path: Path) -> None:
        """CLI creates the .memory/ directory."""
        run_memory_init("--workspace", str(tmp_path))
        assert (tmp_path / ".memory").is_dir()

    def test_creates_all_five_md_files(self, tmp_path: Path) -> None:
        """CLI creates all 5 template .md files per contract."""
        run_memory_init("--workspace", str(tmp_path))
        memory_dir = tmp_path / ".memory"
        for filename in EXPECTED_MD_FILES:
            filepath = memory_dir / filename
            assert filepath.exists(), f"Missing file: {filename}"
            assert filepath.stat().st_size > 0, f"Empty file: {filename}"

    def test_creates_memoryrc(self, tmp_path: Path) -> None:
        """CLI creates the .memoryrc configuration file."""
        run_memory_init("--workspace", str(tmp_path))
        memoryrc = tmp_path / ".memory" / EXPECTED_CONFIG_FILE
        assert memoryrc.exists()
        assert memoryrc.stat().st_size > 0

    def test_memoryrc_contains_retention_days(self, tmp_path: Path) -> None:
        """.memoryrc contains retention_days setting."""
        run_memory_init("--workspace", str(tmp_path))
        content = (tmp_path / ".memory" / ".memoryrc").read_text()
        assert "retention_days" in content

    def test_memoryrc_contains_max_size(self, tmp_path: Path) -> None:
        """.memoryrc contains max_size_mb setting."""
        run_memory_init("--workspace", str(tmp_path))
        content = (tmp_path / ".memory" / ".memoryrc").read_text()
        assert "max_size_mb" in content

    def test_memoryrc_contains_excluded_patterns(self, tmp_path: Path) -> None:
        """.memoryrc contains excluded_patterns list."""
        run_memory_init("--workspace", str(tmp_path))
        content = (tmp_path / ".memory" / ".memoryrc").read_text()
        assert "excluded_patterns" in content

    def test_md_files_have_h1_heading(self, tmp_path: Path) -> None:
        """Each .md file starts with an H1 heading per contract."""
        run_memory_init("--workspace", str(tmp_path))
        memory_dir = tmp_path / ".memory"
        for filename in EXPECTED_MD_FILES:
            content = (memory_dir / filename).read_text()
            assert content.startswith("# "), f"{filename} should start with H1 heading"

    def test_creates_gitignore(self, tmp_path: Path) -> None:
        """CLI creates a .gitignore in .memory/ directory."""
        run_memory_init("--workspace", str(tmp_path))
        gitignore = tmp_path / ".memory" / ".gitignore"
        assert gitignore.exists()

    def test_gitignore_excludes_db_files(self, tmp_path: Path) -> None:
        """.gitignore excludes database files per contract."""
        run_memory_init("--workspace", str(tmp_path))
        content = (tmp_path / ".memory" / ".gitignore").read_text()
        assert "*.db" in content
        assert "*.db-wal" in content
        assert "*.db-shm" in content

    def test_force_flag_overwrites_files(self, tmp_path: Path) -> None:
        """--force flag overwrites existing files."""
        run_memory_init("--workspace", str(tmp_path))

        # Modify a file
        goals_file = tmp_path / ".memory" / "goals.md"
        original = goals_file.read_text()
        goals_file.write_text("# Modified\n")

        # Run with --force
        run_memory_init("--workspace", str(tmp_path), "--force")
        restored = goals_file.read_text()

        assert restored == original
        assert restored != "# Modified\n"

    def test_without_force_preserves_existing(self, tmp_path: Path) -> None:
        """Without --force, existing files are preserved."""
        run_memory_init("--workspace", str(tmp_path))

        goals_file = tmp_path / ".memory" / "goals.md"
        goals_file.write_text("# Custom Goals\n")

        run_memory_init("--workspace", str(tmp_path))
        assert goals_file.read_text() == "# Custom Goals\n"
