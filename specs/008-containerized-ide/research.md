# Research: Containerized IDE

**Phase**: 0 (Outline & Research)
**Date**: 2026-01-23
**Feature**: 008-containerized-ide

## Research Summary

All technical unknowns from the Technical Context have been resolved via spike results (documented in PRD) and architectural analysis (ARD). No NEEDS CLARIFICATION items remain.

---

## Decision 1: IDE Server Selection

**Decision**: OpenVSCode-Server (gitpod/openvscode-server)

**Rationale**:
- Smallest resource footprint: 848MB image, 23MB idle RAM (vs code-server: 1.12GB, 37MB)
- Closest alignment with upstream VS Code — fewer extension compatibility issues
- MIT license with no proprietary dependencies
- Official multi-arch Docker images (linux/amd64, linux/arm64)
- 8-second startup time verified in spike

**Alternatives Considered**:
- **code-server (Coder)**: Larger footprint, more community docs, diverges from upstream. Documented as fallback.
- **VS Code Tunnels (Microsoft)**: Requires MS account and internet — violates M-9 (open source)
- **JetBrains Gateway**: Proprietary, requires host client — violates M-2 and M-9

**Source**: Spike results in `spikes/008-containerized-ide/RESULTS.md`; PRD evaluation criteria table.

---

## Decision 2: Extension Registry

**Decision**: Open VSX (openvsx.org) exclusively

**Rationale**:
- Only open registry compatible with non-Microsoft VS Code forks
- Python, TypeScript/JavaScript, and Rust extensions verified available
- VSIX sideloading available as fallback for missing extensions
- No Microsoft account or licensing dependency

**Alternatives Considered**:
- **Microsoft Marketplace**: Requires Microsoft account; licensing prohibits use with non-official VS Code
- **Self-hosted registry**: Unnecessary complexity for single-user; Open VSX sufficient

**Source**: PRD Technical Constraints; spike verified Python extension install from Open VSX.

---

## Decision 3: Authentication Mechanism

**Decision**: Connection token via `--connection-token` flag + `CONNECTION_TOKEN` environment variable

**Rationale**:
- Built-in to OpenVSCode-Server — no additional dependencies
- Environment variable injection aligns with Docker best practices
- Simple to automate (generate token, pass as env var)
- No external auth service required for single-user

**Alternatives Considered**:
- **Password auth**: Available in code-server but not OpenVSCode-Server's primary mechanism
- **OAuth proxy**: Over-engineered for single-user local development; deferred to future multi-user PRD
- **No auth**: Unacceptable per SEC review — full container access without any barrier

**Source**: PRD Decision Log (2025-01-21); SEC requirements SEC-1 through SEC-3.

---

## Decision 4: Extension Persistence Strategy

**Decision**: Docker named volume at `/home/.openvscode-server/extensions` + manifest-driven install at startup

**Rationale**:
- Volume persists across container restarts and rebuilds
- Manifest-driven install ensures declared extensions are always present
- Avoids baking extensions into image (anti-pattern: increases image size, forces rebuild for changes)
- Entrypoint script checks for missing extensions and installs only what's needed

**Alternatives Considered**:
- **Build-time installation**: Extensions baked into image layer — rejected because any extension change requires full rebuild
- **Bind mount from host**: Breaks container isolation; platform-specific paths
- **No persistence**: Unacceptable — extensions would download on every restart

**Source**: ARD Implementation Guardrails; PRD anti-patterns section.

---

## Decision 5: Image Version Pinning

**Decision**: Pin to specific version tag (e.g., `gitpod/openvscode-server:1.96.4`) in production; use `latest` only for development/spike

**Rationale**:
- Constitution Principle V requires reproducible builds with no floating versions
- Specific version tags ensure deterministic behavior across builds
- Version can be bumped explicitly via PR

**Alternatives Considered**:
- **`:latest` tag**: Non-deterministic; may break on upstream release — prohibited by constitution
- **Digest pinning (`@sha256:...`)**: Maximum reproducibility but harder to read; acceptable but version tag preferred

**Source**: Constitution Principle V (Reproducibility); PRD anti-patterns.

---

## Decision 6: Network Binding

**Decision**: Bind to `0.0.0.0` inside container (Docker handles port mapping); Docker Compose maps to `127.0.0.1:3000` on host

**Rationale**:
- Inside the container, `0.0.0.0` is required for Docker port mapping to work
- Host-side binding to `127.0.0.1` via compose `ports: "127.0.0.1:3000:3000"` satisfies SEC-3 (localhost only)
- External access requires explicit compose override to bind to `0.0.0.0` on host

**Alternatives Considered**:
- **Bind to `127.0.0.1` inside container**: Breaks Docker port forwarding — container port unreachable from host
- **Bind to `0.0.0.0` on host**: Exposes to all network interfaces — rejected per SEC-3

**Source**: SEC requirement SEC-3; Docker networking best practices.

---

## Decision 7: Token Generation

**Decision**: Provide a helper script (`generate-token.sh`) that uses `/dev/urandom` to create a 32-character hex token; user stores in `.env` file

**Rationale**:
- CSPRNG from `/dev/urandom` satisfies SEC-2 (cryptographically random)
- 32 hex chars = 128 bits of entropy — infeasible to brute-force
- `.env` file is gitignored by convention; aligns with Constitution Principle IV (no secrets in code)

**Alternatives Considered**:
- **Manual token creation**: Error-prone; users may choose weak tokens
- **Docker secrets**: More complex setup; overkill for single-user local development
- **Auto-generated on each start**: Inconvenient — user must retrieve new token each restart

**Source**: SEC requirement SEC-2; Constitution Principle IV (Security-First Design).

---

## Decision 8: Entrypoint Script Design

**Decision**: Single `ide-entrypoint.sh` that: (1) reads extensions.json, (2) installs missing extensions, (3) launches OpenVSCode-Server with token

**Rationale**:
- Single script keeps container startup logic in one place (Principle VII: simplicity)
- Extension install is non-blocking (warnings only if registry unreachable)
- Server launch is the final `exec` call — PID 1 for proper signal handling

**Alternatives Considered**:
- **Multiple scripts (install.sh + start.sh)**: Unnecessary indirection for 3 steps
- **Supervisor process**: Over-engineered; single process is sufficient
- **Docker HEALTHCHECK + separate init**: OpenVSCode-Server handles its own lifecycle

**Source**: ARD Key Algorithms/Patterns section; Constitution Principle VII.

---

## Dependency Best Practices

### OpenVSCode-Server in Docker

- Use official multi-arch image as base
- Preserve default user (`openvscode-server`, UID 1000)
- Use `--host 0.0.0.0` for container networking
- Use `--connection-token` (not `--connection-secret` which reads from file)
- Extensions install via CLI: `openvscode-server --install-extension <id>`

### Docker Compose for Development

- Use `127.0.0.1:3000:3000` port mapping for localhost-only
- Use `env_file: .env` for token injection
- Set `mem_limit: 512m` for resource constraint
- Use `restart: unless-stopped` for development convenience
- Named volumes for workspace and extensions

### Integration Testing Containers

- Use `docker compose up -d` + wait for health check
- Assert HTTP 200 with `curl -sf http://localhost:3000`
- Assert auth with `curl -sf http://localhost:3000` (expect 401 without token)
- Assert user with `docker exec <container> id -u` (expect 1000)
- Cleanup with `docker compose down -v` (remove volumes for clean state)
