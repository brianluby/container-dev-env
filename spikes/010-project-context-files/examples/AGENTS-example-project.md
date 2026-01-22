# Example: container-dev-env AGENTS.md

This is an example AGENTS.md following the standard spec format for the container-dev-env project. The actual project uses a custom format in the root AGENTS.md that's optimized for this specific workflow.

---

# Project: container-dev-env

## Overview

Containerized development environment with AI agent integration, providing consistent tooling, secret management, and development workflows across machines.

**Status**: Active Development
**Primary Language**: Bash, Docker
**Domain**: Infrastructure / Developer Tooling

## Goals

- Provide reproducible containerized development environments
- Integrate AI coding assistants (Claude Code, Cline, Continue, etc.)
- Manage secrets securely with encryption at rest
- Support multiple language runtimes (Rust, Python, TypeScript, Go)

## Technology Stack

### Languages & Runtimes
- **Shell**: Bash 5.x
- **Planned**: Rust 1.75+, Python 3.12+, Node.js 22.x, Go 1.21+

### Frameworks & Tools
- Docker & Docker Compose
- Chezmoi (dotfile management)
- age (encryption)

### Infrastructure
- **Containerization**: Docker with multi-stage builds
- **CI/CD**: GitHub Actions
- **Dev Environment**: VS Code Dev Containers

## Project Structure

```
container-dev-env/
├── docker/                 # Docker configurations
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── entrypoint.sh
├── prds/                   # Product Requirements Documents
├── specs/                  # Feature specifications
│   └── {feature}/
│       ├── spec.md
│       ├── plan.md
│       └── tasks.md
├── spikes/                 # Technical explorations
├── scripts/                # Utility scripts
├── .specify/               # SpecKit configuration
│   ├── scripts/bash/
│   └── templates/
├── AGENTS.md               # AI agent context (this file)
└── CLAUDE.md               # Claude-specific config
```

## Coding Standards

### Style Guide
- **Bash**: Use `shellcheck` for linting
- **Docker**: Follow Dockerfile best practices (multi-stage, minimal layers)
- **Markdown**: Use markdownlint for consistency

### Naming Conventions
- **Files**: kebab-case (e.g., `my-script.sh`)
- **Scripts**: Descriptive names with action prefix (e.g., `secrets-load.sh`)
- **Feature branches**: `###-short-description` (zero-padded number)

### Error Handling
- Bash: Use `set -euo pipefail` at script start
- Always validate required environment variables
- Log errors with context before exiting

## Common Patterns

### Pattern: Feature Workflow
**When to use**: Starting any new feature
```bash
# 1. Create feature scaffolding
./.specify/scripts/bash/create-new-feature.sh 'Feature description' --short-name my-feature

# 2. Set up plan
./.specify/scripts/bash/setup-plan.sh --json

# 3. Update agent contexts after planning
./.specify/scripts/bash/update-agent-context.sh
```

### Pattern: Secret Management
**When to use**: Working with sensitive data
```bash
# Setup secrets (first time)
./scripts/secrets-setup.sh

# Load secrets into environment
source ./scripts/secrets-load.sh

# Edit encrypted secrets
./scripts/secrets-edit.sh
```

## Testing Requirements

### Running Tests
```bash
# Container build test
docker build -t devcontainer .

# Integration tests
./tests/integration/test-*.sh

# Health check
./scripts/health-check.sh
```

### Testing Conventions
- Integration tests in `tests/integration/`
- Each test script should be self-contained
- Clean up resources after test completion

## Git Workflow

### Branch Naming
- Use `create-new-feature.sh` script (enforces `###-short-description` format)
- Never create branches manually

### Commit Messages
Follow Conventional Commits:
```
feat(docker): add multi-stage build for smaller image
fix(secrets): handle missing age key gracefully
chore(ci): update GitHub Actions workflow
```

## Security Considerations

### Secrets Management
- Secrets encrypted with `age` (symmetric key in `~/.config/age/key.txt`)
- Never commit unencrypted secrets
- Use environment variables at runtime, not files

### Container Security
- Run as non-root user where possible
- Minimize base image footprint
- Pin dependency versions

## AI Agent Instructions

### Always Do
- Read existing code before making changes
- Follow the SpecKit workflow for new features
- Run `update-agent-context.sh` after modifying plans
- Use existing scripts from `scripts/` and `.specify/scripts/`

### Never Do
- Commit secrets or credentials
- Skip the feature scaffolding workflow
- Modify `.specify/scripts` without tests
- Create branches manually (use `create-new-feature.sh`)

### When Making Changes
1. Check prerequisites: `./.specify/scripts/bash/check-prerequisites.sh --json`
2. Read the relevant spec/plan in `specs/<branch>/`
3. Follow existing patterns in similar files
4. Update documentation if changing public interfaces
5. Run container build to verify: `docker build -t devcontainer .`

## Quick Commands

```bash
# Prerequisites check
./.specify/scripts/bash/check-prerequisites.sh --json

# Create new feature
./.specify/scripts/bash/create-new-feature.sh 'Description' --short-name name

# Setup plan
./.specify/scripts/bash/setup-plan.sh --json

# Update agent contexts
./.specify/scripts/bash/update-agent-context.sh

# Build container
docker build -t devcontainer .

# Run container
docker run --rm devcontainer whoami
```

---

Note: This example follows the AGENTS.md specification format. The actual project
AGENTS.md uses a more detailed custom format optimized for this specific workflow.
