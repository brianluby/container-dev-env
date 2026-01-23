# Security Guidance for Context Files

## Overview

Context files (AGENTS.md, CLAUDE.md) are committed to git and potentially
visible to anyone with repository access. They must never contain secrets,
credentials, or internal infrastructure details.

## What NOT to Include

- API keys, tokens, or secrets of any kind
- Passwords or authentication credentials
- Internal URLs, IP addresses, or hostnames
- Database connection strings
- Private certificate or key material
- Customer data or PII
- Proprietary algorithm details that shouldn't be public

## What TO Include

- Security patterns and practices (e.g., "use JWT for auth")
- Compliance requirements (e.g., "HIPAA-compliant data handling required")
- Input validation approaches (e.g., "validate all user input at boundaries")
- Authentication flow descriptions (without credentials)
- Data classification levels (e.g., "PII must be encrypted at rest")

## Local Overrides: AGENTS.local.md

For environment-specific details that shouldn't be shared:

1. Create `AGENTS.local.md` in the project root
2. This file is gitignored by default (added to `.gitignore`)
3. Use it for:
   - Local development URLs
   - Personal workflow preferences
   - Team-specific but non-public information

## Pre-Commit Hook Recommendation

Add automated secret scanning to catch accidental inclusion:

### Option A: detect-secrets (Yelp)

```bash
# Install
pip install detect-secrets

# Initialize baseline
detect-secrets scan > .secrets.baseline

# Add to pre-commit config (.pre-commit-config.yaml)
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
        files: '(AGENTS|CLAUDE).*\.md$'
```

### Option B: gitleaks

```bash
# Install
brew install gitleaks  # macOS
# or download from https://github.com/gitleaks/gitleaks

# Add to pre-commit config (.pre-commit-config.yaml)
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

### Option C: Simple grep check (no dependencies)

```bash
# Add to .git/hooks/pre-commit
#!/bin/bash
if git diff --cached --name-only | grep -E '(AGENTS|CLAUDE).*\.md$' | \
   xargs grep -ilE '(api_key|password|secret|token|private_key)' 2>/dev/null; then
  echo "ERROR: Potential secret detected in context file"
  exit 1
fi
```

## Template Security Features

All provided templates include:

1. **HTML comment warnings** in the Security Considerations section:
   ```html
   <!-- WARNING: Do NOT include actual secrets, API keys, passwords, or internal URLs. -->
   ```

2. **Placeholder text** that describes what to document (patterns, not values):
   ```markdown
   - [Authentication and authorization patterns]
   - [Data handling requirements and constraints]
   ```

3. **No examples containing fake secrets** — placeholders never suggest inserting real credentials

## Verification

Run the automated security tests:

```bash
./tests/bats/bin/bats tests/integration/test_security.bats
```

This validates:
- All templates contain security warning comments
- No placeholder text suggests including secrets
