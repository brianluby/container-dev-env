# Research: Terminal AI Agent

**Phase**: 0 (Outline & Research)
**Date**: 2026-01-22
**Feature**: 005-terminal-ai-agent

## Research Tasks

### R-1: OpenCode Release URL Format and SHA256 Availability

**Decision**: Download architecture-specific binary from GitHub Releases using the pattern:
`https://github.com/opencode-ai/opencode/releases/download/{VERSION}/opencode-linux-{ARCH}`

**Rationale**: GitHub Releases provides stable, versioned URLs with checksums available in the release assets (SHA256SUMS file). This avoids the install script (curl|bash) and provides verifiable integrity.

**Alternatives considered**:
- `curl | bash` install script — rejected for supply chain risk (SEC finding F2)
- `go install` from source — requires Go toolchain in container; adds build time and complexity
- Container registry (pre-built image layer) — over-engineering for a single binary

**Implementation details**:
- Architecture mapping: `dpkg --print-architecture` returns `amd64` or `arm64`
- SHA256 file: Download `SHA256SUMS` from same release, or pin checksum in Dockerfile ARG
- Recommended: Pin checksum directly in Dockerfile ARG for simplicity (no extra download step)
- Version format: `v0.x.x` (semver with `v` prefix)

---

### R-2: OpenCode Configuration File Format

**Decision**: YAML configuration at `~/.config/opencode/config.yaml`, managed by Chezmoi template.

**Rationale**: OpenCode uses YAML for its configuration file. Chezmoi can template this with Go templates to inject per-environment values while keeping defaults static.

**Alternatives considered**:
- TOML — not supported by OpenCode
- Environment variables only — insufficient for complex settings (model selection, behavior flags)
- JSON — supported but less readable; YAML is the documented default

**Configuration structure** (from OpenCode docs):
```yaml
# Provider and model selection (empty = user must configure)
provider: ""
model: ""

# Agent behavior
agent:
  mode: build          # Default mode (plan or build)
  auto_commit: true    # Auto-commit approved changes
  commit_style: conventional  # conventional, descriptive, or minimal

# Session persistence
session:
  persist: true
  path: ~/.local/share/opencode/sessions/

# Shell execution
shell:
  approval_required: true  # Always require user approval

# Timeouts
api:
  timeout: 60          # Seconds before timeout
  retries: 1           # Number of retries on timeout
```

---

### R-3: Chezmoi Template Structure for Config Delivery

**Decision**: Use Chezmoi's `.tmpl` suffix with Go template conditionals for provider-specific defaults.

**Rationale**: Chezmoi already manages dotfiles in this project (002-dotfile-management). Adding an OpenCode config template is consistent with existing patterns and allows per-environment customization.

**Alternatives considered**:
- Direct file copy in Dockerfile — no per-environment customization
- Runtime script that generates config on first start — adds startup latency; fragile
- Symlink to mounted volume — requires volume architecture (004) dependency

**Template approach**:
```yaml
# ~/.config/opencode/config.yaml.tmpl
provider: {{ env "OPENCODE_PROVIDER" | default "" }}
model: {{ env "OPENCODE_MODEL" | default "" }}

agent:
  mode: build
  auto_commit: true
  commit_style: conventional

session:
  persist: true
  path: {{ .chezmoi.homeDir }}/.local/share/opencode/sessions/

shell:
  approval_required: true

api:
  timeout: 60
  retries: 1
```

---

### R-4: Integration Test Approach for Container-Based CLI Tools

**Decision**: Use shell scripts with `docker run` commands to test the installed binary. Tests run as part of CI after container build.

**Rationale**: The feature installs a pre-built binary — there's no application code to unit test. Integration tests verify the binary is correctly installed, configured, and operational within the container.

**Alternatives considered**:
- bats (Bash Automated Testing System) — good framework but adds a dependency; overkill for 5 test files
- pytest with docker SDK — adds Python testing dependency for shell-level tests
- Makefile targets — less structured; harder to get pass/fail reporting

**Test structure**:
```bash
# Each test file is a standalone script that:
# 1. Runs a docker command
# 2. Checks exit code and output
# 3. Returns 0 (pass) or non-zero (fail)

# Example: test_opencode_install.sh
#!/bin/bash
set -euo pipefail

IMAGE="${TEST_IMAGE:-devcontainer:test}"

# Verify binary exists and is executable
docker run --rm "$IMAGE" which opencode
docker run --rm "$IMAGE" opencode --version

# Verify architecture matches
EXPECTED_ARCH=$(docker run --rm "$IMAGE" dpkg --print-architecture)
docker run --rm "$IMAGE" file /usr/local/bin/opencode | grep -q "$EXPECTED_ARCH"

echo "PASS: OpenCode install verification"
```

**CI integration**: Tests run after `docker build` in the CI pipeline. Failed tests block the build.

---

### R-5: File Conflict Detection Approach

**Decision**: Rely on OpenCode's built-in file change detection. If the tool does not natively support this, document as a known limitation and add a pre-write timestamp check wrapper.

**Rationale**: FR-018 requires detecting when files have been modified since last read. OpenCode's architecture (reads file → generates changes → user approves → writes) naturally supports a modification time check between read and write.

**Alternatives considered**:
- File watcher (inotify) — over-engineering for an interactive CLI tool
- Git status check before write — only catches committed/staged changes, not unsaved edits
- Custom wrapper script — fragile; breaks tool updates

**Verification approach**: Integration test that modifies a file between agent read and agent write, verifying the agent warns rather than overwrites.

---

### R-6: Multi-Architecture Binary Download

**Decision**: Use Dockerfile ARGs for version and per-architecture SHA256 checksums. Buildx provides `TARGETARCH` build argument automatically.

**Rationale**: Docker Buildx sets `TARGETARCH` (amd64 or arm64) during multi-platform builds. The Dockerfile can use this to download the correct binary variant.

**Alternatives considered**:
- Separate Dockerfiles per architecture — duplication; maintenance burden
- Runtime detection script — adds complexity at container start; binary should be correct at build time
- `COPY --from` multi-stage with go build — requires Go toolchain; defeats purpose of pre-built binary

**Implementation**:
```dockerfile
ARG OPENCODE_VERSION=v0.1.0
ARG OPENCODE_SHA256_AMD64=<hash>
ARG OPENCODE_SHA256_ARM64=<hash>
ARG TARGETARCH

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) SHA="${OPENCODE_SHA256_AMD64}" ;; \
      arm64) SHA="${OPENCODE_SHA256_ARM64}" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/opencode-ai/opencode/releases/download/${OPENCODE_VERSION}/opencode-linux-${TARGETARCH}" \
      -o /usr/local/bin/opencode; \
    echo "${SHA}  /usr/local/bin/opencode" | sha256sum -c -; \
    chmod +x /usr/local/bin/opencode
```

## Summary of Resolved Items

| Item | Resolution | Source |
|------|-----------|--------|
| Binary download URL | GitHub Releases per-arch binary | R-1 |
| Checksum verification | SHA256 pinned in Dockerfile ARGs | R-1 |
| Config format | YAML at `~/.config/opencode/config.yaml` | R-2 |
| Config delivery | Chezmoi `.tmpl` with Go template syntax | R-3 |
| Test approach | Shell scripts with `docker run` | R-4 |
| File conflict detection | Built-in tool behavior + integration test | R-5 |
| Multi-arch support | TARGETARCH build arg + per-arch checksums | R-6 |

All NEEDS CLARIFICATION items resolved. Proceeding to Phase 1.
