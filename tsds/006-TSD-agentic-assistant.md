# Technical Specification Document: 006-agentic-assistant

**Date**: 2026-01-21
**Author**: Gemini CLI
**Target**: `specs/006-agentic-assistant/` and `prds/006-prd-agentic-assistant.md`

## 1. Executive Summary

This document defines the technical specifications for the Agentic Assistant, enabling autonomous, multi-file coding tasks. The architecture leverages **Claude Code** (or open-source equivalent like **Cline** CLI) running in a headless or TUI mode within the container. Key focus areas are safe autonomous operation (checkpointing) and recovery.

## 2. Technical Specifications

### 2.1 Autonomous Loop Architecture
The agent operates in a `Plan -> Act -> Observe` loop.
*   **Plan**: Analyze the request and `AGENTS.md` context.
*   **Act**: Execute shell commands or file edits.
*   **Observe**: Read command output or file contents.

### 2.2 Safety Mechanisms
*   **Sandboxing**: The agent runs as the non-root `dev` user, restricting system-level damage.
*   **Rate Limiting**: Implementation of a "Budget" system (token or step count) to prevent infinite loops.

## 3. Data Models

### 3.1 Checkpoint State
To support rollback (PRD 006 Requirement), we utilize git.
*   **Pre-Task Snapshot**: `git stash create`
*   **Step Commit**: `git commit -m "Agent Step: <action>"`
*   **Rollback**: `git reset --hard <pre-task-hash>`

### 3.2 Task Definition
```json
{
  "task_id": "uuid",
  "status": "running|completed|failed",
  "budget": {
    "max_steps": 50,
    "max_cost": 2.00
  },
  "context_files": ["src/main.py", "README.md"]
}
```

## 4. API Contracts & Interfaces

### 4.1 CLI Interface
*   `agent start "<task>"`: Initiates an autonomous session.
*   `agent stop`: Sends SIGINT to the agent process.
*   `agent status`: Reads the current task state JSON.

### 4.2 MCP Integration
The agent acts as an MCP *Client*, connecting to MCP Servers defined in PRD 011.
*   **Config**: `~/.config/claude-code/config.json` (or equivalent).

## 5. Architectural Improvements

### 5.1 Watchdog Process
**Problem**: Agents can hang or loop indefinitely.
**Solution**: Implement a background watchdog script `agent-watchdog.sh` that monitors the agent's PID and log output. If no log activity for > 5 minutes, it alerts the user (via PRD 015 notifications).

### 5.2 Context Optimization
**Problem**: Large codebases exhaust context windows.
**Solution**: Enforce usage of `010-project-context-files` (AGENTS.md). The agent's system prompt is automatically prepended with the content of `AGENTS.md` via a wrapper script.

## 6. Testing Strategy
*   **Scenario Test**: "Refactor function X in file Y". Verify git commit created.
*   **Failure Test**: "Delete system files". Verify permission denied and agent handles error gracefully.
