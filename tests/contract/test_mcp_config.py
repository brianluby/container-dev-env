"""T031: Contract tests for MCP server configuration templates.

Validates that generated configuration files for Claude Code, Cline, and
Continue match the expected structure defined in the MCP server config contract.
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest
import yaml

# Path to the contract specification
_CONTRACTS_DIR = (
    Path(__file__).parent.parent.parent / "specs" / "013-persistent-memory" / "contracts"
)
_CONTRACT_PATH = _CONTRACTS_DIR / "mcp-server-config.json"

# Path to the generated config templates
_CONFIGS_DIR = Path(__file__).parent.parent.parent / "src" / "memory_init" / "configs"


@pytest.fixture
def contract() -> dict:
    """Load the MCP server config contract."""
    return json.loads(_CONTRACT_PATH.read_text(encoding="utf-8"))


@pytest.fixture
def claude_config() -> dict:
    """Load the generated claude.json config."""
    config_path = _CONFIGS_DIR / "claude.json"
    return json.loads(config_path.read_text(encoding="utf-8"))


@pytest.fixture
def cline_config() -> dict:
    """Load the generated cline.json config."""
    config_path = _CONFIGS_DIR / "cline.json"
    return json.loads(config_path.read_text(encoding="utf-8"))


@pytest.fixture
def continue_config() -> dict:
    """Load the generated continue.yaml config."""
    config_path = _CONFIGS_DIR / "continue.yaml"
    return yaml.safe_load(config_path.read_text(encoding="utf-8"))


# ---------------------------------------------------------------------------
# Claude Code Config Tests
# ---------------------------------------------------------------------------


class TestClaudeConfig:
    """Test generated claude.json matches the expected contract structure."""

    def test_has_mcp_servers_key(self, claude_config: dict) -> None:
        """claude.json has top-level mcpServers key."""
        assert "mcpServers" in claude_config

    def test_has_memory_server(self, claude_config: dict) -> None:
        """claude.json has a 'memory' server defined."""
        assert "memory" in claude_config["mcpServers"]

    def test_command_is_python(self, claude_config: dict) -> None:
        """Memory server command is 'python'."""
        server = claude_config["mcpServers"]["memory"]
        assert server["command"] == "python"

    def test_args_launch_memory_server(self, claude_config: dict) -> None:
        """Memory server args launch the memory_server module."""
        server = claude_config["mcpServers"]["memory"]
        assert server["args"] == ["-m", "memory_server"]

    def test_env_has_required_vars(self, claude_config: dict) -> None:
        """Memory server env contains all required environment variables."""
        env = claude_config["mcpServers"]["memory"]["env"]
        assert "MEMORY_DB_PATH" in env
        assert "MEMORY_WORKSPACE" in env
        assert "MEMORY_SOURCE_TOOL" in env
        assert "MEMORY_LOG_LEVEL" in env

    def test_source_tool_is_claude_code(self, claude_config: dict) -> None:
        """MEMORY_SOURCE_TOOL is set to 'claude-code'."""
        env = claude_config["mcpServers"]["memory"]["env"]
        assert env["MEMORY_SOURCE_TOOL"] == "claude-code"

    def test_env_matches_contract(self, claude_config: dict, contract: dict) -> None:
        """Environment variables match those defined in the contract."""
        env = claude_config["mcpServers"]["memory"]["env"]
        contract_env = contract["environment_variables"]
        # All env vars in the config should be documented in the contract
        for key in env:
            assert key in contract_env, f"Env var {key} not in contract"


# ---------------------------------------------------------------------------
# Cline Config Tests
# ---------------------------------------------------------------------------


class TestClineConfig:
    """Test generated cline.json matches the expected contract structure."""

    def test_has_mcp_servers_key(self, cline_config: dict) -> None:
        """cline.json has top-level mcpServers key."""
        assert "mcpServers" in cline_config

    def test_has_memory_server(self, cline_config: dict) -> None:
        """cline.json has a 'memory' server defined."""
        assert "memory" in cline_config["mcpServers"]

    def test_command_is_python(self, cline_config: dict) -> None:
        """Memory server command is 'python'."""
        server = cline_config["mcpServers"]["memory"]
        assert server["command"] == "python"

    def test_args_launch_memory_server(self, cline_config: dict) -> None:
        """Memory server args launch the memory_server module."""
        server = cline_config["mcpServers"]["memory"]
        assert server["args"] == ["-m", "memory_server"]

    def test_source_tool_is_cline(self, cline_config: dict) -> None:
        """MEMORY_SOURCE_TOOL is set to 'cline'."""
        env = cline_config["mcpServers"]["memory"]["env"]
        assert env["MEMORY_SOURCE_TOOL"] == "cline"

    def test_has_disabled_field(self, cline_config: dict) -> None:
        """cline.json has 'disabled' field set to false."""
        server = cline_config["mcpServers"]["memory"]
        assert "disabled" in server
        assert server["disabled"] is False

    def test_has_always_allow_list(self, cline_config: dict) -> None:
        """cline.json has 'alwaysAllow' with read-only tools."""
        server = cline_config["mcpServers"]["memory"]
        assert "alwaysAllow" in server
        assert isinstance(server["alwaysAllow"], list)

    def test_always_allow_contains_safe_tools(self, cline_config: dict) -> None:
        """alwaysAllow includes search, list, and stats (read-only operations)."""
        server = cline_config["mcpServers"]["memory"]
        expected_tools = ["search_memories", "list_memories", "get_memory_stats"]
        for tool in expected_tools:
            assert tool in server["alwaysAllow"]

    def test_env_matches_contract(self, cline_config: dict, contract: dict) -> None:
        """Environment variables match those defined in the contract."""
        env = cline_config["mcpServers"]["memory"]["env"]
        contract_env = contract["environment_variables"]
        for key in env:
            assert key in contract_env, f"Env var {key} not in contract"


# ---------------------------------------------------------------------------
# Continue Config Tests
# ---------------------------------------------------------------------------


class TestContinueConfig:
    """Test generated continue.yaml matches the expected contract structure."""

    def test_has_mcp_servers_key(self, continue_config: dict) -> None:
        """continue.yaml has top-level mcpServers key."""
        assert "mcpServers" in continue_config

    def test_mcp_servers_is_list(self, continue_config: dict) -> None:
        """continue.yaml mcpServers is a list (not a dict like claude/cline)."""
        assert isinstance(continue_config["mcpServers"], list)

    def test_has_memory_server_entry(self, continue_config: dict) -> None:
        """continue.yaml has an entry with name 'memory'."""
        names = [s["name"] for s in continue_config["mcpServers"]]
        assert "memory" in names

    def test_command_is_python(self, continue_config: dict) -> None:
        """Memory server command is 'python'."""
        server = next(s for s in continue_config["mcpServers"] if s["name"] == "memory")
        assert server["command"] == "python"

    def test_args_launch_memory_server(self, continue_config: dict) -> None:
        """Memory server args launch the memory_server module."""
        server = next(s for s in continue_config["mcpServers"] if s["name"] == "memory")
        assert server["args"] == ["-m", "memory_server"]

    def test_source_tool_is_continue(self, continue_config: dict) -> None:
        """MEMORY_SOURCE_TOOL is set to 'continue'."""
        server = next(s for s in continue_config["mcpServers"] if s["name"] == "memory")
        assert server["env"]["MEMORY_SOURCE_TOOL"] == "continue"

    def test_env_has_required_vars(self, continue_config: dict) -> None:
        """Memory server env contains required environment variables."""
        server = next(s for s in continue_config["mcpServers"] if s["name"] == "memory")
        env = server["env"]
        assert "MEMORY_DB_PATH" in env
        assert "MEMORY_WORKSPACE" in env
        assert "MEMORY_SOURCE_TOOL" in env


# ---------------------------------------------------------------------------
# Cross-Config Environment Variable Tests
# ---------------------------------------------------------------------------


class TestEnvVarsContract:
    """Validate env vars section matches contract across all configs."""

    def test_all_configs_have_db_path(
        self, claude_config: dict, cline_config: dict, continue_config: dict
    ) -> None:
        """All configs specify MEMORY_DB_PATH."""
        assert "MEMORY_DB_PATH" in claude_config["mcpServers"]["memory"]["env"]
        assert "MEMORY_DB_PATH" in cline_config["mcpServers"]["memory"]["env"]
        continue_server = next(s for s in continue_config["mcpServers"] if s["name"] == "memory")
        assert "MEMORY_DB_PATH" in continue_server["env"]

    def test_all_configs_have_workspace(
        self, claude_config: dict, cline_config: dict, continue_config: dict
    ) -> None:
        """All configs specify MEMORY_WORKSPACE."""
        assert "MEMORY_WORKSPACE" in claude_config["mcpServers"]["memory"]["env"]
        assert "MEMORY_WORKSPACE" in cline_config["mcpServers"]["memory"]["env"]
        continue_server = next(s for s in continue_config["mcpServers"] if s["name"] == "memory")
        assert "MEMORY_WORKSPACE" in continue_server["env"]

    def test_db_path_uses_standard_location(
        self, claude_config: dict, cline_config: dict, continue_config: dict
    ) -> None:
        """MEMORY_DB_PATH uses the standard XDG-style location."""
        expected_path = "${HOME}/.local/share/ai-memory/projects"
        assert claude_config["mcpServers"]["memory"]["env"]["MEMORY_DB_PATH"] == expected_path
        assert cline_config["mcpServers"]["memory"]["env"]["MEMORY_DB_PATH"] == expected_path
        continue_server = next(s for s in continue_config["mcpServers"] if s["name"] == "memory")
        assert continue_server["env"]["MEMORY_DB_PATH"] == expected_path

    def test_workspace_uses_workspace_folder_var(
        self, claude_config: dict, cline_config: dict, continue_config: dict
    ) -> None:
        """MEMORY_WORKSPACE uses ${workspaceFolder} variable."""
        expected = "${workspaceFolder}"
        assert claude_config["mcpServers"]["memory"]["env"]["MEMORY_WORKSPACE"] == expected
        assert cline_config["mcpServers"]["memory"]["env"]["MEMORY_WORKSPACE"] == expected
        continue_server = next(s for s in continue_config["mcpServers"] if s["name"] == "memory")
        assert continue_server["env"]["MEMORY_WORKSPACE"] == expected
