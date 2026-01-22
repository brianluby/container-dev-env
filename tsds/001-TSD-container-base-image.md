# Technical Specification Document: 001-container-base-image

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/001-container-base-image/` and `prds/001-prd-container-base.md`

## 1. Executive Summary

This document outlines the technical review of the Container Base Image feature (PRD 001). The implementation strategy using a single Dockerfile with multi-stage builds for Python and Node.js is sound and adheres to the "Container-First" constitution principle. The inclusion of `chezmoi` and `age` tools, while not explicitly detailed in the PRD's "Must Have" requirements, strategically positions the base image for upcoming features (002 and 003).

## 2. Content Accuracy & Discrepancy Analysis

### 2.1 Spec vs. Implementation Divergence
**Observation**: The `Dockerfile` includes installation steps for `chezmoi` and `age`.
- `chezmoi` is the selected tool for PRD 002.
- `age` is the selected tool for PRD 003.
- **Issue**: These are not listed in `specs/001-container-base-image/spec.md` under "Functional Requirements" or "Installed Tools", creating a drift between documentation and code.
- **Recommendation**: Update `spec.md` to include these as "Enablement Tools" or "Future-proofing Requirements" to reflect the actual image state.

### 2.2 Versioning Assumptions
**Observation**: The reliance on `python:3.14-slim-bookworm` assumes this specific tag will be available and stable in early 2026.
- **Risk**: If Python 3.14 release logic or Docker image naming conventions change, the build will break.
- **Mitigation**: Add a fallback plan in `research.md` to use the latest stable (e.g., 3.13) if 3.14 is unavailable or unstable.

## 3. Optimization Opportunities

### 3.1 Package Management Efficiency
**Observation**: `uv` is installed via `pip install uv`.
- **Improvement**: `uv` is significantly faster than `pip`. Future layers or user instructions should explicitly recommend using `uv pip install` instead of standard `pip install` to leverage this speed.
- **Action**: Add a note in `quickstart.md` and `README.md` promoting `uv` usage.

### 3.2 Test Coverage Expansion
**Observation**: The `test-contract.md` and `test-container.sh` cover core tools (git, curl, python, node).
- **Gap**: Since `chezmoi` and `age` are baked in, they are currently untested in the acceptance suite.
- **Recommendation**: Add version checks for `chezmoi` and `age` to `test-contract.md` and `test-container.sh` to ensure these critical downstream tools are functional.

## 4. Architectural Consistency

### 4.1 Layer Ordering
**Status**: **Optimal**.
- The `Dockerfile` correctly places volatile layers (COPY of scripts, user config) after heavy, static layers (apt install, runtime setup). This maximizes build cache efficiency.

### 4.2 Security
**Status**: **High**.
- Non-root user `dev` is correctly configured.
- `sudo` access is passwordless, which is standard for dev containers but warrants a specific "Security Note" in documentation regarding the trade-off between convenience and strict isolation.

## 5. Specific Recommendations for Improvement

### 5.1 Documentation Updates
**Target**: `specs/001-container-base-image/spec.md`
- **Add FR-015**: "Container SHOULD include `chezmoi` and `age` to support downstream dotfile and secret management features."
- **Update Data Model**: Add `chezmoi` and `age` to the `InstalledTools` entity.

### 5.2 Test Suite Updates
**Target**: `scripts/test-container.sh`
- **Add**:
  ```bash
  echo "=== Future-Proofing Tools Tests ==="
  docker run --rm $IMAGE chezmoi --version
  docker run --rm $IMAGE age --version
  ```

### 5.3 Quickstart Enhancement
**Target**: `specs/001-container-base-image/quickstart.md`
- **Add**: A "Performance Tip" section highlighting `uv` for Python dependency management.

## 6. Conclusion

The `001-container-base-image` is technically solid. The primary required actions are documentation synchronization (listing `chezmoi`/`age`) and expanding the test contract to cover these included tools. No structural code changes are required for the `Dockerfile`.
