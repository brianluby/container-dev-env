# PRD Recommendations from TSD 005-015 Review

**Date**: 2026-01-21
**Reviewer**: Claude Opus 4.5
**Status**: Review Complete

## Executive Summary

This document provides a critical review of the Technical Spike Documents (TSDs) 005-015 and their recommendations for the corresponding Product Requirements Documents (PRDs). Not all suggestions are accepted—each is evaluated for practical value versus added complexity.

**Overall Assessment**: The TSDs contain useful insights but show a tendency toward over-engineering. Many recommendations add wrapper scripts, automated enforcement, or solve theoretical problems that don't exist in practice. This review filters for pragmatic, high-value changes.

---

## Analysis Document Recommendations

Source: `005-015-review-analysis.md`

| Priority | Recommendation | Verdict | Reasoning |
|----------|----------------|---------|-----------|
| **P0** | Unified Credential Injection | **ACCEPT** | Legitimate concern. Multiple tools with slightly different env var names is real friction. PRD 003 should include a mapping layer. |
| **P1** | Declarative Extension Manager | **ACCEPT** | Extensions lost on rebuild is a real problem. PRDs 008/009 mention this—needs formalization. |
| **P1** | Context Hierarchy Definition | **PARTIAL** | Useful mental model but overly prescriptive. Add as documentation/guidance, not enforcement. |
| **P2** | Notification Rate Limiting | **ACCEPT** | Reasonable safeguard against notification spam. Add to PRD 015. |
| **P3** | Shared Session Logging | **REJECT** | Over-engineering. Each tool's native logging is sufficient. Standardization effort outweighs benefit. |
| **P3** | Automated Doc Validation | **REJECT** | Pre-commit hooks blocking on docs are annoying. Better handled by team discipline. |

---

## Cluster 1: AI Agents (PRDs 005, 006, 007)

### TSD 005 (Terminal AI Agent)

| Recommendation | Verdict | Reasoning |
|----------------|---------|-----------|
| Unified Credential Wrapper (`opencode-wrap`) | **REJECT** | Unnecessary friction. Tools already provide clear error messages when keys are missing. Users learn after one failed attempt. |
| Pre-download model tokenizers | **REJECT** | Premature optimization. OpenCode is a Go binary that starts instantly. Tokenizer downloads are cached after first use. |
| API Key Environment Variable Mapping | **ACCEPT** | The table mapping internal secrets to tool-specific vars is useful documentation for PRD 005. |

### TSD 006 (Agentic Assistant)

| Recommendation | Verdict | Reasoning |
|----------------|---------|-----------|
| Watchdog Process (`agent-watchdog.sh`) | **REJECT** | Over-engineering. Claude Code and other tools have native timeout mechanisms. Adding monitoring layers creates complexity. |
| Context Optimization via AGENTS.md injection | **PARTIAL** | Good idea but `prompt-wrapper.sh` is clunky. Document that tools already read context files automatically. |
| Checkpoint State using git | **ACCEPT** | Git-based approach (`git stash create`, step commits) is a reasonable implementation detail to add to PRD 006. |
| Budget System (token/step limits) | **ACCEPT** | Already in PRD 006. Good validation this is needed. |

### TSD 007 (Git Worktree Compat)

| Recommendation | Verdict | Reasoning |
|----------------|---------|-----------|
| Volume Strategy Update | **ACCEPT** | Warning about mounting worktree directory without parent access is legitimate. Add note to PRD 004. |
| Validation in entrypoint.sh | **PARTIAL** | A warning message is fine. But PRD spike found "worktree compatibility is a non-issue"—keep lightweight. |
| `check-worktree-compat` JSON output | **REJECT** | Over-engineering for a "non-issue". PRD spike proved tools work fine. No validation script needed. |

---

## Cluster 2: IDE & Extensions (PRDs 008, 009)

### TSD 008 (Containerized IDE)

| Recommendation | Verdict | Reasoning |
|----------------|---------|-----------|
| Declarative Extension Management | **ACCEPT** | `install-extensions.sh` + `extensions.json` manifest is good practice. Formalize in PRD. |
| Settings Synchronization via symlinks | **PARTIAL** | Symlinking VS Code settings to Chezmoi-managed files is reasonable. Document as optional pattern. |
| Resource Limits (JVM/Node.js memory) | **ACCEPT** | Practical. Add "Resource Management" section to PRD 008 with sensible defaults. |
| Health Check endpoint | **ACCEPT** | Already in PRD 008. The curl command is a fine implementation. |

### TSD 009 (AI IDE Extensions)

| Recommendation | Verdict | Reasoning |
|----------------|---------|-----------|
| Local Model Optimization | **ACCEPT** | Connect to host Ollama via `host.docker.internal:11434`. Running Ollama inside container is wasteful. |
| Config symlinking | **ACCEPT** | Extension configs being ephemeral is a real problem. Already mentioned in PRD 009. |
| Environment variable expansion | **ACCEPT** | `${{ secrets.API_KEY }}` syntax already in PRD 009. Good validation. |

---

## Cluster 3: Context & Memory (PRDs 010, 011, 012, 013)

### TSD 010 (Project Context Files)

| Recommendation | Verdict | Reasoning |
|----------------|---------|-----------|
| Context Injection Hook (`prompt-wrapper.sh`) | **REJECT** | Tools like Claude Code, Cline, and Continue already read context files automatically. Manual prepending creates duplication. |
| Linter Rules for AGENTS.md | **PARTIAL** | Basic markdownlint is fine. "Must contain Tech Stack section" is too prescriptive—projects vary. |
| Context Hierarchy | **ACCEPT** | Good mental model (User Prompt → activeContext → AGENTS.md → docs/). Add as guidance, not enforcement. |
| Max Size recommendation (< 10KB) | **ACCEPT** | Practical guidance to prevent context bloat. Add to PRD 010. |

### TSD 011 (MCP Integration)

| Recommendation | Verdict | Reasoning |
|----------------|---------|-----------|
| Server Lazy Loading | **ACCEPT** | Already how MCP works. Document explicitly in PRD 011. |
| NPX caching persistence | **ACCEPT** | Persist `~/.npm` on volume to prevent re-downloading MCP servers. Add to PRD 004. |
| MCP Security (filesystem scoping) | **ACCEPT** | Already in PRD 011. Good validation. |

### TSD 012 (Persistent Memory)

| Recommendation | Verdict | Reasoning |
|----------------|---------|-----------|
| Sync Mechanism / Update Protocol | **PARTIAL** | Including "update memory before task completion" in prompts is unreliable—AI may forget. Document as best practice only. |
| Hybrid Storage architecture | **ACCEPT** | `.memory-bank` git-tracked, `.mcp-memory` git-ignored. Already in PRD 012. |

### TSD 013 (Project Knowledge)

| Recommendation | Verdict | Reasoning |
|----------------|---------|-----------|
| Automated Diagram Generation (`mmd-cli`) | **REJECT** | Over-engineering. Mermaid renders natively in GitHub, VS Code, and most tools. PNG generation is maintenance burden. |
| Link checking via lychee | **PARTIAL** | Running in CI is fine. Don't make it a blocking pre-commit hook—docs can have temporary broken links. |
| ADR Template | **ACCEPT** | Already in PRD 013. TSD template aligns well. |

---

## Cluster 4: Interfaces (PRDs 014, 015)

### TSD 014 (Voice Input)

| Recommendation | Verdict | Reasoning |
|----------------|---------|-----------|
| Host-Side Dictation as Primary | **ACCEPT** | Pragmatic. Docker audio forwarding is unreliable. Clipboard/OSC52 approach works. |
| Web Speech API for code-server | **ACCEPT** | Good secondary option. Browser-based voice input avoids container audio complexity. |
| Custom Dictionary | **PARTIAL** | Useful for accuracy, but implementation depends on voice tool. Add as "Could Have". |
| OSC 52 clipboard requirement | **ACCEPT** | Already in PRD 014. Good technical detail. |

### TSD 015 (Mobile Access)

| Recommendation | Verdict | Reasoning |
|----------------|---------|-----------|
| Rate Limiter (token bucket) | **ACCEPT** | Sensible safeguard. "1 per minute, 10 per hour" are reasonable defaults. |
| Deep Linking with click URLs | **ACCEPT** | Good UX. Tap notification → open PR/issue directly. Low effort, high value. |
| ntfy.sh as primary | **ACCEPT** | Already selected in PRD 015 spike. Zero-setup, open source, works well. |

---

## Actionable Changes by PRD

### PRD 003 (Secret Injection)
- **ADD**: Environment variable mapping table for tool-specific names

### PRD 004 (Volume Architecture)
- **ADD**: Note about mounting repository root for worktree compatibility
- **ADD**: Persist `~/.npm` cache for MCP server downloads

### PRD 005 (Terminal AI Agent)
- **ADD**: API key environment variable documentation table

### PRD 006 (Agentic Assistant)
- **ADD**: Git-based checkpoint implementation detail (stash/commit pattern)

### PRD 007 (Git Worktree Compat)
- **ADD**: Warning about partial worktree mounts in entrypoint

### PRD 008 (Containerized IDE)
- **ADD**: Resource limits section with JVM/Node.js memory settings
- **FORMALIZE**: Extension management via `extensions.json` manifest

### PRD 009 (AI IDE Extensions)
- **ADD**: Host Ollama connection pattern (`host.docker.internal:11434`)

### PRD 010 (Project Context Files)
- **ADD**: Max file size recommendation (< 10KB)
- **ADD**: Context hierarchy as documentation/guidance

### PRD 011 (MCP Integration)
- **ADD**: Note about lazy loading behavior

### PRD 013 (Project Knowledge)
- **ADD**: Optional link checking in CI (non-blocking)

### PRD 014 (Voice Input)
- **ADD**: Web Speech API as secondary pattern

### PRD 015 (Mobile Access)
- **ADD**: Rate limiting with token bucket (1/min, 10/hour default)
- **ADD**: Deep linking requirement for notifications

---

## Rejected Recommendations Summary

| Recommendation | Reason for Rejection |
|----------------|---------------------|
| Credential wrapper scripts | Unnecessary friction; tools have good error messages |
| Pre-download tokenizers | Premature optimization; not a real problem |
| Watchdog process | Over-engineering; tools have native timeout handling |
| `check-worktree-compat` script | Spike proved worktrees work fine; non-issue |
| Context injection wrapper | Tools already read context files automatically |
| Mandatory AGENTS.md linter rules | Too prescriptive; projects vary |
| Automated PNG diagram generation | Mermaid renders natively everywhere; PNG is maintenance burden |
| Shared session logging format | Each tool's native logging is sufficient |
| Automated doc validation pre-commit | Annoying in practice; better handled by discipline |

---

## Key Themes in Rejected Recommendations

The TSDs show a tendency toward **over-engineering** in several areas:

### 1. Wrapper Scripts Everywhere
Adding shell script wrappers around tools adds maintenance burden and complexity. Trust the tools to handle their own errors.

### 2. Automated Validation/Enforcement
Pre-commit hooks and mandatory linters sound good in theory but create friction in practice. Prefer documentation and team conventions over programmatic enforcement.

### 3. Solving Non-Problems
Several recommendations address theoretical issues that the spike results showed don't exist (worktree compatibility, startup latency).

### 4. Generating Artifacts No One Asked For
PNG diagrams from Mermaid, standardized session logs across tools—these create maintenance burden without clear benefit.

---

## Guiding Principle

The accepted recommendations share a common trait: they address **real friction points** observed in practice (extension loss on rebuild, container resource limits, notification spam) with **minimal additional complexity**.

Avoid adding layers of abstraction, wrapper scripts, or automation for problems that:
- Don't exist in practice (validated by spike results)
- Are already handled well by existing tools
- Create more maintenance burden than they solve
