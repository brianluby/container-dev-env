# Nested AGENTS.md Examples

This document demonstrates how to use nested AGENTS.md files for module-specific context.

## How Nested Files Work

The AGENTS.md spec defines that:
1. **Closest file takes precedence** - When editing `src/api/users.py`, the AI reads `src/api/AGENTS.md` before the root `AGENTS.md`
2. **Files supplement, not replace** - Nested files add context; they don't override the root file
3. **Inheritance is implicit** - All root-level rules still apply unless explicitly contradicted

## Directory Structure Example

```
project/
├── AGENTS.md                    # Root: project-wide context
├── src/
│   ├── api/
│   │   ├── AGENTS.md            # API-specific context
│   │   ├── auth.py
│   │   └── users.py
│   ├── core/
│   │   ├── AGENTS.md            # Core domain context
│   │   └── models.py
│   └── frontend/
│       ├── AGENTS.md            # Frontend-specific context
│       └── components/
│           └── AGENTS.md        # Component-specific context
├── tests/
│   └── AGENTS.md                # Testing context
└── docs/
    └── AGENTS.md                # Documentation context
```

---

## Example: API Module AGENTS.md

**File**: `src/api/AGENTS.md`

```markdown
# API Module Context

This directory contains the REST API layer.

## Responsibilities
- HTTP request/response handling
- Input validation and serialization
- Authentication and authorization middleware
- Rate limiting and request throttling

## Dependencies
- Uses services from `../core/services/`
- Uses models from `../core/models/`
- Should NOT directly access database

## Patterns

### Endpoint Structure
All endpoints follow this pattern:
```python
@router.get("/resource/{id}")
async def get_resource(
    id: int,
    service: ResourceService = Depends(get_resource_service)
) -> ResourceResponse:
    """Get a resource by ID."""
    return await service.get_by_id(id)
```

### Error Handling
Use HTTPException with appropriate status codes:
```python
from fastapi import HTTPException

raise HTTPException(status_code=404, detail="Resource not found")
```

### Validation
Use Pydantic models for all request/response bodies:
```python
class CreateResourceRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: str | None = None
```

## Testing
- API tests live in `tests/api/`
- Use `TestClient` for HTTP tests
- Mock services, not databases

## Anti-Patterns
- Never import from `../infrastructure/` directly
- Never put business logic in endpoint functions
- Never return raw database models
```

---

## Example: Core/Domain Module AGENTS.md

**File**: `src/core/AGENTS.md`

```markdown
# Core Domain Context

This directory contains the business logic and domain models.

## Architecture
This is the innermost layer - it has NO external dependencies.
Only pure Python and standard library imports allowed.

## Responsibilities
- Domain entities and value objects
- Business rules and invariants
- Domain services and use cases

## Patterns

### Entity Definition
```python
@dataclass
class User:
    id: UserId
    email: Email
    name: str
    created_at: datetime

    def can_perform_action(self, action: Action) -> bool:
        """Business rule for action permissions."""
        return self.role.has_permission(action)
```

### Value Objects
Use value objects for validated primitives:
```python
class Email:
    def __init__(self, value: str):
        if not self._is_valid(value):
            raise ValueError(f"Invalid email: {value}")
        self._value = value

    @staticmethod
    def _is_valid(value: str) -> bool:
        return "@" in value and "." in value
```

### Service Definition
```python
class UserService:
    def __init__(self, repository: UserRepository):
        self._repository = repository

    async def register(self, email: Email, name: str) -> User:
        if await self._repository.exists_by_email(email):
            raise UserAlreadyExistsError(email)
        return await self._repository.create(User(...))
```

## Rules
- No framework imports (FastAPI, Django, etc.)
- No database imports (SQLAlchemy, etc.)
- No I/O operations directly - use repository pattern
- All business logic must be testable without mocks

## Testing
- Pure unit tests only
- No database, network, or file I/O
- Test business rules exhaustively
```

---

## Example: Frontend Module AGENTS.md

**File**: `src/frontend/AGENTS.md`

```markdown
# Frontend Context

React frontend application.

## Tech Stack
- React 18 with TypeScript
- React Query for data fetching
- Tailwind CSS for styling
- Vite for build tooling

## Structure
```
frontend/
├── components/         # Reusable UI components
├── features/           # Feature-based modules
├── hooks/              # Custom React hooks
├── pages/              # Route components
├── services/           # API client functions
└── utils/              # Utility functions
```

## Patterns

### Component Structure
```tsx
interface ButtonProps {
  variant?: "primary" | "secondary";
  children: React.ReactNode;
  onClick?: () => void;
}

export function Button({ variant = "primary", children, onClick }: ButtonProps) {
  return (
    <button
      className={cn("btn", variant === "primary" ? "btn-primary" : "btn-secondary")}
      onClick={onClick}
    >
      {children}
    </button>
  );
}
```

### Data Fetching
Always use React Query:
```tsx
function useUsers() {
  return useQuery({
    queryKey: ["users"],
    queryFn: () => api.getUsers(),
  });
}
```

## Rules
- No `any` types - use proper TypeScript
- Components must be pure when possible
- Side effects only in hooks or event handlers
- Use Tailwind - no inline styles or CSS modules
```

---

## Example: Tests Module AGENTS.md

**File**: `tests/AGENTS.md`

```markdown
# Testing Context

## Test Organization
```
tests/
├── unit/               # Pure unit tests (no I/O)
├── integration/        # Tests with real dependencies
├── e2e/                # End-to-end browser tests
├── fixtures/           # Shared test data
└── conftest.py         # pytest configuration
```

## Running Tests

```bash
# All tests
pytest

# Unit tests only (fast)
pytest tests/unit/

# Integration tests
pytest tests/integration/

# With coverage
pytest --cov=src --cov-report=html
```

## Conventions

### Test Naming
```python
def test_{function}_{scenario}_{expected}():
    # Example: test_create_user_with_duplicate_email_raises_error
```

### Test Structure (AAA)
```python
def test_user_creation():
    # Arrange
    email = "test@example.com"
    name = "Test User"

    # Act
    user = create_user(email, name)

    # Assert
    assert user.email == email
    assert user.name == name
```

### Fixtures
Define reusable fixtures in `conftest.py`:
```python
@pytest.fixture
def user():
    return User(id=1, email="test@example.com", name="Test")
```

## Rules
- Tests must be independent - no shared state
- No sleeps or time-based assertions
- Mock external services, not internal modules
- Each test file mirrors a source file
```

---

## When to Create Nested AGENTS.md

Create a nested file when a module has:
1. **Different technology** - Frontend (React) vs Backend (Python)
2. **Different patterns** - API layer vs Domain layer
3. **Specialized rules** - Testing conventions, migration patterns
4. **Complex domain** - Module-specific terminology or business rules
5. **Separate team ownership** - Different coding standards

## When NOT to Create Nested AGENTS.md

Don't create nested files for:
1. **Simple directories** - Just a few files with no special rules
2. **Generated code** - Migrations, compiled output, etc.
3. **Vendor code** - Third-party libraries
4. **Duplication** - If it just repeats the root file
