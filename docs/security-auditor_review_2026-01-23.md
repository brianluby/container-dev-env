# Security Audit Review (2026-01-23)

Repository: container-dev-env

This document is an engineering-focused security posture review of the repo's container images, scripts, templates, CI, and docs. It avoids secrets and internal URLs by design.

## Scope And Method

- In scope: Dockerfiles and compose files, entrypoints and shell scripts, agent wrapper, MCP config tooling, Python persistent-memory service, templates and docs, GitHub Actions.
- Out of scope: runtime behavior of external services (LLM providers, ntfy, Slack, GitHub), vulnerabilities inside upstream images/packages beyond the controls used here.
- Methods: static review for OWASP-style issues (input handling, auth, secrets, logging, least privilege), supply-chain risks, and CI/CD hardening opportunities.

## Notable Strengths

- Non-root execution is the default across images (`USER dev` / `USER openvscode-server`), reducing blast radius.
- Strong intent around secret hygiene: `.gitignore` patterns, `docs/security-guidance.md`, `docs/security/authentication.md`, and age+chezmoi workflows.
- `src/mcp/validate-mcp.sh` explicitly detects hardcoded credential-like values in MCP config and encourages `${ENV_VAR}` references.
- `src/docker/docker-compose.ide.yml` binds the IDE to localhost only and enforces a connection token.
- `src/notify.sh` enforces HTTPS for outbound endpoints and sanitizes message content to reduce accidental secret leakage.

## Findings (Prioritized)

Severity scale: Critical, High, Medium, Low.

### F-001 (High) Command Injection Via `eval` In Agent Wrapper

- Affected: `src/agent/agent.sh`, `src/agent/lib/provider.sh`
- Issue: `agent.sh` builds a shell command string that includes a user-controlled task description and executes it with `eval`. `provider.sh` wraps the task in double quotes but does not escape embedded quotes or other shell metacharacters. This is classic shell injection risk.
- Impact: local code execution inside the container under the agent user; with passwordless sudo in several images, this can become container-root.
- Recommendation:
  - Remove `eval` and use argv arrays, e.g. `cmd=(opencode run "$task")` and `exec "${cmd[@]}"`.
  - If a string must be produced, use robust escaping (`printf '%q'`) and still avoid `eval` where possible.
  - Add unit tests covering hostile task strings (quotes, semicolons, subshells).

### F-002 (High) Supply-Chain Risk: Remote Install Scripts And Unverified Downloads

- Affected:
  - `Dockerfile` (NodeSource setup script; chezmoi installer script)
  - `docker/Dockerfile` (NodeSource setup script)
  - `docker/Dockerfile.agent` (optional Claude install via remote script; OpenCode binary download without integrity verification)
  - `src/scripts/install-extensions.sh` (VSIX downloads without checksums)
- Issue: multiple build steps execute remote content directly (curl pipe to shell) and/or download executables without checksum/signature verification.
- Impact: a compromised upstream endpoint, DNS, TLS interception, or upstream account compromise can lead to malicious code baked into images.
- Recommendation:
  - Prefer package-manager installs with pinned repository keys, or vendor artifacts.
  - Pin and verify:
    - OpenCode binary: verify SHA256 (pattern already shown in `src/docker/Dockerfile`).
    - VSIX files: store expected SHA256 in the repo and verify after download.
    - Node installation: avoid the NodeSource script; install via Debian packages where feasible, or add explicit GPG key verification for the repo.
    - Chezmoi: prefer distro packages, or download a specific release artifact and verify checksum.
  - Consider generating and attaching an SBOM (SPDX or CycloneDX) for built images.

### F-003 (High) Network Exposure: Agent Server Port Published On All Interfaces

- Affected: `docker/docker-compose.agent.yml`
- Issue: ports mapping uses `${AGENT_SERVER_PORT:-4096}:4096` which binds to 0.0.0.0 by default on most Docker hosts. This can unintentionally expose the agent server to the local network.
- Impact: if `agent --serve` is used and authentication is weak/missing, remote users on the same network could access the service.
- Recommendation:
  - Bind localhost explicitly: `127.0.0.1:${AGENT_SERVER_PORT:-4096}:4096`.
  - Require `OPENCODE_SERVER_PASSWORD` when server mode is enabled, and fail closed if missing.
  - Document firewall expectations for laptop and shared networks.

### F-004 (Medium) Passwordless Sudo Broadens Blast Radius

- Affected: `Dockerfile`, `docker/Dockerfile`, `docker/entrypoint.sh`
- Issue: dev user is granted `NOPASSWD:ALL`. This is convenient, but it means any process running as the user (including untrusted code executed from the workspace) can become root inside the container.
- Impact: container-root. While this is a dev environment, it increases risk of host-impacting actions via Docker mounts (workspace bind mount) and supply-chain scripts.
- Recommendation:
  - Prefer running the entrypoint as root for the minimal permission-fix steps, then `exec` as the non-root user.
  - If passwordless sudo is required, restrict to the specific commands needed (e.g., `chown`, `mkdir`) via sudoers rules.

### F-005 (Medium) Secrets Loader Uses `source` On `.env`-Style Files

- Affected: `scripts/secrets-load.sh`, `docs/secrets-guide.md`
- Issue: `secrets-load.sh` validates keys, then uses `source "$file"` to load values. If the secrets file is tampered with (or created from untrusted input), it can execute shell code.
- Impact: code execution in the calling shell context (entrypoint or interactive shells). In worst cases, this runs during container startup.
- Recommendation:
  - Parse `KEY=value` safely (line-by-line) and export without `source` (reject `export`, command substitutions, backticks, and multiline values).
  - Enforce `0600` permissions on decrypted secrets files and fail if the file is group/world writable.
  - Add a gitignore rule for common secret filenames (for example `.secrets.env`) to reduce accidental commits.

### F-006 (Medium) Secrets Editing Helper Can Corrupt Values And Leaves Plaintext On Disk

- Affected: `scripts/secrets-edit.sh`
- Issues:
  - `add` uses `sed` substitution with unescaped values; common secret characters (e.g., `&`, `|`, `\`) can break or alter output.
  - Temp files contain plaintext secrets; cleanup uses traps, but a crash or external read can still expose them.
  - The script removes the encrypted chezmoi source file (`rm -f`) before re-adding, increasing risk of data loss.
- Impact: secret corruption/loss; increased exposure window on disk.
- Recommendation:
  - Prefer `chezmoi edit ~/.secrets.env` for modifications.
  - If keeping `add`, implement robust escaping and use `printf '%s'` for writes; avoid deleting the encrypted source file directly.
  - Add tests for special-character values and multiline inputs.

### F-007 (Medium) CI Supply-Chain Hardening: Unpinned Actions And `@master`

- Affected: `.github/workflows/worktree-tests.yml`, `.github/workflows/container-build.yml`
- Issue: workflows use third-party actions by tag; one uses `ludeeus/action-shellcheck@master`.
- Impact: action tag retargeting or upstream compromise can modify CI execution.
- Recommendation:
  - Pin actions to full commit SHA (including ShellCheck action).
  - Keep `permissions` minimal per job (already mostly done in `container-build.yml`).
  - Add Dependabot updates for GitHub Actions.
  - Add secret scanning and container scanning jobs (gitleaks, trivy/grype).

### F-008 (Medium) Base Images Not Pinned To Digests

- Affected: `Dockerfile`, `docker/Dockerfile`, `src/docker/Dockerfile.ide`, `src/docker/Dockerfile.ai-extensions`
- Issue: images are pinned to tags, but not to immutable digests. Tags can be repointed upstream.
- Impact: unexpected image content changes; supply-chain drift.
- Recommendation:
  - Pin `FROM ...@sha256:<digest>` for reproducibility and stronger provenance.
  - Add a scheduled workflow that rebuilds with updated digests after verification.

### F-009 (Low) Documentation Contains Realistic Secret-Like Example Strings

- Affected: `docs/secrets-guide.md`, `scripts/secrets-setup.sh`, `templates/chezmoi/private_dot_secrets.env.age.tmpl`
- Issue: examples include realistic-looking token prefixes (for example, AWS access key ID format). This can cause false positives and, more importantly, normalizes putting secret-like values into docs.
- Impact: operational noise (secret scanners) and minor cultural risk.
- Recommendation:
  - Replace with clearly fake placeholders (e.g., `EXAMPLE_TOKEN_VALUE`) that do not match real token formats.

### F-010 (Low) Memory System Can Ingest Sensitive Text Without Hard Guards

- Affected: `src/memory_server/strategic.py`, `src/memory_server/server.py`, `.memory` design
- Issue: strategic memory reads `.memory/*.md` without a hard size cap and without content secret scanning. The repo relies on guidance and excluded patterns elsewhere.
- Impact: accidental secret persistence in AI context; potential DoS via oversized files.
- Recommendation:
  - Enforce a hard maximum on total strategic memory size and per-file size.
  - Add optional secret-pattern scanning (best-effort, fail closed or warn loudly).

## DevSecOps Recommendations (Concrete Next Steps)

1. Fix agent command execution (`eval` removal) and add tests for hostile inputs.
2. Bind agent server port to localhost and require auth when serving.
3. Replace curl-pipe-shell patterns and add checksum verification for all downloaded binaries/VSIX.
4. Add CI security gates:
   - Secret scanning (gitleaks or detect-secrets) on PRs.
   - Container scanning (trivy/grype) on built images.
   - Dependency scanning for Python (`pip-audit`) and npm.
5. Pin GitHub Actions and container base images to immutable digests/SHAs.
