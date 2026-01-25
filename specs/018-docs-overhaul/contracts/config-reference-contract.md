# Contract: Configuration Reference

This contract defines the required structure for the configuration reference (FR-010 / SC-007).

## Scope

- Every user-configurable setting exposed by the project must be documented.
- Settings must be grouped by feature/subsystem.

## Per-setting schema

For each setting, document:

- Name / key
- Where it is configured (file, environment variable, tool)
- Type (string/bool/int/list/object)
- Default value
- Allowed values / constraints
- Security notes (if sensitive)
- Example

## Security notes

- Do not include real secrets.
- Use `.env.example` style placeholders where appropriate.
