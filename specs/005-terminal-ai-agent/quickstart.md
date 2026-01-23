# Quickstart: Terminal AI Agent

**Date**: 2026-01-22
**Feature**: 005-terminal-ai-agent

## Prerequisites

1. Container built from the dev environment image (includes OpenCode binary)
2. At least one LLM API key configured via 003-secret-injection
3. A git-initialized project directory

## First Run

### 1. Verify Installation

```bash
opencode --version
# Expected: opencode v0.1.0 (or later pinned version from Dockerfile ARG OPENCODE_VERSION)
```

### 2. Configure Your Provider

Set your API key via 003-secret-injection (encrypted, loaded at container start):

```bash
# Verify key is available
echo "Provider key configured: $(test -n "${OPENAI_API_KEY:-}" && echo 'OpenAI' || echo 'not set')"
echo "Provider key configured: $(test -n "${ANTHROPIC_API_KEY:-}" && echo 'Anthropic' || echo 'not set')"
```

Optionally set provider/model preference:

```bash
export OPENCODE_PROVIDER=openai
export OPENCODE_MODEL=gpt-4o
```

Or edit `~/.config/opencode/config.yaml`:

```yaml
provider: openai
model: gpt-4o
```

### 3. Start the Agent

```bash
cd /path/to/your/project
opencode
```

The TUI launches. You can now type natural language prompts.

## Common Workflows

### Generate Code

```
> Add a function to parse JSON from a file and return a typed struct
```

The agent reads your project, generates code, and shows a diff. Approve to apply + auto-commit.

### Ask About Your Code

```
> What does the main function do?
> How is error handling structured in this project?
```

The agent searches project files and responds with context-aware answers.

### Multi-File Changes

```
> Refactor the logging module to use structured JSON output across all services
```

Multiple files are modified in a single atomic commit.

### Run Tests (with approval)

```
> Run the test suite and fix any failures
```

The agent proposes `cargo test` (or equivalent) — you approve before execution.

### One-Shot Mode

```bash
opencode "add a health check endpoint to the API server"
```

Runs a single prompt without entering the TUI.

## Agent Modes

Switch between modes for safety:

- **build** (default): Full read/write access. Use for active development.
- **plan**: Read-only. Use for analysis without risk of modifying files.

## Session Management

Sessions persist automatically. On next start, you can resume a previous conversation:

```bash
opencode
# Select from previous sessions or start new
```

## Viewing Costs

After each operation, token usage and approximate cost are displayed:

```
Tokens: 1,234 input / 567 output
Estimated cost: $0.02
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| "No API key found" | Secrets not loaded | Run 003-secret-injection setup |
| Agent hangs on start | Network issue to LLM API | Check outbound HTTPS connectivity |
| "File conflict detected" | File edited externally during session | Re-request the change |
| Timeout error | LLM API slow | Retry happens automatically (1x); check provider status |
| Wrong language output | Project type not detected | Ensure project has language-specific files (Cargo.toml, package.json, etc.) |

## Alternative: Using Aider Instead

If you prefer Aider (not pre-installed), self-install:

```bash
# Python is available in the base image
pip install aider-install && aider-install
aider --model gpt-4o
```

See [Aider docs](https://aider.chat/docs/) for usage. Key differences:
- Better git integration (conventional commits, `/undo` command)
- Voice coding support
- Requires Python runtime (already in base image)
