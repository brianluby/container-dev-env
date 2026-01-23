# Technical Specification Document: 003-secret-injection

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/003-secret-injection/` and `prds/003-prd-secret-injection.md`

## 1. Executive Summary

This document outlines the technical review of the Secret Injection feature (PRD 003). The design leverages `chezmoi`'s native encryption capabilities with `age`, which is a secure, modern, and standard-compliant approach. The separation of concerns between setup (`secrets-setup.sh`), editing (`secrets-edit.sh`), and runtime loading (`secrets-load.sh`) promotes maintainability and usability. The "Fail Fast" requirement for malformed secrets is critical for developer experience and is correctly emphasized.

## 2. Content Accuracy & Discrepancy Analysis

### 2.1 Contract vs. Implementation Alignment
**Observation**: The `secrets-load.sh` contract specifies that it should be sourced by the entrypoint.
- **Verification**: The entrypoint logic in `specs/003-secret-injection/research.md` confirms this integration.
- **Gap**: The `secrets-load.sh` contract mentions a `--check` flag for standalone validation, but the usage description implies it's primarily for sourcing.
- **Clarification**: Ensure the script handles both `source` (no arguments) and `execution` (with arguments) modes correctly. A typical `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]` block is needed to distinguish execution from sourcing.

### 2.2 Security Model Nuances
**Observation**: The `secrets-edit.sh` `add` command takes the secret value as a command-line argument.
- **Risk**: As noted in the contract, this exposes secrets to shell history (`.bash_history`).
- **Mitigation**: The contract notes this risk, but the tool should actively mitigate it.
- **Recommendation**: Implement a `read -s` prompt flow for the `add` command if the value is not provided as an argument, allowing users to paste secrets without them appearing in history.

## 3. Optimization Opportunities

### 3.1 Performance
**Observation**: `secrets-load.sh` validates the format of every line in `~/.secrets.env` at runtime.
- **Impact**: For large secret files, this regex validation in bash might be slow.
- **Optimization**: Since `secrets-edit.sh` already validates on save, the runtime check can be lighter (e.g., just checking for basic `KEY=` structure) or skipped if the file checksum matches a trusted state. However, given the scale (10-50 secrets), the current approach is acceptable for safety.

### 3.2 Developer Experience (DX)
**Observation**: The `secrets-edit.sh` tool wraps `chezmoi edit`.
- **Improvement**: Users might forget to run `chezmoi apply` after editing if they use raw `chezmoi` commands. `secrets-edit.sh` handles re-encryption but the contract says "Restart container to apply changes".
- **Refinement**: Explicitly state in the output of `secrets-edit.sh` whether an `apply` is needed or if the file is updated in place. (Note: `chezmoi edit` updates the *source* state; `chezmoi apply` updates the *target* state. Runtime loading reads the *target* file `~/.secrets.env`. So `apply` is strictly required before restart).
- **Action**: Ensure `secrets-edit.sh` runs `chezmoi apply` automatically after a successful edit to ensure the target file is ready for the next container restart.

## 4. Architectural Consistency

### 4.1 Integration with Dotfile Management
**Status**: **Optimal**.
- The feature correctly builds upon PRD 002 by using the existing `chezmoi` installation.
- The use of `private_` prefix in `chezmoi` templates (`private_dot_secrets.env.age`) is the correct convention for keeping files out of `chezmoi diff`'s default output and treating them as sensitive.

### 4.2 Runtime Injection
**Status**: **Secure**.
- Loading secrets into the entrypoint process's environment is the standard container pattern.
- **Verification**: Ensure the `entrypoint.sh` sources the secrets *before* executing the main command (`exec "$@"`), which `research.md` confirms.

## 5. Specific Recommendations for Improvement

### 5.1 CLI Enhancements
**Target**: `scripts/secrets-edit.sh`
- **Modify**: The `add` command to support secure input:
  ```bash
  if [ -z "$VALUE" ]; then
    read -rs -p "Enter value for $KEY: " VALUE
    echo
  fi
  ```
- **Modify**: Automatically run `chezmoi apply` after any modification (`edit`, `add`, `remove`) so the user doesn't have to manually apply before restarting.

### 5.2 Documentation Updates
**Target**: `docs/secrets-guide.md`
- **Add**: "Troubleshooting" section for common errors like "Age key not found" or "Decryption failed".
- **Add**: Explicit warning about shell history when using `secrets-edit.sh add KEY=VALUE`.

### 5.3 Test Coverage
**Target**: `contracts/test-contract.md` (missing in current file list, should be created)
- **Add**: Test case for special characters in secrets (quotes, spaces, symbols) to ensuring `secrets-load.sh` handles them correctly.
- **Add**: Test case for `secrets-edit.sh add` history safety (verifying it doesn't log to stdout).

## 6. Conclusion

The `003-secret-injection` feature is architecturally sound and secure. The use of standard tools (`age`, `chezmoi`) minimizes maintenance burden. The main improvements focus on the "secure by default" usability of the helper scripts (masking input, auto-applying changes).
