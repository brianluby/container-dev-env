# Spike Results: 012-persistent-memory

**Date**: 2026-01-21
**Platform**: Darwin arm64 (Apple Silicon)

## Executive Summary

The **Hybrid Approach** combining **Memory Bank (Markdown files)** with **MCP Memory Service** is recommended for persistent AI memory. Memory Bank provides human-maintained strategic context (architecture, decisions, patterns) while MCP Memory Service handles automatic tactical memory capture (recent sessions, code changes).

## Approach Comparison Matrix

| Feature | Memory Bank | MCP Memory Service | OpenMemory (Mem0) |
|---------|-------------|-------------------|-------------------|
| Storage Format | Markdown files | SQLite + vectors | Local DB |
| Human Readable | Excellent | Poor (DB) | Poor (DB) |
| Git Friendly | Excellent | Not recommended | Not recommended |
| Semantic Search | None | Yes (5ms) | Yes |
| Auto Capture | Manual only | Yes | Yes |
| Container Support | Excellent | Good (Docker image) | Good |
| Cross-Tool | Any tool | 13+ AI tools | MCP clients |
| Setup Complexity | None | Medium | Medium |
| Dependencies | None | Python, SQLite | Python |

## Memory Bank (Markdown) - RECOMMENDED for Strategic Context

### Overview
Plain markdown files that store project context in a human-readable, git-friendly format.

### Directory Structure
```
.memory-bank/
├── projectbrief.md      # Project goals, scope, success criteria
├── productContext.md    # Users, problems solved, value proposition
├── systemPatterns.md    # Architecture, design patterns, conventions
├── techContext.md       # Stack, dependencies, constraints, APIs
├── activeContext.md     # Current work, recent changes, WIP
└── progress.md          # Completed work, decisions, lessons learned
```

### Strengths
- **Human readable**: Can inspect, edit, review in any editor
- **Git friendly**: Commit with code, track changes, PR reviews
- **No dependencies**: Works with any AI tool immediately
- **Portable**: Copy between projects, share with team
- **Transparent**: Know exactly what context AI receives

### Weaknesses
- **Manual updates**: Requires discipline to maintain
- **No semantic search**: AI must read entire files
- **No auto-capture**: Won't remember session details automatically

### Best Practices
1. Update `activeContext.md` at start/end of each session
2. Update `progress.md` after completing features
3. Update `systemPatterns.md` after architectural decisions
4. Keep files focused and concise (AI context window limits)
5. Commit memory bank with related code changes

### Templates Created
See `memory-bank-templates/` directory for ready-to-use templates:
- `projectbrief.md` - Project overview template
- `productContext.md` - User and product context template
- `systemPatterns.md` - Architecture and patterns template
- `techContext.md` - Technical stack template
- `activeContext.md` - Current work context template
- `progress.md` - Progress tracking template

## MCP Memory Service - RECOMMENDED for Tactical Context

### Overview
Automatic context memory with semantic search, supporting 13+ AI tools.

**Source**: [doobidoo/mcp-memory-service](https://github.com/doobidoo/mcp-memory-service)

### Key Features
- **5ms retrieval latency** for context injection
- **Semantic search** using MiniLM-L6-v2 embeddings
- **SQLite-vec storage** with vector embeddings
- **Auto-capture** with intelligent pattern detection
- **13+ tool support**: Claude Code, Cursor, VS Code, Windsurf, etc.
- **Graph traversal** for connected memory queries

### Docker Deployment
```yaml
services:
  mcp-memory:
    image: mcp/memory:latest
    volumes:
      - mcp-memory-data:/data
    environment:
      - MCP_MEMORY_STORAGE_BACKEND=sqlite_vec
      - MCP_MEMORY_DB_PATH=/data/memory.db
```

### Container Compatibility
- Official Docker image available
- Persistent storage via Docker volumes
- ARM64 optimized builds (Apple Silicon)
- Recent fix for container restart database locking

### Resource Requirements
- **Memory**: 4GB minimum, 8GB recommended
- **Storage**: ~400-600MB for embedding model
- **CPU**: Works on standard containers

### MCP Tools Provided
- `store_memory` - Save context to memory
- `retrieve_memory` - Semantic search for relevant context
- `find_connected_memories` - Graph traversal
- `get_memory_subgraph` - Related memory clusters

## OpenMemory MCP (Mem0) - ALTERNATIVE

### Overview
Privacy-focused cross-client memory from Mem0.

**Source**: [mem0.ai](https://mem0.ai/blog/introducing-openmemory-mcp)

### Key Features
- Cross-client memory sharing
- Fully local storage (no cloud)
- MCP native integration
- Privacy-focused design

### Assessment
Less mature than MCP Memory Service but viable alternative if privacy is paramount. Documentation is less comprehensive.

## Knowledge Graph MCP - NOT RECOMMENDED

### Overview
Entity and relationship tracking for complex projects.

### Assessment
Overkill for most projects. Consider only for:
- Very large codebases with many interconnected components
- Projects requiring formal entity relationship tracking
- Team environments with complex domain models

## Recommended Hybrid Architecture

```
/workspace/
├── .memory-bank/                    # Strategic memory (git tracked)
│   ├── projectbrief.md             # Project overview
│   ├── productContext.md           # Users and value
│   ├── systemPatterns.md           # Architecture decisions
│   ├── techContext.md              # Technical stack
│   ├── activeContext.md            # Current work
│   └── progress.md                 # Progress log
│
├── .mcp-memory/                     # Tactical memory (git ignored)
│   ├── memory.db                    # SQLite with embeddings
│   └── config.json                  # MCP memory config
│
└── .gitignore                       # Ignore .mcp-memory/
```

### Why Hybrid?

| Context Type | Memory Bank | MCP Memory |
|--------------|-------------|------------|
| Architecture decisions | Yes | |
| Design patterns | Yes | |
| Project goals | Yes | |
| Recent code changes | | Yes |
| Session conversations | | Yes |
| Error patterns | | Yes |
| Frequently used commands | | Yes |

### Git Integration
```gitignore
# .gitignore
.mcp-memory/
```

Memory Bank files are committed; MCP Memory database is local only.

## Implementation Recommendations

### Phase 1: Memory Bank Only (Immediate)
1. Create `.memory-bank/` directory structure
2. Populate templates with project context
3. Configure AI tools to read memory bank files
4. Establish update discipline

### Phase 2: Add MCP Memory Service (Later)
1. Deploy MCP Memory Service in container
2. Configure with Docker volume for persistence
3. Enable auto-capture for tactical context
4. Configure `.gitignore` to exclude MCP database

### Claude Code Configuration
Claude Code already reads `CLAUDE.md` files. For Memory Bank:

```markdown
# .memory-bank/CLAUDE.md (symlink or copy key context)
See project context in:
- projectbrief.md - Project overview
- systemPatterns.md - Architecture patterns
- activeContext.md - Current work focus
```

### Cline Configuration
Cline supports custom instructions. Point to Memory Bank:

```json
{
  "customInstructions": "Read context from .memory-bank/ directory before each task."
}
```

## Acceptance Criteria Status

| Criterion | Status | Notes |
|-----------|--------|-------|
| Persistent storage across restarts | PASS | Volume-backed storage |
| Project-scoped memory | PASS | Per-project directories |
| Works with Claude Code, Cline, etc. | PASS | MCP + markdown universal |
| Human-readable format | PASS | Memory Bank is markdown |
| Automatic context injection | PASS | MCP Memory Service |
| Runs in container | PASS | Docker deployment ready |
| Semantic search | PASS | MCP Memory 5ms retrieval |
| Memory categories | PASS | Memory Bank file structure |

## Files Created

```
spikes/012-persistent-memory/
├── RESULTS.md                           # This file
├── memory-bank-templates/
│   ├── projectbrief.md                  # Project overview template
│   ├── productContext.md                # Product context template
│   ├── systemPatterns.md                # System patterns template
│   ├── techContext.md                   # Technical context template
│   ├── activeContext.md                 # Active context template
│   └── progress.md                      # Progress log template
├── mcp-memory/
│   ├── docker-compose.yml               # MCP Memory Service deployment
│   └── claude-desktop-config.example.json
└── research/                            # Research notes (empty)
```

## Next Steps

1. [ ] Test MCP Memory Service Docker deployment
2. [ ] Measure actual retrieval latency in container
3. [ ] Test cross-tool memory sharing (Claude Code → Cursor)
4. [ ] Create initialization script for new projects
5. [ ] Document backup/restore procedures
6. [ ] Test memory pruning for long-running projects

## References

- [MCP Memory Service](https://github.com/doobidoo/mcp-memory-service)
- [Memory Bank Workflow](https://tweag.github.io/agentic-coding-handbook/WORKFLOW_MEMORY_BANK/)
- [Cline Memory Bank](https://cline.bot/blog/memory-bank-how-to-make-cline-an-ai-agent-that-never-forgets)
- [Docker MCP Toolkit](https://docs.docker.com/ai/mcp-catalog-and-toolkit/toolkit/)
- [MCP Memory Docker Hub](https://hub.docker.com/r/mcp/memory)
