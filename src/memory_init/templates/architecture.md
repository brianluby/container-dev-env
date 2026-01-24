# Architecture

<!-- WARNING: Do not store API keys, tokens, passwords, or other credentials in this file -->

This file documents system design decisions, component relationships,
and architectural patterns used in the project.

## System Overview

<!-- High-level description of the system architecture -->
<!-- Example: Microservices architecture with API gateway, three backend services, and shared PostgreSQL -->

## Components

<!-- List major components and their responsibilities -->
<!-- Example: auth-service - handles user authentication and JWT issuance -->
<!-- Example: data-service - manages CRUD operations for core domain entities -->

## Data Flow

<!-- How data moves through the system -->
<!-- Example: Client -> API Gateway -> Auth middleware -> Service -> Database -->

## Key Decisions

<!-- Important architectural decisions and their rationale -->
<!-- Example: Chose SQLite over PostgreSQL because single-user deployment, no concurrent writes needed -->
<!-- Example: Event-driven over request-response for inter-service communication to decouple services -->

## Boundaries

<!-- System boundaries, interfaces, and integration points -->
<!-- Example: External API consumed: Stripe for payments (webhook-based) -->
