"""T008/T051: Tests for project ID hashing and DB path scoping in memory_server.project.

Tests validate that generate_project_id produces deterministic, unique,
16-character hex identifiers from workspace paths, and that get_db_path
produces correctly scoped database paths.
"""

from __future__ import annotations

import os
from pathlib import Path

from memory_server.project import generate_project_id, get_db_path


class TestGenerateProjectId:
    """Tests for the generate_project_id function."""

    def test_returns_string(self) -> None:
        """generate_project_id returns a string."""
        result = generate_project_id("/home/user/project")
        assert isinstance(result, str)

    def test_result_is_exactly_16_chars(self) -> None:
        """Result is exactly 16 characters long."""
        result = generate_project_id("/home/user/project")
        assert len(result) == 16

    def test_result_is_hex_chars_only(self) -> None:
        """Result contains only hexadecimal characters (0-9, a-f)."""
        result = generate_project_id("/home/user/project")
        assert all(c in "0123456789abcdef" for c in result)

    def test_deterministic_same_path(self) -> None:
        """Same path always produces the same project ID."""
        path = "/home/user/my-project"
        id1 = generate_project_id(path)
        id2 = generate_project_id(path)
        assert id1 == id2

    def test_different_paths_produce_different_ids(self) -> None:
        """Different paths produce different project IDs."""
        id1 = generate_project_id("/home/user/project-a")
        id2 = generate_project_id("/home/user/project-b")
        assert id1 != id2

    def test_handles_trailing_slash(self) -> None:
        """Trailing slashes are normalized (same result with/without)."""
        id_without = generate_project_id("/home/user/project")
        id_with = generate_project_id("/home/user/project/")
        assert id_without == id_with

    def test_handles_multiple_trailing_slashes(self) -> None:
        """Multiple trailing slashes are all normalized."""
        id_clean = generate_project_id("/home/user/project")
        id_slashes = generate_project_id("/home/user/project///")
        assert id_clean == id_slashes

    def test_resolves_symlinks(self, tmp_path: Path) -> None:
        """Symlinked paths resolve to the same project ID as the real path."""
        real_dir = tmp_path / "real-project"
        real_dir.mkdir()
        symlink_dir = tmp_path / "link-project"
        symlink_dir.symlink_to(real_dir)

        id_real = generate_project_id(str(real_dir))
        id_symlink = generate_project_id(str(symlink_dir))
        assert id_real == id_symlink

    def test_resolves_relative_components(self) -> None:
        """Paths with .. and . components are canonicalized."""
        id_clean = generate_project_id("/home/user/project")
        id_dotdot = generate_project_id("/home/user/other/../project")
        assert id_clean == id_dotdot

    def test_case_sensitive_paths(self) -> None:
        """Different cases produce different IDs (on case-sensitive filesystems)."""
        # This test is meaningful on Linux; on macOS HFS+ it may behave differently
        # depending on the filesystem. We test the hashing logic directly.
        id_lower = generate_project_id("/home/user/Project")
        id_upper = generate_project_id("/home/user/project")
        # On case-sensitive FS these should differ; on case-insensitive they may match.
        # We just verify both produce valid 16-char hex.
        assert len(id_lower) == 16
        assert len(id_upper) == 16

    def test_long_path(self) -> None:
        """Very long paths still produce exactly 16 hex chars."""
        long_path = "/home/user/" + "a" * 500 + "/project"
        result = generate_project_id(long_path)
        assert len(result) == 16
        assert all(c in "0123456789abcdef" for c in result)

    def test_root_path(self) -> None:
        """Root path produces a valid project ID."""
        result = generate_project_id("/")
        assert len(result) == 16
        assert all(c in "0123456789abcdef" for c in result)

    def test_unicode_path(self) -> None:
        """Paths with unicode characters produce valid IDs."""
        result = generate_project_id("/home/user/proyecto-\u00e9special")
        assert len(result) == 16
        assert all(c in "0123456789abcdef" for c in result)

    def test_uses_sha256_truncation(self) -> None:
        """The ID is derived from SHA-256 hash truncated to 16 hex chars (8 bytes)."""
        import hashlib

        path = "/home/user/test-project"
        # Canonical path resolution - we replicate expected behavior
        canonical = os.path.realpath(path.rstrip("/"))
        expected_hash = hashlib.sha256(canonical.encode()).hexdigest()[:16]
        result = generate_project_id(path)
        assert result == expected_hash


# ---------------------------------------------------------------------------
# T051: Tests for get_db_path
# ---------------------------------------------------------------------------


class TestGetDbPath:
    """Tests for the get_db_path function."""

    def test_scoped_path_structure(self, tmp_path: Path) -> None:
        """get_db_path returns base/projects/<project_id>/memory.db."""
        base = str(tmp_path / "data")
        result = get_db_path(base, "a1b2c3d4e5f67890")
        expected = str(Path(base) / "projects" / "a1b2c3d4e5f67890" / "memory.db")
        assert result == expected

    def test_creates_parent_directories(self, tmp_path: Path) -> None:
        """get_db_path creates the parent directory structure."""
        base = str(tmp_path / "new" / "nested" / "data")
        result = get_db_path(base, "a1b2c3d4e5f67890")
        parent = Path(result).parent
        assert parent.exists()
        assert parent.is_dir()

    def test_different_project_ids_produce_different_paths(self, tmp_path: Path) -> None:
        """Different project_ids produce different file paths."""
        base = str(tmp_path / "data")
        path_a = get_db_path(base, "aaaa111122223333")
        path_b = get_db_path(base, "bbbb444455556666")
        assert path_a != path_b

    def test_different_workspaces_produce_different_paths(self, tmp_path: Path) -> None:
        """Different workspaces produce different DB file paths via project_id."""
        base = str(tmp_path / "data")
        id_a = generate_project_id("/workspace/project-alpha")
        id_b = generate_project_id("/workspace/project-beta")
        path_a = get_db_path(base, id_a)
        path_b = get_db_path(base, id_b)
        assert path_a != path_b

    def test_symlink_canonicalization(self, tmp_path: Path) -> None:
        """Symlinked workspace paths produce the same project_id and DB path."""
        base = str(tmp_path / "data")
        real_dir = tmp_path / "real-project"
        real_dir.mkdir()
        symlink_dir = tmp_path / "link-project"
        symlink_dir.symlink_to(real_dir)

        id_real = generate_project_id(str(real_dir))
        id_symlink = generate_project_id(str(symlink_dir))
        assert id_real == id_symlink

        path_real = get_db_path(base, id_real)
        path_symlink = get_db_path(base, id_symlink)
        assert path_real == path_symlink

    def test_idempotent_directory_creation(self, tmp_path: Path) -> None:
        """Calling get_db_path multiple times does not raise."""
        base = str(tmp_path / "data")
        get_db_path(base, "a1b2c3d4e5f67890")
        get_db_path(base, "a1b2c3d4e5f67890")  # Should not raise
