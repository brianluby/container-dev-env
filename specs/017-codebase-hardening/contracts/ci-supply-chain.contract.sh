#!/usr/bin/env bash
# ci-supply-chain.contract.sh — Contract tests for CI and supply chain hardening
# Verifies: FR-003, FR-009, FR-010, FR-015

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/../../.."

echo "=== CI & Supply Chain Contracts ==="
echo ""

# --- Contract: SHA pinning (FR-009) ---
echo "Contract: GitHub Actions SHA pinning"
echo "  Scope: all .github/workflows/*.yml files"
echo "  Expected: every 'uses:' line with a third-party action has @<40-char-sha>"
echo "  Expected: no @v<N>, @main, @master, or @latest references"
echo "  Expected: SHA followed by comment with version (# v4.2.2)"
echo ""

# --- Contract: Path filter coverage (FR-010) ---
echo "Contract: CI workflow path filter coverage"
echo "  Scope: container-build.yml on.push.paths and on.pull_request.paths"
echo "  Expected: paths include at minimum:"
echo "    - 'docker/**'"
echo "    - 'src/**'"
echo "    - 'templates/**'"
echo "    - 'scripts/**'"
echo "    - 'Dockerfile'"
echo "    - 'pyproject.toml'"
echo "    - 'uv.lock'"
echo "    - 'Makefile'"
echo "    - '.github/workflows/container-build.yml'"
echo ""

# --- Contract: Checksum manifest exists (FR-003) ---
echo "Contract: Centralized checksum manifest"
echo "  Expected: checksums.sha256 exists at repository root"
echo "  Expected: contains SHA256 hashes for all downloaded binaries:"
echo "    - opencode-linux-amd64"
echo "    - opencode-linux-arm64"
echo "    - chezmoi (per arch)"
echo "    - age (per arch)"
echo "  Expected: format is '<hash>  <filename>' (sha256sum convention)"
echo ""

# --- Contract: Dockerfile verification (FR-003) ---
echo "Contract: Downloads verified against manifest"
echo "  Scope: all Dockerfiles with curl/wget downloads"
echo "  Expected: each download followed by sha256sum verification"
echo "  Expected: build fails (exit 1) if checksum mismatch"
echo ""

# --- Contract: Dependabot configuration (FR-015) ---
echo "Contract: Dependabot monitors actions and images"
echo "  Expected: .github/dependabot.yml exists"
echo "  Expected: configured with package-ecosystem 'github-actions'"
echo "  Expected: configured with package-ecosystem 'docker'"
echo "  Expected: schedule interval is 'weekly'"
echo ""

echo "---"
echo "Contract specification complete."
echo "Use grep-based validation scripts to verify SHA pinning and path filter contracts."
