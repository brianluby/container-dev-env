# Research: Codebase Hardening

**Feature**: 017-codebase-hardening | **Date**: 2026-01-23 | **Status**: Complete

---

## 1. Safe Command Execution in Bash Without `eval`

**Requirement**: FR-001 (agent command execution MUST NOT use `eval` or interpret shell metacharacters in user-provided task descriptions)

### Decision

Use Bash array-based command construction with direct execution via `"${cmd[@]}"` expansion. Store the command name and each argument as separate array elements, then execute the array directly. For cases where the command needs to replace the current process, use `exec "${cmd[@]}"`.

### Rationale

- Array expansion with `"${cmd[@]}"` treats each element as a distinct argument, preserving spaces and special characters without double-parsing.
- The shell performs exactly one parse pass, so metacharacters in user data (`$()`, backticks, `;`, `|`, `&&`) are never interpreted -- they are passed as literal string arguments to the target command.
- This is the approach recommended by the [BashFAQ/048](https://mywiki.wooledge.org/BashFAQ/048) ("AVOID PASSING DATA TO EVAL AT ALL COSTS").
- The pattern works directly for commands like `opencode run "$task"` or `claude -p "$task"` where `$task` is untrusted user input: `cmd=(opencode run "$task")` followed by `"${cmd[@]}"`.

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| `eval "$cmd_string"` | Double-parsing allows arbitrary code execution via metacharacters in user input. The core vulnerability this feature remediates. |
| `bash -c "$cmd_string"` | Same injection risk as `eval` -- the string undergoes full shell parsing in the child process. Only safe if the command string is fully controlled. |
| Variable indirection (`${!var}`) | Only solves dynamic variable access, not dynamic command execution with arguments. |
| `printf '%q'` quoting | Attempts to escape values for safe `eval` use, but is fragile and error-prone. Still relies on `eval` for execution. |
| Subshell `( command )` | Provides process isolation but does not prevent argument injection if the command string is constructed unsafely. |

### Key Pattern

```text
cmd=(<command> <fixed-arg1> <fixed-arg2> "$untrusted_variable")
"${cmd[@]}"
```

The untrusted variable is always a single array element, never split or interpreted.

---

## 2. Safe JSON Construction in Bash

**Requirement**: FR-002 (all JSON construction MUST properly escape user-controlled fields)

### Decision

Use `jq` with `--arg` for string values and `--argjson` for typed values, combined with `--null-input` (`-n`) to construct JSON from scratch without stdin. Never interpolate shell variables directly into jq filter strings.

### Rationale

- `jq --arg name "$value"` handles all JSON escaping automatically: quotes, backslashes, newlines, control characters, and unicode. The shell variable is passed as a pre-bound jq variable, never parsed as part of the filter expression.
- `jq --argjson name "$json_value"` validates that the value is already valid JSON before binding, catching malformed data early.
- `jq -n` allows building JSON objects from nothing (no stdin needed), making it ideal for creating log entries and session records.
- This approach completely eliminates JSON injection because user data never appears in the jq filter string -- it is always accessed via `$variable_name` within the jq expression.

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| `printf '{"key": "%s"}' "$value"` | Does not escape embedded quotes, backslashes, newlines, or control characters. Produces invalid JSON for many real inputs. |
| `python -c "import json; ..."` | Adds Python runtime dependency. Correct but heavyweight for simple JSON construction in shell scripts. |
| Manual escaping with `sed`/`tr` | Fragile, error-prone, and inevitably misses edge cases (unicode, control chars). Reimplements what `jq` already does correctly. |
| `jo` (JSON output tool) | Less widely available than `jq`, not in base image. Would add a new dependency. |
| Here-doc with variable substitution | Same problem as printf -- no automatic escaping of special JSON characters. |

### Key Pattern

```text
jq -n \
  --arg task "$untrusted_task" \
  --arg timestamp "$ts" \
  --argjson exit_code "$code" \
  '{"task": $task, "timestamp": $timestamp, "exit_code": $exit_code}'
```

Named arguments are also accessible via `$ARGS.named` for complex filters.

---

## 3. Checksum Verification Patterns in Dockerfiles

**Requirement**: FR-003 (all external binary downloads MUST be verified against SHA256 checksums)

### Decision

Use `sha256sum -c` verification in `RUN` commands with architecture-specific checksum selection via `TARGETARCH` build arg. Store checksums in a centralized `checksums.sha256` manifest file at repository root. The Dockerfile copies in the manifest and uses shell logic to select the correct checksum per architecture.

### Rationale

- `sha256sum -c` is available in all Debian-based images (coreutils), requires no additional dependencies.
- The `TARGETARCH` build arg (automatically set by BuildKit in multi-platform builds) enables a single Dockerfile to verify different binaries for amd64 vs arm64.
- A centralized manifest file at repo root (`checksums.sha256`) makes checksum updates discoverable and auditable in code review. Dependabot or manual updates can target a single file.
- The multi-stage build pattern keeps download/verification logic separate from the final image, reducing attack surface and layer bloat.
- Immediate `exit 1` on checksum mismatch ensures builds fail fast with clear error messages.

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| `ADD --checksum=sha256:<hash>` | Cannot parameterize the hash per `TARGETARCH` -- requires hard-coding a single hash per `ADD` instruction. Impractical for multi-arch builds. Only supports HTTP(S) sources. Known bugs with algorithm handling. |
| GPG signature verification | Not all upstream projects provide GPG signatures. Adds key management complexity (importing, trusting keys). Checksums are sufficient when the manifest is version-controlled. |
| `openssl dgst -sha256` | Produces different output format than `sha256sum`, requiring custom parsing. Less standard for Dockerfile patterns. |
| Per-binary checksums in Dockerfile comments | Scatters checksums across multiple files and stages. Hard to audit, easy to miss during updates. |
| No verification (trust HTTPS) | HTTPS only authenticates the server, not the file content. A compromised CDN or mirror serves malicious binaries over valid TLS. |

### Key Pattern

```text
COPY checksums.sha256 /tmp/checksums.sha256

ARG TARGETARCH
RUN case "$TARGETARCH" in \
      amd64) HASH="<sha256-amd64>" ;; \
      arm64) HASH="<sha256-arm64>" ;; \
    esac && \
    curl -fsSL -o /tmp/binary "$DOWNLOAD_URL" && \
    echo "$HASH  /tmp/binary" | sha256sum -c - && \
    install /tmp/binary /usr/local/bin/
```

Alternative: grep the relevant line from `checksums.sha256` for the architecture-specific filename.

---

## 4. Safe KEY=VALUE File Parsing in Bash

**Requirement**: FR-004, FR-006, FR-014, FR-017 (safe line-by-line parsing, key validation, command substitution rejection, first-`=` split)

### Decision

Use a `while IFS='=' read -r key value` loop that: (1) skips comments and blank lines, (2) validates key format against `^[A-Z_][A-Z0-9_]*$`, (3) rejects values containing command substitution patterns (`$()`, `${}`, backticks), (4) splits only on the first `=` (inherent to `read -r` with two variables), and (5) exports validated pairs without `eval` or `source`.

### Rationale

- `IFS='=' read -r key value` naturally splits on the first `=` only -- all subsequent `=` characters remain in `$value`. The `-r` flag prevents backslash interpretation.
- Key validation via regex (`[[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]]`) ensures only safe variable names are accepted, blocking injection through malformed keys.
- Explicit pattern matching for `$()`, `${}`, and backticks in values catches command substitution attempts without over-blocking bare `$` characters (per clarification).
- `export "$key=$value"` (with validated key) is safe because `export` with a literal assignment does not invoke shell expansion on the value.
- Permission checking (`stat -c %a` or equivalent) before parsing prevents reading tampered world-readable files.

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| `source .env` / `. .env` | Executes the file as shell code. Any command substitution, subshell, or function definition in the file is executed with full shell privileges. This is the vulnerability being fixed. |
| `set -a; source .env; set +a` | Same as `source` -- `set -a` only controls auto-export, does not prevent code execution. |
| `sed` + `export` pipeline | Fragile regex-based approaches miss edge cases. Also vulnerable if `sed` output is passed to `eval`. |
| `envfile` / `dotenv` external tools | Adds runtime dependencies. `shdotenv` is comprehensive but introduces a third-party dependency. |
| `declare` instead of `export` | `declare` with untrusted key names can still set unexpected shell options or variables. Key validation is still required regardless. |
| Python `dotenv` library | Correct and safe, but adds Python runtime dependency to what should be a pure-shell operation at container startup. |

### Key Pattern

```text
while IFS='=' read -r key value; do
  [[ -z "$key" || "$key" == \#* ]] && continue
  [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] || { warn "invalid key: $key"; continue; }
  if [[ "$value" =~ \$\( || "$value" =~ \$\{ || "$value" =~ \` ]]; then
    warn "command substitution rejected in: $key"; continue
  fi
  export "$key=$value"
done < "$secrets_file"
```

---

## 5. GitHub Actions SHA Pinning

**Requirement**: FR-009 (all third-party Actions pinned to commit SHAs), FR-015 (Dependabot configured for monitoring)

### Decision

Pin all third-party GitHub Actions to full-length (40-character) commit SHAs with a trailing comment indicating the human-readable version tag. Configure Dependabot with `package-ecosystem: github-actions` for automated update PRs. Use `pinact` CLI tool for initial bulk conversion.

### Rationale

- Full SHA pinning is the only way to get an immutable reference to an action's code. Tags are mutable and can be force-pushed to point at malicious commits (supply-chain attack vector demonstrated in the `tj-actions/changed-files` compromise).
- The trailing comment (e.g., `# v4.2.2`) serves two purposes: human readability and enabling Dependabot to detect available updates and create PRs.
- Dependabot's `github-actions` ecosystem natively understands SHA-pinned actions with version comments, creating PRs that update both the SHA and the comment.
- GitHub now offers organization-level policies to enforce SHA pinning, providing a governance backstop.

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| Tag pinning (`@v4`) | Tags are mutable. A compromised repository can rewrite tags to point at malicious code. No integrity guarantee. |
| Major version tags (`@v4`) with `actions/allowed-actions` | Reduces scope but still vulnerable to tag rewriting. Does not provide immutability. |
| Renovate instead of Dependabot | Renovate is more configurable but Dependabot is native to GitHub, zero-config for this use case, and already available per assumptions. |
| Manual SHA tracking | Error-prone, does not scale. No automated PR creation for updates. |
| Vendoring actions into the repository | Extreme measure. Eliminates supply-chain risk but creates maintenance burden and bloats the repository. |

### Key Pattern

Workflow file:
```text
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
```

Dependabot configuration (`.github/dependabot.yml`):
```text
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

### Tools for Initial Conversion

- **pinact** (`suzukishunsuke/pinact`): CLI tool that scans workflows and replaces tag references with SHA pins plus version comments.
- **pin-github-action** (`mheap/pin-github-action`): Alternative CLI tool with similar functionality.
- **StepSecurity Harden-Runner**: Automated scanning and PR generation for SHA pinning.

---

## 6. BATS Testing Patterns for Security Tests

**Requirement**: SC-001 (hostile-input test suite passing 100%), SC-004 (zero unintended command executions)

### Decision

Use BATS with `bats-assert` helpers (`assert_success`, `assert_failure`, `assert_output`, `refute_output`) to validate that hostile inputs are NOT executed. Structure tests as: (1) set up a canary (a detectable side-effect marker), (2) pass hostile input through the function under test, (3) assert the canary was NOT triggered and the output does not contain evidence of execution.

### Rationale

- BATS executes each `@test` block in its own process, providing natural isolation between security tests -- a failed injection in one test cannot affect others.
- `refute_output --partial` is the primary assertion for injection tests: it verifies that command output from an injection attempt does NOT appear in the program's output.
- Canary-based testing (e.g., creating a temp file as the "injected command" and asserting it was never created) provides definitive proof that the injection did not execute, beyond just checking output.
- The `run` helper captures both stdout and exit code, enabling assertions on both the output content and the success/failure status.
- BATS' `setup` and `teardown` functions provide consistent test fixture management (creating temp dirs, cleaning up canary files).

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| ShellCheck alone | Static analysis catches some issues but cannot verify runtime behavior. Does not test that specific hostile inputs are handled correctly. |
| Manual `test` assertions | Verbose, no TAP output, no test isolation, no helper ecosystem. Reinvents what BATS provides. |
| Python `subprocess` tests | Adds a language boundary. BATS tests live closer to the code under test and share the same shell semantics. |
| `shunit2` | Less actively maintained than bats-core. Smaller ecosystem of assertion helpers. |
| Container-level integration tests only | Too coarse-grained for injection testing. Cannot isolate which function or path is vulnerable. Unit-level BATS tests pinpoint exact failure locations. |

### Key Patterns

**Pattern 1: Canary-based injection test**
```text
@test "agent rejects command substitution in task" {
  canary=$(mktemp)
  rm -f "$canary"
  hostile_task='$(touch '"$canary"')'

  run agent_execute "$hostile_task"

  assert_success
  [ ! -f "$canary" ]  # Canary file must NOT exist
}
```

**Pattern 2: Output-based injection test**
```text
@test "agent does not execute backtick injection" {
  run agent_execute '`whoami`'

  assert_success
  refute_output --partial "$(whoami)"  # Real username must not appear
  assert_output --partial '`whoami`'   # Literal backticks preserved in output
}
```

**Pattern 3: Multi-vector injection sweep**
```text
HOSTILE_INPUTS=(
  '; rm -rf /'
  '$(cat /etc/passwd)'
  '`id`'
  '| cat /etc/shadow'
  '&& echo pwned'
  $'\n; echo injected'
)

for input in "${HOSTILE_INPUTS[@]}"; do
  @test "rejects injection vector: ${input:0:20}..." {
    run target_function "$input"
    refute_output --partial "pwned"
    refute_output --partial "root:"
    refute_output --partial "uid="
  }
done
```

**Pattern 4: Permission-based security test**
```text
@test "secrets loader rejects world-readable file" {
  chmod 644 "$TEST_SECRETS_FILE"

  run secrets_load "$TEST_SECRETS_FILE"

  assert_failure
  assert_output --partial "[ERROR]"
  assert_output --partial "permission"
}
```

### Test Organization

- Group security tests in dedicated files (`test_agent_injection.bats`, `test_secrets_load.bats`, `test_json_escape.bats`).
- Use `setup_file()` for one-time fixtures and `setup()` for per-test isolation.
- Load shared helpers via `bats_load_library` for `bats-assert` and `bats-support`.
- Run security tests as part of CI with `bats --timing tests/unit/`.

---

## Sources

- [BashFAQ/048 - Eval Alternatives](https://mywiki.wooledge.org/BashFAQ/048)
- [Safely Execute Commands with Bash Eval Alternatives](https://sqlpey.com/bash/safely-execute-commands-bash-eval-alternatives/)
- [jq 1.8 Manual](https://jqlang.org/manual/)
- [Baeldung: Passing Bash Variables to jq](https://www.baeldung.com/linux/jq-passing-bash-variables)
- [Verifying Download Hashes During Docker Build](https://adrianhesketh.com/2022/01/26/verifying-download-hashes-during-docker-build/)
- [Docker: How to Verify Your Downloads in Builds](https://www.coguard.io/post/how-to-verify-your-downloads-in-docker-builds)
- [Dockerfile Reference - ADD](https://docs.docker.com/reference/dockerfile/)
- [bashup/dotenv - Programmatic .env Parsing](https://github.com/bashup/dotenv)
- [Baeldung: Parsing Properties Files in Linux](https://www.baeldung.com/linux/script-parsing-properties-file)
- [StepSecurity: Pinning GitHub Actions](https://www.stepsecurity.io/blog/pinning-github-actions-for-enhanced-security-a-complete-guide)
- [Why You Should Pin Actions by Commit-Hash](https://blog.rafaelgss.dev/why-you-should-pin-actions-by-commit-hash)
- [GitHub Actions Policy: SHA Pinning Support](https://github.blog/changelog/2025-08-15-github-actions-policy-now-supports-blocking-and-sha-pinning-actions/)
- [GitHub: Secure Use Reference](https://docs.github.com/en/actions/reference/security/secure-use)
- [BATS Core Documentation](https://bats-core.readthedocs.io/en/stable/)
- [bats-assert: Common Assertions](https://github.com/ztombol/bats-assert)
- [HackerOne: Testing Bash Scripts with BATS](https://www.hackerone.com/blog/testing-bash-scripts-bats-practical-guide)
- [Apple: Shell Script Security](https://developer.apple.com/library/archive/documentation/OpenSource/Conceptual/ShellScripting/ShellScriptSecurity/ShellScriptSecurity.html)
