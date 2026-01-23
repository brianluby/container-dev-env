# Spec-Kit Templates

> **Version:** 3.0  
> **Last Updated:** January 2025  
> **Audience:** LLM agents, human product managers, engineers

A spec-driven development framework for human-AI collaboration. These templates create structured requirements documents that both humans and LLM agents can work with effectively.

---

## What Is This?

Spec-Kit is an approach to product development that puts **specifications first**. Before any code is written, features are fully specified through three interconnected documents:

```
┌─────────────────────────────────────────────────────────────────┐
│                        Product Roadmap                          │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     PRD (What & Why)                            │
│              Product Requirements Document                       │
│         "What problem are we solving? What do we need?"         │
└─────────────────────────────────────────────────────────────────┘
                               │
              ┌────────────────┴────────────────┐
              ▼                                 ▼
┌─────────────────────────┐       ┌─────────────────────────┐
│    ARD (How)            │       │    SEC (Risk)           │
│  Architecture Decision  │       │   Security Review       │
│       Record            │       │   (Lightweight)         │
│ "How will we build it?" │       │ "What could go wrong?"  │
└─────────────────────────┘       └─────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Implementation                            │
│              (Code, Tests, Infrastructure)                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Why Spec-Driven Development?

### For Humans
- **Clarity before commitment** — Forces thinking through requirements before coding
- **Audit trail** — Every decision is documented with rationale
- **Handoff quality** — New team members can understand why things were built a certain way

### For LLM Agents
- **Grounded context** — Agents work from explicit requirements, not inferred intent
- **Clear boundaries** — Scope, constraints, and guardrails are explicit
- **Traceability** — Requirements have IDs that flow through to tests
- **Human checkpoints** — Critical decisions require human confirmation

---

## The Three Documents

### 1. PRD — Product Requirements Document
**Purpose:** Define *what* we're building and *why*

**Key Sections:**
- Problem Statement & User Story
- Requirements (Must/Should/Could/Won't with IDs like M-1, S-2)
- Technical Constraints
- Acceptance Criteria (mapped to requirement IDs)
- Definition of Ready (gate before implementation)

**Filename Convention:** `[NNN]-prd-[slug].md`  
**Example:** `001-prd-user-authentication.md`

---

### 2. ARD — Architecture Decision Record
**Purpose:** Define *how* we're building it and *why this approach*

**Key Sections:**
- Decision Drivers (prioritized, traced to PRD)
- Options Considered (including Option 0: Status Quo)
- Selected Option with Rationale
- Simplest Implementation Comparison (guards against over-engineering)
- Implementation Guardrails (DO NOT / MUST rules for agents)
- Rollback Plan with triggers

**Filename Convention:** `[NNN]-ard-[slug].md`  
**Example:** `001-ard-user-authentication.md`

---

### 3. SEC — Security Review (Lightweight)
**Purpose:** Catch obvious security issues early

**Key Sections:**
- Attack Surface Analysis (what's exposed?)
- Data Inventory (what data, how sensitive?)
- CIA Impact Assessment (confidentiality, integrity, availability)
- Third-Party & Supply Chain risks
- Security Requirements with verification methods

**Filename Convention:** `[NNN]-sec-[slug].md`  
**Example:** `001-sec-user-authentication.md`

---

## Review Tiers

Every section in these templates is marked with a review tier that indicates who is responsible:

| Marker | Tier | Meaning |
|--------|------|---------|
| 🔴 `@human-required` | Human Generated | Human must author this section |
| 🟡 `@human-review` | LLM + Human Review | LLM drafts, human validates and confirms |
| 🟢 `@llm-autonomous` | LLM Autonomous | LLM completes without human review |
| ⚪ `@auto` | Auto-generated | System fills (timestamps, links) |

### Why Tiers Matter

**For humans:** Know exactly where your input is required vs. where you're just reviewing AI work.

**For LLM agents:** Know when to prompt the user, when to draft and wait for confirmation, and when to proceed autonomously.

**For tooling (Speckit):** Tiers become workflow instructions — the tool can prompt for human input at 🔴 sections, generate drafts and request confirmation at 🟡 sections, and auto-fill 🟢 and ⚪ sections.

---

## Traceability Chain

A key feature of these templates is end-to-end traceability:

```
PRD Requirement (M-1)
    │
    ├──► PRD Acceptance Criteria (AC-1)
    │
    ├──► ARD Driving Requirement (traces to M-1)
    │        │
    │        └──► ARD Decision Driver
    │                 │
    │                 └──► ARD Option Rating
    │
    ├──► ARD Traceability Matrix (M-1 → Component A)
    │
    ├──► SEC Data Inventory (PRD Entity reference)
    │
    └──► SEC Security Requirement (SEC-1)
             │
             └──► Verification Method (Integration Test)
                      │
                      └──► Test Location (tests/auth_test.rs)
```

This means:
- Every architectural decision traces back to a PRD requirement
- Every security requirement traces to a PRD acceptance criteria
- Every test traces to a security or functional requirement
- Auditors can follow the chain from code back to business need

---

## Getting Started

### Step 1: Start with the PRD

1. Copy `prd-template-v3.md` to your specs directory
2. Rename to `[NNN]-prd-[your-feature].md`
3. Fill in all 🔴 `@human-required` sections first:
   - Background
   - Problem Statement
   - User Story
   - Must Have & Should Have requirements
   - Success Metrics
4. Have an LLM draft the 🟡 `@human-review` sections
5. Review and confirm/edit the drafts
6. Complete the Definition of Ready checklist

### Step 2: Create the ARD

1. Copy `ard-template-v3.md`
2. Rename to `[NNN]-ard-[your-feature].md`
3. Link to the PRD in the Linkage table
4. Fill in 🔴 sections: Decision, Problem Space, Decision Drivers
5. Have an LLM draft options based on the drivers
6. Make and document your decision
7. Define Implementation Guardrails

### Step 3: Complete the Security Review

1. Copy `sec-template-v3.md`
2. Rename to `[NNN]-sec-[your-feature].md`
3. Link to PRD and ARD
4. Fill in Risk Assessment
5. Have an LLM draft Attack Surface and Data Inventory
6. Review CIA assessment
7. Document any risk acceptances with sign-off

### Step 4: Implementation

Only after all three documents are approved:
- PRD Definition of Ready is complete
- ARD is in Accepted status
- SEC is Approved (or Approved with conditions)

Then implementation can begin, guided by:
- PRD Acceptance Criteria → test cases
- ARD Implementation Guardrails → coding constraints
- SEC Security Requirements → security test cases

---

## Document Lifecycle

```
Draft ──► In Review ──► Approved ──► In Progress ──► Complete
                            │
                            ▼
                    [Implementation begins]
```

**Living Documents:** These specs are meant to be updated as the product evolves. Use the Changelog and Decision Log to track changes over time.

---

## Best Practices

### For Humans

1. **Don't skip the "Why"** — Problem statements and rationale are as important as requirements
2. **Be explicit about scope** — Out of Scope sections prevent creep
3. **Use the Glossary** — Define terms once, use consistently
4. **Accept risks formally** — Risk acceptance needs a name and date

### For LLM Agents

1. **Follow the Completion Order** — Don't fill downstream sections before upstream human input exists
2. **Trace to PRD IDs** — Every reference should include the requirement ID (M-1, S-2, etc.)
3. **Use Glossary terms** — Don't invent new terminology
4. **Respect guardrails** — Implementation Guardrails are hard constraints, not suggestions
5. **Compare to simplest** — Always consider if complexity is justified

### For Tooling Integration

The `@human-required`, `@human-review`, `@llm-autonomous`, and `@auto` markers are machine-readable. A spec management tool can:

1. Parse templates for markers
2. Build a workflow: prompt → draft → confirm → auto-fill
3. Track completion status per section
4. Enforce the Definition of Ready gate

---

## File Structure

Recommended directory layout:

```
/specs
  /features
    /001-user-authentication
      001-prd-user-authentication.md
      001-ard-user-authentication.md
      001-sec-user-authentication.md
    /002-api-rate-limiting
      002-prd-api-rate-limiting.md
      002-ard-api-rate-limiting.md
      002-sec-api-rate-limiting.md
  /templates
    prd-template-v3.md
    ard-template-v3.md
    sec-template-v3.md
  roadmap.md
```

---

## Template Files

| Template | Purpose | Start Here |
|----------|---------|------------|
| `prd-template-v3.md` | Product Requirements | ✅ First |
| `ard-template-v3.md` | Architecture Decisions | Second |
| `sec-template-v3.md` | Security Review | Third |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Jan 2025 | Initial templates |
| 2.0 | Jan 2025 | Added review tier markers for Speckit automation |
| 3.0 | Jan 2025 | Added traceability (requirement IDs, PRD cross-refs), Definition of Ready, Supply Chain section, Completion Order guidance, anti-hallucination guardrails |

---

## Contributing

These templates are designed to evolve. When you find:
- A section that's consistently skipped → consider removing or making optional
- A missing consideration → propose a new section
- An LLM failure mode → add guardrails or change the tier

Update the templates, bump the version, and document the change.

---

## License

[Your license here]

---

## Acknowledgments

Inspired by:
- GitHub's Speckit model of spec-driven development
- Architecture Decision Records (ADR) format
- OWASP threat modeling practices
- MoSCoW prioritization framework
