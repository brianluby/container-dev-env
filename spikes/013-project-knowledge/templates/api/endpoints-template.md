# API Endpoints

<!--
AI Agent Instructions:
- This document details all API endpoints
- Check authentication requirements before calling
- Use exact request/response formats shown
- Note rate limits and error responses
-->

## Endpoint Summary

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | `/resources` | List resources | Required |
| POST | `/resources` | Create resource | Required |
| GET | `/resources/{id}` | Get resource | Required |
| PUT | `/resources/{id}` | Update resource | Required |
| DELETE | `/resources/{id}` | Delete resource | Required |

---

## Resources

### List Resources

**Endpoint**: `GET /resources`

**Description**: Retrieve a paginated list of resources.

**Authentication**: Required

**Query Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | integer | No | Page number (default: 1) |
| `per_page` | integer | No | Items per page (default: 20, max: 100) |
| `status` | string | No | Filter by status |
| `sort` | string | No | Sort field (default: `-created_at`) |

**Request Example**:

```bash
curl -X GET "https://api.example.com/v1/resources?page=1&per_page=10" \
  -H "Authorization: Bearer <token>" \
  -H "Accept: application/json"
```

**Response** (200 OK):

```json
{
  "data": [
    {
      "id": "res_123",
      "type": "resource",
      "attributes": {
        "name": "Example Resource",
        "status": "active",
        "createdAt": "2024-01-01T00:00:00Z"
      }
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "perPage": 10,
      "total": 50,
      "totalPages": 5
    }
  }
}
```

**Error Responses**:

| Status | Code | Description |
|--------|------|-------------|
| 401 | `AUTH_REQUIRED` | Missing authentication |
| 403 | `FORBIDDEN` | Insufficient permissions |

---

### Create Resource

**Endpoint**: `POST /resources`

**Description**: Create a new resource.

**Authentication**: Required

**Request Body**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Resource name (1-100 chars) |
| `description` | string | No | Description (max 1000 chars) |
| `settings` | object | No | Resource settings |

**Request Example**:

```bash
curl -X POST "https://api.example.com/v1/resources" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Resource",
    "description": "Resource description"
  }'
```

**Response** (201 Created):

```json
{
  "data": {
    "id": "res_456",
    "type": "resource",
    "attributes": {
      "name": "New Resource",
      "description": "Resource description",
      "status": "active",
      "createdAt": "2024-01-01T12:00:00Z"
    }
  }
}
```

**Error Responses**:

| Status | Code | Description |
|--------|------|-------------|
| 400 | `VALIDATION_ERROR` | Invalid input |
| 401 | `AUTH_REQUIRED` | Missing authentication |
| 409 | `CONFLICT` | Resource already exists |

**Validation Errors**:

```json
{
  "errors": [
    {
      "code": "VALIDATION_ERROR",
      "field": "name",
      "message": "Name is required"
    }
  ]
}
```

---

### Get Resource

**Endpoint**: `GET /resources/{id}`

**Description**: Retrieve a single resource by ID.

**Authentication**: Required

**Path Parameters**:

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | Resource ID |

**Request Example**:

```bash
curl -X GET "https://api.example.com/v1/resources/res_123" \
  -H "Authorization: Bearer <token>"
```

**Response** (200 OK):

```json
{
  "data": {
    "id": "res_123",
    "type": "resource",
    "attributes": {
      "name": "Example Resource",
      "description": "Description here",
      "status": "active",
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-02T00:00:00Z"
    },
    "relationships": {
      "owner": {
        "data": { "id": "user_789", "type": "user" }
      }
    }
  }
}
```

**Error Responses**:

| Status | Code | Description |
|--------|------|-------------|
| 401 | `AUTH_REQUIRED` | Missing authentication |
| 404 | `NOT_FOUND` | Resource not found |

---

### Update Resource

**Endpoint**: `PUT /resources/{id}`

**Description**: Update an existing resource.

**Authentication**: Required

**Path Parameters**:

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | Resource ID |

**Request Body**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | No | Resource name |
| `description` | string | No | Description |
| `status` | string | No | Status (active, archived) |

**Request Example**:

```bash
curl -X PUT "https://api.example.com/v1/resources/res_123" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Name",
    "status": "archived"
  }'
```

**Response** (200 OK):

```json
{
  "data": {
    "id": "res_123",
    "type": "resource",
    "attributes": {
      "name": "Updated Name",
      "status": "archived",
      "updatedAt": "2024-01-03T00:00:00Z"
    }
  }
}
```

**Error Responses**:

| Status | Code | Description |
|--------|------|-------------|
| 400 | `VALIDATION_ERROR` | Invalid input |
| 404 | `NOT_FOUND` | Resource not found |
| 409 | `CONFLICT` | State conflict |

---

### Delete Resource

**Endpoint**: `DELETE /resources/{id}`

**Description**: Delete a resource.

**Authentication**: Required

**Path Parameters**:

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | Resource ID |

**Request Example**:

```bash
curl -X DELETE "https://api.example.com/v1/resources/res_123" \
  -H "Authorization: Bearer <token>"
```

**Response** (204 No Content): Empty body

**Error Responses**:

| Status | Code | Description |
|--------|------|-------------|
| 401 | `AUTH_REQUIRED` | Missing authentication |
| 404 | `NOT_FOUND` | Resource not found |
| 409 | `CONFLICT` | Cannot delete (has dependencies) |

---

## Nested Resources

### List Resource Items

**Endpoint**: `GET /resources/{resourceId}/items`

**Description**: List items belonging to a resource.

[Follow same documentation pattern...]

---

## References

- [API Overview](./overview.md) - Design principles
- [Authentication](../security/auth.md) - Auth details
- [Schema Definitions](./schemas/) - Request/response schemas
