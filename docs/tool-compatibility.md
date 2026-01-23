# AI Tool Compatibility: Context File Discovery

## Overview

AGENTS.md is recognized by all major AI coding tools. This document describes
per-tool discovery behavior to help developers understand how context files
are loaded and applied.

## Tool Discovery Matrix

| Tool | Primary File | Supplement File | Nested Support | Discovery Trigger |
|------|-------------|-----------------|----------------|-------------------|
| Claude Code | AGENTS.md | CLAUDE.md | Yes | Session start |
| Cline | AGENTS.md | .clinerules | Yes | Session start |
| Continue | AGENTS.md | .continuerules | Yes | Session start |
| Roo-Code | AGENTS.md | .roo/rules | Yes | Session start |
| OpenCode | AGENTS.md | config.yaml | Yes | Session start |
| Cursor | AGENTS.md | .cursorrules / .cursor/rules/*.mdc | Limited | File open |

## Per-Tool Details

### Claude Code

- **Discovery**: Reads AGENTS.md and CLAUDE.md from project root at session start
- **Nested**: Reads AGENTS.md from subdirectories when working in those paths
- **Precedence**: CLAUDE.md supplements AGENTS.md (both are loaded)
- **Reload**: Changes take effect on next session (no hot-reload)
- **Format**: Standard Markdown (CommonMark)

### Cline

- **Discovery**: Reads AGENTS.md from project root at session start
- **Supplement**: .clinerules file in project root for Cline-specific instructions
- **Nested**: Supports subdirectory AGENTS.md files
- **Precedence**: .clinerules supplements AGENTS.md
- **Format**: Standard Markdown

### Continue

- **Discovery**: Reads AGENTS.md from project root
- **Supplement**: .continuerules file in project root
- **Nested**: Supports subdirectory context, nested overrides root for scope
- **Format**: Standard Markdown

### Roo-Code

- **Discovery**: Reads AGENTS.md from project root
- **Supplement**: .roo/rules directory for Roo-specific configurations
- **Nested**: Supports subdirectory AGENTS.md files
- **Format**: Standard Markdown

### OpenCode

- **Discovery**: Reads AGENTS.md from project root
- **Supplement**: config.yaml for OpenCode-specific settings
- **Nested**: Supports subdirectory context files
- **Format**: Standard Markdown

### Cursor

- **Discovery**: Reads AGENTS.md from project root (newer versions)
- **Legacy**: .cursorrules in project root (deprecated)
- **Modern**: .cursor/rules/*.mdc files for structured rules
- **Nested**: Limited subdirectory support
- **Precedence**: .mdc rules override AGENTS.md on conflict
- **Format**: Markdown (AGENTS.md) or MDC format (.mdc files)

## Universal Compatibility Guidelines

1. **Use standard Markdown** — All tools parse CommonMark; avoid tool-specific extensions in AGENTS.md
2. **Keep under 10KB** — Fits within all tools' context windows
3. **Use UTF-8 with LF** — Universal encoding support
4. **Case-sensitive filename** — Must be exactly `AGENTS.md` (not agents.md)
5. **Put tool-specific content in supplements** — Keep AGENTS.md universal
6. **No secrets** — All tools may log or transmit context file content
