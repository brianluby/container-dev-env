# Security Guidance

This page documents security guidance for documentation, context files, and configuration examples.
It focuses on patterns and practices, not sensitive values.

Applies to: `main`

## Prerequisites

- None

## What not to include

- Secrets (tokens, passwords, private keys)
- Internal URLs, IP addresses, or hostnames
- Customer data or PII

## What to include

- Security patterns and practices
- Input validation expectations
- Authentication/authorization flows (without credentials)

## Local-only overrides

Use `AGENTS.local.md` (gitignored) for environment-specific details that should not be committed.

## Related

- [Authentication](security/authentication.md)
- [Secrets Management](../features/secrets-management.md)

## Next steps

- If you are adding configuration examples, use `.env.example` style placeholders
