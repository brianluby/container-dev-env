# 002-prd-dotfile-management

## Problem Statement

Developer configuration files (dotfiles) are not portable between machines or
container instances. Each new environment requires manual setup of shell config,
git settings, editor preferences, and tool configurations. This creates
inconsistent experiences and wastes time recreating personalized setups. A
dotfile management solution enables reproducible, version-controlled
configuration that works seamlessly in containerized development environments.

## Requirements

### Must Have (M)

- [ ] Dotfiles sync from external repository into container on startup
- [ ] Support for common dotfiles: .bashrc, .gitconfig, .vimrc, .tmux.conf
- [ ] Works with the container base image (001-prd-container-base)
- [ ] Non-destructive: does not overwrite existing files without explicit action
- [ ] Works offline after initial sync (no network dependency at runtime)
- [ ] Configuration stored in user-controlled git repository

### Should Have (S)

- [ ] Template support for machine-specific values (email, paths, hostnames)
- [ ] Secret placeholder support (actual secrets handled by 003-prd-secret-injection)
- [ ] Automatic application on container start (optional, user-controlled)
- [ ] Easy bootstrap: single command to initialize in new environment
- [ ] Diff/preview before applying changes

### Could Have (C)

- [ ] Multi-machine profiles (work vs personal vs container)
- [ ] Encrypted file support for semi-sensitive config
- [ ] Hooks for post-apply scripts (e.g., reload shell, install plugins)
- [ ] Integration with shell plugin managers (oh-my-zsh, zinit)
- [ ] Rollback to previous configuration state

### Won't Have (W)

- [ ] Secret management (covered in 003-prd-secret-injection)
- [ ] System-level configuration (/etc files)
- [ ] Package installation (handled by Dockerfile or separate tooling)
- [ ] GUI application preferences
- [ ] Windows-specific dotfiles

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| Container-friendly | Must | Works in ephemeral container environments |
| Simple mental model | High | Easy to understand what happens and where |
| Cross-platform | High | macOS, Linux, container environments |
| Template support | High | Machine-specific values without forking |
| Active maintenance | High | Regular updates, responsive to issues |
| Minimal dependencies | Medium | Fewer moving parts = fewer failure modes |
| Learning curve | Medium | Quick to get started, depth available |
| MIT-compatible license | Must | Open source project compatibility |

## Tool Candidates

| Tool | License | Pros | Cons | Spike Result |
|------|---------|------|------|--------------|
| Chezmoi | MIT | Templates, encryption, cross-platform, single binary, excellent docs | Learning curve for templates, Go dependency for building | Evaluate |
| GNU Stow | GPL-3.0 | Simple symlink model, no dependencies, Unix philosophy | No templates, manual conflict resolution, symlinks can confuse some tools | Evaluate |
| Bare git repo | N/A | No extra tools, pure git, ultimate flexibility | Manual setup, no templates, easy to mess up home directory | Evaluate |
| Nix home-manager | MIT | Declarative, reproducible, rollback support | Heavy Nix dependency, steep learning curve, overkill for dotfiles-only | Evaluate |

## Selected Approach

***Chezmoi*** selected for dotfile management

## Acceptance Criteria

- [ ] Given a fresh container, when I run the bootstrap command, then my dotfiles are applied within 30 seconds
- [ ] Given applied dotfiles, when I start a new shell, then my aliases and prompt are configured
- [ ] Given a dotfiles repo with templates, when I apply on different machines, then machine-specific values are correctly substituted
- [ ] Given existing files in home directory, when I apply dotfiles, then I am warned about conflicts before any overwrites
- [ ] Given no network access, when I start a container with previously synced dotfiles, then configuration still works
- [ ] Given changes to my dotfiles repo, when I pull and re-apply, then changes are reflected in the container
- [ ] Given the container base image, when dotfile tool is added, then image size increases by less than 50MB

## Dependencies

- Requires: 001-prd-container-base (completed)
- Blocks: 005-prd-ide-integration (editor configs depend on dotfiles)

## Spike Tasks

- [x] Test Chezmoi: install, init from git repo, apply, verify templates work
- [x] Test GNU Stow: setup dotfiles repo structure, stow packages, verify symlinks
- [x] Test bare git repo: init, set worktree to $HOME, checkout, handle .gitignore
- [x] Test Nix home-manager: install Nix, configure home.nix, apply, measure overhead
- [x] Compare bootstrap time for each approach (fresh container)
- [x] Compare disk space overhead for each tool
- [x] Test template substitution for machine-specific values
- [x] Test conflict handling when files already exist
- [x] Evaluate documentation quality and community support
- [x] Document pros/cons from hands-on testing
