# Spec-Driven Development Pipeline

## Overview

A parallelized, AI-agent-assisted pipeline for turning a product roadmap into implemented features. Each layer operates independently, enabling concurrent progress across multiple features.

## Process Layers

| Layer | Input | Output | Tool/Method |
|-------|-------|--------|-------------|
| 1. Product Roadmap | Vision, themes | Prioritized feature list | Manual / strategic planning |
| 2. Feature Decomposition | Roadmap themes | Discrete features (branches) | Manual breakdown |
| 3. PRD Creation | Feature definition | Product Requirements Document | MoSCoW prioritization + Feature Spikes |
| 4. Specification | PRD | Testable spec (`spec.md`) | `/speckit.specify` |
| 5. Agent Iteration | Draft spec | Refined spec, plan, tasks | `/speckit.clarify` → `/speckit.plan` → `/speckit.tasks` |
| 6. Implementation | Tasks | Working code | `/speckit.implement` |

## Detailed Layer Descriptions

### 1. Product Roadmap

Define high-level product vision, themes, and feature priorities. This is the strategic input that drives all downstream work.

### 2. Feature Decomposition

Break roadmap themes into discrete, implementable features. Each feature gets its own branch (e.g., `005-terminal-ai-agent`) and directory under `specs/`.

### 3. PRD Creation

For each feature, produce a Product Requirements Document:

- **MoSCoW Prioritization**: Classify requirements as Must/Should/Could/Won't
- **Feature Spikes**: Exploratory research to de-risk unknowns before committing to a spec

### 4. Specification (Speckit)

Transform PRDs into detailed, testable specifications via the speckit workflow:

1. `/speckit.specify` — Generate initial spec from PRD/description
2. `/speckit.clarify` — Identify and resolve ambiguities (up to 5 targeted questions)
3. `/speckit.plan` — Create implementation plan with architectural decisions
4. `/speckit.tasks` — Generate dependency-ordered, actionable task list

### 5. AI Agent Iteration

Agents refine specs through clarification loops, plan reviews, and task generation. Each step can feed back into the previous one if issues are discovered.

### 6. Implementation

Execute tasks from the finalized spec. Sub-agents handle independent workstreams concurrently.

## Parallelization Model

### Horizontal Parallelism

Multiple features progress through the pipeline concurrently on separate branches. Feature A can be in implementation while Feature B is still in clarification.

### Vertical Parallelism

Within each feature, agents parallelize sub-work:

- Multiple clarification questions researched concurrently
- Independent tasks executed in parallel during implementation
- Plan validation and task generation can overlap where dependencies allow

### Agent Fan-Out

A coordinating agent can spawn sub-agents for independent workstreams, maximizing throughput at each layer.

## Pipeline Diagram

```mermaid
graph TD
    subgraph "Strategic Layer"
        R[Product Roadmap]
    end

    subgraph "Decomposition Layer"
        R --> F1[Feature A]
        R --> F2[Feature B]
        R --> F3[Feature N...]
    end

    subgraph "PRD Layer (parallel)"
        F1 --> PRD1[PRD A<br/>MoSCoW + Spike]
        F2 --> PRD2[PRD B<br/>MoSCoW + Spike]
        F3 --> PRD3[PRD N<br/>MoSCoW + Spike]
    end

    subgraph "Speckit Layer (parallel)"
        PRD1 --> S1[/speckit.specify/]
        PRD2 --> S2[/speckit.specify/]
        PRD3 --> S3[/speckit.specify/]
    end

    subgraph "Agent Iteration Layer (parallel agents)"
        S1 --> C1[/speckit.clarify/]
        S2 --> C2[/speckit.clarify/]
        S3 --> C3[/speckit.clarify/]

        C1 --> P1[/speckit.plan/]
        C2 --> P2[/speckit.plan/]
        C3 --> P3[/speckit.plan/]

        P1 --> T1[/speckit.tasks/]
        P2 --> T2[/speckit.tasks/]
        P3 --> T3[/speckit.tasks/]
    end

    subgraph "Implementation Layer (parallel sub-agents)"
        T1 --> I1[/speckit.implement/<br/>Sub-agents]
        T2 --> I2[/speckit.implement/<br/>Sub-agents]
        T3 --> I3[/speckit.implement/<br/>Sub-agents]
    end

    %% Feedback loops
    C1 -.->|refine| S1
    P1 -.->|rework| C1
    I1 -.->|issues| T1
```

## Feedback Loops

The pipeline is not strictly linear. At each layer, issues can trigger rework:

- **Clarify → Specify**: Ambiguities reveal spec gaps, requiring spec updates
- **Plan → Clarify**: Architectural decisions surface new questions
- **Implement → Tasks**: Implementation blockers require task revision
- **Any layer → PRD**: Fundamental feasibility issues escalate back to requirements

## Key Principles

1. **Parallelism by default** — Never block one feature waiting on another
2. **Specs before code** — Implementation starts only after spec is refined and approved
3. **Agent-assisted, human-approved** — AI agents propose; humans decide
4. **Incremental refinement** — Each pass through the loop adds clarity and reduces risk
5. **Branch isolation** — Each feature lives on its own branch until ready to merge
