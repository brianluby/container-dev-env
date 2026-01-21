<!--
SYNC IMPACT REPORT
==================
Version change: 0.0.0 → 1.0.0 (MAJOR - initial ratification)

Modified Principles: N/A (initial version)

Added Sections:
- Core Principles (7 principles)
- Technology Stack
- Development Workflow
- Documentation Standards
- Governance

Removed Sections: N/A (initial version)

Templates Requiring Updates:
- .specify/templates/plan-template.md: ✅ Compatible (Constitution Check section exists)
- .specify/templates/spec-template.md: ✅ Compatible (requirements structure aligns)
- .specify/templates/tasks-template.md: ✅ Compatible (phase structure supports principles)

Follow-up TODOs: None
==================
-->

# Container Dev Env Constitution

## Core Principles

### I. Container-First Architecture (NON-NEGOTIABLE)

Every development environment component MUST run inside containers. Containers must be:

- **Reproducible**: Identical builds on any host (arm64, amd64)
- **Isolated**: No host system pollution or dependency conflicts
- **Declarative**: Dockerfile and compose files are the source of truth
- **Minimal**: Only include what's necessary for the use case
- **Versioned**: All base images and tools pinned to specific versions

**Prohibited**: Installing tools directly on host, implicit dependencies, undocumented manual setup steps, unpinned base image tags (`:latest`).

**Container Boundaries**:
- **Base Image**: Debian Bookworm-slim with common dev tools (foundation layer)
- **Language Runtimes**: Python, Node.js, Go, Rust toolchains (optional layers)
- **Dev Tools**: Git, curl, jq, make, build-essential (included in base)
- **IDE Integration**: VS Code devcontainer support (future layer)

**Build Requirements**:
- Multi-architecture support (arm64 + amd64) via `docker buildx`
- Build time under 5 minutes on CI
- Image size under 2GB for full-stack image
- All components MIT-compatible licensed

**Rationale**: Containerization eliminates "works on my machine" problems, ensures reproducible environments across team members and CI, and provides isolation from host system drift.

### II. Multi-Language Standards (NON-NEGOTIABLE)

Container Dev Env supports four primary languages with unified quality expectations:

**Rust**:
- Build: `cargo build`
- Lint: `cargo clippy --all-targets --all-features -D warnings`
- Format: `cargo fmt`
- Test: `cargo test`
- Error handling: `Result<T, E>` with `thiserror` for custom errors
- Prefer iterators over loops, embrace the borrow checker

**Python (3.11+)**:
- Package manager: `uv` or `pip` with `venv`
- Lint: `ruff check .`
- Format: `ruff format .`
- Test: `pytest`
- Type hints mandatory for function signatures
- Use `pathlib` over `os.path`, `dataclasses` for simple containers

**TypeScript/Node.js**:
- Package manager: `bun` or `npm` (per subproject)
- Lint: `npm run lint` (ESLint)
- Format: `prettier --write .`
- Test: `npm test` (Jest)
- Strict mode enabled, prefer `const` over `let`, avoid `any`

**Go (1.21+)**:
- Build: `go build ./...`
- Lint: `golangci-lint run`
- Format: `gofmt -w .` (use `goimports` for imports)
- Test: `go test ./...`
- Explicit error handling with wrapped errors

**Cross-Language Requirements**:
- All code MUST pass formatter before commit
- All code MUST pass linter with zero errors
- All public APIs MUST have documentation
- All new features MUST have automated tests

**Rationale**: Unified standards across languages ensure consistent quality regardless of which language is used for a given component.

### III. Test-First Development (NON-NEGOTIABLE)

TDD is mandatory for all production code:

- Tests MUST be written before implementation
- Tests MUST fail before implementation begins
- Red-Green-Refactor cycle MUST be followed strictly
- Pull requests without tests for new functionality MUST be rejected

**TDD Cycle**:
1. **Write Test**: Create test demonstrating desired behavior
2. **User Review**: Test reviewed and approved BEFORE implementation
3. **Verify Failure**: Test must FAIL with clear error message
4. **Implement**: Write minimal code to pass test
5. **Verify Pass**: Test must PASS
6. **Refactor**: Improve code while maintaining passing tests

**Testing Stack by Language**:
- **Rust**: `cargo test` with integration tests in `tests/`
- **Python**: `pytest` with fixtures and parametrization
- **TypeScript**: Jest with ts-jest
- **Go**: `go test` with table-driven tests

**Test Organization**:
```
tests/
├── unit/           # Isolated function tests
├── integration/    # Cross-component tests
└── contract/       # API contract validation
```

**Test Requirements**:
- Follow AAA pattern (Arrange, Act, Assert)
- Use descriptive names explaining the scenario
- Test edge cases and error conditions
- Keep tests isolated and independent

**Rationale**: TDD ensures code correctness, provides living documentation, and catches regressions early. Container environments must be reliable.

### IV. Security-First Design (NON-NEGOTIABLE)

Security is foundational for development environments:

**Container Security**:
- Run as non-root user with sudo access
- Minimize attack surface (slim base images)
- Scan images for vulnerabilities before release
- Pin base image digests for reproducibility
- No secrets baked into images

**Secrets Management**:
- Secrets MUST never be committed to code
- Use `.env` files (gitignored) or environment variables
- `.env.example` serves as template without real values
- API keys/credentials NEVER logged or exposed in errors

**Input Validation**:
- Validate all external input (user input, file uploads, API responses)
- Sanitize paths to prevent directory traversal
- Use parameterized queries for any database access

**Dependency Security**:
- Scan dependencies for vulnerabilities before adding
- Block on HIGH/CRITICAL vulnerabilities
- Keep dependencies current (no more than 1 major version behind)
- Document any exceptions with justification and remediation plan

**File System Security**:
- Temporary files cleaned up after processing
- File permissions set appropriately (no world-writable)
- Sensitive config files protected

**Rationale**: Development environments handle source code, credentials, and have broad system access. Security breaches could compromise entire projects.

### V. Reproducibility & Portability (NON-NEGOTIABLE)

Builds MUST be deterministic and cross-platform:

**Version Pinning**:
- Base images pinned to specific digests or version tags
- All package versions locked (lockfiles committed)
- Tool versions documented in Dockerfiles
- No floating versions (`:latest`, `^`, `~`) in production configs

**Cross-Platform Support**:
- arm64 (Apple Silicon) and amd64 MUST both be supported
- Test builds on both architectures in CI
- Document any platform-specific workarounds
- Prefer glibc over musl for maximum compatibility

**Build Reproducibility**:
- Same inputs MUST produce functionally identical outputs
- Use multi-stage builds to minimize final image size
- Cache layers effectively for fast rebuilds
- Document build dependencies explicitly

**Environment Parity**:
- Development, CI, and production MUST use same base image
- Environment differences documented and minimized
- Configuration externalized via environment variables

**Rationale**: Reproducible builds eliminate environment drift, enable reliable CI/CD, and ensure any team member can recreate the exact same environment.

### VI. Observability & Debuggability

Every component must be debuggable in production:

**Health Checks**:
- All containers MUST have health check endpoints or scripts
- Health checks validate actual functionality, not just process status
- Dependency health included in readiness checks

**Structured Logging**:
- Use structured logging (JSON format) for machine parsing
- Log levels configurable per environment
- Include correlation IDs for request tracing
- Sensitive fields auto-redacted

**CLI Output Standards**:
- Text in/out protocol: stdin/args → stdout, errors → stderr
- Support both JSON and human-readable formats
- Exit codes meaningful (0 = success, non-zero = specific error)
- Progress indicators for long-running operations

**Debugging Support**:
- Containers built with debug symbols available
- Source maps included for TypeScript
- Easy to attach debuggers to running containers
- Log aggregation ready (stdout/stderr capture)

**Rationale**: Development environments are complex multi-layer systems. Without observability, debugging issues becomes guesswork.

### VII. Simplicity & Pragmatism

Start simple, add complexity only when justified:

- YAGNI (You Aren't Gonna Need It) principle MUST be followed
- Premature optimization MUST be avoided
- Third-party dependencies MUST be minimized and justified
- Design patterns MUST solve real problems
- Complexity MUST be justified in documentation

**Dependency Principles**:
- Prefer well-maintained packages with active communities
- Avoid dependencies with security vulnerabilities
- Smaller is better: fewer dependencies = smaller attack surface
- License compatibility: MIT, Apache-2.0, BSD-3-Clause preferred

**Architecture Decisions**:
- Start with monolithic Dockerfile, split when proven necessary
- Avoid premature microservice extraction
- Layer images logically (base → runtime → tools)
- Document why, not just what

**Rationale**: Unnecessary complexity increases maintenance burden, build times, and attack surface. Simple, focused containers are easier to secure and maintain.

## Technology Stack

### Container Stack

| Component | Technology | Version | Rationale |
|-----------|-----------|---------|-----------|
| **Base Image** | Debian Bookworm-slim | 12.x | glibc compatibility, DFSG license, ~80MB |
| **Container Runtime** | Docker | 24+ | Industry standard, buildx for multi-arch |
| **Orchestration (local)** | Docker Compose | 2.x | Simple multi-container development |
| **Multi-arch Build** | Docker Buildx | Bundled | arm64 + amd64 support |

### Language Runtimes

| Language | Version | Package Manager | Notes |
|----------|---------|-----------------|-------|
| **Python** | 3.11+ | pip, uv | System python in container (features may require newer) |
| **Node.js** | LTS (22.x) | npm, bun | Via NodeSource apt repo or official images |
| **Go** | 1.21+ | go mod | Official binary distribution |
| **Rust** | 1.75+ | cargo | Via rustup |

### Development Tools (Base Image)

| Tool | Purpose |
|------|---------|
| git | Version control |
| curl, wget | HTTP clients |
| jq | JSON processing |
| make | Build automation |
| build-essential | C/C++ compilation |
| sudo | Privilege escalation (non-root user) |

### Quality Tools by Language

**Rust**: clippy, rustfmt, cargo-audit
**Python**: ruff, pytest, mypy
**TypeScript**: eslint, prettier, jest
**Go**: golangci-lint, gofmt, go test

## Development Workflow

### Pre-commit Requirements

Before every commit:
- Code MUST be formatted (language-specific formatter)
- Linters MUST pass with zero errors
- Type checks MUST pass (where applicable)
- Tests SHOULD pass for changed code
- No secrets in diff

### Branching Strategy

- Main branch: `main` (always buildable)
- Feature branches: `###-feature-name` (via `create-new-feature.sh`)
- Merge strategy: Squash merge for features

### Commit Messages

Follow Conventional Commits:

```
feat(docker): Add Python 3.11 to base image
fix(build): Correct arm64 compatibility for Node.js
docs(readme): Update build instructions
chore(deps): Upgrade base image to bookworm-20240101
security(container): Run as non-root user by default
```

### Quality Gates

```bash
# Build verification
docker build -t devcontainer .
docker run --rm devcontainer whoami  # Should output non-root user

# Language-specific checks (run inside container or on host)
cargo clippy && cargo test           # Rust
ruff check . && pytest               # Python
npm run lint && npm test             # TypeScript
golangci-lint run && go test ./...   # Go
```

### Pull Request Requirements

- All quality gates MUST pass
- At least one approval required
- Branch MUST be up-to-date with main
- Docker build MUST succeed on both arm64 and amd64

## Documentation Standards

### Dockerfile Documentation

All Dockerfiles require comprehensive comments:

```dockerfile
# Base image: Debian Bookworm-slim for glibc compatibility
# Pinned to specific date tag for reproducibility
FROM debian:bookworm-20240101-slim

# Create non-root user with sudo access
# UID/GID 1000 matches typical host user for volume mounts
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID
```

### README Requirements

Each major component requires:
- Purpose and scope
- Prerequisites
- Build instructions
- Usage examples
- Troubleshooting guide

### API Documentation

- All CLI tools document `--help` output
- All public functions have doc comments
- Examples included where helpful

## Governance

### Amendment Process

Constitution changes MUST follow this process:

1. **Propose**: Document rationale in GitHub issue
2. **Discuss**: Team review (minimum 2 business days for core principles)
3. **Document**: Update constitution with version bump
4. **Propagate**: Update dependent templates (plan, spec, tasks)
5. **Communicate**: Announce changes to contributors

### Versioning Policy

Constitution version follows semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Backward incompatible changes (principle removal/redefinition)
- **MINOR**: New principle added or materially expanded guidance
- **PATCH**: Clarifications, wording fixes, typo corrections

### Compliance Review

All pull requests MUST verify constitution compliance:

- Reviewers check against relevant principles
- Container changes validate security requirements
- New tools added to appropriate layer
- Breaking changes documented

### Constitution Authority

- This constitution supersedes all other development practices
- Conflicts MUST defer to constitution
- Violations MUST be fixed or justified before merge
- Use AGENTS.md and CLAUDE.md for tactical guidance

**Version**: 1.0.0 | **Ratified**: 2026-01-20 | **Last Amended**: 2026-01-20
