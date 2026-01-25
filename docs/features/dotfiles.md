# Dotfiles (Chezmoi)

Chezmoi is used to manage per-user configuration inside the container (dotfiles, tool configs, and encrypted secrets).

Applies to: `main`

## Prerequisites

- `docs/getting-started/index.md`
- Familiarity with dotfiles and shell configuration

## What Chezmoi manages here

- Tool configuration templates under `src/chezmoi/`
- Secrets encryption (age) integration: `docs/features/secrets-management.md`

## Basic workflow

Edit a managed file:

```bash
chezmoi edit ~/.bashrc
```

Apply changes:

```bash
chezmoi apply
```

## Configuration

- Chezmoi source state is in `~/.local/share/chezmoi/`
- Repo-provided templates live under `src/chezmoi/`

## Common pitfalls

- Changes do not appear: run `chezmoi status` then `chezmoi apply`
- Confusing template behavior: search for the `.tmpl` file in `src/chezmoi/`

## Related

- `docs/features/secrets-management.md`
- `docs/reference/configuration.md`

## Next steps

- Enable AI tooling: `docs/features/ai-assistants.md`
