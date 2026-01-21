# AGENT OPERATIONS GUIDE

This file keeps human and AI contributors aligned inside `container-dev-env`. Read it end-to-end before running commands or editing files; keep a copy open while you work.

## 1. QUICK CONTEXT

1. Repo scope: containerized development environment plus SpecKit/Opencode automation glue. See README.md (root) and prds/001-prd-container-base.md for product rationale.
2. Primary tooling: Bash, Docker, SpecKit scripts under `.specify/scripts/bash`, Opencode/Bun helper commands inside `.opencode`, Claude preference file at `/Users/bluby/.claude/CLAUDE.md` (mirrors repo expectations).
3. No language sources yet, but plan for Rust, Python, TypeScript/Node, and Go per CLAUDE.md—set standards now so future code lands clean.
4. Constitution template lives at `.specify/memory/constitution.md`. Replace placeholders with project values before approving any plan/spec.
5. There are currently **no Cursor rules** (`.cursor/rules/` missing) and **no Copilot instructions** (`.github/copilot-instructions.md` absent). If you introduce them, update this file immediately.

## 2. WORKFLOW COMMANDS

1. **Prerequisite check** (verifies branch + plan/tasks):
   - `./.specify/scripts/bash/check-prerequisites.sh --json` (plan) 
   - `./.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` (implementation)
2. **Create feature scaffolding**: `./.specify/scripts/bash/create-new-feature.sh 'Short feature description' --short-name my-feature`
3. **Plan setup**: `./.specify/scripts/bash/setup-plan.sh --json` (copies plan template into `specs/<branch>/plan.md`)
4. **Update agent contexts**: `./.specify/scripts/bash/update-agent-context.sh opencode` (or omit arg to refresh all agent files once plan.md is populated)
5. **Opencode CLI install/update** (run once per change to `.opencode`):
   - `cd .opencode && bun install`
   - Invoke commands via `/speckit.*` wrappers described in `.opencode/command/*.md`
6. **Dev container build** (from PRD #001): `docker build -t devcontainer .` then `docker run --rm devcontainer whoami`
7. **Environment lints/tests**: run language-specific commands below once code appears; for now they serve as enforced defaults.

## 3. LANGUAGE COMMAND CHEATSHEET

1. **Rust**
   - Build: `cargo build`
   - Lint: `cargo clippy --all-targets --all-features -D warnings`
   - Test suite: `cargo test`
   - Single test: `cargo test module_name::tests::target_case`
2. **Python**
   - Env: prefer `uv` or `venv` from CLAUDE.md; `pip install -r requirements.txt`
   - Format: `ruff format .`
   - Lint: `ruff check .`
   - Tests: `pytest`
   - Single test: `pytest path/to/test_file.py::TestClass::test_method`
3. **TypeScript/Node (use Bun/NPM per project)**
   - Install: `bun install` or `npm install` (lock decision per subproject)
   - Format: `pnpm prettier --write .` or `npm run format` (ensure script exists)
   - Lint: `npm run lint`
   - Tests: `npm test`
   - Single test (Jest): `npx jest path/to/file.test.ts -t "test name"`
4. **Go**
   - Build: `go build ./...`
   - Format: `gofmt -w` (use goimports for imports)
   - Lint: `golangci-lint run`
   - Tests: `go test ./...`
   - Single test: `go test ./path -run TestName`

## 4. CODE STYLE CORE (REF: `/Users/bluby/.claude/CLAUDE.md`)

1. **General**: Explicit > implicit, readability > cleverness, single responsibility. Favor self-documenting identifiers; comments only when logic is non-obvious.
2. **Imports**: keep deterministic order (stdlib → third-party → local). Remove unused imports before committing. In Go use `goimports`, in Python rely on Ruff fix, in TS run ESLint/prettier variants, in Rust let `rustfmt`/`cargo fix` organize `use` statements.
3. **Formatting**: Always run stack formatter before commit (`rustfmt`, `ruff format`, `prettier`, `gofmt`). Do not hand-align columns; trust formatter defaults.
4. **Types & Interfaces**:
   - Rust: embrace `Result<T,E>` + `thiserror` for custom errors, prefer iterators.
   - Python: annotate functions with typing; use `dataclasses` for simple containers; prefer `pathlib`.
   - TypeScript: enable `strict` mode, prefer `const`, avoid `any`; use discriminated unions for complex state.
   - Go: keep interfaces small, return `(value, error)`; avoid stuttered names.
5. **Naming**: descriptive snake_case for Python, camelCase for TS, PascalCase for types, Rust uses snake_case for modules/functions and UpperCamelCase for types. Avoid single letters except trivial loop indices.
6. **Error Handling**: never swallow errors. Rust: bubble via `?`. Python: raise explicit exceptions with context. Go: wrap errors (`fmt.Errorf("context: %w", err)`). JS/TS: throw typed errors or discriminated union results.
7. **Security**: validate external input, sanitize user data, keep dependencies patched, never commit secrets (.env, credentials). Follow OWASP basics; prefer parameterized queries.
8. **Docs**: add doc comments for public APIs, keep README plus new specs aligned; record design decisions in plan/spec artifacts.

## 5. TESTING EXPECTATIONS

1. TDD strongly encouraged (see CLAUDE.md + constitution template). Follow Arrange/Act/Assert naming.
2. Write integration tests for CLI/tooling changes; prefer `cargo test`, `pytest`, `npm test`, `go test` with coverage flags when available.
3. Every new feature needs at least one automated test proving the main path plus edge case coverage; document manual steps in specs when automation not feasible.
4. Keep tests isolated: avoid shared global state, use tmp dirs or in-memory fakes.
5. Run relevant targeted command (single-test instructions above) before pushing to keep loops fast.

## 6. GIT & BRANCHING

1. Branch naming enforced via `create-new-feature.sh`: `###-short-description` (zero-padded). Do not handcraft branch names unless script unavailable.
2. When git unavailable (rare), export `SPECIFY_FEATURE` env var so scripts know which spec directory to use.
3. Commit style = Conventional Commits (`feat:`, `fix:`, `chore:`). Keep subject <72 chars, focus on why. Reference issues `Fixes #123` when possible.
4. Never rewrite history that predates your session; avoid `git reset --hard`. Use `git status` before running scripts to avoid clobbering staged work.
5. Run formatter + tests before committing; mention verification in commit body or PR description.

## 7. SPEC/PLAN WORKFLOW (SPECkit)

1. `specs/<branch>/spec.md` (generated via `/speckit.specify`) defines requirements; update as facts change.
2. `plan.md` uses `.specify/templates/plan-template.md` to drive research/design. Fill `NEEDS CLARIFICATION` items before coding.
3. Constitution gates (from `.specify/memory/constitution.md`) are mandatory—replace placeholders with real principle names per project.
4. Phase outputs (research.md, data-model.md, contracts/, quickstart.md, tasks.md) must be regenerated when scope shifts. Keep directories tidy; remove stale artifacts only if replaced in same PR.
5. After plan updates, run `update-agent-context.sh` so AGENTS.md, CLAUDE.md, etc., stay synchronized.

## 8. AGENT/TOOLING NOTES

1. `.opencode/command/*.md` describe `/speckit.*` commands—read the relevant file before invoking to understand required inputs and downstream handoffs.
2. `.claude/commands/*.md` mirror the same pipeline for Claude-specific agents; instructions emphasize absolute paths and constitution enforcement.
3. Keep AGENTS.md around ~150 lines; when instructions change (new linters, Cursor files, Copilot policies), update this document in the same PR.
4. When you add code for a new language, extend Section 3 with concrete commands (install, lint, single test) and cite new files.
5. If Cursor/Copilot rules are later created, summarize them here verbatim or link to their paths. For now note their absence in PR summaries so reviewers know agents rely solely on this doc + CLAUDE.md.

## 9. REVIEW & RELEASE CHECKS

1. Before raising PR, ensure `docker build -t devcontainer .` succeeds (from PRD acceptance criteria) and mention test matrix run.
2. Validate automation scripts by running them in dry-run/JSON mode first; avoid editing `.specify/scripts` without companion tests.
3. Capture deviations from CLAUDE.md in the spec/plan and negotiate before implementing.
4. Document manual QA steps when automated coverage is unavailable; add them to `quickstart.md` inside the relevant spec directory.
5. Keep this file authoritative—link to it when creating new agent configs so future tools inherit the same rules.

(149 lines)

## Active Technologies
- Bash (shell scripts), Go templates (Chezmoi) + Chezmoi (dotfile manager), age (encryption), existing base container image (003-secret-injection)
- Encrypted files on host filesystem, decrypted to environment variables at runtime (003-secret-injection)

## Recent Changes
- 003-secret-injection: Added Bash (shell scripts), Go templates (Chezmoi) + Chezmoi (dotfile manager), age (encryption), existing base container image
