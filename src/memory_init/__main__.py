"""T028/T037: CLI entry point for memory-init.

Provides the main() function that initializes strategic memory
in a workspace directory, and optionally sets up AI tool configurations.

Usage:
    memory-init [--workspace PATH] [--force] [--quiet] [--output-format json|text]
    memory-init --setup-tools [--workspace PATH] [--quiet]

Exit codes:
    0 - Success
    1 - Invalid arguments
    2 - Workspace not found
    3 - Permission denied
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

from memory_init.init import init_memory

# Path to bundled config templates
_CONFIGS_DIR = Path(__file__).parent / "configs"

# Mapping of source config templates to their workspace target paths
_TOOL_CONFIG_TARGETS: dict[str, str] = {
    "claude.json": ".mcp.json",
    "cline.json": ".cline/cline_mcp_settings.json",
    "continue.yaml": ".continue/config.yaml",
}


def _build_parser() -> argparse.ArgumentParser:
    """Build the argument parser for memory-init CLI."""
    parser = argparse.ArgumentParser(
        prog="memory-init",
        description="Initialize strategic memory directory with template files.",
    )
    parser.add_argument(
        "--workspace",
        default=".",
        help="Target workspace directory (default: current directory)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing template files",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Suppress informational output",
    )
    parser.add_argument(
        "--output-format",
        choices=["json", "text"],
        default="text",
        help="Output format (default: text)",
    )
    parser.add_argument(
        "--setup-tools",
        action="store_true",
        help="Copy AI tool MCP config templates to the workspace",
    )
    return parser


def _format_text_output(result: dict[str, list[str]]) -> str:
    """Format the init result as human-readable text."""
    lines: list[str] = []

    if result["created"]:
        lines.append("Created:")
        for filename in result["created"]:
            lines.append(f"  .memory/{filename}")

    if result["skipped"]:
        lines.append("Skipped (already exist):")
        for filename in result["skipped"]:
            lines.append(f"  .memory/{filename}")

    total_created = len(result["created"])
    total_skipped = len(result["skipped"])
    lines.append(f"\nDone: {total_created} created, {total_skipped} skipped.")

    return "\n".join(lines)


def setup_tools(workspace: str, quiet: bool = False) -> dict[str, list[str]]:
    """Copy AI tool MCP config templates to the workspace.

    For each known tool config (Claude, Cline, Continue), copies the template
    to the appropriate location in the workspace. Only creates files that
    do not already exist (never overwrites).

    Args:
        workspace: Path to the target workspace directory.
        quiet: If True, suppress informational output.

    Returns:
        A dict with keys 'created' and 'skipped' listing config file paths.

    Raises:
        FileNotFoundError: If the workspace path does not exist.
        NotADirectoryError: If the workspace path is not a directory.
    """
    workspace_path = Path(workspace)

    if not workspace_path.exists():
        msg = f"Workspace path does not exist: {workspace}"
        raise FileNotFoundError(msg)

    if not workspace_path.is_dir():
        msg = f"Workspace path is not a directory: {workspace}"
        raise NotADirectoryError(msg)

    created: list[str] = []
    skipped: list[str] = []

    for source_name, target_rel in _TOOL_CONFIG_TARGETS.items():
        source_path = _CONFIGS_DIR / source_name
        target_path = workspace_path / target_rel

        if target_path.exists():
            skipped.append(target_rel)
            continue

        # Create parent directories if needed
        target_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(str(source_path), str(target_path))
        created.append(target_rel)

    return {"created": created, "skipped": skipped}


def main() -> None:
    """Entry point for the memory-init CLI."""
    parser = _build_parser()
    args = parser.parse_args()

    # Handle --setup-tools mode
    if args.setup_tools:
        try:
            result = setup_tools(args.workspace, quiet=args.quiet)
        except FileNotFoundError as exc:
            sys.stderr.write(f"Error: {exc}\n")
            sys.exit(2)
        except NotADirectoryError as exc:
            sys.stderr.write(f"Error: {exc}\n")
            sys.exit(2)

        if not args.quiet:
            if result["created"]:
                sys.stdout.write("Created tool configs:\n")
                for path in result["created"]:
                    sys.stdout.write(f"  {path}\n")
            if result["skipped"]:
                sys.stdout.write("Skipped (already exist):\n")
                for path in result["skipped"]:
                    sys.stdout.write(f"  {path}\n")
            sys.stdout.write(
                f"\nDone: {len(result['created'])} created, {len(result['skipped'])} skipped.\n"
            )
        sys.exit(0)

    try:
        result = init_memory(args.workspace, force=args.force)
    except FileNotFoundError as exc:
        if args.output_format == "json":
            error_output = json.dumps({"error": str(exc)})
            sys.stderr.write(error_output + "\n")
        else:
            sys.stderr.write(f"Error: {exc}\n")
        sys.exit(2)
    except NotADirectoryError as exc:
        if args.output_format == "json":
            error_output = json.dumps({"error": str(exc)})
            sys.stderr.write(error_output + "\n")
        else:
            sys.stderr.write(f"Error: {exc}\n")
        sys.exit(2)
    except PermissionError as exc:
        if args.output_format == "json":
            error_output = json.dumps({"error": str(exc)})
            sys.stderr.write(error_output + "\n")
        else:
            sys.stderr.write(f"Error: {exc}\n")
        sys.exit(3)

    if args.quiet:
        sys.exit(0)

    if args.output_format == "json":
        sys.stdout.write(json.dumps(result) + "\n")
    else:
        sys.stdout.write(_format_text_output(result) + "\n")

    sys.exit(0)


if __name__ == "__main__":
    main()
