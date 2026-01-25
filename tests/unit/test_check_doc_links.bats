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

@test "check-doc-links: handles links with query parameters" {
  mkdir -p "$TEST_DIR/docs"

  cat > "$TEST_DIR/README.md" <<'EOF'
# Example

- With query: [docs/page.md?param=value](docs/page.md?param=value)
EOF

  cat > "$TEST_DIR/docs/page.md" <<'EOF'
# Page
EOF

  run bash "$SCRIPT_PATH" --root "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "check-doc-links: handles links with fragments" {
  mkdir -p "$TEST_DIR/docs"

  cat > "$TEST_DIR/README.md" <<'EOF'
# Example

- With fragment: [docs/page.md#section](docs/page.md#section)
EOF

  cat > "$TEST_DIR/docs/page.md" <<'EOF'
# Page

## Section
EOF

  run bash "$SCRIPT_PATH" --root "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "check-doc-links: handles links with both fragment and query" {
  mkdir -p "$TEST_DIR/docs"

  cat > "$TEST_DIR/README.md" <<'EOF'
# Example

- Combined: [docs/page.md?foo=bar#section](docs/page.md?foo=bar#section)
EOF

  cat > "$TEST_DIR/docs/page.md" <<'EOF'
# Page
EOF

  run bash "$SCRIPT_PATH" --root "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "check-doc-links: handles image links" {
  mkdir -p "$TEST_DIR/docs/images"

  cat > "$TEST_DIR/README.md" <<'EOF'
# Example

![Logo](docs/images/logo.png)
EOF

  touch "$TEST_DIR/docs/images/logo.png"

  run bash "$SCRIPT_PATH" --root "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "check-doc-links: fails on broken image links" {
  mkdir -p "$TEST_DIR/docs"

  cat > "$TEST_DIR/README.md" <<'EOF'
# Example

![Missing](docs/missing.png)
EOF

  run bash "$SCRIPT_PATH" --root "$TEST_DIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *"BROKEN:"* ]]
}

@test "check-doc-links: handles links with angle brackets" {
  mkdir -p "$TEST_DIR/docs"

  cat > "$TEST_DIR/README.md" <<'EOF'
# Example

- Bracketed: [page](<docs/page.md>)
EOF

  cat > "$TEST_DIR/docs/page.md" <<'EOF'
# Page
EOF

  run bash "$SCRIPT_PATH" --root "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "check-doc-links: skips pure anchor links" {
  mkdir -p "$TEST_DIR/docs"

  cat > "$TEST_DIR/README.md" <<'EOF'
# Example

- [Jump to section](#section)

## Section

Content here.
EOF

  run bash "$SCRIPT_PATH" --root "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "check-doc-links: handles directory links" {
  mkdir -p "$TEST_DIR/docs/subdir"

  cat > "$TEST_DIR/README.md" <<'EOF'
# Example

- [Docs folder](docs/subdir)
EOF

  run bash "$SCRIPT_PATH" --root "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}
