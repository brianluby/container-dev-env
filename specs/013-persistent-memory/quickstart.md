# Quickstart: Persistent Memory for AI Agent Context

## Prerequisites

- Container dev environment running (features 001, 004 complete)
- MCP infrastructure available (feature 011)
- Python 3.11+ available in container

## 1. Initialize Strategic Memory

```bash
# In your project workspace
memory-init

# Creates:
# .memory/goals.md
# .memory/architecture.md
# .memory/patterns.md
# .memory/technology.md
# .memory/status.md
# .memory/.memoryrc
```

## 2. Edit Strategic Memory Files

Fill in at least one file with project context:

```bash
$EDITOR .memory/patterns.md
```

Example content:
```markdown
# Coding Patterns

## Naming Conventions
- Functions: camelCase
- Classes: PascalCase
- Constants: UPPER_SNAKE_CASE

## Error Handling
- Use Result types for recoverable errors
- Log errors with structured JSON format
- Include correlation IDs in all error messages
```

## 3. Verify MCP Server is Running

The memory MCP server starts automatically when an AI tool connects:

```bash
# Check server availability
python -m memory_server --health-check

# Expected output:
# {"status": "healthy", "project_id": "a1b2c3d4e5f6g7h8", "entries": 0}
```

## 4. Use with AI Tools

### Claude Code
Strategic memory is loaded automatically via CLAUDE.md integration.
Tactical memory available through MCP tools (search_memories, store_memory).

### Cline
Configure in `.cline/cline_mcp_settings.json`:
```json
{
  "mcpServers": {
    "memory": {
      "command": "python",
      "args": ["-m", "memory_server"],
      "env": {
        "MEMORY_WORKSPACE": "${workspaceFolder}"
      }
    }
  }
}
```

### Continue
Configure in `continue/config.yaml`:
```yaml
mcpServers:
  - name: memory
    command: python
    args: ["-m", "memory_server"]
```

## 5. Verify Memory Persistence

```bash
# Store a test memory via MCP tool
# (normally done automatically by AI during sessions)

# Restart container
docker restart <container-name>

# Start new AI session — previous context should be available
# Strategic memory: loaded from .memory/ files
# Tactical memory: loaded from SQLite on Docker volume
```

## 6. Manage Tactical Memory

```bash
# View memory stats
# (via MCP tool: get_memory_stats)

# Search memories
# (via MCP tool: search_memories with query)

# Delete specific entry
# (via MCP tool: delete_memory with ID)
```

## 7. Commit Strategic Memory

```bash
# Strategic memory files are version-controlled
git add .memory/
git commit -m "feat(memory): initialize project strategic context"

# Tactical memory is excluded via .memory/.gitignore
```

## Configuration

Edit `.memory/.memoryrc` to customize:

```yaml
retention_days: 30      # Auto-prune entries older than this
max_size_mb: 500        # Hard cap on tactical memory size
excluded_patterns:      # Content patterns to never capture
  - "*.key"
  - "*password*"
  - "*secret*"
  - "*token*"
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| AI doesn't know project context | Strategic memory files empty | Edit `.memory/*.md` files |
| Tactical memory lost on restart | Volume not mounted | Check Docker volume mount |
| MCP server won't start | Python deps missing | Run `pip install memory-server` |
| Slow startup (>2s) | Large tactical DB | Check retention config |
| Cross-project bleed | Wrong workspace env | Verify `MEMORY_WORKSPACE` |
