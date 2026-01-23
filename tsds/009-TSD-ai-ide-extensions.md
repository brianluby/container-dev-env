# Technical Specification Document: 009-ai-ide-extensions

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/009-ai-ide-extensions/` and `prds/009-prd-ai-ide-extensions.md`

## 1. Executive Summary

This document specifies the integration of AI-powered extensions into the containerized IDE (PRD 008). The primary selection is **Continue** due to its open-source nature, multi-provider support, and direct compatibility with `code-server` via Open VSX. A secondary option, **Cline**, is included for agentic workflows.

## 2. Technical Specifications

### 2.1 Extension Installation
Extensions are installed via `code-server` CLI during build or startup (see PRD 008 TSD).
*   **Primary ID**: `Continue.continue`
*   **Secondary ID**: `saoudrizwan.claude-dev` (Cline)
*   **Source**: Open VSX Registry (default in `code-server`).

### 2.2 Configuration Management
**Problem**: `~/.continue/config.json` is ephemeral.
**Solution**:
*   **Source**: `.devcontainer/continue-config.json` (version controlled).
*   **Target**: Symlinked to `~/.continue/config.json` at startup.

## 3. Data Models

### 3.1 Configuration Schema (`config.json`)
```json
{
  "models": [
    {
      "title": "Claude 3.5 Sonnet",
      "provider": "anthropic",
      "model": "claude-3-5-sonnet-20240620",
      "apiKey": "${ANTHROPIC_API_KEY}"
    }
  ],
  "tabAutocompleteModel": {
    "title": "StarCoder2",
    "provider": "ollama",
    "model": "starcoder2:3b"
  }
}
```

## 4. API Contracts & Interfaces

### 4.1 Credential Injection
Extensions expect API keys.
*   **Mechanism**: Environment variable expansion in `config.json`.
*   **Variables**: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`.
*   **Source**: PRD 003 Secret Injection.

## 5. Architectural Improvements

### 5.1 Local Model Optimization
**Problem**: Running local models (Ollama) inside the container is heavy.
**Solution**: Configure Continue to connect to a *host* Ollama instance if available (`host.docker.internal:11434`), falling back to a cloud provider if not. This offloads inference from the dev container.

## 6. Testing Strategy
*   **Integration Test**: Verify `~/.continue/config.json` exists and contains valid JSON.
*   **Functional Test**: Use `code-server` API to verify extension activation status.
