#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-doc-links.sh [--root PATH] [--paths P1[,P2...]]

Validates that Markdown links in README.md and docs/ resolve to existing files.

Checks:
  - Markdown links of the form [text](target) and images ![alt](target)
  - Relative links only (skips http/https/mailto/# anchors)
  - File existence only (does not validate section anchors)

Options:
  --root PATH     Repository root to scan (default: git root)
  --paths LIST    Comma-separated paths to scan (default: README.md,docs)
  --help          Show this help
EOF
}

ROOT=""
PATHS_CSV="README.md,docs"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --paths)
      PATHS_CSV="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$ROOT" ]]; then
  if ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    :
  else
    ROOT="$(pwd)"
  fi
fi

python3 - "$ROOT" "$PATHS_CSV" <<'PY'
import os
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
paths = [p.strip() for p in sys.argv[2].split(",") if p.strip()]

skip_prefixes = (
    "http://",
    "https://",
    "mailto:",
    "tel:",
)

link_re = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")

def normalize_target(raw: str) -> str:
    t = raw.strip()
    # Strip surrounding quotes or angle brackets.
    if (t.startswith("<") and t.endswith(">")) or (t.startswith("\"") and t.endswith("\"")) or (t.startswith("'") and t.endswith("'")):
        t = t[1:-1].strip()
    return t

def is_relative_file_link(target: str) -> bool:
    if not target:
        return False
    if target.startswith("#"):
        return False
    if target.startswith(skip_prefixes):
        return False
    return True

def strip_fragment_and_query(target: str) -> str:
    t = target.split("#", 1)[0]
    t = t.split("?", 1)[0]
    return t

def resolve_path(source_file: Path, target: str) -> Path:
    # Treat leading '/' as repo-root relative.
    if target.startswith("/"):
        return (root / target.lstrip("/")).resolve()
    return (source_file.parent / target).resolve()

md_files: list[Path] = []
for p in paths:
    candidate = (root / p).resolve() if not os.path.isabs(p) else Path(p).resolve()
    if not candidate.exists():
        # If a user passes a missing path, treat it as an error.
        print(f"ERROR: scan path does not exist: {candidate}")
        sys.exit(2)
    if candidate.is_file():
        if candidate.suffix.lower() == ".md":
            md_files.append(candidate)
    else:
        md_files.extend(sorted(candidate.rglob("*.md")))

broken: list[tuple[Path, str, Path]] = []
for md in md_files:
    try:
        text = md.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        text = md.read_text(encoding="utf-8", errors="replace")

    for m in link_re.finditer(text):
        raw_target = m.group(1)
        target = normalize_target(raw_target)
        if not is_relative_file_link(target):
            continue

        target = strip_fragment_and_query(target)
        if not target:
            continue

        # Skip common non-file targets.
        if target.startswith("data:"):
            continue

        resolved = resolve_path(md, target)

        # Allow directory links if the directory exists.
        if not resolved.exists():
            broken.append((md.relative_to(root), target, resolved.relative_to(root) if resolved.is_relative_to(root) else resolved))

if broken:
    for src, target, resolved in broken:
        print(f"BROKEN: {src}: {target} -> {resolved}")
    print(f"\nFound {len(broken)} broken link(s).")
    sys.exit(1)

print(f"OK: {len(md_files)} Markdown file(s) scanned; no broken links.")
PY
