#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  SCRIPT_PATH="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../scripts" && pwd)/check-doc-links.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "check-doc-links: passes on valid links" {
  mkdir -p "$TEST_DIR/docs/getting-started" "$TEST_DIR/docs/reference"

  cat > "$TEST_DIR/README.md" <<'EOF'
# Example

- Getting started: [docs/getting-started/index.md](docs/getting-started/index.md)
EOF

  cat > "$TEST_DIR/docs/getting-started/index.md" <<'EOF'
# Getting Started

See [configuration](../reference/configuration.md).
EOF

  cat > "$TEST_DIR/docs/reference/configuration.md" <<'EOF'
# Configuration

Back to [README](../../README.md).
EOF

  run bash "$SCRIPT_PATH" --root "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "check-doc-links: fails on broken links" {
  mkdir -p "$TEST_DIR/docs"

  cat > "$TEST_DIR/README.md" <<'EOF'
# Example

- Missing: [docs/missing.md](docs/missing.md)
EOF

  cat > "$TEST_DIR/docs/ok.md" <<'EOF'
# OK
EOF

  run bash "$SCRIPT_PATH" --root "$TEST_DIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *"BROKEN:"* ]]
  [[ "$output" == *"docs/missing.md"* ]]
}
