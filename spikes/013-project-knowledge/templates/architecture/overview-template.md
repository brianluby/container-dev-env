# Architecture Overview

<!--
AI Agent Instructions:
- This document provides the high-level system architecture
- Read this FIRST when understanding the system
- Refer to diagrams for visual understanding
- Check ADRs for decision rationale
-->

## System Summary

| Aspect | Description |
|--------|-------------|
| **Purpose** | [One-line description of what the system does] |
| **Type** | [Web app, CLI tool, Library, Service, Platform] |
| **Primary Users** | [Who uses this system] |
| **Tech Stack** | [Key technologies] |

## Architecture Style

<!--
Describe the overall architectural approach:
- Monolith, Microservices, Serverless, etc.
- Key patterns used (CQRS, Event Sourcing, etc.)
-->

[Describe the architecture style and why it was chosen]

## System Context

<!--
External systems and actors that interact with this system
-->

```mermaid
graph TB
    subgraph External
        User[Users]
        ExtAPI[External APIs]
        CI[CI/CD System]
    end

    subgraph System [Your System]
        App[Application]
    end

    User --> App
    App --> ExtAPI
    CI --> App
```

### External Dependencies

| System | Purpose | Protocol | Notes |
|--------|---------|----------|-------|
| [External System 1] | [Purpose] | [HTTP/gRPC/etc] | [Notes] |
| [External System 2] | [Purpose] | [Protocol] | [Notes] |

## Container Diagram

<!--
Major deployable units / containers in the system
-->

```mermaid
graph TB
    subgraph System
        Web[Web Frontend]
        API[API Server]
        Worker[Background Workers]
        DB[(Database)]
        Cache[(Cache)]
        Queue[Message Queue]
    end

    Web --> API
    API --> DB
    API --> Cache
    API --> Queue
    Worker --> Queue
    Worker --> DB
```

### Container Descriptions

| Container | Technology | Purpose | Scaling |
|-----------|------------|---------|---------|
| [Container 1] | [Tech] | [Purpose] | [Horizontal/Vertical/None] |
| [Container 2] | [Tech] | [Purpose] | [Scaling approach] |

## Component Structure

<!--
Internal structure of key containers
-->

### [Main Container Name]

```mermaid
graph TB
    subgraph Container [API Server]
        Routes[Route Handlers]
        Services[Business Services]
        Repos[Repositories]
        Models[Domain Models]
    end

    Routes --> Services
    Services --> Repos
    Services --> Models
    Repos --> Models
```

## Data Architecture

### Data Stores

| Store | Type | Purpose | Retention |
|-------|------|---------|-----------|
| [Store 1] | [PostgreSQL/Redis/etc] | [Purpose] | [Retention policy] |

### Data Flow

```mermaid
flowchart LR
    Input[Input] --> Validate[Validation]
    Validate --> Process[Processing]
    Process --> Store[Storage]
    Store --> Output[Output]
```

## Key Patterns

<!--
Important patterns used throughout the codebase
-->

### [Pattern 1 Name]

**Where Used**: [Components/modules]

**Description**: [How the pattern is implemented]

**Example**:
```
[Code example or reference to file]
```

### [Pattern 2 Name]

**Where Used**: [Components/modules]

**Description**: [How the pattern is implemented]

## Security Architecture

<!--
High-level security considerations
See security/ docs for details
-->

- **Authentication**: [Method used]
- **Authorization**: [Approach]
- **Data Protection**: [Encryption, etc.]
- **Network Security**: [Firewalls, VPCs, etc.]

## Deployment Architecture

<!--
How the system is deployed
-->

```mermaid
graph TB
    subgraph Production
        LB[Load Balancer]
        App1[App Instance 1]
        App2[App Instance 2]
        DB[(Database)]
    end

    LB --> App1
    LB --> App2
    App1 --> DB
    App2 --> DB
```

### Environments

| Environment | Purpose | URL | Notes |
|-------------|---------|-----|-------|
| Development | Local dev | localhost | [Notes] |
| Staging | Pre-prod testing | [URL] | [Notes] |
| Production | Live system | [URL] | [Notes] |

## Cross-Cutting Concerns

### Logging

- **Format**: [Structured JSON, etc.]
- **Levels**: [DEBUG, INFO, WARN, ERROR]
- **Destination**: [stdout, file, service]

### Monitoring

- **Metrics**: [What is measured]
- **Alerting**: [Alert conditions]
- **Dashboards**: [Where to find them]

### Error Handling

- **Strategy**: [How errors are handled]
- **Recovery**: [Retry policies, circuit breakers]

## Related Documentation

- [ADRs](./decisions/) - Architecture decisions
- [API Documentation](../api/overview.md) - API details
- [Domain Model](../domain/model.md) - Business logic
- [Operations](../operations/) - Runbooks and procedures

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| YYYY-MM-DD | @author | Initial version |
