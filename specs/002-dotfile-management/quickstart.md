# Quickstart: Dotfile Management with Chezmoi

**Feature**: 002-dotfile-management
**Date**: 2026-01-20

## Prerequisites

- Container image built with Chezmoi (this feature)
- Your dotfiles in a git repository (GitHub, GitLab, etc.)
- Network access for initial setup

## Quick Bootstrap

### One-Command Setup

```bash
# Start container
docker run -it --rm devcontainer

# Inside container: bootstrap from your dotfiles repo
chezmoi init --apply gh-username
# Or with full URL:
chezmoi init --apply https://github.com/username/dotfiles.git
```

That's it! Your dotfiles are now applied.

## Step-by-Step Setup

### 1. Start the Container

```bash
# Interactive session
docker run -it --rm devcontainer

# Or with mounted workspace
docker run -it --rm -v "$(pwd)":/workspace -w /workspace devcontainer
```

### 2. Initialize Chezmoi

```bash
# Initialize from GitHub (shorthand)
chezmoi init gh-username

# Or from any git URL
chezmoi init https://github.com/username/dotfiles.git
```

### 3. Preview Changes

```bash
# See what will be applied
chezmoi diff

# List managed files
chezmoi managed
```

### 4. Apply Dotfiles

```bash
# Apply all dotfiles
chezmoi apply

# Or apply with verbose output
chezmoi apply -v
```

### 5. Verify

```bash
# Check your prompt changed (if configured)
exec bash

# Verify git config
git config --list

# Check aliases
alias
```

## Common Operations

### Update from Remote

```bash
# Pull and apply latest changes
chezmoi update
```

### Edit a Managed File

```bash
# Edit source (not target) - opens in $EDITOR
chezmoi edit ~/.bashrc

# Apply the change
chezmoi apply
```

### Add a New Dotfile

```bash
# Add existing file to management
chezmoi add ~/.tmux.conf

# Add as template
chezmoi add --template ~/.gitconfig

# Commit and push
chezmoi cd
git add .
git commit -m "Add tmux config"
git push
```

### Check Status

```bash
# See what differs between source and target
chezmoi status

# Full doctor check
chezmoi doctor
```

## Template Variables

Use these in your `.tmpl` files:

| Variable | Value in Container |
|----------|-------------------|
| `{{ .chezmoi.hostname }}` | Container ID |
| `{{ .chezmoi.os }}` | `linux` |
| `{{ .chezmoi.arch }}` | `amd64` or `arm64` |
| `{{ .chezmoi.username }}` | `dev` |
| `{{ .chezmoi.homeDir }}` | `/home/dev` |

### Custom Variables

Create `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    email = "you@example.com"
    name = "Your Name"
    machine_type = "container"
```

Use in templates:

```bash
# In dot_gitconfig.tmpl
[user]
    email = {{ .email }}
    name = {{ .name }}
```

## Encrypted Files

### Setup Encryption

```bash
# Generate age key
age-keygen -o ~/.config/chezmoi/key.txt

# Add to chezmoi config
cat >> ~/.config/chezmoi/chezmoi.toml << 'EOF'
encryption = "age"
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1..."  # Your public key from above
EOF
```

### Add Encrypted File

```bash
# Add file with encryption
chezmoi add --encrypt ~/.ssh/config
```

## Persistent Setup

To keep dotfiles across container rebuilds, mount the Chezmoi directories:

```bash
docker run -it --rm \
  -v chezmoi-source:/home/dev/.local/share/chezmoi \
  -v chezmoi-config:/home/dev/.config/chezmoi \
  devcontainer
```

Or use host directories:

```bash
docker run -it --rm \
  -v ~/.local/share/chezmoi:/home/dev/.local/share/chezmoi \
  -v ~/.config/chezmoi:/home/dev/.config/chezmoi \
  devcontainer

# Then just apply (no init needed)
chezmoi apply
```

## Troubleshooting

### "Template error: undefined variable"

Your template uses a variable not in your config.

```bash
# Check what's available
chezmoi data

# Add missing variable to ~/.config/chezmoi/chezmoi.toml
```

### "Permission denied"

File permissions issue.

```bash
# Check source permissions
chezmoi cat ~/.bashrc

# Force apply (overwrites)
chezmoi apply --force
```

### "Merge conflict"

Local changes conflict with source.

```bash
# See the diff
chezmoi diff ~/.bashrc

# Accept source version
chezmoi apply --force

# Or edit to resolve
chezmoi edit ~/.bashrc
```

### Offline Issues

After initial setup, most operations work offline:

```bash
# These work offline:
chezmoi apply
chezmoi diff
chezmoi status

# This requires network:
chezmoi update  # Needs to pull from remote
```

## Next Steps

1. **Create your dotfiles repo** if you don't have one
2. **Add templates** for machine-specific config
3. **Set up encryption** for sensitive configs
4. **Configure container volumes** for persistence

## References

- [Chezmoi User Guide](https://www.chezmoi.io/user-guide/setup/)
- [Chezmoi Reference](https://www.chezmoi.io/reference/)
- [Template Syntax](https://www.chezmoi.io/user-guide/templating/)
