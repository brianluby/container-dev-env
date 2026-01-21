# Feature Specification: Dotfile Management with Chezmoi

**Feature Branch**: `002-dotfile-management`
**Created**: 2026-01-20
**Status**: Draft
**Input**: User description: "prds/002-prd-dotfile-management.md - Chezmoi selected based on user testing"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bootstrap Dotfiles in Fresh Container (Priority: P1)

A developer starts a fresh development container and wants their personalized shell configuration, git settings, and editor preferences available immediately. They run a single bootstrap command that pulls their dotfiles from their git repository and applies them to the container.

**Why this priority**: This is the core functionality - without bootstrap capability, no dotfiles can be applied. Establishes the foundation for all subsequent personalization.

**Independent Test**: Can be fully tested by running `chezmoi init --apply <repo>` in a fresh container and verifying that dotfiles appear in the correct locations. Delivers immediate value of personalized environment.

**Acceptance Scenarios**:

1. **Given** a fresh container with Chezmoi installed, **When** I run `chezmoi init --apply <my-dotfiles-repo>`, **Then** my dotfiles are cloned and applied to my home directory within 30 seconds
2. **Given** a fresh container, **When** I run the bootstrap command, **Then** my shell prompt, aliases, and git configuration are immediately available in new shell sessions
3. **Given** a dotfiles repository URL, **When** I bootstrap on a container without prior Chezmoi state, **Then** all managed dotfiles are created in their target locations

---

### User Story 2 - Template-Based Machine-Specific Configuration (Priority: P1)

A developer uses different email addresses and paths on different machines (work laptop, personal machine, container). They want their dotfiles to automatically substitute the correct values based on which environment they're in, without maintaining multiple copies of config files.

**Why this priority**: Templates are essential for portable dotfiles - without them, developers must fork their dotfiles or manually edit after every sync. This is the key differentiator that led to Chezmoi selection.

**Independent Test**: Can be tested by applying the same dotfiles repo on two different machines/containers and verifying different values are substituted. Delivers value of single-source-of-truth for config.

**Acceptance Scenarios**:

1. **Given** a `.gitconfig.tmpl` template with `email = {{ .email }}`, **When** I apply dotfiles on my work machine, **Then** my work email is substituted
2. **Given** the same dotfiles repo, **When** I apply on my personal machine, **Then** my personal email is substituted
3. **Given** a template referencing hostname, **When** I apply in a container, **Then** the container hostname is correctly detected and substituted

---

### User Story 3 - Preview and Diff Before Applying Changes (Priority: P2)

A developer has made changes to their dotfiles repository and wants to see exactly what will change in their home directory before applying. They run a diff command to preview additions, modifications, and deletions.

**Why this priority**: Safe updates prevent accidental overwrites and give developers confidence. Important for daily use but not required for initial setup.

**Independent Test**: Can be tested by modifying a dotfile in the source repo and running `chezmoi diff` to see the proposed changes. Delivers value of safe, predictable updates.

**Acceptance Scenarios**:

1. **Given** changes in my dotfiles source, **When** I run `chezmoi diff`, **Then** I see a clear diff of what will be added, modified, or removed
2. **Given** a pending change that would overwrite local modifications, **When** I run `chezmoi diff`, **Then** the conflict is clearly highlighted
3. **Given** no changes between source and target, **When** I run `chezmoi diff`, **Then** output is empty indicating sync is current

---

### User Story 4 - Update Dotfiles from Remote Changes (Priority: P2)

A developer has pushed changes to their dotfiles repository from another machine and wants to pull those changes into their current environment. They run update commands to fetch and apply the latest configuration.

**Why this priority**: Enables workflow where dotfiles evolve over time. Important for ongoing use but not critical for initial setup.

**Independent Test**: Can be tested by pushing a change to the dotfiles repo from another machine, then running `chezmoi update` and verifying the change appears. Delivers value of synchronized config across machines.

**Acceptance Scenarios**:

1. **Given** new commits in my remote dotfiles repo, **When** I run `chezmoi update`, **Then** changes are pulled and applied to my home directory
2. **Given** I've made local changes to a managed file, **When** I run `chezmoi update` with remote changes to the same file, **Then** I am warned about the conflict before any overwrite
3. **Given** my dotfiles repo is unchanged, **When** I run `chezmoi update`, **Then** the command completes quickly with no changes applied

---

### User Story 5 - Add New Dotfiles to Management (Priority: P3)

A developer creates a new configuration file (e.g., `.tmux.conf`) and wants to add it to their managed dotfiles so it's available on other machines. They use Chezmoi commands to add the file to source control.

**Why this priority**: Enables growth of managed dotfiles over time. Lower priority because initial dotfiles are typically added during setup, not during regular development.

**Independent Test**: Can be tested by creating a new dotfile, running `chezmoi add`, and verifying it appears in the source directory. Delivers value of expanding managed configuration.

**Acceptance Scenarios**:

1. **Given** a new `~/.tmux.conf` file, **When** I run `chezmoi add ~/.tmux.conf`, **Then** the file is copied to my Chezmoi source directory
2. **Given** an added file, **When** I commit and push my dotfiles repo, **Then** the file is available for bootstrap on other machines
3. **Given** a file I want to template, **When** I run `chezmoi add --template ~/.config/myapp/config`, **Then** a `.tmpl` file is created in source

---

### User Story 6 - Offline Operation After Initial Sync (Priority: P2)

A developer has previously bootstrapped their dotfiles and now starts their container without network access (e.g., on a plane). Their dotfiles should still work because Chezmoi stores state locally.

**Why this priority**: Containers are often run in varied network conditions. Essential for reliable developer experience but requires initial online bootstrap first.

**Independent Test**: Can be tested by bootstrapping dotfiles, disconnecting network, restarting container, and verifying dotfiles are still present and functional. Delivers value of reliable offline operation.

**Acceptance Scenarios**:

1. **Given** previously applied dotfiles, **When** I start a container without network, **Then** all my dotfiles are present and functional
2. **Given** offline operation, **When** I run `chezmoi apply`, **Then** local source state is applied without network calls
3. **Given** offline operation, **When** I try `chezmoi update`, **Then** I get a clear error about network unavailability (not a crash)

---

### Edge Cases

- What happens when the dotfiles repository doesn't exist or URL is wrong? Chezmoi reports clear error with the invalid URL and exits non-zero.
- What happens when a template references an undefined variable? Chezmoi reports the missing variable name and file, exits non-zero without partial application.
- What happens when target file is a symlink but source expects regular file? Chezmoi handles the type mismatch and reports it clearly.
- What happens when user doesn't have write permission to target location? Chezmoi reports permission error with the specific path.
- What happens when disk is full during apply? Chezmoi fails gracefully and reports disk space error.
- How does Chezmoi handle binary files? Binary files are copied directly without template processing.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST install Chezmoi binary in the container base image
- **FR-002**: System MUST support initializing from a git repository URL via `chezmoi init`
- **FR-003**: System MUST support applying dotfiles to home directory via `chezmoi apply`
- **FR-004**: System MUST support Go text/template syntax for machine-specific values
- **FR-005**: System MUST preserve file permissions when applying dotfiles
- **FR-006**: System MUST support `.chezmoiignore` for excluding files per-machine
- **FR-007**: System SHOULD provide `chezmoi diff` to preview changes before applying
- **FR-008**: System SHOULD provide `chezmoi update` to pull and apply remote changes
- **FR-009**: System SHOULD provide `chezmoi add` to add new files to management
- **FR-010**: System SHOULD support encrypted files via age encryption for semi-sensitive config
- **FR-011**: System COULD support run scripts (`.chezmoiscripts/`) for post-apply actions
- **FR-012**: System COULD support external data sources (1Password, Bitwarden) for secret placeholders
- **FR-013**: System MUST NOT require network access after initial bootstrap for basic operation
- **FR-014**: System MUST NOT overwrite files without explicit user action (apply command)

### Key Entities

- **Dotfile**: A configuration file managed by Chezmoi. Key attributes: source path (in Chezmoi repo), target path (in home directory), file type (regular, template, symlink, script), permissions.
- **Source State**: The desired configuration stored in the Chezmoi source directory (`~/.local/share/chezmoi`). Represents the canonical version of all managed dotfiles.
- **Target State**: The actual files in the user's home directory. May differ from source state if changes haven't been applied.
- **Template**: A dotfile with `.tmpl` extension that uses Go template syntax for variable substitution. Variables come from `.chezmoidata.*` files or system detection.
- **Chezmoi Config**: The `.chezmoi.toml` file containing user-specific data (email, name, machine type) used for template substitution.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can bootstrap their complete dotfile configuration in under 30 seconds on a fresh container
- **SC-002**: Dotfiles work identically across Linux container environments (arm64, amd64) without manual adjustments. Note: macOS/Windows host support is out of scope for this feature; Chezmoi itself supports these platforms for users managing dotfiles outside containers.
- **SC-003**: Template substitution correctly handles at least 5 common variables (email, name, hostname, OS, machine type)
- **SC-004**: Container image size increase from adding Chezmoi is under 50MB
- **SC-005**: Developers can preview all pending changes before applying (zero surprise overwrites)
- **SC-006**: Dotfiles remain functional when container operates offline after initial sync
- **SC-007**: Adding a new dotfile to management takes under 1 minute including commit

## Assumptions

- Developers have an existing dotfiles git repository or will create one
- The container base image (001-prd-container-base) is available and working
- Git is available in the container for repository operations
- Developers are comfortable with basic git workflows (clone, commit, push)
- Internet access is available during initial bootstrap
- Home directory has standard structure (`~/.config/`, `~/.local/`, etc.)

## Scope Boundaries

### In Scope

- Installing Chezmoi in the container image
- Documenting bootstrap workflow for users
- Supporting common dotfiles (.bashrc, .gitconfig, .vimrc, .tmux.conf, etc.)
- Template support for machine-specific configuration
- Basic encrypted file support for semi-sensitive config
- Integration with container startup (optional auto-apply)

### Out of Scope

- Secret management (API keys, tokens) - covered in 003-prd-secret-injection
- System-level configuration (/etc files)
- Package installation or plugin managers
- GUI application preferences
- Windows-specific dotfiles or workflows
- Creating a dotfiles repository for users (they bring their own)

## Dependencies

- **Requires**: 001-prd-container-base (completed)
- **Blocks**: 005-prd-ide-integration (editor configs depend on dotfiles being available)
