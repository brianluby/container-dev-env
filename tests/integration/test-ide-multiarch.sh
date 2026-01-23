#!/usr/bin/env bash
# Integration Test: Multi-architecture build verification
# Verifies docker buildx build succeeds for linux/amd64 and linux/arm64
# Task: T058 (Phase 9)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOCKERFILE="${REPO_ROOT}/src/docker/Dockerfile.ide"
BUILD_CONTEXT="${REPO_ROOT}/src"

echo "=== Test: Multi-arch build (linux/amd64, linux/arm64) ==="

# Check buildx is available
if ! docker buildx version >/dev/null 2>&1; then
  echo "SKIP: docker buildx not available"
  exit 0
fi

# Ensure a builder with multi-platform support exists
builder_name="devenv-multiarch-test"
if ! docker buildx inspect "${builder_name}" >/dev/null 2>&1; then
  echo "Creating buildx builder: ${builder_name}..."
  docker buildx create --name "${builder_name}" --use >/dev/null 2>&1 || true
fi

# Build for both platforms (no push, just verify it builds)
echo "Building for linux/amd64,linux/arm64..."
if docker buildx build \
  --builder "${builder_name}" \
  --platform linux/amd64,linux/arm64 \
  -f "${DOCKERFILE}" \
  "${BUILD_CONTEXT}" 2>&1; then
  echo "PASS: Multi-arch build succeeded for both platforms"
else
  echo "FAIL: Multi-arch build failed"
  exit 1
fi

echo "Multi-arch test completed."
