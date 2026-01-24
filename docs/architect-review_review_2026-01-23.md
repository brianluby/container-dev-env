# Architecture Review (2026-01-23)

Repository: `container-dev-env`

This review focuses on repository-level architecture, component boundaries, build/test workflow cohesion, and maintainability risks. It avoids secrets and internal URLs by design.

## Executive Overview

The repo shows strong product thinking (feature-numbered specs/PRDs, clear documentation navigation, and a well-defined volume architecture) and has meaningful automated coverage (BATS + pytest). The biggest architectural risk is *drift between multiple “container stacks”* (root `Dockerfile` vs `docker/` vs `src/docker/`), which can lead to CI gaps, duplicated logic, and unclear “blessed” entrypoints.

## Key Findings

- Feature-driven workflow is consistently implemented (`specs/`, `prds/`, checklists/contracts) and is a good backbone for parallel development.
- Volume architecture is unusually well-documented and operationalized (`docs/volume-architecture.md`, `docker/docker-compose.yml`, `docker/entrypoint.sh`).
- There are at least three container build surfaces with overlapping responsibilities:
  - Base image: root `Dockerfile`
  - Dev container + MCP: `docker/Dockerfile` + `docker/docker-compose.yml`
  - IDE container: `src/docker/Dockerfile.ide` + `src/docker/docker-compose.ide.yml`
  This is workable, but currently reads like multiple “products” sharing a repo.
- CI coverage is uneven relative to repo structure:
  - `.github/workflows/container-build.yml` only triggers on root `Dockerfile` and `scripts/**`, but much of the runtime/compose surface lives in `docker/` and `src/`.
  - The worktree workflow is targeted and good, but uses `@master` actions (`.github/workflows/worktree-tests.yml`).
- Shell scripting standards are documented but inconsistently applied (e.g. scripts that use `set -e` + `pipefail` but omit `-u`). This increases the chance of “works locally, fails in CI” behavior.
- The agent wrapper (`src/agent/agent.sh`) is a meaningful subsystem with its own state model (sessions/logs/checkpoints/background tasks). It likely warrants explicit architecture docs and stable CLI contract tests (in addition to unit BATS).

## Risks

- High: Container architecture drift / unclear canonical path. Root `Dockerfile` and `docker/Dockerfile` represent different base assumptions (package sets, Python strategy, MCP install), and it’s not obvious which is “the” development image.
- High: CI trigger gaps allow regressions in primary user flows. Changes under `docker/**`, `src/**`, and `templates/**` can bypass `.github/workflows/container-build.yml` entirely.
- Medium: Shell-safety inconsistencies and string-based execution patterns increase operational fragility (see security review re: `eval` usage in `src/agent/agent.sh`).
- Medium: Supply-chain and reproducibility posture is partially implemented (pinned versions exist, but not consistently pinned to digests/SHAs across images and GH actions).
- Low: Docs are strong but not fully “indexable” from one place; readers have to infer which container stack to use for which scenario.

## Recommended Improvements (Prioritized)

1. Define and document “blessed” container targets.
   - Add a short decision doc (ADR) clarifying which image(s) are canonical for:
     - base dev image
     - dev image with MCP
     - agent-enabled image
     - IDE image
   - Suggested location: `docs/decisions/` + link from `docs/architecture/overview.md`.
2. Align CI triggers to the real architecture surface.
   - Update `.github/workflows/container-build.yml` to include changes under `docker/**`, `src/**`, `templates/**`, and `pyproject.toml` (and ideally `uv.lock`).
   - Consider splitting workflows by image type (base/dev/agent/ide) so changes build/test the right targets.
3. Reduce duplication across Dockerfiles/entrypoints.
   - Consolidate shared installation steps (Node/Python/uv, common tooling) into one canonical Dockerfile or shared build stages.
   - If multiple images are intentional, explicitly separate concerns and reuse stages via `FROM ... AS` + `COPY --from` patterns.
4. Standardize shell strict mode and a shared library pattern.
   - For scripts that should fail-fast, prefer `set -euo pipefail` and consistent helper libs (similar to `src/scripts/lib/common.sh`).
   - Where fail-fast is not desired (test runners), document why in the script header and keep the deviations intentional.
5. Strengthen subsystem boundaries with contract tests.
   - Agent CLI: add/expand contract tests that validate output/exit codes for `agent config`, `agent status`, `agent sessions`, etc. (ties to `specs/005-terminal-ai-agent/contracts/`).
   - Container interfaces: add explicit “interface snapshots” for `docker/docker-compose.yml` + `docker/entrypoint.sh` env vars.

## Quick Wins (<1 day)

- Add a `docs/architecture/images.md` (or similar) listing each image/compose entrypoint and intended usage, with “use this by default” guidance.
- Expand CI path filters to include `docker/**` and `src/**` so core changes don’t bypass builds.
- Pin GitHub Actions currently using `@master` in `.github/workflows/worktree-tests.yml` to a commit SHA.
- Add a small “Repo Map” section to `README.md` pointing readers to `docs/navigation.md`, `docker/`, and `src/docker/`.
- Run ShellCheck uniformly over `src/scripts/**` and `scripts/**` in CI (the repo already has a strong standard; enforce it consistently).
