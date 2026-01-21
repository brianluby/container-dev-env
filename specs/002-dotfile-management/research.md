# Research: Dotfile Management with Chezmoi

**Feature**: 002-dotfile-management
**Date**: 2026-01-20

## Overview

Research findings for implementing Chezmoi-based dotfile management in the container development environment.

## Decision: Chezmoi Installation Method

**Decision**: Install Chezmoi using the official installation script with version pinning

**Rationale**:
- Official script handles architecture detection (arm64/amd64) automatically
- Single command installation reduces Dockerfile complexity
- Script is well-maintained and widely used
- Supports pinning to specific version for reproducibility

**Alternatives Considered**:
| Alternative | Pros | Cons | Rejected Because |
|------------|------|------|------------------|
| apt package | Package manager native | Outdated version in Debian repos | Version too old, missing features |
| Go build from source | Full control | Requires Go toolchain, slow | Adds ~500MB+ to image, unnecessary complexity |
| Download binary directly | Simple | Must handle arch detection manually | Script does this better |
| Homebrew | Common tool | Requires Homebrew install | Heavy dependency, not container-friendly |

**Implementation**:
```dockerfile
# Install Chezmoi v2.47.1 (latest stable as of 2026-01)
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin -t v2.47.1
```

## Decision: Chezmoi Binary Location

**Decision**: Install to `/usr/local/bin`

**Rationale**:
- Standard location for locally installed binaries
- Already in default PATH
- Consistent with other tools in the base image
- Accessible by non-root user

**Alternatives Considered**:
| Alternative | Pros | Cons | Rejected Because |
|------------|------|------|------------------|
| /home/dev/.local/bin | User-owned | Requires user context during build | Complicates Dockerfile ordering |
| /usr/bin | System standard | Reserved for package manager | May conflict with future apt packages |
| /opt/chezmoi/bin | Isolated | Not in PATH by default | Requires PATH modification |

## Decision: age Encryption Support

**Decision**: Include age binary for encrypted file support (optional feature)

**Rationale**:
- Chezmoi recommends age over gpg for new users
- age is simpler, faster, and more modern than gpg
- Single binary, small footprint (~5MB)
- Enables encrypted dotfiles without requiring user to install separately
- MIT license compatible

**Alternatives Considered**:
| Alternative | Pros | Cons | Rejected Because |
|------------|------|------|------------------|
| gpg only | Already in Debian | Complex key management, heavy | age is simpler and recommended |
| No encryption | Simpler | Users must install age manually | Small cost for significant convenience |
| Both gpg and age | Maximum compatibility | Larger image | gpg already available via gnupg package |

**Implementation**:
```dockerfile
# Install age for Chezmoi encryption support
RUN curl -fsSL https://github.com/FiloSottile/age/releases/download/v1.1.1/age-v1.1.1-linux-$(dpkg --print-architecture).tar.gz | \
    tar -xz -C /usr/local/bin --strip-components=1 age/age age/age-keygen
```

## Decision: Dockerfile Layer Ordering

**Decision**: Install Chezmoi after development tools, before user configuration

**Rationale**:
- Chezmoi depends on git (for init) and curl (for installation)
- Installing before user setup allows testing in build
- Layer ordering maximizes cache reuse

**Layer Order**:
1. Base image + apt packages (existing)
2. Python installation (existing)
3. Node.js installation (existing)
4. **Chezmoi + age installation (new)**
5. User creation and configuration (existing)
6. Health check (existing)

## Best Practices: Chezmoi in Containers

**Findings from official documentation and community**:

1. **Bootstrap Pattern**: Use `chezmoi init --apply` for single-command setup
   - Combines clone + apply in one step
   - Supports GitHub shorthand: `chezmoi init --apply gh-username`

2. **Source Directory**: Default `~/.local/share/chezmoi` is ideal
   - XDG-compliant location
   - Survives container rebuilds if home is mounted

3. **Config File Location**: `~/.config/chezmoi/chezmoi.toml`
   - Machine-specific configuration (email, name, etc.)
   - Can be templated for interactive setup

4. **Template Variables**: Common variables to document
   - `.chezmoi.hostname` - container hostname
   - `.chezmoi.os` - operating system
   - `.chezmoi.arch` - architecture (amd64, arm64)
   - `.email`, `.name` - user-defined in config

5. **Container-Specific Considerations**:
   - Dotfiles source survives if `~/.local/share` is a volume
   - Applied files in `~` may need re-apply after rebuild
   - Use `.chezmoiignore` to exclude container-inappropriate configs

## Best Practices: Version Pinning

**Decision**: Pin Chezmoi to specific version in Dockerfile

**Rationale**:
- Constitution requires version pinning (Principle V)
- Ensures reproducible builds
- Prevents surprise breaking changes

**Version Strategy**:
- Pin to latest stable at implementation time
- Document version in Dockerfile comment
- Update via explicit PR with testing

## Size Impact Analysis

**Estimated size additions**:
| Component | Size | Notes |
|-----------|------|-------|
| Chezmoi binary | ~15MB | Single statically-linked Go binary |
| age binary | ~5MB | Encryption support |
| age-keygen | ~5MB | Key generation tool |
| **Total** | **~25MB** | Well under 50MB constraint |

## Security Considerations

**Findings**:

1. **No Secrets in Image**: Chezmoi source not included in image
   - Users bring their own dotfiles repo
   - No credentials baked in

2. **Encrypted Files**: age provides secure encryption
   - Private keys stored outside image
   - Encrypted files safe in public repos

3. **Network Security**: Bootstrap requires network
   - Uses HTTPS for git operations
   - Official installation script uses HTTPS

4. **Permission Model**: Chezmoi respects file permissions
   - Preserves source permissions on apply
   - Non-root user owns all applied files

## References

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Chezmoi Installation Guide](https://www.chezmoi.io/install/)
- [age Encryption](https://github.com/FiloSottile/age)
- [Chezmoi Container Guide](https://www.chezmoi.io/user-guide/use-chezmoi-on-a-container/)
