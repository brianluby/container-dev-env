# Technical Specification Document: 008-containerized-ide

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/008-containerized-ide/` and `prds/008-prd-containerized-ide.md`

## 1. Executive Summary

This document defines the technical specifications for the Containerized IDE, utilizing **OpenVSCode-Server**. It details the configuration, authentication, extension management, and integration with the container environment.

## 2. Technical Specifications

### 2.1 Server Configuration
*   **Binary**: `openvscode-server`
*   **Port**: 3000 (HTTP)
*   **Launch Command**:
    ```bash
    openvscode-server \
      --port 3000 \
      --host 0.0.0.0 \
      --without-connection-token \ # Security handled by network/auth proxy if needed, or use token
      --telemetry-level off
    ```
*   **User**: `dev` (UID 1000)

### 2.2 Extension Management (P1 Priority)
**Problem**: Extensions installed manually are lost on container rebuild.
**Solution**: Declarative Extension Management.
*   **Manifest**: `.devcontainer/extensions.json` (standard VS Code format).
*   **Installer Script**: `scripts/install-extensions.sh` runs at build time or startup.
    *   Iterates `extensions.json`.
    *   Calls `openvscode-server --install-extension <id>`.

## 3. Data Models

### 3.1 Persistence
*   **User Data**: `~/.openvscode-server/data/`
    *   Contains: `User/settings.json`, `User/keybindings.json`.
    *   **Mapping**: Persisted via `home-data` named volume (PRD 004).
*   **Extensions**: `~/.openvscode-server/extensions/`
    *   **Mapping**: Persisted via `home-data` named volume.

## 4. API Contracts & Interfaces

### 4.1 Access Control
*   **Token Auth**: `CONNECTION_TOKEN` environment variable.
    *   Value injected via `003-secret-injection`.
    *   Passed to server via `--connection-token $CONNECTION_TOKEN`.

### 4.2 Health Check
*   **Endpoint**: `http://localhost:3000/health` (or basic TCP check).
*   **Script**: `curl -f http://localhost:3000 || exit 1`.

## 5. Architectural Improvements

### 5.1 Settings Synchronization
**Problem**: Dotfiles (PRD 002) and VS Code settings might conflict.
**Solution**: Symlink `~/.openvscode-server/data/User/settings.json` to a file managed by Chezmoi (e.g., `~/.config/vscode/settings.json`). This makes VS Code settings version-controlled and portable.

### 5.2 Resource Limits
**Problem**: VS Code Java/TS servers can consume GBs of RAM.
**Solution**: Configure JVM and Node.js memory limits within the IDE settings (`"typescript.tsserver.maxTsServerMemory": 4096`) to prevent OOM kills in the container.

## 6. Testing Strategy
*   **Build Test**: Verify `openvscode-server` binary exists.
*   **Runtime Test**: Start container, curl port 3000, verify HTTP 200.
*   **Extension Test**: Verify `openvscode-server --list-extensions` output matches `extensions.json`.
