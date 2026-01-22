# ADR-002: Use Chezmoi for Dotfile Management

<!--
AI Agent Instructions:
- This ADR documents the dotfile management approach
- Chezmoi templates use Go template syntax
- Dotfiles are stored in ~/.local/share/chezmoi (source) and applied to ~
- Secrets are handled separately via age encryption or env vars
-->

## Metadata

| Field | Value |
|-------|-------|
| Status | Accepted |
| Date | 2024-01-16 |
| Decision Makers | @brianluby |
| Tags | configuration, dotfiles, developer-experience |

## Context

Developer configuration files (dotfiles) need to be:

1. **Portable**: Work across host machines and containers
2. **Version controlled**: Track changes in git
3. **Templatable**: Support machine-specific values (email, paths)
4. **Non-destructive**: Warn before overwriting existing files
5. **Container-friendly**: Work in ephemeral environments

The dotfile management tool must integrate with the containerized development environment and support both local development and container use cases.

## Decision

We will use **Chezmoi** for dotfile management.

### Implementation Details

1. Install Chezmoi binary in container image (~10MB)
2. Users maintain their own dotfiles repo with Chezmoi structure
3. Bootstrap with: `chezmoi init --apply <github-username>`
4. Container entrypoint optionally runs `chezmoi apply` on start
5. Templates use Go template syntax for machine-specific values
6. Secrets handled via age encryption or environment variable placeholders

### Configuration Structure

```
~/.local/share/chezmoi/           # Source directory
├── .chezmoi.yaml.tmpl            # Chezmoi config template
├── dot_bashrc.tmpl               # .bashrc with templates
├── dot_gitconfig.tmpl            # .gitconfig with templates
├── private_dot_ssh/              # SSH directory (private)
│   └── config                    # SSH config
└── run_once_install-packages.sh  # One-time setup script
```

## Consequences

### Positive

- **Single binary**: No runtime dependencies, easy to install
- **Powerful templates**: Go templates handle complex machine-specific logic
- **Built-in encryption**: age encryption for sensitive (non-secret) files
- **Excellent docs**: Comprehensive documentation and examples
- **Active development**: Regular releases, responsive maintainers
- **Cross-platform**: Works on Linux, macOS, and containers identically
- **Diff preview**: `chezmoi diff` shows changes before applying

### Negative

- **Learning curve**: Go template syntax takes time to learn
- **Mitigation**: Provide examples and documentation for common patterns
- **Another tool**: Developers need to learn Chezmoi commands
- **Mitigation**: Simple bootstrap command hides complexity

### Neutral

- Requires users to restructure existing dotfiles repos
- Templates are more powerful than some developers need

## Alternatives Considered

### Alternative 1: GNU Stow

**Description**: Symlink farm manager using a simple directory structure

**Pros**:
- Simple mental model (directories become symlink targets)
- No templates to learn
- No external dependencies

**Cons**:
- No template support for machine-specific values
- Manual conflict resolution
- Symlinks can confuse some tools and IDEs

**Why Rejected**: Template support is essential for machine-specific configuration (different git emails for work/personal, different paths per machine).

### Alternative 2: Bare Git Repository

**Description**: Git repo with worktree set to $HOME

**Pros**:
- No extra tools required
- Pure git workflow
- Maximum flexibility

**Cons**:
- Easy to accidentally add sensitive files
- No template support
- Complex .gitignore management
- Risk of corrupting home directory

**Why Rejected**: Too error-prone and no template support. The flexibility comes with significant footguns.

### Alternative 3: Nix Home Manager

**Description**: Declarative configuration management using Nix

**Pros**:
- Fully declarative and reproducible
- Built-in rollback support
- Can manage packages too

**Cons**:
- Requires Nix installation (heavy dependency)
- Steep learning curve for Nix language
- Overkill for dotfiles-only use case
- Slow initial setup

**Why Rejected**: The Nix ecosystem overhead is not justified for dotfile management alone. May reconsider if project adopts Nix for package management.

## References

- [PRD-002: Dotfile Management](../../../prds/002-prd-dotfile-management.md)
- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Chezmoi Quick Start](https://www.chezmoi.io/quick-start/)
- [Go Template Syntax](https://pkg.go.dev/text/template)
