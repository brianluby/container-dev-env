# Feature Specification: Secret Injection for Development Containers

**Feature Branch**: `003-secret-injection`
**Created**: 2026-01-20
**Status**: Draft
**Input**: PRD 003-prd-secret-injection.md - Secure secret injection using age-encrypted dotfiles

## Clarifications

### Session 2026-01-20

- Q: What happens when the encryption key is lost or corrupted? → A: User is responsible for key backup; document best practices only (no built-in recovery features)
- Q: How does the system handle malformed or incomplete secrets files? → A: Fail container startup with clear error message pointing to the issue

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-Time Secret Setup (Priority: P1)

A developer setting up their development container for the first time needs to configure their secrets (API keys, tokens, credentials) so they can work with external services. They want a quick, guided setup that doesn't require learning complex tooling.

**Why this priority**: This is the gateway experience - if developers can't get secrets working quickly, they'll abandon the secure approach and resort to insecure workarounds.

**Independent Test**: Can be fully tested by running the setup wizard and verifying that a sample secret is accessible inside the container within 5 minutes.

**Acceptance Scenarios**:

1. **Given** a fresh container with no secrets configured, **When** I run the secret setup command, **Then** I am guided through creating an encryption key and adding my first secret
2. **Given** I have completed the setup wizard, **When** I start the container, **Then** my secrets are available as environment variables without additional steps
3. **Given** I am a new team member, **When** I follow the setup documentation, **Then** I can configure my own secrets without accessing or seeing other team members' secrets

---

### User Story 2 - Daily Development Workflow (Priority: P1)

A developer working on a project needs their secrets available automatically when they start their container. They don't want to think about secrets during normal development - they should just work.

**Why this priority**: This is the daily experience - secrets must be transparent and automatic for developers to adopt secure practices.

**Independent Test**: Can be tested by starting a container and immediately running a command that requires credentials (e.g., API call), verifying it succeeds without manual intervention.

**Acceptance Scenarios**:

1. **Given** secrets are configured, **When** I start the development container, **Then** all my secrets are automatically available as environment variables
2. **Given** a running container, **When** I run docker inspect on it, **Then** no secrets are visible in the output
3. **Given** secrets loaded as environment variables, **When** my application reads them, **Then** it works without any code changes to handle special secret formats

---

### User Story 3 - Adding or Updating Secrets (Priority: P2)

A developer needs to add a new API key or rotate an existing credential. They want a simple command to update their secrets without disrupting their workflow.

**Why this priority**: Secret rotation is a regular maintenance task that must be easy enough that developers actually do it.

**Independent Test**: Can be tested by adding a new secret, restarting the container, and verifying the new secret is available.

**Acceptance Scenarios**:

1. **Given** an existing secrets configuration, **When** I add a new secret, **Then** it is encrypted and stored securely
2. **Given** an updated secret value, **When** I restart the container, **Then** the new value is available
3. **Given** I edit the secrets file, **When** I commit to git, **Then** only encrypted content is stored in the repository

---

### User Story 4 - Offline Development (Priority: P2)

A developer working without internet access (airplane, remote location) needs their previously configured secrets to still work. No network dependency for secret access.

**Why this priority**: Development shouldn't require constant connectivity - secrets configured locally should remain accessible.

**Independent Test**: Can be tested by configuring secrets, disconnecting from network, restarting container, and verifying secrets are still available.

**Acceptance Scenarios**:

1. **Given** secrets were previously configured with network access, **When** I start the container without network connectivity, **Then** my secrets are still available
2. **Given** my encryption key is stored locally, **When** the container starts, **Then** decryption happens locally without external service calls

---

### User Story 5 - Team Onboarding (Priority: P3)

A team lead needs to onboard new developers to a project that uses secrets. Each developer should have their own secrets (not shared), and the process should be documented and repeatable.

**Why this priority**: Team scaling is important but less frequent than individual developer workflows.

**Independent Test**: Can be tested by having a new team member follow the onboarding guide and successfully configure their own secrets.

**Acceptance Scenarios**:

1. **Given** a new developer joins the team, **When** they clone the repository, **Then** they see documentation explaining how to set up their own secrets
2. **Given** the project uses encrypted secrets, **When** a new developer generates their own encryption key, **Then** they can create their own secrets file without affecting others
3. **Given** multiple developers on a project, **When** each has their own secrets configured, **Then** no developer can read another developer's secrets

---

### Edge Cases

- **Key loss/corruption**: User is responsible for backing up their encryption key; documentation provides best practices (e.g., store in password manager). Lost keys require re-creating secrets from source systems.
- **Malformed secrets file**: Container startup fails immediately with a clear error message identifying the parsing issue and file location. No partial loading.
- What happens if a secret value contains special characters (quotes, newlines, equals signs)?
- How are secrets handled if the container crashes during startup?
- What happens when a developer tries to access a secret that doesn't exist?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST keep secrets out of container images (not baked in at build time)
- **FR-002**: System MUST keep secrets out of version control (only encrypted form may be committed)
- **FR-003**: System MUST make secrets available as environment variables inside the container
- **FR-004**: System MUST encrypt secrets at rest using the user's personal encryption key
- **FR-005**: System MUST integrate with the existing Chezmoi dotfile management system
- **FR-006**: System MUST work with docker run, docker-compose, and devcontainer workflows
- **FR-007**: System MUST provide a setup wizard or guide for first-time configuration
- **FR-008**: System MUST allow adding, updating, and removing individual secrets
- **FR-009**: System MUST work offline after initial configuration
- **FR-010**: System MUST not expose secrets in docker inspect, docker history, or process listings
- **FR-011**: System MUST support secrets containing special characters (quotes, newlines, unicode)
- **FR-012**: System MUST provide clear error messages when secrets cannot be loaded
- **FR-013**: Documentation MUST include best practices for encryption key backup
- **FR-014**: System MUST fail fast on malformed secrets files with actionable error messages

### Key Entities

- **Secret**: A key-value pair representing sensitive configuration (e.g., API_KEY=abc123). Has a name, encrypted value, and optional metadata (description, expiry hint).
- **Encryption Key**: User's personal age key used to encrypt/decrypt their secrets. Stored securely on the host, never in the container image or repository. User responsible for backup.
- **Secrets File**: An encrypted file containing multiple secrets. Can be committed to version control safely. Decrypted at container startup. Must be fully valid or startup fails.
- **Secret Profile**: An optional grouping of secrets for different contexts (e.g., dev, staging). Allows switching between credential sets.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: New developers can configure their first secret within 5 minutes of following the setup guide
- **SC-002**: Secrets are available in the container within 2 seconds of container startup
- **SC-003**: 100% of secrets remain inaccessible via docker inspect or docker history
- **SC-004**: System adds less than 10MB to container image size
- **SC-005**: Secret update workflow (edit, encrypt, restart) completes in under 1 minute
- **SC-006**: System works with 0 external network calls after initial setup
- **SC-007**: Encrypted secrets file size is within 2x of plaintext size (reasonable encryption overhead)
- **SC-008**: Malformed secrets files produce error messages that identify the problem in 100% of cases

## Assumptions

- Developers have age encryption tooling available (already installed per 002-dotfile-management)
- Developers are using Chezmoi for dotfile management (dependency on 002-prd-dotfile-management)
- Each developer manages their own encryption key (no shared team keys)
- Secrets are developer-specific, not shared across the team
- Container restarts are acceptable for picking up secret changes (no hot-reload requirement)
- The host machine is trusted (encryption key stored on host filesystem)
