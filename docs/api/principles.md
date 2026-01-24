# API Design Principles

> Interface design conventions, endpoint patterns, and error response formats.
> AI agents: follow these principles when creating or modifying API endpoints.

## REST Conventions

This project follows RESTful design principles for any HTTP APIs:

- **Resource-oriented URLs**: Use nouns, not verbs (`/users`, not `/getUsers`)
- **HTTP methods**: GET (read), POST (create), PUT (replace), PATCH (partial update), DELETE (remove)
- **Plural resource names**: `/containers`, `/features`, `/decisions`
- **Nested resources for relationships**: `/features/{id}/tasks`

## Endpoint Naming

- Use kebab-case for multi-word resources: `/decision-records`
- Version APIs in the URL path: `/api/v1/resource`
- Use query parameters for filtering: `/decisions?status=accepted`
- Avoid deep nesting (max 2 levels): `/features/{id}/tasks` not `/projects/{id}/features/{id}/tasks/{id}/comments`

## Request/Response Format

- Content-Type: `application/json` for all API requests and responses
- Use camelCase for JSON field names
- Include `id` field in all response objects
- Use ISO 8601 for dates: `2026-01-23T10:30:00Z`

## Error Responses

Standard error response format:

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Decision record 042 not found",
    "details": {}
  }
}
```

HTTP status codes:
- `400` Bad Request — invalid input
- `401` Unauthorized — missing or invalid authentication
- `403` Forbidden — insufficient permissions
- `404` Not Found — resource does not exist
- `409` Conflict — state conflict (e.g., duplicate)
- `422` Unprocessable Entity — validation failure
- `500` Internal Server Error — unexpected failure

## CLI Interface Conventions

For command-line tools in this project:

- Use `--long-flags` (GNU style) with `-s` short alternatives
- Support `--help` and `--version` on all commands
- Output to stdout for data, stderr for errors and progress
- Exit code 0 for success, 1 for runtime errors, 2 for usage errors
- Support `--json` flag for machine-readable output where applicable
- Use `--quiet` / `-q` to suppress non-essential output

## Authentication Patterns

- API keys passed via `Authorization: Bearer <token>` header
- Never pass credentials in URL query parameters
- Tokens should have minimal required scope
- See [`security/authentication.md`](../security/authentication.md) for detailed patterns
