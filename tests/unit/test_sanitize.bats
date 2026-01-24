#!/usr/bin/env bats

# Tests for content sanitization in notify-sanitize.sh
# T017 [US5]: Sanitization tests

load "../helpers/test_helper.bash"

setup() {
  setup_test_env
  source_sanitize
}

teardown() {
  teardown_test_env
}

@test "sanitize: strips absolute file paths" {
  local result
  result="$(sanitize_message "Error in /home/user/project/src/auth.ts on line 42")"
  [[ "${result}" != *"/home/user/project/src/auth.ts"* ]]
  [[ "${result}" =~ "Error in" ]]
}

@test "sanitize: strips paths with dots and tildes" {
  local result
  result="$(sanitize_message "Found issue at /usr/local/lib/node_modules/.bin/tsc")"
  [[ "${result}" != *"/usr/local/lib"* ]]
}

@test "sanitize: strips API key pattern sk-*" {
  local result
  result="$(sanitize_message "API key sk-abc123def456ghi789 was used")"
  [[ "${result}" != *"sk-abc123def"* ]]
}

@test "sanitize: strips token pattern tk_*" {
  local result
  result="$(sanitize_message "Token tk_tokenvalue123abc was expired")"
  [[ "${result}" != *"tk_tokenvalue123abc"* ]]
}

@test "sanitize: strips long uppercase strings (20+ chars)" {
  local result
  result="$(sanitize_message "Key ABCDEFGHIJKLMNOPQRSTUVWXYZ was found")"
  [[ "${result}" != *"ABCDEFGHIJKLMNOPQRSTUVWXYZ"* ]]
}

@test "sanitize: strips env var assignments" {
  local result
  result="$(sanitize_message "Set API_KEY=secret123value for auth")"
  [[ "${result}" != *"API_KEY=secret123value"* ]]
}

@test "sanitize: strips lines with curly braces" {
  local result
  result="$(sanitize_message "function foo() { return bar; }")"
  [[ "${result}" != *"{"* ]]
  [[ "${result}" != *"}"* ]]
}

@test "sanitize: strips lines with semicolons" {
  local result
  result="$(sanitize_message "const x = 5; let y = 10;")"
  [[ "${result}" != *";"* ]]
}

@test "sanitize: strips lines with 'function ' keyword" {
  local result
  result="$(sanitize_message "function handleError(err) found")"
  [[ "${result}" != *"function "* ]]
}

@test "sanitize: strips lines with 'class ' keyword" {
  local result
  result="$(sanitize_message "class UserService extends BaseService")"
  [[ "${result}" != *"class "* ]]
}

@test "sanitize: strips lines with 'import ' keyword" {
  local result
  result="$(sanitize_message "import { useState } from react")"
  [[ "${result}" != *"import "* ]]
}

@test "sanitize: collapses multiple spaces to single" {
  local result
  result="$(sanitize_message "Hello    world     test")"
  [[ "${result}" == *"Hello world test"* ]]
}

@test "sanitize: truncates to 200 characters" {
  local long_msg
  long_msg="$(printf 'A%.0s' {1..250})"
  local result
  result="$(sanitize_message "${long_msg}")"
  [[ "${#result}" -le 200 ]]
}

@test "sanitize: preserves non-sensitive text" {
  local result
  result="$(sanitize_message "Task completed successfully with 12 files updated")"
  [[ "${result}" == "Task completed successfully with 12 files updated" ]]
}

@test "sanitize: handles empty input" {
  local result
  result="$(sanitize_message "")"
  [[ -z "${result}" ]]
}

@test "sanitize: combined patterns — strips path and key together" {
  local result
  result="$(sanitize_message "Error in /src/auth.ts: sk-abc123 token invalid")"
  [[ "${result}" != *"/src/auth.ts"* ]]
  [[ "${result}" != *"sk-abc123"* ]]
}
