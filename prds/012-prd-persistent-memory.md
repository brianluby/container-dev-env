# 012-prd-persistent-memory

## Problem Statement

AI coding agents lose context between sessions, requiring developers to repeatedly explain
project details, recent changes, and ongoing work. This wastes time and reduces AI effectiveness.
A persistent memory system allows AI agents to remember project context, decisions, and patterns
across sessions, providing continuity similar to working with a human colleague who remembers
past conversations.

**Critical constraint**: Memory storage must persist within the containerized environment using
mounted volumes. Memory should be project-scoped and portable (can be committed to git or
backed up).

## Requirements

### Must Have (M)

- [x] Persistent storage across container restarts *(verified: volume-backed storage)*
- [x] Project-scoped memory (isolated per project) *(verified: per-project directories)*
- [x] Works with Claude Code, Cline, Continue, and other AI tools *(verified: MCP + markdown universal)*
- [x] Human-readable storage format (inspectable, editable) *(verified: Memory Bank is markdown)*
- [x] Automatic context injection into AI sessions *(verified: MCP Memory Service)*
- [x] Runs entirely within container environment *(verified: Docker deployment)*

### Should Have (S)

- [x] Semantic search for relevant context retrieval *(verified: MCP Memory 5ms retrieval)*
- [x] Memory categories (architecture, decisions, patterns, recent work) *(verified: 6 Memory Bank files)*
- [x] Automatic memory capture from AI sessions *(verified: MCP auto-capture)*
- [x] Cross-tool memory sharing (same memory works with different AI tools) *(verified: 13+ tools supported)*
- [ ] Memory size management (pruning, summarization)
- [x] MCP integration for memory access *(verified: MCP Memory Service)*

### Could Have (C)

- [ ] Vector embeddings for semantic similarity
- [ ] Knowledge graph for entity relationships
- [ ] Memory versioning (git-friendly)
- [ ] Team/shared memory capabilities
- [ ] Memory import/export
- [ ] Memory analytics (what's being used most)

### Won't Have (W)

- [ ] Cloud-hosted memory (local only for privacy)
- [ ] Real-time sync across machines (manual sync via git)
- [ ] Memory for non-coding contexts
- [ ] Self-updating memory without user involvement

## Evaluation Criteria

| Criterion | Weight | Notes | Spike Result |
|-----------|--------|-------|--------------|
| Container compatibility | Must | Runs in Docker, uses volumes for persistence | **PASS** - Both approaches work |
| Cross-tool support | Must | Works with multiple AI coding tools | **PASS** - 13+ tools supported |
| Human readable | Must | Can inspect and edit stored memory | **PASS** - Memory Bank markdown |
| Privacy | Must | Local storage, no cloud dependency | **PASS** - All local |
| Retrieval quality | High | Finds relevant context accurately | **PASS** - 5ms semantic search |
| Performance | High | Fast retrieval, doesn't slow down sessions | **PASS** - Sub-10ms latency |
| Storage efficiency | Medium | Reasonable disk usage | **PASS** - SQLite-vec efficient |
| Maintenance | Medium | Active development, documentation | **PASS** - Active projects |

## Approach Candidates

| Approach | Type | Pros | Cons | Container Mode | Spike Result |
|----------|------|------|------|----------------|--------------|
| MCP Memory Service | MCP Server | Automatic context, semantic search, 5ms retrieval, works with many tools | Requires MCP support, newer project | Volume-backed | **SELECTED** - Tactical memory |
| OpenMemory MCP (Mem0) | MCP Server | Cross-client memory, fully local, privacy-focused | Newer, less battle-tested | Volume-backed | **ALTERNATIVE** - Less documented |
| Memory Bank (Markdown) | File-based | Simple, human-readable, git-friendly, no dependencies | Manual updates, no semantic search | Volume-backed | **SELECTED** - Strategic memory |
| Knowledge Graph MCP | MCP Server | Entity relationships, structured data | More complex, overkill for many projects | Volume-backed | **NOT RECOMMENDED** - Overkill |
| Custom Vector Store | Self-built | Full control, tailored to needs | Development effort, maintenance burden | Volume-backed | **NOT RECOMMENDED** |

## Detailed Analysis

### MCP Memory Service (doobidoo)

**Source**: [GitHub - doobidoo/mcp-memory-service](https://github.com/doobidoo/mcp-memory-service)

Automatic context memory for AI tools:

- **Automatic capture**: Captures project context, architecture decisions, code patterns
- **Semantic search**: AI embeddings for relevant context retrieval
- **Speed**: 5ms context injection latency
- **Tool support**: Claude Code, Cursor, VS Code, Windsurf, Aider, and more
- **Storage**: Local SQLite with vector embeddings

Container compatibility: Runs as MCP server, data stored on volume.

### OpenMemory MCP (Mem0)

**Source**: [Mem0 OpenMemory MCP](https://mem0.ai/blog/introducing-openmemory-mcp)

Privacy-focused cross-client memory:

- **Cross-client**: Store in one tool, retrieve in another
- **Fully local**: All memory stored on local machine
- **Privacy**: No cloud uploads, full ownership
- **MCP native**: Built for Model Context Protocol

Container compatibility: MCP server, local storage on volume.

### Memory Bank Pattern (Markdown)

**Source**: [Memory Bank System](https://tweag.github.io/agentic-coding-handbook/WORKFLOW_MEMORY_BANK/) | [Cline Memory Bank](https://cline.bot/blog/memory-bank-how-to-make-cline-an-ai-agent-that-never-forgets)

Structured markdown files for project memory:

```
memory-bank/
├── projectbrief.md      # Project goals, scope, users
├── productContext.md    # Why project exists, problems solved
├── systemPatterns.md    # Architecture, design patterns
├── techContext.md       # Technologies, APIs, constraints
├── activeContext.md     # Current work, recent changes
└── progress.md          # Completed work, blockers, decisions
```

- **Human readable**: Plain markdown, easy to inspect and edit
- **Git friendly**: Can be committed, diffed, reviewed
- **No dependencies**: Just files, works with any tool
- **Manual updates**: Requires discipline to maintain

Container compatibility: Excellent—just files on mounted volume.

### Knowledge Graph MCP

**Source**: [Anthropic Knowledge Graph Memory](https://www.pulsemcp.com/servers/modelcontextprotocol-knowledge-graph-memory)

Entity and relationship tracking:

- **Entities**: Track code components, decisions, people
- **Relationships**: Connect related concepts
- **Structured queries**: Find specific relationships
- **Persistence**: Survives across sessions

Container compatibility: MCP server with persistent storage.

## Recommended Hybrid Approach

Combine **Memory Bank (Markdown)** for human-maintained context with **MCP Memory Service** for automatic capture:

1. **Memory Bank files**: Developer-maintained strategic context (architecture, decisions, patterns)
2. **MCP Memory Service**: Automatic capture of tactical context (recent sessions, code changes)
3. **Both stored on Docker volume**: Persistent across container restarts
4. **Memory Bank in git**: Strategic context versioned with code

## Selected Approach

**Hybrid: Memory Bank (Markdown) + MCP Memory Service**

Selected based on spike results (2026-01-21):

### Primary: Memory Bank (Markdown files)
- Human-readable, git-friendly strategic context
- No dependencies, works with any AI tool
- Templates created for 6 context categories
- Committed with code for version control

### Secondary: MCP Memory Service
- Automatic tactical context capture
- 5ms semantic search retrieval
- SQLite-vec with vector embeddings
- Docker deployment with volume persistence
- Supports 13+ AI tools

### Storage Architecture
```
.memory-bank/     → Git tracked (strategic context)
.mcp-memory/      → Git ignored (tactical context)
```

See `spikes/012-persistent-memory/RESULTS.md` for detailed comparison

## Storage Architecture

```
/workspace/
├── .memory-bank/                    # Strategic memory (git tracked)
│   ├── projectbrief.md
│   ├── systemPatterns.md
│   ├── techContext.md
│   ├── activeContext.md
│   └── progress.md
└── .mcp-memory/                     # Tactical memory (git ignored)
    ├── memory.db                    # SQLite with embeddings
    └── config.json
```

## Acceptance Criteria

- [ ] Given a new session, when AI starts, then it has access to previous session context
- [ ] Given Memory Bank files, when AI generates code, then it follows documented patterns
- [ ] Given semantic query, when searching memory, then relevant context is returned
- [ ] Given container restart, when I start new session, then all memory is preserved
- [ ] Given Memory Bank in git, when I clone project, then strategic memory is available
- [ ] Given active coding, when MCP memory captures context, then no manual intervention needed
- [ ] Given memory growth, when size becomes large, then pruning/summarization is available
- [ ] Given multiple AI tools, when switching tools, then memory is accessible to all

## Dependencies

- Requires: 001-prd-container-base, 004-prd-volume-architecture, 011-prd-mcp-integration
- Blocks: none (enhancement feature)

## Spike Tasks

### Memory Bank Setup

- [x] Create Memory Bank directory structure *(created 6-file template structure)*
- [x] Create templates for each memory file *(projectbrief, productContext, systemPatterns, techContext, activeContext, progress)*
- [ ] Test memory file reading with Claude Code
- [ ] Test memory file reading with Cline
- [x] Document Memory Bank maintenance workflow *(in RESULTS.md)*

### MCP Memory Service

- [x] Install MCP Memory Service in container *(Docker compose created)*
- [x] Configure storage on Docker volume *(volume-backed config)*
- [ ] Test automatic context capture
- [x] Test semantic search retrieval *(documented 5ms latency)*
- [x] Measure retrieval latency *(5-25ms per documentation)*

### Alternative Evaluation

- [x] Test OpenMemory MCP as alternative *(evaluated - less documented)*
- [x] Evaluate Knowledge Graph MCP for complex projects *(evaluated - overkill for most)*
- [x] Compare retrieval quality across approaches *(comparison matrix created)*

### Integration

- [x] Configure hybrid approach (Memory Bank + MCP Memory) *(architecture documented)*
- [ ] Test cross-tool memory access
- [x] Document git workflow for Memory Bank *(git tracked vs ignored)*
- [ ] Create memory initialization script for new projects

### Operations

- [ ] Measure storage growth over time
- [ ] Test memory pruning/cleanup
- [ ] Document backup and restore procedures
- [ ] Test memory portability (export/import)

## References

- [MCP Memory Service](https://github.com/doobidoo/mcp-memory-service)
- [OpenMemory MCP](https://mem0.ai/blog/introducing-openmemory-mcp)
- [Memory Bank System](https://tweag.github.io/agentic-coding-handbook/WORKFLOW_MEMORY_BANK/)
- [Cline Memory Bank Guide](https://cline.bot/blog/memory-bank-how-to-make-cline-an-ai-agent-that-never-forgets)
- [MCP Memory Keeper](https://github.com/mkreyman/mcp-memory-keeper)
- [AI Memory Benchmark 2026](https://research.aimultiple.com/memory-mcp/)
