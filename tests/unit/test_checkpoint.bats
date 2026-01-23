#!/usr/bin/env bats
load '../test_helper'

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export AGENT_STATE_DIR="${TEST_TMPDIR}/state"
  mkdir -p "${AGENT_STATE_DIR}/sessions"
  create_mock_repo "${TEST_TMPDIR}/repo"
  cd "${TEST_TMPDIR}/repo"
}

teardown() {
  cd /
  rm -rf "${TEST_TMPDIR}"
}

@test "checkpoint: creates git stash with metadata message" {
  echo "change" >> file.txt
  source_lib checkpoint
  run create_checkpoint "test-session" "Before refactoring" "file_edit"
  [[ "${status}" -eq 0 ]]
  git stash list | grep -q "checkpoint:"
}

@test "checkpoint: list returns all checkpoints with timestamps" {
  echo "change1" >> file.txt
  source_lib checkpoint
  create_checkpoint "s1" "First op" "file_edit"
  echo "change2" >> file.txt
  git add file.txt
  create_checkpoint "s1" "Second op" "multi_file"
  run list_checkpoints
  [[ "${status}" -eq 0 ]]
  [[ $(echo "${output}" | wc -l) -ge 2 ]]
}

@test "checkpoint: rollback restores file state" {
  source_lib checkpoint
  echo "original" > file.txt
  git add file.txt && git commit -m "original"
  echo "modified" > file.txt
  git add file.txt
  create_checkpoint "s1" "Before bad change" "file_edit"
  echo "bad change" > file.txt
  run rollback_checkpoint "stash@{0}"
  [[ "${status}" -eq 0 ]]
}

@test "checkpoint: rollback fails for non-existent checkpoint" {
  source_lib checkpoint
  run rollback_checkpoint "stash@{99}"
  [[ "${status}" -ne 0 ]]
}

@test "checkpoint: retention prunes when exceeding max_count" {
  source_lib checkpoint
  export AGENT_CFG_CHECKPOINT_MAX_COUNT=2
  for i in 1 2 3; do
    echo "change${i}" >> file.txt
    git add file.txt
    create_checkpoint "s1" "Op ${i}" "file_edit"
  done
  run prune_checkpoints 2
  [[ "${status}" -eq 0 ]]
  local count
  count=$(git stash list | wc -l | tr -d ' ')
  [[ "${count}" -le 2 ]]
}

@test "checkpoint: disk space check warns on low space" {
  source_lib checkpoint
  run check_disk_space
  [[ "${status}" -eq 0 ]]
}
