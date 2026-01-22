# Spike Results: 008-containerized-ide

**Date**: 2026-01-21
**Platform**: Darwin arm64 (Apple Silicon)

## Executive Summary

Both **code-server** and **OpenVSCode-Server** are viable options for containerized IDE deployment. After testing, **OpenVSCode-Server** is recommended as the primary choice due to smaller image size, lower memory footprint, and closer alignment with upstream VS Code. code-server remains a strong alternative with more mature documentation and enterprise features.

## Tool Comparison Matrix

| Feature | code-server | OpenVSCode-Server |
|---------|-------------|-------------------|
| Image Size | 1.12 GB | 848 MB |
| Startup Time | ~8 sec | ~8 sec |
| Memory Usage (idle) | 36.75 MiB | 23.47 MiB |
| Browser Access | PASS (302 redirect to login) | PASS (200 OK) |
| Extension Support | PASS (via Open VSX) | PASS (via Open VSX) |
| Git Integration | git 2.39.5 | git 2.34.1 |
| Terminal | PASS | PASS |
| Authentication | Built-in password | Connection token |
| Multi-arch | amd64, arm64 | amd64, arm64, arm |
| License | MIT | MIT |

## code-server Results

- **Image Size**: 1.12GB
- **Architectures**: linux/amd64, linux/arm64
- **Startup Time**: ~8000ms
- **Memory Usage (idle)**: 36.75MiB
- **Browser Access**: PASS (HTTP 302 redirect to login page)
- **Authentication**: PASS (password-based login required)
- **Terminal**: PASS
- **Git**: git version 2.39.5
- **Extension CLI**: PASS
- **Python**: not installed (requires custom image)
- **Node.js**: not installed (requires custom image)

### code-server Pros
- Mature project maintained by Coder
- Extensive documentation and community
- Built-in password authentication (simple to configure)
- Enterprise features (OAuth proxy support)
- Stable configuration via config.yaml

### code-server Cons
- Larger image size (1.12GB)
- Higher memory usage
- Uses Open VSX (some extensions unavailable)

### code-server Access URL
```
URL: http://localhost:8443
Password: spikepwd123
```

## OpenVSCode-Server Results

- **Image Size**: 848MB
- **Architectures**: linux/amd64, linux/arm64, linux/arm
- **Startup Time**: ~7800ms
- **Memory Usage (idle)**: 23.47MiB
- **Browser Access**: PASS (HTTP 200)
- **Authentication**: Token-based (via --connection-token flag)
- **Terminal**: PASS
- **Git**: git version 2.34.1
- **Extension Support**: PASS (extensions directory created on install)
- **Python**: not installed (requires custom image)
- **Node.js**: not installed (requires custom image)

### OpenVSCode-Server Pros
- Smaller image (848MB vs 1.12GB)
- Lower memory footprint (23MB vs 37MB idle)
- Closer to upstream VS Code (maintained by Gitpod)
- Supports ARM32 in addition to ARM64
- Minimal patches, faster VS Code version alignment

### OpenVSCode-Server Cons
- Less documentation than code-server
- Token auth requires URL parameter (less user-friendly)
- Smaller community

### OpenVSCode-Server Access URL
```
URL: http://localhost:3000
(Add ?tkn=TOKEN for token-protected instances)
```

## JetBrains Gateway Evaluation (Documentation Only)

JetBrains Gateway was not tested live due to licensing requirements.

**Key characteristics from documentation:**
- Requires JetBrains license (paid)
- Requires Gateway client on host (thin launcher, ~150MB)
- Backend runs in container, provides full IDE features
- Supports devcontainer.json natively
- Higher resource usage than VS Code-based options
- Excellent for Java/Kotlin/Python development

**Verdict**: Does not meet 'no host installation' requirement strictly,
and requires paid license. Not recommended for this use case.

## VS Code Remote Tunnels Evaluation (Documentation Only)

VS Code Remote Tunnels was not tested live due to Microsoft account requirement.

**Key characteristics from documentation:**
- Requires Microsoft/GitHub account for authentication
- Accessible via vscode.dev (browser) - no client installation needed
- Full VS Code Marketplace access (major advantage)
- Server component runs in container
- Official Microsoft support and maintenance

**Verdict**: Good option if Microsoft account is acceptable.
Provides full Marketplace access which code-server/OpenVSCode lack.

## Extension Installation Test

Both IDEs successfully installed the Python extension (`ms-python.python`):

**code-server:**
```
Extension 'ms-python.vscode-python-envs' v1.16.0 was successfully installed.
Extension 'ms-python.debugpy' v2024.0.0 was successfully installed.
Extension 'ms-python.python' v2026.0.0 was successfully installed.
```

**OpenVSCode-Server:**
```
Extension 'ms-python.vscode-python-envs' v1.10.0 was successfully installed.
Extension 'ms-python.debugpy' v2025.18.0 was successfully installed.
Extension 'ms-python.python' v2026.0.0 was successfully installed.
```

Both use Open VSX Registry for extensions. Most popular extensions are available.

## Recommendations

### Primary Recommendation: OpenVSCode-Server

OpenVSCode-Server is recommended for the container-dev-env project because:
1. **Smaller footprint**: 848MB image, 23MB idle memory
2. **Upstream alignment**: Closer to VS Code releases
3. **Broader architecture support**: Includes ARM32
4. **Active maintenance**: Backed by Gitpod
5. **Simpler licensing**: Pure MIT license

### Secondary Recommendation: code-server

Use code-server if:
1. Built-in password auth is preferred over token-based
2. Enterprise OAuth integration is needed
3. More mature documentation is important
4. Need Coder's enterprise support

### Not Recommended

- **JetBrains Gateway**: Requires host client, paid license
- **VS Code Tunnels**: Requires Microsoft account, potential privacy concerns

## Implementation Notes

### Custom Image Requirements

Neither base image includes Python or Node.js. A custom Dockerfile is needed:

```dockerfile
FROM gitpod/openvscode-server:latest

USER root

# Install development tools
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

USER openvscode-server
```

### Authentication Configuration

For production, configure authentication:

**OpenVSCode-Server (token-based):**
```yaml
command: --connection-token ${CONNECTION_TOKEN}
```

**code-server (password-based):**
```yaml
environment:
  - PASSWORD=${CODE_SERVER_PASSWORD}
```

### HTTPS/TLS

Use a reverse proxy (Traefik, Caddy, nginx) for HTTPS termination in production.

## Next Steps

1. [x] ~~Deploy code-server in container, verify browser access~~
2. [x] ~~Deploy OpenVSCode-Server in container, verify browser access~~
3. [ ] Create custom Dockerfile with Python/Node/development tools
4. [ ] Configure HTTPS via reverse proxy
5. [ ] Test IntelliSense and code completion manually in browser
6. [ ] Test Git workflow (commit, diff, branch) in browser
7. [ ] Evaluate multi-user isolation options
8. [ ] Document secure remote access patterns

## Test Artifacts

- `code-server/docker-compose.yml` - code-server deployment config
- `openvscode-server/docker-compose.yml` - OpenVSCode-Server deployment config
- `workspace/sample-project/` - Test project files for validation
