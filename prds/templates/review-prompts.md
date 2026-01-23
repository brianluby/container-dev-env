# Spec-Kit Review Prompts

Use these prompts to kick off structured reviews of PRD, ARD, and SEC documents. Each prompt is designed to be given to an LLM reviewer (or used as a checklist for human review).

---

## PRD Review Prompt

```
You are reviewing a Product Requirements Document (PRD) for completeness, clarity, and implementability. Your goal is to ensure this PRD provides sufficient context for an LLM agent to create a high-quality Architecture Decision Record (ARD) and for engineers to implement the feature correctly.

## Review the attached PRD against these criteria:

### Critical (Must fix before proceeding)
- [ ] **Problem Statement clarity:** Can you explain the problem in one sentence? If not, it's unclear.
- [ ] **Requirement IDs exist:** Every requirement has a unique ID (M-1, S-2, etc.)
- [ ] **Acceptance Criteria traceability:** Every Must Have requirement has at least one linked AC
- [ ] **Definition of Ready:** Is the checklist complete? Any unchecked items?

### High Priority
- [ ] **Scope boundaries:** Are Out of Scope items explicit? Are there obvious "near-miss" features that should be listed but aren't?
- [ ] **Testable requirements:** Can each requirement be verified as done/not done? Flag any vague language ("fast", "user-friendly", "secure")
- [ ] **Technical Constraints:** Are constraints specific enough? (e.g., "performant" → "<100ms p95")
- [ ] **Assumptions:** Are there implicit assumptions that should be explicit?

### Medium Priority  
- [ ] **Glossary completeness:** Are domain terms defined? Are they used consistently throughout?
- [ ] **Data Model:** Does it define WHAT (fields, relationships) without over-specifying HOW (implementation)?
- [ ] **Interface Contract:** Is it a contract or an implementation? Flag if too specific.
- [ ] **Dependencies:** Are they validated? Who owns them?

### Low Priority
- [ ] **Diagram consistency:** Do diagram terms match Glossary and Requirements?
- [ ] **Won't Have rationale:** Is it clear WHY items are deferred?

## Output Format

Provide your review as:

### Critical Issues
[List any blockers that must be fixed]

### Suggested Improvements  
[List recommended changes by priority]

### Questions for the Author
[List clarifying questions]

### Positive Observations
[Note what's done well]

### Verdict
[ ] Ready for ARD creation
[ ] Needs revision (see Critical Issues)
```

---

## ARD Review Prompt

```
You are reviewing an Architecture Decision Record (ARD) for technical soundness, traceability to requirements, and implementability. Your goal is to ensure this ARD provides sufficient guidance for an LLM agent or engineer to implement the feature correctly without over-engineering.

## Review the attached ARD against these criteria:

### Critical (Must fix before proceeding)
- [ ] **PRD traceability:** Does every Driving Requirement reference a specific PRD requirement ID (M-1, S-2)?
- [ ] **Option 0 exists:** Is "Status Quo / Do Nothing" documented (unless greenfield)?
- [ ] **Decision is explicit:** Is there a clear Selected Option with rationale?
- [ ] **Simplest Implementation comparison:** Is complexity justified against the simplest approach?

### High Priority
- [ ] **Decision Drivers are prioritized:** Are drivers ordered by importance?
- [ ] **Options are fairly evaluated:** Do all options use the same drivers for comparison?
- [ ] **Implementation Guardrails:** Are DO NOT and MUST rules specific and actionable?
- [ ] **Rollback Plan:** Are triggers, authority, and procedure defined?
- [ ] **Cherry-picking check:** Do Driving Requirements include ALL relevant PRD Must Haves, not just convenient ones?

### Medium Priority
- [ ] **Component naming consistency:** Do diagram names match the Component Overview table exactly?
- [ ] **Constraints distinction:** Is it clear which constraints are inherited from PRD vs. added by architecture?
- [ ] **Decision Scope:** Is it clear what this ARD does NOT decide?
- [ ] **Reference Implementations:** Are external links appropriate and approved?

### Low Priority
- [ ] **Consequences:** Are both positive and negative consequences documented?
- [ ] **Traceability Matrix:** Does it cover all PRD Must Have requirements?

## Anti-Pattern Detection

Flag if you see:
- **Over-engineering:** Microservices when a monolith would work, abstractions without justification
- **Resume-driven development:** Using trendy tech without clear benefit
- **Incomplete analysis:** Dismissing options without fair evaluation
- **Missing Option 0:** Not explaining why status quo is unacceptable

## Output Format

Provide your review as:

### Critical Issues
[List any blockers that must be fixed]

### Architecture Concerns
[Technical issues with the proposed approach]

### Traceability Gaps
[PRD requirements not addressed or incorrectly mapped]

### Questions for the Author
[Clarifying questions]

### Positive Observations
[Note what's done well]

### Verdict
[ ] Ready for implementation
[ ] Needs revision (see Critical Issues)
```

---

## SEC Review Prompt

```
You are reviewing a Security Review document for completeness and accuracy. This is a LIGHTWEIGHT review intended to catch obvious issues early — not a comprehensive threat model. Your goal is to ensure attack surface, data sensitivity, and basic risks are documented.

## Review the attached SEC against these criteria:

### Critical (Must fix before proceeding)
- [ ] **Risk Level justified:** Does the stated Risk Level (Low/Med/High/Critical) match the documented risks?
- [ ] **Exposure Points consistency:** Is there ONLY "None" OR specific endpoints listed (not both)?
- [ ] **Data Inventory completeness:** Does every PRD Data Model entity appear with a classification?
- [ ] **Risk Acceptance signed:** Are any accepted risks signed with name, date, and justification?

### High Priority
- [ ] **Authentication/Authorization:** Is auth status documented for every internet-facing endpoint?
- [ ] **Data Classification accuracy:** Is PII marked as Confidential or higher? Are secrets/tokens marked Restricted?
- [ ] **Third-Party/Supply Chain:** Are new external services and dependencies listed?
- [ ] **CIA Assessment:** Are Confidentiality, Integrity, Availability each assessed with specific scenarios?

### Medium Priority
- [ ] **Security Requirements verifiable:** Does each SEC requirement have a Verification Method?
- [ ] **Security Requirements traced:** Do requirements map to PRD Acceptance Criteria where applicable?
- [ ] **Trust Boundaries:** Are boundaries between untrusted/trusted zones identified?
- [ ] **Compliance N/A justified:** If regulations are marked N/A, is there a justification?

### Low Priority
- [ ] **Diagram consistency:** Do Data Flow diagram nodes match Data Inventory elements?
- [ ] **Findings severity:** Are findings using consistent severity definitions?

## Red Flags to Watch For

Flag if you see:
- **Optimistic classification:** Sensitive data marked as "Internal" or "Public"
- **Missing auth:** Public endpoints without authentication requirement
- **Handwaving risks:** Risks dismissed without mitigation or explicit acceptance
- **Incomplete supply chain:** New APIs or libraries used but not listed
- **Contradictory exposure:** Both "None" and actual endpoints in Exposure Points table

## Output Format

Provide your review as:

### Critical Issues
[Security blockers that must be fixed]

### Security Concerns
[Issues that increase risk if not addressed]

### Classification Questions
[Data elements that may be misclassified]

### Missing Coverage
[Attack surface or data not documented]

### Positive Observations
[Good security practices noted]

### Verdict
[ ] Approved
[ ] Approved with conditions (list conditions)
[ ] Needs revision (see Critical Issues)
[ ] Flagged for deep review (requires full threat model)
```

---

## Combined Review Prompt (All Three Documents)

```
You are reviewing a complete feature specification consisting of three documents:
1. PRD (Product Requirements Document) — What & Why
2. ARD (Architecture Decision Record) — How
3. SEC (Security Review) — Risks

Your goal is to ensure these documents are internally consistent, properly cross-referenced, and ready for implementation.

## Cross-Document Consistency Checks

### PRD → ARD Traceability
- [ ] Every PRD Must Have (M-x) appears in ARD Driving Requirements
- [ ] ARD Decision Drivers trace back to specific PRD requirements
- [ ] ARD Technical Constraints include all PRD Technical Constraints
- [ ] ARD Traceability Matrix covers all PRD Must Haves

### PRD → SEC Traceability  
- [ ] Every PRD Data Model entity appears in SEC Data Inventory
- [ ] SEC Security Requirements reference PRD Acceptance Criteria where applicable
- [ ] PRD Security Considerations section links to SEC document

### ARD → SEC Consistency
- [ ] SEC Attack Surface matches ARD Architecture (same endpoints, components)
- [ ] SEC Third-Party section includes dependencies from ARD
- [ ] ARD Security Considerations align with SEC findings

### Terminology Consistency
- [ ] PRD Glossary terms are used consistently across all three documents
- [ ] Component names in ARD diagrams match SEC diagrams
- [ ] Data element names are consistent across PRD Data Model, ARD specs, and SEC Data Inventory

## Completeness Gates

### PRD Ready?
- [ ] Definition of Ready checklist is complete
- [ ] No open questions blocking implementation

### ARD Ready?
- [ ] Status is "Accepted"
- [ ] Simplest Implementation comparison is done
- [ ] Implementation Guardrails are defined

### SEC Ready?
- [ ] Sign-off section is complete
- [ ] No Critical/High findings remain Open
- [ ] Risk acceptances are signed

## Output Format

### Cross-Reference Issues
[Inconsistencies between documents]

### Per-Document Issues

**PRD:**
[Issues specific to PRD]

**ARD:**
[Issues specific to ARD]

**SEC:**
[Issues specific to SEC]

### Overall Verdict
[ ] Ready for implementation
[ ] Needs revision (specify which documents)
```

---

## Usage Tips

### For LLM-Assisted Review
1. Attach the document(s) to be reviewed
2. Paste the appropriate prompt
3. Review the LLM's output
4. Address Critical Issues before proceeding

### For Human Review
Use these prompts as checklists — the checkbox format works for manual review too.

### For Automated Tooling
These prompts can be integrated into a CI/CD pipeline:
1. Parse documents for required sections
2. Run LLM review on PR
3. Block merge if Critical Issues found
4. Require human approval for Verdict

---

## Quick Reference: What Each Review Catches

| Review | Primary Focus | Key Question |
|--------|---------------|--------------|
| PRD | Completeness & Clarity | "Can someone implement this without guessing?" |
| ARD | Technical Soundness & Justification | "Is complexity justified? Are trade-offs explicit?" |
| SEC | Risk Coverage | "What could go wrong? Is it documented?" |
| Combined | Consistency & Traceability | "Do these documents tell a coherent story?" |
