# Feature Specification: Supply-Chain Hardening — Updated Software, Image Signing & SBOM

**Feature Branch**: `002-supply-chain-hardening`
**Created**: 2026-02-23
**Status**: Implemented
**Input**: User description: "Add supply chain hardening with updated software, image signing and SBOM generation"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Verifiable software installation (Priority: P1)

As a platform maintainer, I need every piece of software in the container image to be installed through a verifiable method — pinned to a specific version with integrity verification — so that no dependency can be silently tampered with or replaced between builds.

**Why this priority**: This is the foundational supply-chain guarantee. Image signing and SBOMs have limited value if the software inside the image was installed through unverifiable channels. Currently, the Node.js runtime is installed via a script-piped pattern (`curl | bash`), package manager installs lack version pinning, and at least one tool install lacks version pinning. These gaps must be closed before the other stories deliver meaningful trust.

**Independent Test**: Can be fully tested by inspecting all build definitions for script-piped install patterns, verifying every tool and package is pinned to a specific version, and confirming integrity checks (checksums or signatures) are present for all binary downloads.

**Acceptance Scenarios**:

1. **Given** the container build definition, **When** a reviewer audits all software installation steps, **Then** zero script-piped installation patterns (e.g., piping a remote script to a shell interpreter) exist.
2. **Given** a tool binary downloaded during the build, **When** the download completes, **Then** a checksum or cryptographic signature verification step runs before the binary is installed, and the build fails if verification fails.
3. **Given** any package manager install step, **When** the build runs, **Then** every standalone tool and language runtime is pinned to a specific version with integrity verification. Operating system packages installed via `apt` are excluded from individual version pinning; their reproducibility is ensured by the pinned base image digest, and their exact versions are recorded in the generated SBOM.
4. **Given** the tool version pins in the build definition, **When** compared against latest stable releases, **Then** all tool versions are within one minor release of the latest stable version at the time of this feature's completion.

---

### User Story 2 - Software inventory for published images (Priority: P2)

As an image consumer, I need a machine-readable software inventory (SBOM) generated for every published image so that I can audit exactly what software is included, respond to vulnerability disclosures quickly, and meet compliance requirements.

**Why this priority**: Software transparency is the most commonly requested supply-chain artifact by enterprise consumers and is increasingly a regulatory expectation. It also enables automated vulnerability matching — a consumer can check an SBOM against a CVE database without pulling and scanning the full image.

**Independent Test**: Can be fully tested by triggering a build, verifying an SBOM artifact is produced for each published image variant, and confirming the SBOM can be parsed by a standard SBOM consumer tool to list all included packages and their versions.

**Acceptance Scenarios**:

1. **Given** a successful image build in the CI pipeline, **When** the build completes, **Then** an SBOM in an industry-standard machine-readable format is generated for each published image variant.
2. **Given** an SBOM produced by the build, **When** a consumer retrieves the SBOM, **Then** it lists all operating system packages, programming language runtimes, package manager dependencies, and standalone tool binaries included in the image with their exact versions.
3. **Given** a published multi-architecture image, **When** SBOMs are generated, **Then** separate SBOMs are produced for each architecture variant, reflecting the actual contents of each variant.
4. **Given** an SBOM attached to a published image, **When** a consumer wants to verify it, **Then** the SBOM is retrievable from the same registry as the image without requiring separate access or credentials.

---

### User Story 3 - Cryptographic image signing (Priority: P3)

As an image consumer, I need every published image to be cryptographically signed by the project's official build pipeline so that I can verify the image I pull was produced by a trusted build and has not been modified after publication.

**Why this priority**: Image signing is the capstone supply-chain guarantee — it binds the verified build process (US1) and software inventory (US2) to a specific published artifact. Without signing, a consumer cannot distinguish between an image produced by the project's CI and one injected by a compromised registry or man-in-the-middle. Signing depends on a clean build (US1) to be meaningful.

**Independent Test**: Can be fully tested by pulling a published image, running a signature verification command, and confirming the signature traces back to the project's build pipeline identity.

**Acceptance Scenarios**:

1. **Given** a successful image publication in the CI pipeline, **When** the image is pushed to the registry, **Then** a cryptographic signature is attached to the published image.
2. **Given** a signed published image, **When** a consumer runs a signature verification, **Then** the verification succeeds and identifies the project's official build pipeline as the signer.
3. **Given** a multi-architecture manifest, **When** images are signed, **Then** both individual architecture digests and the multi-architecture manifest are signed.
4. **Given** a published image with both a signature and SBOM, **When** a consumer inspects the image in the registry, **Then** both the signature and SBOM are discoverable through the registry's standard artifact APIs alongside the image.

---

### Edge Cases

- A tool's upstream release does not provide official checksums or signatures: the build process must compute and commit a locally-verified checksum, and the verification source must be documented.
- A checksum verification fails during build: the build must fail immediately with a clear error message identifying which artifact failed verification, and must not fall back to an unverified install.
- An SBOM cannot be generated for a specific image variant (e.g., build failure on one architecture): the CI pipeline must report a blocking failure for that variant and must not publish a partial set of SBOMs.
- The signing identity or credentials are unavailable during CI (e.g., secrets not configured for fork PRs): the build must still succeed for testing purposes but must not publish unsigned images to the production registry. The signing step may be skipped for non-publishable builds (PRs, forks).
- A base image digest changes between the time it is pinned and the time the build runs: the digest validation step must fail the build rather than silently using a different base image.
- SBOM generation adds significant build time: the SBOM generation must not increase overall build time by more than 3 minutes per architecture variant.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST eliminate all script-piped installation patterns from the container build definition, replacing them with verifiable installation methods.
- **FR-002**: The system MUST pin every standalone tool, language runtime, and package manager binary in the build to a specific version with integrity verification. Operating system packages installed via `apt` are excluded from individual version pinning — their reproducibility is ensured by the pinned base image digest (see research.md Decision 2), and their exact versions are recorded in the SBOM (FR-005).
- **FR-003**: The system MUST verify the integrity of every binary artifact downloaded during the build via checksum or cryptographic signature verification, failing the build on mismatch.
- **FR-004**: The system MUST update all pinned tool versions to the latest stable release available at the time of implementation (within one minor version).
- **FR-005**: The system MUST generate a machine-readable SBOM in an industry-standard format for each published image variant after a successful build.
- **FR-006**: The system MUST include in the SBOM all operating system packages, language runtime versions, package manager dependencies, and standalone tool binaries present in the image.
- **FR-007**: The system MUST produce architecture-specific SBOMs for each variant in a multi-architecture build.
- **FR-008**: The system MUST attach SBOMs to the published image in the container registry so they are retrievable alongside the image.
- **FR-009**: The system MUST cryptographically sign every published image using the build pipeline's identity.
- **FR-010**: The system MUST sign both individual architecture digests and the multi-architecture manifest.
- **FR-011**: The system MUST allow consumers to verify image signatures using a publicly documented verification method.
- **FR-012**: The system MUST skip signing for non-publishable builds (pull requests, fork builds) without failing the build.
- **FR-013**: The system MUST maintain a centralized record of all pinned versions and their checksums to simplify future updates.
- **FR-014**: The system MUST document the image verification workflow (signature check + SBOM retrieval) for downstream consumers.

### Assumptions

- The existing CI pipeline already builds multi-architecture images (amd64/arm64) and publishes to a container registry — this feature extends but does not replace that pipeline.
- The CI platform supports workload identity or OIDC-based signing (no long-lived signing keys need to be managed).
- The container registry supports OCI artifact storage for attaching SBOMs and signatures alongside images.
- Base images (Debian, Python) are already pinned to digest — this feature focuses on tools and packages installed on top of them.
- The project publishes a single image type (the base development container); multiple image variants are defined by architecture, not by purpose.
- Checksums for tool binaries are sourced from official upstream releases when available, and locally verified and committed when not.

### Key Entities

- **Pinned Dependency**: A software component installed in the image with a specific version and integrity verification artifact (checksum or signature).
- **Software Bill of Materials (SBOM)**: A machine-readable inventory of all software components in a published image, including name, version, and supplier for each component.
- **Image Signature**: A cryptographic attestation binding a published image digest to the build pipeline identity that produced it.
- **Verification Record**: A documented procedure and set of artifacts enabling a consumer to independently verify an image's signature and inspect its SBOM.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of software installation steps in the build definition use verifiable methods — zero script-piped patterns remain.
- **SC-002**: 100% of packages and tools installed during the build are pinned to a specific version with integrity verification.
- **SC-003**: 100% of published image variants have an SBOM attached in the container registry.
- **SC-004**: The SBOM for each variant lists at least 95% of the installed packages and tools when cross-checked against a manual inventory of the image contents.
- **SC-005**: 100% of published images are cryptographically signed by the build pipeline.
- **SC-006**: A consumer can verify an image signature and retrieve the SBOM using documented steps in under 5 minutes with no missing information.
- **SC-007**: SBOM generation adds no more than 3 minutes to the build time per architecture variant.
- **SC-008**: All pinned tool versions are within one minor release of the latest stable version at feature completion.
