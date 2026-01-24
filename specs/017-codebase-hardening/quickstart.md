# Quickstart: Codebase Hardening

**Feature**: 017-codebase-hardening | **Date**: 2026-01-24

---

## Prerequisites

- Bash 5.x
- `jq` installed
- BATS test framework (in `tests/unit/.bats-battery/`)
- ShellCheck (for linting)
- Docker + BuildKit (for container builds)
- `sha256sum` (coreutils, already in Debian base)

## Development Workflow

### 1. Run existing tests first (baseline)

```bash
# Run existing BATS tests to establish baseline
tests/unit/.bats-battery/bats-core/bin/bats tests/unit/

# Run ShellCheck on all scripts
shellcheck scripts/*.sh src/agent/*.sh src/agent/lib/*.sh src/scripts/*.sh
```

### 2. Write security tests (TDD: Red phase)

Create test files in `tests/unit/`:
- `test_agent_injection.bats` — Command injection vectors
- `test_secrets_load.bats` — Safe secrets parsing
- `test_json_escape.bats` — JSON construction safety

```bash
# Run new tests (should FAIL before implementation)
tests/unit/.bats-battery/bats-core/bin/bats tests/unit/test_agent_injection.bats
tests/unit/.bats-battery/bats-core/bin/bats tests/unit/test_secrets_load.bats
tests/unit/.bats-battery/bats-core/bin/bats tests/unit/test_json_escape.bats
```

### 3. Implement fixes (TDD: Green phase)

Priority order:
1. **P1**: Fix command injection in `src/agent/lib/provider.sh` + `src/agent/agent.sh`
2. **P1**: Fix JSON injection in `src/agent/lib/session.sh` + `src/agent/lib/log.sh`
3. **P2**: Rewrite `scripts/secrets-load.sh` for safe parsing
4. **P2**: Add checksum verification to Dockerfiles + create `checksums.sha256`
5. **P2**: Fix port binding and auth in agent server mode
6. **P2**: Fix CI workflows (SHA pins + path filters)
7. **P3**: Fix secrets editor, add strict mode, create ADR + Dependabot config

### 4. Verify (TDD: Green confirmation)

```bash
# All security tests pass
tests/unit/.bats-battery/bats-core/bin/bats tests/unit/test_agent_injection.bats
tests/unit/.bats-battery/bats-core/bin/bats tests/unit/test_secrets_load.bats
tests/unit/.bats-battery/bats-core/bin/bats tests/unit/test_json_escape.bats

# All existing tests still pass
tests/unit/.bats-battery/bats-core/bin/bats tests/unit/

# ShellCheck passes
shellcheck scripts/*.sh src/agent/*.sh src/agent/lib/*.sh

# Container builds with checksum verification
docker build -t devcontainer:test .

# Verify SHA pinning (no @vN references)
grep -rn 'uses:' .github/workflows/ | grep -v '@[a-f0-9]\{40\}'
# (should return empty if all pinned)
```

### 5. Validate contracts

```bash
# Run contract test scripts
bash specs/017-codebase-hardening/contracts/secrets-loader.contract.sh
bash specs/017-codebase-hardening/contracts/agent-execution.contract.sh
bash specs/017-codebase-hardening/contracts/ci-supply-chain.contract.sh
bash specs/017-codebase-hardening/contracts/shell-standards.contract.sh
```

## Key Files to Modify

| File | Change | FR |
|------|--------|-----|
| `src/agent/lib/provider.sh` | Replace string-based `build_backend_command` with array | FR-001 |
| `src/agent/agent.sh` | Replace `eval "${cmd}"` with `"${cmd[@]}"` | FR-001 |
| `src/agent/lib/session.sh` | Use `jq` for session JSON creation | FR-002 |
| `src/agent/lib/log.sh` | Use `jq` for JSONL log entries | FR-002 |
| `scripts/secrets-load.sh` | Rewrite with safe line-by-line parser | FR-004/005/006/014/017 |
| `scripts/secrets-edit.sh` | Fix `printf` usage for special chars | FR-011 |
| `Dockerfile` | Add checksum verification for downloads | FR-003 |
| `docker/Dockerfile.agent` | Add checksums, localhost bind, auth check | FR-003/007/008 |
| `.github/workflows/*.yml` | Pin SHAs, expand paths | FR-009/010 |
| `.github/dependabot.yml` | New: actions + docker monitoring | FR-015 |
| `checksums.sha256` | New: centralized checksum manifest | FR-003 |
| `docs/adr/NNN-container-images.md` | New: container image ADR | FR-013 |

## Verification Checklist

- [ ] No `eval` in agent execution path
- [ ] All session/log JSON passes `jq empty` with hostile input
- [ ] All downloads have SHA256 verification
- [ ] Build fails on checksum mismatch
- [ ] Secrets loader rejects command substitution patterns
- [ ] Secrets loader rejects world-readable files
- [ ] Agent server binds to 127.0.0.1 only
- [ ] Agent server refuses to start without auth config
- [ ] All GitHub Actions pinned to SHAs
- [ ] CI triggers on docker/**, src/**, templates/** changes
- [ ] Dependabot monitors actions and docker
- [ ] All .sh files have `set -euo pipefail`
- [ ] Secrets editor round-trips special characters
- [ ] Container image ADR exists
- [ ] All diagnostics use `[ERROR]/[WARN]` format
