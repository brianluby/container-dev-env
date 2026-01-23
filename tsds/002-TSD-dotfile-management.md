# Technical Specification Document: 002-dotfile-management

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/002-dotfile-management/` and `prds/002-prd-dotfile-management.md`

## 1. Executive Summary

This document outlines the technical review of the Dotfile Management feature (PRD 002). The selection of `chezmoi` as the management tool is technically sound due to its native template support, single-binary architecture, and XDG compliance. The integration of `age` for encryption is a forward-looking decision that enables secure dotfile management. The implementation plan is robust, but there are opportunities to optimize the bootstrap user experience and testing strategy.

## 2. Content Accuracy & Discrepancy Analysis

### 2.1 Spec vs. Implementation Divergence
**Observation**: The `spec.md` lists `FR-001` as installing `chezmoi` in the container base image.
- **Status**: Completed in `001-container-base-image` Dockerfile.
- **Issue**: The implementation of `002-dotfile-management` is primarily about *using* the tool, but the project structure suggests `Dockerfile` modifications in this phase.
- **Correction**: Clarify that the implementation phase for PRD 002 should focus on *verifying* the tool's presence (since it was added in 001) and documenting the *usage workflow*, rather than re-implementing the installation.

### 2.2 Version Pinning Strategy
**Observation**: `research.md` and `contracts/build-contract.md` specify pinning `chezmoi` to `v2.47.1` and `age` to `v1.1.1`.
- **Validation**: These versions match what was implemented in the `001` Dockerfile.
- **Risk**: If the `001` Dockerfile is updated with newer versions, the `002` contract docs will become stale.
- **Recommendation**: Reference the `Dockerfile` ARGs as the source of truth rather than hardcoding version numbers in documentation, or explicitly link the update process.

## 3. Optimization Opportunities

### 3.1 Bootstrap Efficiency
**Observation**: User Story 1 describes bootstrapping via `chezmoi init --apply <repo>`.
- **Optimization**: To handle the "offline" requirement (User Story 6) more robustly, the documentation should suggest a volume mount strategy for the `~/.local/share/chezmoi` directory. This ensures that even if the container is destroyed, the source state remains on the host (or named volume), reducing the need for network calls on subsequent recreations.
- **Action**: Add a recommendation in `quickstart.md` for mounting a persistent volume for Chezmoi source data.

### 3.2 Automated Testing
**Observation**: The `test-contract.md` includes extensive functional tests.
- **Gap**: `FUNC-001` tests with a public repo (`twpayne/dotfiles`), which requires external network access and relies on a third-party repo.
- **Improvement**: Create a minimal, self-contained "test dotfiles" repo fixture within the project (e.g., in `tests/fixtures/dotfiles`). Use this local fixture for testing `chezmoi init` to ensure tests are deterministic and work without external internet dependencies (except for initial container build).

## 4. Architectural Consistency

### 4.1 Dependency Management
**Status**: **Optimal**.
- Integrating `chezmoi` directly into the base image rather than installing it at runtime (e.g., via `postCreateCommand`) is the correct architectural choice. It ensures the tool is available immediately and immutably, adhering to the "Container-First" principle.

### 4.2 Security
**Status**: **High**.
- The inclusion of `age` enables secure secret management within dotfiles.
- **Warning**: The specification mentions `FR-010` (Encrypted files). Documentation must clearly warn users *not* to commit their private `age` keys to their public dotfile repositories. A specific "Security Best Practices" section in the user guide is required.

## 5. Specific Recommendations for Improvement

### 5.1 Documentation Updates
**Target**: `specs/002-dotfile-management/quickstart.md`
- **Add**: Section on "Persistent Dotfiles" describing how to use Docker volumes to persist `~/.local/share/chezmoi` so re-downloading isn't necessary.
- **Add**: "Security Warning" about `age` key management.

### 5.2 Test Suite Updates
**Target**: `scripts/test-container.sh` (or `test-contract.md`)
- **Modify**: `FUNC-001` to use a local directory or controlled test repo instead of a random public GitHub repo to prevent flaky tests.
  ```bash
  # Example concept
  mkdir -p /tmp/test-dotfiles
  git init /tmp/test-dotfiles
  # ... populate with dummy config ...
  docker run -v /tmp/test-dotfiles:/dotfiles ... chezmoi init --apply file:///dotfiles
  ```

## 6. Conclusion

The `002-dotfile-management` feature is well-designed. The primary technical recommendation is to decouple the test suite from external dependencies to improve reliability and speed. The integration with PRD 001 is seamless as the binary installation was proactively handled.
