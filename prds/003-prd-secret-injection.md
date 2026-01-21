# 003-prd-secret-injection

## Problem Statement

Development containers need access to secrets (API keys, tokens, credentials) to
interact with external services during development. Currently, developers either
bake secrets into images (security risk), manually copy them into containers
(tedious and error-prone), or use insecure environment variable passing (visible
in process lists). A secure secret injection pattern is needed that keeps secrets
out of images and version control while making them conveniently available to
development workflows without compromising security.

## Requirements

### Must Have (M)

- [ ] Secrets never baked into container images
- [ ] Secrets never committed to version control
- [ ] Secrets available to applications at runtime (env vars or files)
- [ ] Works with the container base image (001-prd-container-base)
- [ ] Works with containerized development workflows (docker run, compose)
- [ ] Secrets not visible in `docker inspect` or `docker history`
- [ ] Clear documentation on how to add/update/rotate secrets

### Should Have (S)

- [ ] Integration with dotfile management (002-prd-dotfile-management)
- [ ] Support for multiple secret sources (local files, encrypted files, vaults)
- [ ] Easy bootstrap: simple setup for new developers
- [ ] Secrets accessible without modifying application code
- [ ] Support for secret rotation without container restart
- [ ] Works in CI/CD pipelines with appropriate secret backends

### Could Have (C)

- [ ] Integration with cloud secret managers (AWS Secrets Manager, GCP Secret Manager)
- [ ] Integration with password managers (1Password CLI, Bitwarden CLI)
- [ ] Automatic secret expiry/refresh
- [ ] Audit logging of secret access
- [ ] Multi-environment profiles (dev, staging, prod credentials)
- [ ] Secret templating (generate config files from secrets)

### Won't Have (W)

- [ ] Production secret management (different security requirements)
- [ ] Hardware security module (HSM) integration
- [ ] Kubernetes secrets integration (out of scope for local dev)
- [ ] Secret generation/creation (users bring their own secrets)
- [ ] Compliance certification (SOC2, HIPAA) for this solution

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| Security model | Must | Secrets protected at rest and in transit |
| Container-friendly | Must | Works with docker run, compose, devcontainers |
| Developer experience | High | Easy to set up and use daily |
| No image modification | High | Works with existing container image |
| Offline capability | High | Works without network after initial setup |
| Minimal dependencies | Medium | Fewer tools = smaller attack surface |
| Chezmoi integration | Medium | Leverage existing dotfile tooling |
| Cross-platform | Medium | Works on macOS, Linux hosts |
| MIT-compatible license | Must | Open source project compatibility |

## Tool Candidates

| Tool | License | Pros | Cons | Spike Result |
|------|---------|------|------|--------------|
| Docker secrets | Apache-2.0 | Native Docker support, swarm-ready, files in /run/secrets | Requires swarm mode for full features, compose support limited | Evaluate |
| SOPS (Mozilla) | MPL-2.0 | Encrypts files in-place, git-friendly, multiple KMS backends | Requires KMS setup for team use, learning curve | Evaluate |
| age-encrypted dotfiles | BSD-3 | Already have age in image, simple model, Chezmoi integration | Manual key management, no automatic rotation | Evaluate |
| HashiCorp Vault | BUSL-1.1 | Industry standard, full featured, audit logging | Heavy infrastructure, overkill for local dev, license concerns | Evaluate |
| 1Password CLI | Proprietary | Popular password manager, secret references in env | Requires 1Password subscription, proprietary | Evaluate |
| direnv + .envrc | MIT | Simple, automatic env loading, widely used | Secrets in plaintext files (needs encryption layer) | Evaluate |
| Docker --env-file | N/A | No extra tools, simple | Secrets in plaintext file, visible in inspect | Evaluate |

## Selected Approach

[Filled after spike - likely age-encrypted dotfiles with Chezmoi or SOPS]

## Acceptance Criteria

- [ ] Given a fresh container, when I follow the setup guide, then I can inject my first secret within 5 minutes
- [ ] Given secrets configured, when I start the container, then secrets are available as environment variables
- [ ] Given the container image, when I run `docker history`, then no secrets are visible in layers
- [ ] Given a secrets file, when I commit to git, then only encrypted content is stored
- [ ] Given a new team member, when they clone the repo, then they can configure their own secrets without seeing others' secrets
- [ ] Given an API key rotation, when I update the secret, then the container picks up the new value on next start
- [ ] Given no network access, when I start a container with previously configured secrets, then secrets are still available
- [ ] Given the container image with dotfile support, when I add secret injection, then image size increases by less than 10MB
- [ ] Given a running container, when I inspect it, then secrets are not visible in environment or labels

## Dependencies

- Requires: 001-prd-container-base (completed)
- Requires: 002-prd-dotfile-management (in progress - for Chezmoi/age integration)
- Blocks: 004-prd-git-credential-helper (git credentials are a form of secrets)
- Blocks: 006-prd-cloud-cli-tools (cloud CLIs need credentials)

## Spike Tasks

- [ ] Test Docker secrets: setup with compose, access from container, evaluate swarm requirement
- [ ] Test SOPS: encrypt file with age key, decrypt at runtime, evaluate workflow
- [ ] Test age-encrypted Chezmoi: configure encrypted templates, test key management
- [ ] Test Vault dev mode: local server, inject secrets, evaluate complexity
- [ ] Test 1Password CLI: configure secret references, test op run workflow
- [ ] Test direnv + age: encrypt .envrc, decrypt on cd, evaluate UX
- [ ] Compare security models (threat modeling for each approach)
- [ ] Compare setup complexity for solo developer vs team
- [ ] Test CI/CD compatibility (GitHub Actions, GitLab CI)
- [ ] Measure performance overhead for each approach
- [ ] Document key management strategies for each option
- [ ] Evaluate secret rotation workflows for each approach
