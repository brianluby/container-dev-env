# Spike 013: Project Knowledge - Findings

## Executive Summary

This spike establishes a structured documentation system for AI-assisted development. The system uses **markdown-based documentation** with **Mermaid diagrams** and **Architecture Decision Records (ADRs)** to help AI coding agents understand project architecture, decisions, and domain concepts.

## Deliverables Created

### Templates

| Template | Location | Purpose |
|----------|----------|---------|
| ADR Template | `templates/architecture/adr-template.md` | Decision documentation |
| Architecture Overview | `templates/architecture/overview-template.md` | System architecture |
| Patterns | `templates/architecture/patterns-template.md` | Code patterns |
| Domain Model | `templates/domain/model-template.md` | Business entities |
| Glossary | `templates/domain/glossary-template.md` | Terminology |
| Workflows | `templates/domain/workflows-template.md` | Business processes |
| API Overview | `templates/api/overview-template.md` | API principles |
| API Endpoints | `templates/api/endpoints-template.md` | Endpoint docs |
| AGENTS.md | `templates/AGENTS-template.md` | AI navigation guide |

### Tooling

| Tool | Location | Purpose |
|------|----------|---------|
| ADR Script | `scripts/new-adr.sh` | Create new ADRs |
| VS Code Snippets | `vscode-snippets/docs.code-snippets` | Fast documentation |
| Markdownlint Config | `templates/.markdownlint.jsonc` | Doc linting |

### Sample Documentation

| Document | Location | Description |
|----------|----------|-------------|
| ADR-001 | `sample-docs/architecture/decisions/001-*.md` | Debian base image |
| ADR-002 | `sample-docs/architecture/decisions/002-*.md` | Chezmoi selection |
| System Context | `sample-docs/diagrams/system-context.md` | External interactions |
| Container Diagram | `sample-docs/diagrams/container-diagram.md` | Internal structure |
| Glossary | `sample-docs/domain/glossary.md` | Project terminology |

## Documentation Structure

### Recommended Directory Layout

```
docs/
├── AGENTS.md                 # AI navigation guide (required)
├── architecture/
│   ├── overview.md           # System architecture
│   ├── patterns.md           # Code patterns
│   ├── decisions/            # ADRs
│   │   ├── 001-base-image.md
│   │   ├── 002-dotfiles.md
│   │   └── template.md
│   └── diagrams/             # Mermaid diagrams
├── api/
│   ├── overview.md           # API principles
│   ├── endpoints.md          # Endpoint docs
│   └── schemas/              # JSON schemas
├── domain/
│   ├── model.md              # Domain model
│   ├── glossary.md           # Terminology
│   └── workflows.md          # Business processes
├── operations/
│   ├── runbooks/             # Operational procedures
│   └── deployment.md         # Deployment guide
└── security/
    └── auth.md               # Authentication docs
```

## Key Findings

### 1. ADRs Are Essential for AI Context

ADRs provide the "why" behind decisions, which AI agents need to:
- Avoid re-proposing rejected alternatives
- Maintain consistency with past decisions
- Understand trade-offs when modifying code

**Recommendation**: Create ADRs for all significant technical decisions.

### 2. Mermaid Diagrams Are AI-Parseable

Text-based diagrams (Mermaid, PlantUML) can be read and understood by AI agents, unlike image-based formats.

**Supported diagram types**:
- `flowchart`: Process flows, decision trees
- `sequenceDiagram`: Interaction sequences
- `stateDiagram`: State machines
- `erDiagram`: Entity relationships
- `classDiagram`: Class structures
- `graph`: General graphs

**Recommendation**: Use Mermaid for all architectural diagrams.

### 3. Glossary Ensures Consistent Terminology

AI agents can inadvertently introduce synonyms or incorrect terms. A glossary:
- Defines canonical terms
- Maps deprecated terms to replacements
- Provides context for when to use each term

**Recommendation**: Maintain a domain glossary and reference it in AGENTS.md.

### 4. docs/AGENTS.md Provides Navigation

AI agents benefit from explicit guidance on:
- Where to find specific information
- When to consult which documents
- How documents relate to each other

**Recommendation**: Always include docs/AGENTS.md as an AI navigation guide.

### 5. VS Code Snippets Accelerate Documentation

Snippets for common patterns reduce friction:
- ADR creation: `adr` prefix
- Mermaid diagrams: `mermaid-flow`, `mermaid-seq`, etc.
- API endpoints: `api-endpoint`
- Glossary terms: `glossary-term`

**Recommendation**: Install snippets in `.vscode/docs.code-snippets`.

## Implementation Guide

### Initial Setup

1. **Create directory structure**:
   ```bash
   mkdir -p docs/{architecture/{decisions,diagrams},api/schemas,domain,operations/runbooks,security}
   ```

2. **Copy templates**:
   ```bash
   cp spikes/013-project-knowledge/templates/AGENTS-template.md docs/AGENTS.md
   cp spikes/013-project-knowledge/templates/architecture/*.md docs/architecture/
   cp spikes/013-project-knowledge/templates/domain/*.md docs/domain/
   cp spikes/013-project-knowledge/templates/api/*.md docs/api/
   ```

3. **Install tooling**:
   ```bash
   cp spikes/013-project-knowledge/scripts/new-adr.sh scripts/
   chmod +x scripts/new-adr.sh

   mkdir -p .vscode
   cp spikes/013-project-knowledge/vscode-snippets/docs.code-snippets .vscode/

   cp spikes/013-project-knowledge/templates/.markdownlint.jsonc .markdownlint.jsonc
   ```

4. **Create initial ADRs**:
   ```bash
   ./scripts/new-adr.sh "Use Debian Bookworm as base image"
   ./scripts/new-adr.sh "Use Chezmoi for dotfile management"
   ```

### Ongoing Maintenance

| Trigger | Action |
|---------|--------|
| New significant decision | Create ADR |
| Architecture changes | Update diagrams |
| New domain concept | Add to glossary |
| API changes | Update endpoints.md |
| New term used inconsistently | Add to glossary |

### AI Tool Configuration

Configure AI tools to include `docs/` in their context:

**Continue (config.yaml)**:
```yaml
context:
  - provider: file
  - provider: codebase
    params:
      include:
        - docs/**/*.md
```

**Cline (settings)**:
```
Include docs/ directory in file context
```

## Validation Checklist

Before merging documentation:

- [ ] ADRs follow template structure
- [ ] Diagrams render correctly in Mermaid
- [ ] Glossary terms are used consistently
- [ ] docs/AGENTS.md references all new documents
- [ ] Markdownlint passes without errors
- [ ] Cross-references are valid

## Cost-Benefit Analysis

### Benefits

1. **Reduced AI hallucination**: Context prevents AI from making incorrect assumptions
2. **Consistent decisions**: ADRs prevent re-introducing rejected approaches
3. **Faster onboarding**: New team members and AI understand context quickly
4. **Better code quality**: AI follows documented patterns

### Costs

1. **Initial setup time**: ~2-4 hours to establish structure
2. **Ongoing maintenance**: ~10-15 min per significant change
3. **Learning curve**: Team needs to understand ADR workflow

**ROI**: Documentation pays for itself after preventing 2-3 AI-related mistakes or decision reversals.

## Integration with Other PRDs

| PRD | Integration |
|-----|-------------|
| PRD-009 AI Extensions | Configure Continue/Cline to read docs/ |
| PRD-010 Context Files | AGENTS.md complements root AGENTS.md |
| PRD-011 MCP | MCP filesystem server provides doc access |
| PRD-012 Memory Bank | Memory bank can reference ADRs |

## Recommendations

1. **Start with ADRs**: Document existing decisions retroactively
2. **Add glossary early**: Prevents terminology drift
3. **Diagrams for complex systems**: Visual aids help AI understand relationships
4. **Update incrementally**: Don't try to document everything at once
5. **Reference from code**: Link to relevant docs in code comments

## Next Steps

1. Copy templates to `docs/` directory
2. Create initial ADRs for PRD-001 through PRD-004 decisions
3. Configure AI extensions to include docs/ in context
4. Train team on ADR workflow
5. Set up CI to validate markdown

## References

- [Architecture Decision Records](https://adr.github.io/)
- [Mermaid Diagram Syntax](https://mermaid.js.org/)
- [C4 Model](https://c4model.com/)
- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
