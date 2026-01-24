# Code Review (2026-01-23)

Repo: `container-dev-env` (dev container + agent wrapper + IDE image tooling)

## Scope

Reviewed: Dockerfiles/Compose, shell scripts in `scripts/` + `src/scripts/`, agent wrapper in `src/agent/`, CI workflows in `.github/workflows/`, and BATS/unit/contract/integration tests in `tests/`.

## Executive Take

Strong foundations: clear specs-driven structure, lots of automated tests (unit/contract/integration), and good security intent (secret scanning contract tests, telemetry blocking, token gating for IDE).

Main risks are (1) command/JSON injection in the agent wrapper, and (2) supply-chain integrity gaps in container builds (curl|bash/sh, unverified downloads, unpinned GitHub Actions).

## Findings (Prioritized)

### Blocker

1) Agent command injection via `eval`
- Risk: task descriptions can break quoting and execute arbitrary shell.
- Location: `src/agent/agent.sh:656` (`eval "${cmd}"`). The command string is built with embedded quotes in `src/agent/lib/provider.sh:125-144`.
- Recommendation: remove `eval` and build an argv array; pass task as a single argument without re-parsing by the shell. Example approach:
  - `cmd=(opencode run "${task}")` then `"${cmd[@]}"` (or `exec`), and for Claude `cmd=(claude -p "${task}")`.
  - If you must keep string-building, use `printf '%q'` for every argv element (still inferior to arrays).

2) Session/action logs can be corrupted or injection-prone due to unescaped JSON construction
- Risk: any `"`, `\`, newline, or control char in `task_description`, `target`, or `details` makes invalid JSON; downstream tooling that assumes valid JSON may break or misparse.
- Locations:
  - `src/agent/lib/log.sh:99-101` uses `printf '{..."%s"...}'` with raw fields.
  - `src/agent/lib/session.sh:45-66` writes JSON with raw interpolation (notably `task_description`).
- Recommendation: construct JSON with `jq -n` / `jq --arg ...` so escaping is correct. Add unit tests for quotes/newlines in `task_description` and `details`.

### Major

3) Secrets loader executes arbitrary shell when sourcing `.secrets.env`
- Risk: `source` executes command substitutions / backticks inside values; a compromised secrets file becomes code execution at shell startup.
- Location: `scripts/secrets-load.sh:212-215`.
- Recommendation: parse `KEY=value` lines and `export` without `source` (treat values as opaque strings). If you intentionally support shell syntax, document it clearly as a trust boundary.

4) `secrets-edit.sh add` is unsafe for common secret values
- Risk: values containing `&`, `|`, `\`, or the delimiter break the `sed` replacement; `echo` can also mangle content starting with `-n` or containing escapes.
- Location: `scripts/secrets-edit.sh:187-200` (grep/sed update path).
- Recommendation: avoid `sed` substitution with untrusted replacement text; update by rewriting the file via a line-based loop (or `awk`) and use `printf '%s\n'` instead of `echo` for content.

5) Supply-chain integrity gaps in Docker builds
- Risks: remote scripts and binaries are fetched/executed without checksum or signature verification.
- Locations:
  - `Dockerfile:76-78` (NodeSource setup script via `curl | bash`).
  - `Dockerfile:88-89` (Chezmoi install via `curl | sh`).
  - `Dockerfile:92-95` (age tarball download without checksum verification).
  - `src/scripts/install-extensions.sh:14-24` (VSIX downloads without checksum verification).
- Recommendation: prefer signed apt repos / pinned digests; otherwise pin expected checksums in-repo and verify (similar to `src/scripts/opencode-verify.sh`).

6) GitHub Actions workflow uses an unpinned action ref
- Risk: `@master` can change unexpectedly (supply-chain).
- Location: `.github/workflows/worktree-tests.yml:51-66` (`ludeeus/action-shellcheck@master`).
- Recommendation: pin to a release tag or commit SHA.

7) Several shipped scripts do not follow the repo’s strict-mode standard
- Risk: unset vars and pipeline failures can be missed; behavior diverges across scripts.
- Locations:
  - `docker/entrypoint.sh:13-15` (no `-u`).
  - `scripts/health-check.sh:6` (only `set -e`).
  - `scripts/test-worktree.sh:14-15` (no `-u`).
  - `scripts/test-container.sh:6` (no `-u`/`pipefail`).
  - `scripts/volume-health.sh:10` (only `set -e`).
- Recommendation: standardize on `set -euo pipefail` and fix any resulting issues explicitly.

### Minor

8) Docker Compose file version field is legacy
- Location: `docker/docker-compose.yml:11`.
- Recommendation: remove `version:` for Compose V2+ (optional, but reduces warnings).

9) Docs and scripts mix `docker-compose` and `docker compose`
- Location: `README.md:37-48`.
- Recommendation: prefer `docker compose` (keep `docker-compose` notes only if you explicitly support v1).

## Test Gaps Worth Filling

- Add unit tests that include quotes/newlines in `task_description` and verify `src/agent/lib/session.sh` + `src/agent/lib/log.sh` always produce valid JSON.
- Add a contract/unit test ensuring `agent` does not use `eval` (or, better, that argv passing preserves literal task text).
- Add tests for `scripts/secrets-edit.sh add` with values containing common secret characters (`/`, `+`, `=`, `&`).

## Suggested Tooling (Optional)

- Add a CI job for `shellcheck` over `scripts/` + `src/scripts/` (not just `docker/` and `tests/`).
- Add gitleaks/detect-secrets as recommended in `docs/security-guidance.md`.
