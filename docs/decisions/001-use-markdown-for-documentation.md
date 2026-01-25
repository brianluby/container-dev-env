# ADR-001: Use Markdown for All Project Knowledge Documentation

**Status**: Accepted
**Date**: 2026-01-23
**Deciders**: Project maintainers

## Prerequisites

- None

## Context

The project needs a structured knowledge documentation system that AI coding agents can read and understand. The documentation must be portable across different AI tools (Claude Code, Cline, Continue), version-controllable, and human-readable. Multiple formats were considered including rich text, structured data formats (JSON/YAML), and various markup languages.

## Decision

We will use plain Markdown for all project knowledge documentation. All documents in the `docs/` directory will be `.md` files using standard GitHub-Flavored Markdown syntax, including Mermaid code blocks for diagrams.

## Alternatives Considered

### Structured Data (JSON/YAML)

- **Pros**: Machine-parseable, schema-validatable, consistent structure
- **Cons**: Poor human readability, verbose for prose content, requires tooling to render
- **Why rejected**: Documentation is primarily prose with some structure; Markdown is more natural for this use case

### Rich Text (Google Docs, Confluence)

- **Pros**: WYSIWYG editing, collaborative features, rich formatting
- **Cons**: Not version-controllable, not AI-parseable from filesystem, vendor lock-in, proprietary format
- **Why rejected**: AI tools cannot read proprietary formats from the project directory; violates portability constraint

### AsciiDoc

- **Pros**: More features than Markdown, better for technical docs, includes/transclusion
- **Cons**: Less universal AI tool support, more complex syntax, requires tooling for rendering
- **Why rejected**: Markdown has broader AI training data coverage and native GitHub rendering

### reStructuredText

- **Pros**: Python ecosystem standard, powerful cross-referencing, extensible
- **Cons**: Less intuitive syntax, primarily Python-focused, less AI familiarity
- **Why rejected**: Not as universally readable by AI tools; Markdown is the de facto standard

## Consequences

### Positive

- All target AI tools (Claude Code, Cline, Continue) can read Markdown natively
- Documentation is version-controllable with meaningful diffs
- No specialized tooling required — any text editor works
- GitHub renders Markdown automatically, including Mermaid diagrams
- Low barrier to contribution for all team members

### Negative

- Limited formatting compared to rich document formats
- No built-in schema validation for document structure (relies on templates and conventions)
- Cross-references are manual (no automatic link checking without tooling)

## Follow-up Actions

- [x] Create documentation directory structure (`docs/`)
- [x] Establish templates for each documentation category
- [ ] Document Mermaid diagram conventions for consistent usage

## Related

- [Navigation](../navigation.md)
- [Page Template](../_page-template.md)

## Next steps

- If you are updating docs: [Contributing](../contributing/index.md)
