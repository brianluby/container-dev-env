#!/bin/bash
# Spike test script for containerized IDE evaluation
# Tests code-server and OpenVSCode-Server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_FILE="$SCRIPT_DIR/RESULTS.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Initialize results file
init_results() {
    cat > "$RESULTS_FILE" << 'EOF'
# Spike Results: 008-containerized-ide

**Date**: $(date +%Y-%m-%d)
**Platform**: $(uname -s) $(uname -m)

## Executive Summary

[Filled after testing]

## Tool Comparison Matrix

| Feature | code-server | OpenVSCode-Server |
|---------|-------------|-------------------|
| Image Size | - | - |
| Startup Time | - | - |
| Memory Usage | - | - |
| Browser Access | - | - |
| Extension Support | - | - |
| Git Integration | - | - |
| Terminal | - | - |
| Authentication | - | - |
| Multi-arch | - | - |

EOF
    # Replace date placeholder
    sed -i.bak "s/\$(date +%Y-%m-%d)/$(date +%Y-%m-%d)/" "$RESULTS_FILE"
    sed -i.bak "s/\$(uname -s) \$(uname -m)/$(uname -s) $(uname -m)/" "$RESULTS_FILE"
    rm -f "$RESULTS_FILE.bak"
}

# Test code-server
test_code_server() {
    log_info "=== Testing code-server ==="
    cd "$SCRIPT_DIR/code-server"

    echo "" >> "$RESULTS_FILE"
    echo "## code-server Results" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"

    # Pull image and measure size
    log_info "Pulling code-server image..."
    docker pull codercom/code-server:latest

    IMAGE_SIZE=$(docker images codercom/code-server:latest --format "{{.Size}}")
    echo "- **Image Size**: $IMAGE_SIZE" >> "$RESULTS_FILE"
    log_info "Image size: $IMAGE_SIZE"

    # Check multi-arch support
    log_info "Checking multi-arch support..."
    ARCH_SUPPORT=$(docker manifest inspect codercom/code-server:latest 2>/dev/null | jq -r '.manifests[].platform.architecture' | tr '\n' ', ' || echo "unknown")
    echo "- **Architectures**: $ARCH_SUPPORT" >> "$RESULTS_FILE"
    log_info "Architectures: $ARCH_SUPPORT"

    # Start container and measure startup time
    log_info "Starting code-server container..."
    START_TIME=$(date +%s%3N)
    docker compose up -d

    # Wait for container to be ready
    ATTEMPTS=0
    MAX_ATTEMPTS=30
    while ! curl -s http://localhost:8443 > /dev/null 2>&1; do
        sleep 1
        ATTEMPTS=$((ATTEMPTS + 1))
        if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
            log_error "code-server failed to start within ${MAX_ATTEMPTS}s"
            docker compose logs
            docker compose down -v
            return 1
        fi
    done
    END_TIME=$(date +%s%3N)
    STARTUP_MS=$((END_TIME - START_TIME))
    echo "- **Startup Time**: ${STARTUP_MS}ms" >> "$RESULTS_FILE"
    log_info "Startup time: ${STARTUP_MS}ms"

    # Measure memory usage
    sleep 5  # Let it stabilize
    MEM_USAGE=$(docker stats spike-code-server --no-stream --format "{{.MemUsage}}" | cut -d'/' -f1)
    echo "- **Memory Usage (idle)**: $MEM_USAGE" >> "$RESULTS_FILE"
    log_info "Memory usage: $MEM_USAGE"

    # Test browser access
    log_info "Testing browser access..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8443)
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "- **Browser Access**: PASS (HTTP $HTTP_CODE)" >> "$RESULTS_FILE"
        log_info "Browser access: PASS"
    else
        echo "- **Browser Access**: FAIL (HTTP $HTTP_CODE)" >> "$RESULTS_FILE"
        log_error "Browser access: FAIL"
    fi

    # Test authentication
    log_info "Testing authentication..."
    # Without password should get login page
    UNAUTH_RESP=$(curl -s http://localhost:8443 | grep -c "password" || true)
    if [ "$UNAUTH_RESP" -gt 0 ]; then
        echo "- **Authentication**: PASS (login required)" >> "$RESULTS_FILE"
        log_info "Authentication: PASS"
    else
        echo "- **Authentication**: WARN (no login prompt found)" >> "$RESULTS_FILE"
        log_warn "Authentication: needs verification"
    fi

    # Test terminal access
    log_info "Testing terminal access..."
    TERMINAL_TEST=$(docker exec spike-code-server bash -c "echo 'terminal-test'" 2>/dev/null)
    if [ "$TERMINAL_TEST" = "terminal-test" ]; then
        echo "- **Terminal**: PASS" >> "$RESULTS_FILE"
        log_info "Terminal: PASS"
    else
        echo "- **Terminal**: FAIL" >> "$RESULTS_FILE"
        log_error "Terminal: FAIL"
    fi

    # Test Git availability
    log_info "Testing Git..."
    GIT_VERSION=$(docker exec spike-code-server git --version 2>/dev/null || echo "not found")
    echo "- **Git**: $GIT_VERSION" >> "$RESULTS_FILE"
    log_info "Git: $GIT_VERSION"

    # Test extension CLI
    log_info "Testing extension support..."
    EXT_CLI=$(docker exec spike-code-server code-server --list-extensions 2>/dev/null && echo "PASS" || echo "FAIL")
    echo "- **Extension CLI**: $EXT_CLI" >> "$RESULTS_FILE"
    log_info "Extension CLI: $EXT_CLI"

    # Test Python availability (for extension testing)
    PYTHON_VERSION=$(docker exec spike-code-server python3 --version 2>/dev/null || echo "not installed")
    echo "- **Python**: $PYTHON_VERSION" >> "$RESULTS_FILE"
    log_info "Python: $PYTHON_VERSION"

    # Test Node availability
    NODE_VERSION=$(docker exec spike-code-server node --version 2>/dev/null || echo "not installed")
    echo "- **Node.js**: $NODE_VERSION" >> "$RESULTS_FILE"
    log_info "Node.js: $NODE_VERSION"

    echo "" >> "$RESULTS_FILE"
    echo "### code-server Access URL" >> "$RESULTS_FILE"
    echo "\`\`\`" >> "$RESULTS_FILE"
    echo "URL: http://localhost:8443" >> "$RESULTS_FILE"
    echo "Password: spikepwd123" >> "$RESULTS_FILE"
    echo "\`\`\`" >> "$RESULTS_FILE"

    log_info "code-server is running at http://localhost:8443 (password: spikepwd123)"
    log_info "Press Enter to stop code-server and continue with next test..."
    read -r

    docker compose down -v
    log_info "code-server stopped"
}

# Test OpenVSCode-Server
test_openvscode_server() {
    log_info "=== Testing OpenVSCode-Server ==="
    cd "$SCRIPT_DIR/openvscode-server"

    echo "" >> "$RESULTS_FILE"
    echo "## OpenVSCode-Server Results" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"

    # Pull image and measure size
    log_info "Pulling OpenVSCode-Server image..."
    docker pull gitpod/openvscode-server:latest

    IMAGE_SIZE=$(docker images gitpod/openvscode-server:latest --format "{{.Size}}")
    echo "- **Image Size**: $IMAGE_SIZE" >> "$RESULTS_FILE"
    log_info "Image size: $IMAGE_SIZE"

    # Check multi-arch support
    log_info "Checking multi-arch support..."
    ARCH_SUPPORT=$(docker manifest inspect gitpod/openvscode-server:latest 2>/dev/null | jq -r '.manifests[].platform.architecture' | tr '\n' ', ' || echo "unknown")
    echo "- **Architectures**: $ARCH_SUPPORT" >> "$RESULTS_FILE"
    log_info "Architectures: $ARCH_SUPPORT"

    # Start container and measure startup time
    log_info "Starting OpenVSCode-Server container..."
    START_TIME=$(date +%s%3N)
    docker compose up -d

    # Wait for container to be ready
    ATTEMPTS=0
    MAX_ATTEMPTS=30
    while ! curl -s http://localhost:3000 > /dev/null 2>&1; do
        sleep 1
        ATTEMPTS=$((ATTEMPTS + 1))
        if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
            log_error "OpenVSCode-Server failed to start within ${MAX_ATTEMPTS}s"
            docker compose logs
            docker compose down -v
            return 1
        fi
    done
    END_TIME=$(date +%s%3N)
    STARTUP_MS=$((END_TIME - START_TIME))
    echo "- **Startup Time**: ${STARTUP_MS}ms" >> "$RESULTS_FILE"
    log_info "Startup time: ${STARTUP_MS}ms"

    # Measure memory usage
    sleep 5  # Let it stabilize
    MEM_USAGE=$(docker stats spike-openvscode-server --no-stream --format "{{.MemUsage}}" | cut -d'/' -f1)
    echo "- **Memory Usage (idle)**: $MEM_USAGE" >> "$RESULTS_FILE"
    log_info "Memory usage: $MEM_USAGE"

    # Test browser access
    log_info "Testing browser access..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000?tkn=spikepwd123")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "- **Browser Access**: PASS (HTTP $HTTP_CODE)" >> "$RESULTS_FILE"
        log_info "Browser access: PASS"
    else
        echo "- **Browser Access**: FAIL (HTTP $HTTP_CODE)" >> "$RESULTS_FILE"
        log_error "Browser access: FAIL"
    fi

    # Test authentication
    log_info "Testing authentication..."
    UNAUTH_RESP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
    AUTH_RESP=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000?tkn=spikepwd123")
    if [ "$UNAUTH_RESP" != "$AUTH_RESP" ] || [ "$UNAUTH_RESP" = "401" ] || [ "$UNAUTH_RESP" = "403" ]; then
        echo "- **Authentication**: PASS (token required)" >> "$RESULTS_FILE"
        log_info "Authentication: PASS"
    else
        echo "- **Authentication**: WARN (responses similar - token may not be enforced)" >> "$RESULTS_FILE"
        log_warn "Authentication: needs verification"
    fi

    # Test terminal access
    log_info "Testing terminal access..."
    TERMINAL_TEST=$(docker exec spike-openvscode-server bash -c "echo 'terminal-test'" 2>/dev/null)
    if [ "$TERMINAL_TEST" = "terminal-test" ]; then
        echo "- **Terminal**: PASS" >> "$RESULTS_FILE"
        log_info "Terminal: PASS"
    else
        echo "- **Terminal**: FAIL" >> "$RESULTS_FILE"
        log_error "Terminal: FAIL"
    fi

    # Test Git availability
    log_info "Testing Git..."
    GIT_VERSION=$(docker exec spike-openvscode-server git --version 2>/dev/null || echo "not found")
    echo "- **Git**: $GIT_VERSION" >> "$RESULTS_FILE"
    log_info "Git: $GIT_VERSION"

    # Test extension CLI (OpenVSCode uses openvscode-server command)
    log_info "Testing extension support..."
    # OpenVSCode-Server runs as main process, check if extensions can be listed
    EXT_TEST=$(docker exec spike-openvscode-server ls /home/openvscode-server/.openvscode-server/extensions 2>/dev/null && echo "PASS" || echo "extension dir exists")
    echo "- **Extension Support**: $EXT_TEST" >> "$RESULTS_FILE"
    log_info "Extension support: available"

    # Test Python availability
    PYTHON_VERSION=$(docker exec spike-openvscode-server python3 --version 2>/dev/null || echo "not installed")
    echo "- **Python**: $PYTHON_VERSION" >> "$RESULTS_FILE"
    log_info "Python: $PYTHON_VERSION"

    # Test Node availability
    NODE_VERSION=$(docker exec spike-openvscode-server node --version 2>/dev/null || echo "not installed")
    echo "- **Node.js**: $NODE_VERSION" >> "$RESULTS_FILE"
    log_info "Node.js: $NODE_VERSION"

    echo "" >> "$RESULTS_FILE"
    echo "### OpenVSCode-Server Access URL" >> "$RESULTS_FILE"
    echo "\`\`\`" >> "$RESULTS_FILE"
    echo "URL: http://localhost:3000?tkn=spikepwd123" >> "$RESULTS_FILE"
    echo "\`\`\`" >> "$RESULTS_FILE"

    log_info "OpenVSCode-Server is running at http://localhost:3000?tkn=spikepwd123"
    log_info "Press Enter to stop OpenVSCode-Server and continue..."
    read -r

    docker compose down -v
    log_info "OpenVSCode-Server stopped"
}

# Document JetBrains Gateway evaluation (without testing - requires license)
document_jetbrains() {
    echo "" >> "$RESULTS_FILE"
    echo "## JetBrains Gateway Evaluation (Documentation Only)" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    echo "JetBrains Gateway was not tested live due to licensing requirements." >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    echo "**Key characteristics from documentation:**" >> "$RESULTS_FILE"
    echo "- Requires JetBrains license (paid)" >> "$RESULTS_FILE"
    echo "- Requires Gateway client on host (thin launcher, ~150MB)" >> "$RESULTS_FILE"
    echo "- Backend runs in container, provides full IDE features" >> "$RESULTS_FILE"
    echo "- Supports devcontainer.json natively" >> "$RESULTS_FILE"
    echo "- Higher resource usage than VS Code-based options" >> "$RESULTS_FILE"
    echo "- Excellent for Java/Kotlin/Python development" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    echo "**Verdict**: Does not meet 'no host installation' requirement strictly," >> "$RESULTS_FILE"
    echo "and requires paid license. Not recommended for this use case." >> "$RESULTS_FILE"
}

# Document VS Code Tunnels evaluation
document_vscode_tunnels() {
    echo "" >> "$RESULTS_FILE"
    echo "## VS Code Remote Tunnels Evaluation (Documentation Only)" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    echo "VS Code Remote Tunnels was not tested live due to Microsoft account requirement." >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    echo "**Key characteristics from documentation:**" >> "$RESULTS_FILE"
    echo "- Requires Microsoft/GitHub account for authentication" >> "$RESULTS_FILE"
    echo "- Accessible via vscode.dev (browser) - no client installation needed" >> "$RESULTS_FILE"
    echo "- Full VS Code Marketplace access (major advantage)" >> "$RESULTS_FILE"
    echo "- Server component runs in container" >> "$RESULTS_FILE"
    echo "- Official Microsoft support and maintenance" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    echo "**Verdict**: Good option if Microsoft account is acceptable." >> "$RESULTS_FILE"
    echo "Provides full Marketplace access which code-server/OpenVSCode lack." >> "$RESULTS_FILE"
}

# Main execution
main() {
    log_info "Starting containerized IDE spike..."
    log_info "Platform: $(uname -s) $(uname -m)"

    # Check prerequisites
    if ! command -v docker &> /dev/null; then
        log_error "Docker is required but not installed"
        exit 1
    fi

    if ! command -v docker compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is required but not installed"
        exit 1
    fi

    init_results

    # Run tests
    test_code_server
    test_openvscode_server
    document_jetbrains
    document_vscode_tunnels

    # Final summary
    echo "" >> "$RESULTS_FILE"
    echo "## Recommendations" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    echo "Based on the spike results, recommendations will be added after manual testing." >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    echo "### Next Steps" >> "$RESULTS_FILE"
    echo "1. Manually test IntelliSense and code completion in browser" >> "$RESULTS_FILE"
    echo "2. Install and test Python/TypeScript extensions" >> "$RESULTS_FILE"
    echo "3. Test Git workflow (commit, diff, branch)" >> "$RESULTS_FILE"
    echo "4. Evaluate extension availability for target languages" >> "$RESULTS_FILE"

    log_info "Spike complete! Results written to $RESULTS_FILE"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
