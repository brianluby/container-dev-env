#!/usr/bin/env bats
# test_templates.bats — Template validation tests for AGENTS.md templates
# Tests: T006, T007, T008, T012, T013, T018, T019

TESTS_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PROJECT_ROOT="$(cd "${TESTS_DIR}/../.." && pwd)"
TEMPLATES_DIR="${PROJECT_ROOT}/src/templates"

# --- User Story 1: Comprehensive Template Tests (T006, T007, T008) ---

@test "T006: comprehensive template is valid Markdown, under 10KB, UTF-8, LF line endings" {
  local template="${TEMPLATES_DIR}/AGENTS.md.full"
  [ -f "$template" ]

  # Under 10KB
  local size
  size=$(wc -c < "$template")
  [ "$size" -lt 10240 ]

  # UTF-8 encoding
  local encoding
  encoding=$(file --mime-encoding "$template" | awk -F': ' '{print $2}')
  [[ "$encoding" == "utf-8" || "$encoding" == "us-ascii" ]]

  # LF line endings (no carriage returns)
  ! grep -Pq '\r' "$template"
}

@test "T007: comprehensive template contains all 9 required section headings" {
  local template="${TEMPLATES_DIR}/AGENTS.md.full"

  grep -q "^## Overview" "$template"
  grep -q "^## Technology Stack" "$template"
  grep -q "^## Coding Standards" "$template"
  grep -q "^## Architecture" "$template"
  grep -q "^## Common Patterns" "$template"
  grep -q "^## Testing Requirements" "$template"
  grep -q "^## Git Workflow" "$template"
  grep -q "^## Security Considerations" "$template"
  grep -q "^## AI Agent Instructions" "$template"
}

@test "T008: comprehensive template contains security warning HTML comments" {
  local template="${TEMPLATES_DIR}/AGENTS.md.full"

  grep -q "WARNING.*Do NOT include.*secrets" "$template"
  grep -q "API keys" "$template"
  grep -q "passwords" "$template"
}

# --- User Story 2: Minimal Template Tests (T012, T013) ---

@test "T012: minimal template is valid Markdown, under 10KB, UTF-8, LF line endings" {
  local template="${TEMPLATES_DIR}/AGENTS.md.minimal"
  [ -f "$template" ]

  # Under 10KB
  local size
  size=$(wc -c < "$template")
  [ "$size" -lt 10240 ]

  # UTF-8 encoding
  local encoding
  encoding=$(file --mime-encoding "$template" | awk -F': ' '{print $2}')
  [[ "$encoding" == "utf-8" || "$encoding" == "us-ascii" ]]

  # LF line endings (no carriage returns)
  ! grep -Pq '\r' "$template"
}

@test "T013: CLAUDE.md template does not duplicate AGENTS.md section headings" {
  local claude_template="${TEMPLATES_DIR}/CLAUDE.md.template"
  local agents_template="${TEMPLATES_DIR}/AGENTS.md.full"

  [ -f "$claude_template" ]
  [ -f "$agents_template" ]

  # Extract section headings from AGENTS.md.full
  local agents_headings
  agents_headings=$(grep "^## " "$agents_template" | sed 's/^## //')

  # Verify none of these appear in CLAUDE.md.template
  while IFS= read -r heading; do
    ! grep -q "^## ${heading}" "$claude_template"
  done <<< "$agents_headings"
}

# --- User Story 3: Nested Template Tests (T018, T019) ---

@test "T018: nested template is valid Markdown, under 10KB, UTF-8, LF line endings" {
  local template="${TEMPLATES_DIR}/nested-AGENTS.md"
  [ -f "$template" ]

  # Under 10KB
  local size
  size=$(wc -c < "$template")
  [ "$size" -lt 10240 ]

  # UTF-8 encoding
  local encoding
  encoding=$(file --mime-encoding "$template" | awk -F': ' '{print $2}')
  [[ "$encoding" == "utf-8" || "$encoding" == "us-ascii" ]]

  # LF line endings (no carriage returns)
  ! grep -Pq '\r' "$template"
}

@test "T019: nested template contains Module Purpose section heading" {
  local template="${TEMPLATES_DIR}/nested-AGENTS.md"

  grep -q "^## Module Purpose" "$template"
}
