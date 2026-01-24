# Research: 014-project-knowledge

**Date**: 2026-01-23
**Feature**: Structured Project Knowledge for AI Agents

## 1. ADR Template Format

**Decision**: Use a hybrid template combining Michael Nygard's simplicity with MADR's explicit alternatives section. Six sections: Title/Status/Date, Context, Decision, Alternatives Considered, Consequences, Follow-up Actions.

**Rationale**: Nygard's original template (2011) is proven but lacks "Alternatives Considered" — the single most valuable section for preventing AI agents from re-proposing rejected solutions. Full MADR 4.0 is too heavy for the 15-minute fill requirement. The hybrid keeps ADRs to 1-2 pages while explicitly listing rejected alternatives with brief rationale.

**Alternatives considered**:
- Pure Nygard (5 sections): Fastest to fill but no explicit alternatives listing for AI
- Full MADR 4.0 (10+ sections): Most comprehensive but too heavy for 15-min target
- Y-Statements: Single sentence; too terse for AI section-parsing
- arc42 Decision Log: Tied to arc42 ecosystem; overkill for standalone use

## 2. AI-Navigable Documentation

**Decision**: Markdown-based navigation guide in `docs/` directory, referenced from AGENTS.md via explicit file path instruction. Uses a "pointer-not-copy" pattern with progressive disclosure. Navigation guide as routing table (quick-reference table mapping needs to files), not content dump.

**Rationale**: All three target AI tools (Claude Code, Cline, Continue) read Markdown natively. Progressive disclosure keeps root context files lean (under 150 lines) while pointing to detailed subdocuments on a need-to-know basis. Referencing file locations rather than duplicating content prevents staleness.

**Alternatives considered**:
- Single monolithic docs file: Simple but exceeds context window
- Inline everything in AGENTS.md: Bloats every session
- JSON/YAML structured index: Less human-readable than Markdown
- Auto-generated from file headers: Requires build step; adds tooling dependency
- No navigation guide: AI tools may miss relevant docs

## 3. Mermaid Diagram Patterns for AI

**Decision**: Use flowcharts (`flowchart TD/LR`) and sequence diagrams as primary types. Keep diagrams small (under 15 nodes). Label all edges and use descriptive node IDs. Add prose description before each diagram. Avoid C4 syntax (experimental).

**Rationale**: Flowcharts and sequence diagrams are the most reliably parsed by LLMs. Research shows quality degrades quickly as complexity increases. Explicit labels and node IDs help LLMs map diagram elements to code concepts. C4 is still experimental in Mermaid with unstable syntax.

**Alternatives considered**:
- PlantUML: More types but not GitHub-native, requires tooling
- ASCII art: Universal but fragile and limited expressiveness
- D2 (Declarative Diagramming): Clean syntax but less LLM training data
- Prose-only: Simplest but can't convey spatial relationships efficiently

### Diagram Guidelines

1. Use descriptive node IDs (`AuthService` not `A`)
2. Label all edges (`A -->|authenticates| B`)
3. One diagram per concept
4. Avoid subgraphs when possible (nesting complexity)
5. Keep under 15 nodes per diagram
6. Use standard arrow types (`-->`, `-->>`)
7. Add prose description before each diagram

## 4. AGENTS.md Integration Pattern

**Decision**: Single reference block in AGENTS.md pointing to `docs/navigation.md`. Describe capabilities ("architecture decisions, domain terms, design patterns") rather than listing paths. Use explicit "read file X" instruction format for cross-tool compatibility.

**Rationale**: AGENTS.md should stay under 150 lines. Progressive disclosure pattern keeps root as routing table. The explicit file-read instruction works across Claude Code (which supports `@` imports), Cline, and Continue without requiring tool-specific syntax.

**Alternatives considered**:
- Inline all docs content in AGENTS.md: Bloats file, goes stale
- Nested AGENTS.md in docs/ directory: Not all tools support cascading
- `.claude/rules/architecture.md`: Claude-specific, not cross-tool
- No reference: Agents may not discover docs; inconsistent behavior

### Cross-Tool Compatibility

| Tool | Discovery Mechanism | Recommended Format |
|------|---------------------|--------------------|
| Claude Code | CLAUDE.md + `@` imports | `@docs/navigation.md` or explicit path |
| Cline | AGENTS.md / `.clinerules` | Explicit "read file X" instruction |
| Continue | `.continue/config.yaml` + context | File path in docs block |

## 5. Directory Structure

**Decision**: Use `docs/` at project root with category subdirectories matching the spec's documentation categories.

**Rationale**: `docs/` is the GitHub-recognized convention, renders documentation automatically, and is the developer expectation. Category subdirectories map 1:1 to the spec's documentation categories.

**Structure**:
```
docs/
├── navigation.md          # AI navigation guide (entry point)
├── architecture/
│   ├── overview.md        # System structure & components
│   └── diagrams.md        # Mermaid architecture diagrams
├── decisions/
│   ├── _template.md       # ADR template
│   └── 001-example.md     # Sequential ADRs
├── api/
│   └── principles.md      # API design principles & endpoints
├── domain/
│   └── glossary.md        # Domain terminology & concepts
├── operations/
│   └── deployment.md      # Deployment procedures & runbooks
└── security/
    └── authentication.md  # Auth patterns & threat considerations
```
