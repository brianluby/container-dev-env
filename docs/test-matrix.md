# Manual Test Matrix: Context File Recognition

## Purpose

Verify that AGENTS.md is recognized and followed by AI coding tools.
Run these checks after creating or modifying context files.

## Test Procedure

For each tool, perform the following steps:

1. Ensure AGENTS.md exists at project root with filled-in content
2. Start a new session in the tool (fresh context)
3. Ask: "What are this project's coding conventions?"
4. Verify the response references content from AGENTS.md

## Tool Verification Checklist

### Claude Code

- [ ] Start new session with `claude` command in project root
- [ ] Ask about project conventions
- [ ] Verify response references AGENTS.md content (tech stack, coding standards)
- [ ] Verify CLAUDE.md supplement is also loaded (if present)
- [ ] Test nested: navigate to subdirectory, ask about local conventions

### Cline (VS Code Extension)

- [ ] Open project in VS Code with Cline extension
- [ ] Start new Cline chat
- [ ] Ask about project conventions
- [ ] Verify response references AGENTS.md content
- [ ] Verify .clinerules supplement loaded (if present)

### Continue (VS Code/JetBrains Extension)

- [ ] Open project in IDE with Continue extension
- [ ] Start new Continue chat
- [ ] Ask about project conventions
- [ ] Verify response references AGENTS.md content
- [ ] Verify .continuerules supplement loaded (if present)

### Roo-Code

- [ ] Open project with Roo-Code
- [ ] Start new session
- [ ] Ask about project conventions
- [ ] Verify response references AGENTS.md content

### OpenCode (Terminal)

- [ ] Start OpenCode in project directory
- [ ] Ask about project conventions
- [ ] Verify response references AGENTS.md content

## Pass Criteria

- **Minimum**: At least Claude Code recognizes and references AGENTS.md
- **Target**: 3+ tools recognize AGENTS.md without modification
- **Ideal**: All listed tools recognize AGENTS.md

## Failure Troubleshooting

If a tool does not recognize AGENTS.md:

1. Verify filename is exactly `AGENTS.md` (case-sensitive)
2. Verify file is at project root (not in a subdirectory)
3. Start a completely new session (not just a new message)
4. Check tool version — older versions may not support AGENTS.md
5. Check tool documentation for supported context file locations

## Notes

- Results should be recorded with tool version numbers
- Re-run after major tool updates
- File format compliance (UTF-8, LF, <10KB) is tested automatically via BATS
