# 008-prd-containerized-ide

## Problem Statement

Developers need a full-featured IDE accessible from any device without local installation.
The containerized development environment requires an IDE that runs entirely within Docker,
accessible via web browser or remote protocol. This enables consistent development experiences
across machines, easy onboarding, and the ability to work from tablets or thin clients.

**Critical constraint**: The IDE must run entirely within a Docker container. Acceptable modes:
- Web-based IDE accessible via browser (code-server, OpenVSCode-Server)
- Remote backend with thin client (JetBrains Gateway, VS Code Remote)
- No native desktop applications required on the host machine

## Requirements

### Must Have (M)

- [ ] Runs entirely within Docker container
- [ ] Browser-accessible interface (no host IDE installation required)
- [ ] Full code editing with syntax highlighting and IntelliSense
- [ ] Integrated terminal access
- [ ] File explorer and project navigation
- [ ] Extension/plugin support for language tooling
- [ ] Git integration (diff, commit, branch management)
- [ ] Works on arm64 (Apple Silicon) and amd64
- [ ] Open source or permissive license

### Should Have (S)

- [ ] VS Code extension compatibility (large ecosystem)
- [ ] Multi-user support for team environments
- [ ] Authentication and access control
- [ ] HTTPS/TLS support for secure remote access
- [ ] Persistent workspace configuration
- [ ] Debug adapter protocol support
- [ ] Search across files (grep-like functionality)

### Could Have (C)

- [ ] Live collaboration (pair programming)
- [ ] Custom themes and UI customization
- [ ] Split editor and multi-panel layouts
- [ ] Notebook support (Jupyter)
- [ ] SSH tunneling for secure access
- [ ] GPU passthrough for ML workloads

### Won't Have (W)

- [ ] Native desktop application mode (must be containerized)
- [ ] Proprietary IDEs requiring host installation
- [ ] GUI applications requiring X11 forwarding

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| Container native | Must | Runs entirely in Docker |
| Browser accessible | Must | No host IDE installation |
| VS Code compatibility | Must | Extensions, keybindings, settings |
| License | Must | Open source (MIT/Apache) |
| Multi-arch support | Must | arm64 + amd64 |
| Extension ecosystem | High | Access to VS Code Marketplace or Open VSX |
| Performance | High | Responsive editing, fast startup |
| Authentication | Medium | Basic auth or token-based access |
| Active maintenance | Medium | Regular updates, security patches |
| Resource usage | Medium | Memory and CPU efficiency |

## Tool Candidates

| Tool | License | Pros | Cons | Container Mode | Spike Result |
|------|---------|------|------|----------------|--------------|
| code-server | MIT | Mature, widely used, good VS Code compatibility, Coder maintains actively, extensive docs | Uses Open VSX (not full Marketplace), some extension gaps | Docker native | Pending |
| OpenVSCode-Server | MIT | Direct VS Code fork by Gitpod, closer to upstream VS Code, official Docker image | Smaller community than code-server, less documentation | Docker native | Pending |
| JetBrains Gateway | Proprietary | Full JetBrains IDE features, excellent for Java/Kotlin/Python, professional tooling | Requires license, thin client on host, heavier resource usage | Backend in container | Pending |
| VS Code Remote - Tunnels | MIT (client) | Official Microsoft solution, full Marketplace access, seamless experience | Requires vscode.dev or local VS Code, Microsoft account | Backend in container | Pending |

## Detailed Tool Analysis

### code-server

**Source**: [GitHub - coder/code-server](https://github.com/coder/code-server) | [Docs](https://coder.com/docs/code-server)

code-server is VS Code running on a remote server, accessible through the browser:

- **Mature project**: Maintained by Coder, widely deployed in enterprise
- **Docker support**: Official images, easy deployment
- **Extension support**: Uses Open VSX Registry (open source extensions)
- **Authentication**: Built-in password auth, supports OAuth proxies
- **Configuration**: Persistent settings via config file or environment variables

Container compatibility: Excellent—designed for containerized deployment with official Docker images.

### OpenVSCode-Server

**Source**: [GitHub - gitpod-io/openvscode-server](https://github.com/gitpod-io/openvscode-server) | [Docker Hub](https://hub.docker.com/r/gitpod/openvscode-server)

OpenVSCode-Server is Gitpod's open-source VS Code server:

- **Upstream alignment**: Direct fork with minimal patches, stays close to VS Code releases
- **Gitpod backing**: Maintained by Gitpod team
- **Authentication**: Token-based (`--connection-token`) or open access
- **Docker image**: Official image on Docker Hub

Container compatibility: Excellent—built for cloud/container environments, straightforward Docker deployment.

### JetBrains Gateway

**Source**: [JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/) | [Docs](https://www.jetbrains.com/help/idea/remote-development-overview.html)

JetBrains Gateway provides remote development with full IDE features:

- **Full IDE**: IntelliJ, PyCharm, WebStorm, etc. running on remote backend
- **Dev Containers**: Native devcontainer.json support
- **Protocol**: Efficient RD protocol for responsive editing
- **Providers**: Supports Gitpod, GitHub Codespaces, Coder, SSH

Container compatibility: Backend runs in container; requires Gateway client on host (lightweight launcher, not full IDE).

### VS Code Remote - Tunnels

**Source**: [VS Code Server](https://code.visualstudio.com/docs/remote/vscode-server)

Microsoft's official remote development solution:

- **vscode.dev**: Access via browser at vscode.dev
- **Full Marketplace**: Access to complete VS Code extension marketplace
- **Microsoft account**: Required for tunnel authentication
- **Official support**: Maintained by VS Code team

Container compatibility: Server runs in container; accessible via vscode.dev (browser) or local VS Code client.

## Selected Approach

[Filled after spike]

## Acceptance Criteria

- [ ] Given the container image, when I access the IDE URL in browser, then full editor loads without host installation
- [ ] Given a project workspace, when I open files, then syntax highlighting and IntelliSense work correctly
- [ ] Given the integrated terminal, when I run commands, then they execute in the container environment
- [ ] Given extensions, when I install language support (Python, TypeScript, Rust), then they function correctly
- [ ] Given Git integration, when I view diffs and commit, then changes are tracked properly
- [ ] Given authentication configured, when I access remotely, then unauthorized access is prevented
- [ ] Given arm64 and amd64 hosts, when I build/run the image, then both architectures work
- [ ] Given multiple sessions, when users connect concurrently, then isolation is maintained

## Dependencies

- Requires: 001-prd-container-base, 004-prd-volume-architecture
- Blocks: 009-prd-ai-ide-extensions, 010-prd-project-context-files

## Spike Tasks

### Container Deployment

- [ ] Deploy code-server in container, verify browser access
- [ ] Deploy OpenVSCode-Server in container, verify browser access
- [ ] Deploy JetBrains Gateway backend in container, test with Gateway client
- [ ] Deploy VS Code tunnel server in container, test with vscode.dev
- [ ] Measure container image sizes and startup times
- [ ] Test multi-arch builds (arm64 + amd64)

### Feature Validation

- [ ] Install and test Python extension (linting, debugging, IntelliSense)
- [ ] Install and test TypeScript extension (type checking, refactoring)
- [ ] Test integrated terminal (shell access, command execution)
- [ ] Test Git integration (clone, commit, push, diff view)
- [ ] Test file search and replace across project

### Security & Access

- [ ] Configure and test authentication (password, token)
- [ ] Test HTTPS/TLS termination
- [ ] Evaluate multi-user isolation options
- [ ] Document secure remote access patterns

### Performance

- [ ] Measure memory usage under typical workload
- [ ] Test responsiveness with large files (>10k lines)
- [ ] Evaluate startup time cold vs warm
- [ ] Test with slow network connections

## References

- [code-server FAQ](https://coder.com/docs/code-server/FAQ)
- [OpenVSCode-Server vs code-server Discussion](https://github.com/coder/code-server/discussions/4267)
- [JetBrains Dev Containers Guide](https://blog.jetbrains.com/idea/2024/07/using-dev-containers-in-jetbrains-ides-part-1/)
- [VS Code Server Documentation](https://code.visualstudio.com/docs/remote/vscode-server)
