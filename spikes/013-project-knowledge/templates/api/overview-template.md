# API Overview

<!--
AI Agent Instructions:
- This document describes API design principles and conventions
- Follow these patterns when creating new endpoints
- Check endpoints.md for specific endpoint documentation
- Validate changes against these standards
-->

## API Information

| Property | Value |
|----------|-------|
| **Base URL** | `https://api.example.com/v1` |
| **API Version** | v1 |
| **Protocol** | REST / GraphQL / gRPC |
| **Authentication** | Bearer Token / API Key / OAuth 2.0 |
| **Rate Limiting** | [X requests per minute] |

## Design Principles

### 1. RESTful Resource Naming

- Use plural nouns for collections: `/users`, `/orders`
- Use hierarchical paths for relationships: `/users/{id}/orders`
- Use query parameters for filtering: `/users?status=active`
- Use kebab-case for multi-word resources: `/user-profiles`

### 2. HTTP Methods

| Method | Usage | Idempotent | Safe |
|--------|-------|------------|------|
| GET | Retrieve resources | Yes | Yes |
| POST | Create resources | No | No |
| PUT | Replace resources | Yes | No |
| PATCH | Partial update | No | No |
| DELETE | Remove resources | Yes | No |

### 3. Status Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST that creates |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid input |
| 401 | Unauthorized | Missing/invalid authentication |
| 403 | Forbidden | Valid auth but insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Resource state conflict |
| 422 | Unprocessable Entity | Validation errors |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server-side error |

## Request Format

### Headers

```http
Content-Type: application/json
Authorization: Bearer <token>
Accept: application/json
X-Request-ID: <uuid>
```

### Request Body

```json
{
  "data": {
    "attribute1": "value1",
    "attribute2": "value2"
  }
}
```

## Response Format

### Success Response

```json
{
  "data": {
    "id": "123",
    "type": "resource",
    "attributes": {
      "name": "Example"
    }
  },
  "meta": {
    "requestId": "uuid",
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

### Collection Response

```json
{
  "data": [
    { "id": "1", "type": "resource", "attributes": {} },
    { "id": "2", "type": "resource", "attributes": {} }
  ],
  "meta": {
    "requestId": "uuid",
    "pagination": {
      "page": 1,
      "perPage": 20,
      "total": 100,
      "totalPages": 5
    }
  },
  "links": {
    "self": "/resources?page=1",
    "next": "/resources?page=2",
    "prev": null
  }
}
```

### Error Response

```json
{
  "errors": [
    {
      "code": "VALIDATION_ERROR",
      "message": "Email is required",
      "field": "email",
      "details": {}
    }
  ],
  "meta": {
    "requestId": "uuid",
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

## Authentication

### Bearer Token

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### API Key

```http
X-API-Key: your-api-key
```

## Pagination

### Query Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `page` | 1 | Page number |
| `per_page` | 20 | Items per page (max 100) |
| `sort` | `-created_at` | Sort field (prefix `-` for desc) |

### Example

```
GET /users?page=2&per_page=50&sort=-created_at
```

## Filtering

### Query Parameter Conventions

| Pattern | Example | Description |
|---------|---------|-------------|
| Exact match | `?status=active` | Exact value |
| Multiple values | `?status=active,pending` | OR condition |
| Range | `?created_at_gte=2024-01-01` | Greater than or equal |
| Search | `?q=search+term` | Full-text search |

## Versioning

### URL-Based Versioning

```
/v1/users
/v2/users
```

### Version Lifecycle

| Version | Status | Deprecation Date | Sunset Date |
|---------|--------|------------------|-------------|
| v1 | Stable | - | - |
| v2 | Beta | - | - |

## Rate Limiting

### Limits

| Tier | Requests/min | Burst |
|------|--------------|-------|
| Free | 60 | 10 |
| Pro | 600 | 100 |
| Enterprise | 6000 | 1000 |

### Headers

```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1609459200
```

## Error Codes

| Code | Description | Resolution |
|------|-------------|------------|
| `AUTH_REQUIRED` | Authentication required | Provide valid token |
| `AUTH_INVALID` | Invalid authentication | Check token validity |
| `RATE_LIMITED` | Rate limit exceeded | Wait and retry |
| `VALIDATION_ERROR` | Input validation failed | Check error details |
| `NOT_FOUND` | Resource not found | Verify resource ID |
| `INTERNAL_ERROR` | Server error | Contact support |

## Webhooks

### Event Types

| Event | Description | Payload |
|-------|-------------|---------|
| `resource.created` | Resource created | [Schema link] |
| `resource.updated` | Resource updated | [Schema link] |
| `resource.deleted` | Resource deleted | [Schema link] |

### Webhook Payload

```json
{
  "event": "resource.created",
  "timestamp": "2024-01-01T00:00:00Z",
  "data": {
    "id": "123",
    "type": "resource"
  }
}
```

## References

- [Endpoints Documentation](./endpoints.md)
- [Schema Definitions](./schemas/)
- [Authentication Guide](../security/auth.md)
