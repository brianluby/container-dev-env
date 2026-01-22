# Technical Specification Document: 004-volume-architecture

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/004-volume-architecture/` and `prds/004-prd-volume-architecture.md`

## 1. Executive Summary

This document outlines the technical review of the Volume Architecture feature (PRD 004). The hybrid approach (bind mount for source, named volumes for data/cache, tmpfs for temp) is the industry standard for optimizing Docker performance on macOS while maintaining developer usability. The entrypoint-based permission fix strategy is pragmatic and avoids the complexity of external tools like `fixuid`, though it requires careful implementation to be robust across different `stat` command versions (GNU vs BSD).

## 2. Content Accuracy & Discrepancy Analysis

### 2.1 Spec vs. Implementation Divergence
**Observation**: The `entrypoint.contract.sh` specifies logging format and exact behavior.
- **Validation**: The `docker/entrypoint.sh` (read in turn 2) largely implements this logic.
- **Discrepancy**: The contract specifies handling both `stat -c` (Linux) and `stat -f` (BSD/macOS). The implementation in `docker/entrypoint.sh` correctly includes `case "$(uname -s)"` logic to handle this.
- **Risk**: The contract requires "Permission fixes MUST be targeted (not recursive scan)". The implementation uses `chown -R` (recursive) on specific directories.
- **Clarification**: "Targeted" means "only specific top-level directories", not "non-recursive". `chown -R` on `node_modules` is necessary but potentially slow if the volume is huge. The "under 3 seconds" constraint might be violated for very large existing volumes.
- **Mitigation**: Add a check to only `chown -R` if the *top-level* directory ownership is wrong, assuming internal consistency. This optimization is partially present ("if owned by root... fix") but could be explicit about trusting internal state after the root check.

### 2.2 Host UID Detection
**Observation**: The design relies on `LOCAL_UID` environment variable.
- **Issue**: Docker doesn't automatically pass the host user's UID to `LOCAL_UID`. The user must manually set this in `.env` or `docker-compose.yml`.
- **Gap**: `quickstart.md` (read earlier) or documentation must explicitly tell users how to set this. Typically `LOCAL_UID=$(id -u) docker-compose up` or a `.env` file generation step is needed.
- **Action**: Ensure user documentation emphasizes this step, otherwise users on Linux (UID != 1000) or macOS (UID 501) will default to 1000, causing permission issues if 1000 isn't the correct mapping.

## 3. Optimization Opportunities

### 3.1 Performance
**Observation**: `npm install` speed is a key KPI (10-19x improvement).
- **Optimization**: The `docker-compose.volumes.yml` correctly puts `node_modules` in a named volume.
- **Trade-off**: This hides `node_modules` from the host. This breaks IDE features that rely on indexing dependencies (e.g., "Go to Definition" inside a library).
- **Workaround**: Some IDEs (VS Code Remote Containers) run *inside* the container, so they see the named volume. For host-based IDEs, this is a known trade-off.
- **Recommendation**: Explicitly document this trade-off. For users *requiring* host indexing, suggest an alternative configuration (bind mount) with the performance warning.

### 3.2 Volume Pruning Safety
**Observation**: The contract uses labels like `com.devenv.safe-to-prune: "false"` for `home-data`.
- **Implementation**: Docker itself doesn't respect these labels during `docker system prune` automatically; they are metadata for humans or custom scripts.
- **Risk**: Users might expect `docker volume prune` to magically skip these.
- **Clarification**: Update documentation to clarify that standard Docker commands ignore these labels, and "Safe Pruning" relies on the user *not* running `docker volume prune -a` blindly, or using a wrapper script that respects these labels.

## 4. Architectural Consistency

### 4.1 Entrypoint Integration
**Status**: **Robust**.
- The `entrypoint.sh` handles signal forwarding (`trap`), which is critical for graceful shutdowns of databases or servers running in dev mode.
- The use of `exec "$@"` ensures the shell doesn't stick around as PID 1.

### 4.2 Cross-Platform Compatibility
**Status**: **Verified**.
- The `entrypoint.sh` script specifically checks `uname -s` to toggle between Linux and macOS `stat` commands. This is crucial because standard `debian:bookworm` container is Linux, but if the script were ever run on a Mac host (e.g. for testing), it would need adaptation.
- **Correction**: Wait, the entrypoint runs *inside* the container. The container is *always* Linux (Debian). The host OS doesn't matter for the *script's* execution environment, only for the *values* (UIDs) passed in.
- **Redundant Logic**: The `case "$(uname -s)" in Darwin)` block inside the container's `entrypoint.sh` is technically dead code if the container base is always Debian Linux.
- **Correction**: Unless the user mounts the script and runs it on their Mac host for testing. The script *is* portable, which is good practice, but technically unnecessary for production container execution.

## 5. Specific Recommendations for Improvement

### 5.1 Code Cleanups
**Target**: `docker/entrypoint.sh`
- **Refactor**: Remove the `Darwin` check *if* the script is guaranteed to run only in the Debian container. It adds confusion. *However*, keeping it allows local unit testing on macOS without Docker, so it's acceptable if commented as "for local testing".

### 5.2 Documentation Updates
**Target**: `docs/volume-architecture.md` (to be created/updated)
- **Add**: "IDE compatibility" section explaining that `node_modules` in named volumes requires the IDE to connect remotely (VS Code) or accepts missing definitions (Host IDE).
- **Add**: "Pruning Safety" warning explaining that labels are informational.

### 5.3 Test Coverage
**Target**: `tests/integration/test-permissions.sh`
- **Add**: Test case simulating a "corrupt" volume (wrong owner root:root) and asserting it gets fixed on startup.
- **Add**: Test case with a massive number of files to benchmark startup delay.

## 6. Conclusion

The `004-volume-architecture` is highly effective for solving the specific problem of "Docker on macOS I/O performance". The named volume strategy is the correct technical choice. The dynamic UID fixes in the entrypoint are the standard solution for this architectural constraint. The primary risk is user confusion regarding `node_modules` visibility on the host, which must be managed through documentation.
