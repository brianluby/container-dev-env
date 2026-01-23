# Implementation Plan: Project Context Files

**Branch**: `010-project-context-files` | **Date**: 2026-01-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/010-project-context-files/spec.md`

## Summary

Implement a standardized project context file system using AGENTS.md as the primary format (60k+ project adoption). Deliverables include: a comprehensive AGENTS.md template, a minimal AGENTS.md template, a CLAUDE.md supplement template, a Bash bootstrap script for initializing context files in new projects, and documentation for the hierarchical context composition pattern. All artifacts are static Markdown files with no runtime dependencies.

## Technical Context

**Language/Version**: Bash 5.x (bootstrap script), Markdown (content files)
**Primary Dependencies**: None (static files + POSIX-compatible shell script)
**Storage**: Filesystem (static files committed to git repository)
**Testing**: ShellCheck (script linting), BATS (Bash Automated Testing System) for bootstrap script, manual test matrix for AI tool recognition
**Target Platform**: Any POSIX filesystem (Linux containers, macOS, CI environments)
**Project Type**: Single project (documentation + CLI tooling)
**Performance Goals**: N/A (static files, no runtime)
**Constraints**: Each context file < 10KB, UTF-8 encoding, LF line endings, case-sensitive filename `AGENTS.md`
**Scale/Scope**: Per-project (1 root context file + 0-5 nested context files typical)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Container-First Architecture | ✅ Pass | Bootstrap script and templates available inside container image; static files require no container changes |
| II. Multi-Language Standards | ✅ Pass | Bootstrap script in Bash follows shell scripting standards; ShellCheck for linting |
| III. Test-First Development | ✅ Pass | BATS tests for bootstrap script; manual test matrix for template verification |
| IV. Security-First Design | ✅ Pass | Templates explicitly warn against secrets; no credentials in files; SEC review completed (Low risk) |
| V. Reproducibility & Portability | ✅ Pass | Static files work on any platform; no version-dependent behavior |
| VI. Observability & Debuggability | ✅ Pass | Bootstrap script uses structured exit codes and stderr for errors |
| VII. Simplicity & Pragmatism | ✅ Pass | Minimal tooling (single script); files work by simply existing |

**Gate Result**: PASS — No violations. Feature is inherently simple and aligned with all constitution principles.

## Project Structure

### Documentation (this feature)

```text
specs/010-project-context-files/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (file structure contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
src/
├── templates/
│   ├── AGENTS.md.full        # Comprehensive template (all sections)
│   ├── AGENTS.md.minimal     # Minimal template (essential sections only)
│   ├── CLAUDE.md.template    # Claude Code supplement template
│   └── nested-AGENTS.md      # Example nested directory context
└── scripts/
    └── init-context.sh       # Bootstrap script for new projects

tests/
├── unit/
│   └── test_init_context.bats  # BATS tests for bootstrap script
└── integration/
    └── test_templates.bats     # Template validation tests
```

**Structure Decision**: Single project layout. The feature produces templates (static Markdown files) and a bootstrap script (Bash). No services, APIs, or complex module structure needed.

## Complexity Tracking

No constitution violations to justify. Feature complexity is minimal by design.
