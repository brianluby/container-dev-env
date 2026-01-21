# Data Model: Dotfile Management with Chezmoi

**Feature**: 002-dotfile-management
**Date**: 2026-01-20

## Overview

This feature does not introduce new persistent data entities to the container image itself. Instead, it enables users to manage their own dotfile data through Chezmoi. This document describes the data structures Chezmoi uses, which users will interact with.

## User-Managed Entities

### Dotfile Source Repository

**Description**: A git repository containing the user's dotfiles managed by Chezmoi.

**Location**: User's own git hosting (GitHub, GitLab, etc.)

**Structure**:
```
dotfiles/                    # User's dotfiles repo
├── .chezmoi.toml.tmpl      # Optional: interactive config template
├── .chezmoiignore          # Files to ignore per-machine
├── .chezmoiscripts/        # Optional: run scripts
│   ├── run_once_install-packages.sh
│   └── run_onchange_reload-shell.sh
├── dot_bashrc.tmpl         # .bashrc template
├── dot_gitconfig.tmpl      # .gitconfig template
├── dot_vimrc               # .vimrc (no template)
├── dot_tmux.conf           # .tmux.conf
├── dot_config/             # .config/ directory
│   └── nvim/
│       └── init.lua
└── private_dot_ssh/        # .ssh/ (private files)
    └── config.tmpl
```

**Naming Conventions** (Chezmoi-defined):
| Prefix | Meaning | Example Source | Target |
|--------|---------|----------------|--------|
| `dot_` | Hidden file/dir | `dot_bashrc` | `.bashrc` |
| `private_` | Mode 0600/0700 | `private_dot_ssh` | `.ssh` |
| `executable_` | Mode +x | `executable_script.sh` | `script.sh` |
| `empty_` | Create if missing | `empty_dot_keep` | `.keep` |
| `.tmpl` suffix | Template file | `dot_bashrc.tmpl` | `.bashrc` |

### Chezmoi Local State

**Description**: Local state maintained by Chezmoi on each machine.

**Location**: `~/.local/share/chezmoi/` (source directory)

**Contents**:
- Clone of user's dotfiles repository
- Chezmoi metadata files
- Script state (which `run_once` scripts have run)

**Persistence**: Survives container restarts if `~/.local/share` is a volume mount.

### Chezmoi Configuration

**Description**: Machine-specific configuration for template rendering.

**Location**: `~/.config/chezmoi/chezmoi.toml`

**Structure**:
```toml
# chezmoi.toml
[data]
    email = "user@example.com"
    name = "User Name"
    machine_type = "container"  # or "work", "personal"

[git]
    autoCommit = false
    autoPush = false
```

**Template Variables Available**:
| Variable | Source | Example Value |
|----------|--------|---------------|
| `.chezmoi.hostname` | System | `container-abc123` |
| `.chezmoi.os` | System | `linux` |
| `.chezmoi.arch` | System | `amd64` or `arm64` |
| `.chezmoi.username` | System | `dev` |
| `.chezmoi.homeDir` | System | `/home/dev` |
| `.email` | Config | `user@example.com` |
| `.name` | Config | `User Name` |
| `.machine_type` | Config | `container` |

## Container Image Entities

### Chezmoi Binary

**Description**: The Chezmoi executable installed in the container.

**Attributes**:
| Attribute | Value |
|-----------|-------|
| Path | `/usr/local/bin/chezmoi` |
| Version | Pinned (e.g., v2.47.1) |
| Size | ~15MB |
| Owner | root:root |
| Permissions | 0755 |

### age Binary

**Description**: The age encryption tool for Chezmoi encrypted files.

**Attributes**:
| Attribute | Value |
|-----------|-------|
| Path | `/usr/local/bin/age` |
| Version | Pinned (e.g., v1.1.1) |
| Size | ~5MB |
| Owner | root:root |
| Permissions | 0755 |

### age-keygen Binary

**Description**: Key generation tool for age encryption.

**Attributes**:
| Attribute | Value |
|-----------|-------|
| Path | `/usr/local/bin/age-keygen` |
| Version | Pinned (e.g., v1.1.1) |
| Size | ~5MB |
| Owner | root:root |
| Permissions | 0755 |

## State Transitions

### Bootstrap Flow

```
Container Start
     │
     ▼
[No Chezmoi State] ──chezmoi init──▶ [Source Cloned]
                        │                    │
                        │                    ▼
                        │            [Config Prompted]
                        │                    │
                        ▼                    ▼
              ◀── chezmoi apply ──▶ [Dotfiles Applied]
                                            │
                                            ▼
                                    [Ready for Use]
```

### Update Flow

```
[Dotfiles Applied]
        │
        ▼
  chezmoi update ──▶ [Pull Remote Changes]
        │                    │
        │                    ▼
        │            [Diff Computed]
        │                    │
        ▼                    ▼
    [Applied] ◀────── [User Confirms]
```

## Data Validation Rules

### Source Repository
- Must be a valid git repository
- Must be accessible via HTTPS or SSH
- No validation of content structure (user responsibility)

### Chezmoi Configuration
- TOML format required
- Invalid TOML causes init failure with clear error
- Missing config allowed (uses defaults)

### Template Files
- Go template syntax required
- Invalid templates cause apply failure
- Error messages include file path and line number

## Relationships

```
┌─────────────────┐     ┌──────────────────────┐
│  User's Remote  │     │  Container Image     │
│  Dotfiles Repo  │     │                      │
└────────┬────────┘     │  ┌────────────────┐  │
         │              │  │ chezmoi binary │  │
         │ clone        │  └───────┬────────┘  │
         ▼              │          │           │
┌────────────────┐      │          │ manages   │
│ ~/.local/share │◀─────│──────────┘           │
│   /chezmoi/    │      │                      │
│ (source state) │      │  ┌────────────────┐  │
└───────┬────────┘      │  │   age binary   │  │
        │               │  └───────┬────────┘  │
        │ apply         │          │           │
        ▼               │          │ decrypts  │
┌────────────────┐      │          ▼           │
│  ~/.*          │◀─────│──────────────────────│
│ (target state) │      │                      │
│  .bashrc       │      └──────────────────────┘
│  .gitconfig    │
│  .vimrc        │
└────────────────┘
```
