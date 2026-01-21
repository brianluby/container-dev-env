# Test Contract: Dotfile Management with Chezmoi

**Feature**: 002-dotfile-management
**Date**: 2026-01-20

## Overview

This contract defines the acceptance tests for validating Chezmoi integration in the container image.

## Test Categories

### 1. Installation Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| INST-001 | Chezmoi binary exists | `docker run --rm IMG which chezmoi` | `/usr/local/bin/chezmoi` |
| INST-002 | Chezmoi is executable | `docker run --rm IMG chezmoi --version` | Version string |
| INST-003 | age binary exists | `docker run --rm IMG which age` | `/usr/local/bin/age` |
| INST-004 | age is executable | `docker run --rm IMG age --version` | `v1.1.1` |
| INST-005 | age-keygen exists | `docker run --rm IMG which age-keygen` | `/usr/local/bin/age-keygen` |
| INST-006 | age-keygen is executable | `docker run --rm IMG age-keygen --version` | `v1.1.1` |

### 2. Functional Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| FUNC-001 | Init from public repo | `docker run --rm IMG chezmoi init --apply https://github.com/twpayne/dotfiles.git` | Exit 0, files created |
| FUNC-002 | Check status | `docker run --rm IMG bash -c "chezmoi init https://github.com/twpayne/dotfiles.git && chezmoi status"` | Exit 0, status output |
| FUNC-003 | Diff works | `docker run --rm IMG bash -c "chezmoi init https://github.com/twpayne/dotfiles.git && chezmoi diff"` | Exit 0, diff output |
| FUNC-004 | Doctor check | `docker run --rm IMG chezmoi doctor` | Exit 0, all OK |

### 3. Template Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| TMPL-001 | Hostname variable | `docker run --rm IMG chezmoi execute-template "{{ .chezmoi.hostname }}"` | Container hostname |
| TMPL-002 | OS variable | `docker run --rm IMG chezmoi execute-template "{{ .chezmoi.os }}"` | `linux` |
| TMPL-003 | Arch variable | `docker run --rm IMG chezmoi execute-template "{{ .chezmoi.arch }}"` | `amd64` or `arm64` |
| TMPL-004 | Username variable | `docker run --rm IMG chezmoi execute-template "{{ .chezmoi.username }}"` | `dev` |
| TMPL-005 | Home dir variable | `docker run --rm IMG chezmoi execute-template "{{ .chezmoi.homeDir }}"` | `/home/dev` |

### 4. Encryption Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| ENC-001 | Generate age key | `docker run --rm IMG age-keygen` | Public/private key pair |
| ENC-002 | Encrypt with age | `docker run --rm IMG bash -c "echo 'secret' \| age -r age1..."` | Encrypted output |
| ENC-003 | Decrypt with age | Encrypt then decrypt | Original text |

### 5. Permission Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| PERM-001 | Non-root can run chezmoi | `docker run --rm IMG chezmoi --version` | Success (default user) |
| PERM-002 | Source dir writable | `docker run --rm IMG touch ~/.local/share/chezmoi/test` | Exit 0 |
| PERM-003 | Config dir writable | `docker run --rm IMG mkdir -p ~/.config/chezmoi && touch ~/.config/chezmoi/test.toml` | Exit 0 |

### 6. Offline Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| OFF-001 | Apply works offline | Init, disconnect, apply | Exit 0 |
| OFF-002 | Diff works offline | Init, disconnect, diff | Exit 0 |
| OFF-003 | Status works offline | Init, disconnect, status | Exit 0 |

### 7. Size Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| SIZE-001 | Image size increase | Compare before/after | <50MB delta |
| SIZE-002 | Chezmoi binary size | `docker run --rm IMG ls -lh /usr/local/bin/chezmoi` | <20MB |
| SIZE-003 | age binary size | `docker run --rm IMG ls -lh /usr/local/bin/age` | <10MB |

### 8. Architecture Tests

| Test ID | Description | Command | Expected |
|---------|-------------|---------|----------|
| ARCH-001 | amd64 chezmoi works | `docker run --platform linux/amd64 --rm IMG chezmoi --version` | Version string |
| ARCH-002 | arm64 chezmoi works | `docker run --platform linux/arm64 --rm IMG chezmoi --version` | Version string |
| ARCH-003 | amd64 age works | `docker run --platform linux/amd64 --rm IMG age --version` | `v1.1.1` |
| ARCH-004 | arm64 age works | `docker run --platform linux/arm64 --rm IMG age --version` | `v1.1.1` |

## Test Script Additions

Add to `scripts/test-container.sh`:

```bash
log_section "Chezmoi Tests"

# INST-001, INST-002: Chezmoi available
if docker run --rm $IMAGE chezmoi --version | grep -q "chezmoi"; then
    log_pass "INST-001/002: Chezmoi is installed and executable"
else
    log_fail "INST-001/002: Chezmoi not available"
fi

# INST-003, INST-004: age available
if docker run --rm $IMAGE age --version | grep -q "v1"; then
    log_pass "INST-003/004: age is installed and executable"
else
    log_fail "INST-003/004: age not available"
fi

# INST-005, INST-006: age-keygen available
if docker run --rm $IMAGE age-keygen --version | grep -q "v1"; then
    log_pass "INST-005/006: age-keygen is installed and executable"
else
    log_fail "INST-005/006: age-keygen not available"
fi

# FUNC-004: Doctor check
if docker run --rm $IMAGE chezmoi doctor | grep -q "ok"; then
    log_pass "FUNC-004: chezmoi doctor passes"
else
    log_fail "FUNC-004: chezmoi doctor reports issues"
fi

# TMPL-002: OS template variable
if docker run --rm $IMAGE chezmoi execute-template '{{ .chezmoi.os }}' | grep -q "linux"; then
    log_pass "TMPL-002: Template variables work"
else
    log_fail "TMPL-002: Template variables not working"
fi

# PERM-001: Non-root can run
if [ "$(docker run --rm $IMAGE whoami)" = "dev" ] && docker run --rm $IMAGE chezmoi --version > /dev/null; then
    log_pass "PERM-001: Non-root user can run chezmoi"
else
    log_fail "PERM-001: Permission issues with chezmoi"
fi
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | Test assertion failed |
| 2 | Container not found |
| 3 | Build failed |
| 4 | Chezmoi not installed |
| 5 | age not installed |

## CI Integration

```yaml
# Add to test job in .github/workflows/container-build.yml
- name: Run Chezmoi tests
  run: |
    docker run --rm devcontainer:test chezmoi --version
    docker run --rm devcontainer:test chezmoi doctor
    docker run --rm devcontainer:test age --version
    docker run --rm devcontainer:test chezmoi execute-template '{{ .chezmoi.os }}'
```
