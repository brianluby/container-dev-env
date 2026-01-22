# AI Tool Context File Compatibility

This document details how various AI coding tools recognize and use project context files.

## Quick Reference Matrix

| Tool | Primary File | Fallback | Nested Support | Notes |
|------|-------------|----------|----------------|-------|
| Claude Code | CLAUDE.md | AGENTS.md | Yes | Reads both if present |
| Cline | .clinerules/ | AGENTS.md | Yes (via folder) | Folder with numbered .md files |
| Roo-Code | .roo/rules.md | AGENTS.md | Yes | .roo directory structure |
| Continue | .continue/config.json | - | Via config | JSON-based configuration |
| Cursor | .cursor/rules | .cursorrules | Limited | Moving to project rules UI |
| Windsurf | .windsurfrules | AGENTS.md | No | Single file |
| GitHub Copilot | .github/copilot-instructions.md | - | No | Single file |
| Aider | .aider.conf.yml | CONVENTIONS.md | No | YAML config + conventions |
| OpenCode | AGENTS.md | - | Yes | Full AGENTS.md support |

## Detailed Tool Documentation

---

### Claude Code (Anthropic)

**Primary context file**: `CLAUDE.md`

**File locations** (in order of precedence):
1. `~/.claude/CLAUDE.md` - Global user preferences
2. `PROJECT_ROOT/CLAUDE.md` - Project-specific context

**Nested file support**: Yes
- Claude Code reads AGENTS.md files at all levels
- Closest file to the edited file takes precedence

**How it reads context**:
- Loaded automatically when starting a session
- Re-read when navigating to different directories
- Combined with conversation context

**Special features**:
- Supports Claude-specific tool preferences (Task, Bash, Edit)
- Can specify agent selection preferences
- Hooks configuration documentation

**Example structure**:
```
project/
├── CLAUDE.md           # Project context
├── src/
│   └── AGENTS.md       # Module context (also read)
└── tests/
    └── AGENTS.md       # Test context
```

**Documentation**: https://docs.anthropic.com/en/docs/claude-code

---

### Cline (VS Code Extension)

**Primary context file**: `.clinerules/` directory

**File structure**:
```
.clinerules/
├── 01-general.md
├── 02-coding-standards.md
├── 03-testing.md
└── ...
```

**Fallback**: Reads `AGENTS.md` if `.clinerules/` doesn't exist

**Numbered file ordering**:
- Files processed in alphanumeric order
- Use `01-`, `02-` prefixes for explicit ordering
- All files combined into single context

**Nested support**: Via folder structure
- Can have `.clinerules/` in subdirectories
- Directory-specific rules apply when working in that directory

**How it reads context**:
- Scans on workspace load
- Watches for file changes
- Applies rules based on active file location

**Special features**:
- Supports multiple numbered files for organization
- Can reference external files via markdown links
- Memory Bank integration for persistent context

**Example**:
```
.clinerules/
├── 01-project-overview.md
├── 02-tech-stack.md
├── 03-coding-standards.md
├── 04-testing-requirements.md
└── 05-security-rules.md
```

**Documentation**: https://github.com/cline/cline

---

### Roo-Code (VS Code Extension)

**Primary context file**: `.roo/rules.md`

**File structure**:
```
.roo/
├── rules.md           # Main rules file
└── context/           # Additional context files
    ├── architecture.md
    └── patterns.md
```

**Fallback**: Reads `AGENTS.md`

**Nested support**: Yes, through `.roo/` directories

**How it reads context**:
- Loads from `.roo/` directory on startup
- Can specify additional context paths
- Supports dynamic context injection

**Special features**:
- Memory system for persistent learnings
- Can specify tool-specific behaviors
- Supports project vs workspace scope

**Documentation**: https://roo.app/docs

---

### Continue (VS Code/JetBrains)

**Primary context file**: `.continue/config.json`

**Configuration approach**:
```json
{
  "customCommands": [...],
  "contextProviders": [
    {
      "name": "file",
      "params": {
        "path": "AGENTS.md"
      }
    }
  ],
  "models": [...],
  "systemMessage": "Custom system prompt..."
}
```

**Fallback**: No automatic fallback (config-driven)

**Nested support**: Via context provider configuration

**How it reads context**:
- Configuration loaded from `.continue/config.json`
- Context providers can be configured to read any file
- Dynamic context based on configuration

**Special features**:
- Highly configurable via JSON
- Multiple context providers (file, codebase, docs)
- Custom commands and prompt templates

**Manual AGENTS.md setup**:
```json
{
  "contextProviders": [
    {
      "name": "file",
      "params": {
        "path": "AGENTS.md"
      }
    }
  ]
}
```

**Documentation**: https://continue.dev/docs

---

### Cursor

**Primary context file**: `.cursor/rules` (directory) or project rules (UI)

**Legacy support**: `.cursorrules` (deprecated)

**Configuration methods**:
1. **Project Rules (Recommended)**: Settings → Cursor Settings → Rules
2. **File-based**: `.cursor/rules/` directory
3. **Legacy**: `.cursorrules` file (still works but deprecated)

**File structure (new)**:
```
.cursor/
└── rules/
    ├── general.mdc
    └── testing.mdc
```

**Nested support**: Limited
- Directory-based rules in `.cursor/rules/`
- No automatic nested file discovery

**How it reads context**:
- Project rules UI takes precedence
- Falls back to file-based configuration
- Rules combined from all sources

**Special features**:
- AI-generated rules suggestions
- Rule categories and organization
- Integration with Cursor's composer

**Migration from .cursorrules**:
```bash
# Move content to new location
mkdir -p .cursor/rules
mv .cursorrules .cursor/rules/main.mdc
```

**Documentation**: https://cursor.com/docs/context/rules

---

### Windsurf (Codeium)

**Primary context file**: `.windsurfrules`

**Format**: Single markdown file at project root

**Fallback**: Reads `AGENTS.md` if `.windsurfrules` doesn't exist

**Nested support**: No

**How it reads context**:
- Loaded on workspace open
- Single file per project
- Combined with built-in knowledge

**Special features**:
- Cascade AI integration
- Flow awareness for context
- Optimized for Windsurf's AI features

**Example structure**:
```
project/
└── .windsurfrules    # Single file
```

**Documentation**: https://codeium.com/windsurf

---

### GitHub Copilot

**Primary context file**: `.github/copilot-instructions.md`

**Format**: Single markdown file

**Location**: Must be in `.github/` directory

**Nested support**: No

**How it reads context**:
- Loaded per repository
- Applied to all Copilot interactions
- Organization-level files also supported

**Special features**:
- Organization-wide instructions possible
- Integration with GitHub's context
- Works across all Copilot surfaces

**Example**:
```
.github/
└── copilot-instructions.md
```

**Documentation**: https://docs.github.com/en/copilot/customizing-copilot

---

### Aider

**Primary context file**: `.aider.conf.yml` + conventions files

**Configuration**:
```yaml
# .aider.conf.yml
model: claude-3-5-sonnet
auto-commits: true
conventions: true  # Enable CONVENTIONS.md reading
```

**Conventions file**: `CONVENTIONS.md`

**Fallback**: None (explicit configuration)

**Nested support**: No

**How it reads context**:
- Config loaded on startup
- CONVENTIONS.md read if conventions enabled
- Can reference additional files via `/add`

**Special features**:
- Git-aware context
- Automatic commits
- Voice mode
- Web interface

**Documentation**: https://aider.chat/docs

---

### OpenCode

**Primary context file**: `AGENTS.md`

**Full AGENTS.md support**: Yes

**Nested support**: Yes
- Reads AGENTS.md at all directory levels
- Closest file takes precedence

**How it reads context**:
- Automatic discovery of AGENTS.md files
- Merged context from nested files
- Real-time updates on file changes

**Special features**:
- MCP (Model Context Protocol) support
- Multiple provider support
- Full AGENTS.md specification compliance

**Documentation**: https://github.com/opencode-ai/opencode

---

## Recommended Strategy

### For Maximum Compatibility

1. **Create AGENTS.md** at project root (works with most tools)
2. **Add tool-specific files** only when needed:
   - `CLAUDE.md` for Claude Code specific instructions
   - `.clinerules/` if team uses Cline extensively
   - `.github/copilot-instructions.md` for Copilot users

### File Priority Strategy

```
project/
├── AGENTS.md                           # Primary (all tools)
├── CLAUDE.md                           # Claude Code specific
├── .clinerules/                        # Cline specific
│   └── 01-standards.md
├── .cursor/rules/                      # Cursor specific
│   └── main.mdc
├── .github/
│   └── copilot-instructions.md         # Copilot specific
└── .windsurfrules                      # Windsurf specific
```

### Content Duplication Strategy

**Option A: Symlinks** (Unix-like systems)
```bash
ln -s AGENTS.md .windsurfrules
ln -s AGENTS.md .github/copilot-instructions.md
```

**Option B: Script synchronization**
```bash
#!/bin/bash
# sync-context.sh
cp AGENTS.md .windsurfrules
cp AGENTS.md .github/copilot-instructions.md
```

**Option C: Single source of truth**
- Maintain only AGENTS.md
- Let tools fall back to it
- Accept minor incompatibilities

---

## Testing Tool Recognition

### Verification Checklist

1. **Create AGENTS.md** with distinctive content
2. **Start AI tool** in project directory
3. **Ask**: "What are the coding standards for this project?"
4. **Verify**: Response includes content from AGENTS.md

### Quick Test Prompt

Add this to your AGENTS.md and test:
```markdown
## Testing Note
When asked about testing, always mention "pytest is the standard."
```

Then ask: "How should I test this project?"

If the response mentions pytest, the file was read.

---

## References

- [AGENTS.md Specification](https://agents.md/)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Cline GitHub](https://github.com/cline/cline)
- [Continue Documentation](https://continue.dev/docs)
- [Cursor Rules Documentation](https://cursor.com/docs/context/rules)
- [GitHub Copilot Instructions](https://docs.github.com/en/copilot/customizing-copilot)
- [Aider Documentation](https://aider.chat/docs)
