# Example: Development Workflow Context for AGENTS.md

This document shows how to document your team's development process in AGENTS.md so AI agents understand and follow your workflow.

---

## Workflow Section for AGENTS.md

Add this section to your AGENTS.md to document your development process:

```markdown
## Development Workflow

This project follows a structured feature development process. AI agents MUST follow this workflow.

### Phase 1: PRD (Product Requirements Document)

Before any implementation, create a PRD in `prds/`:

1. Copy template: `prds/templates/prd-template.md`
2. Name format: `###-prd-feature-name.md` (zero-padded number)
3. Define: Problem, Requirements (MoSCoW), Evaluation Criteria, Acceptance Criteria
4. PRD must be reviewed before proceeding

**AI Instructions**: When asked to implement a new feature, first check if a PRD exists. If not, suggest creating one.

### Phase 2: Spike (Technical Exploration)

For complex or uncertain features, conduct a spike in `spikes/`:

1. Create directory: `spikes/###-feature-name/`
2. Explore: Research options, prototype solutions, benchmark approaches
3. Document: Create `RESULTS.md` with findings and recommendations
4. Spikes are time-boxed explorations, not production code

**AI Instructions**: When encountering technical uncertainty, suggest a spike before committing to an approach.

### Phase 3: SpecKit Process

Once PRD is approved and spike (if needed) is complete, use SpecKit:

#### 3a. Specification (`/speckit.specify`)
- Creates `specs/<branch>/spec.md`
- Defines detailed requirements from PRD
- Clarifies ambiguities via `/speckit.clarify`

#### 3b. Planning (`/speckit.plan`)
- Creates `specs/<branch>/plan.md`
- Research phase: technology decisions, patterns
- Design phase: data models, contracts, architecture
- Must fill all "NEEDS CLARIFICATION" items

#### 3c. Task Generation (`/speckit.tasks`)
- Creates `specs/<branch>/tasks.md`
- Breaks plan into actionable, dependency-ordered tasks
- Each task is atomic and testable

#### 3d. Implementation (`/speckit.implement`)
- Executes tasks in order
- Updates task status as work progresses
- Follows TDD where applicable

### Workflow Commands

```bash
# Create feature scaffolding (includes branch)
./.specify/scripts/bash/create-new-feature.sh 'Description' --short-name name

# Check prerequisites before work
./.specify/scripts/bash/check-prerequisites.sh --json

# Setup plan from template
./.specify/scripts/bash/setup-plan.sh --json

# Update agent context files after plan changes
./.specify/scripts/bash/update-agent-context.sh
```

### Workflow Rules

1. **Never skip phases**: PRD → Spike (if needed) → Specify → Plan → Tasks → Implement
2. **Update context**: Run `update-agent-context.sh` after modifying plans
3. **Check prerequisites**: Always run prerequisite check before starting work
4. **One feature branch**: Each feature gets its own branch via `create-new-feature.sh`
5. **Atomic commits**: Commit after each completed task

### AI Agent Workflow

When asked to work on a feature:

1. **Check for PRD**: Does `prds/###-prd-*.md` exist for this feature?
   - No → Suggest creating PRD first
   - Yes → Proceed

2. **Check for Spike**: Is there technical uncertainty?
   - Yes → Check `spikes/###-*/RESULTS.md` or suggest spike
   - No → Proceed

3. **Check for Spec**: Does `specs/<branch>/spec.md` exist?
   - No → Run `/speckit.specify`
   - Yes → Verify it's current

4. **Check for Plan**: Does `specs/<branch>/plan.md` exist?
   - No → Run `/speckit.plan`
   - Yes → Check for "NEEDS CLARIFICATION"

5. **Check for Tasks**: Does `specs/<branch>/tasks.md` exist?
   - No → Run `/speckit.tasks`
   - Yes → Start implementation

6. **Implement**: Follow tasks in order, mark complete as you go
```

---

## Integration with Existing AGENTS.md

The container-dev-env project's root AGENTS.md already includes this workflow in sections 2 and 7. Key points:

- Section 2 (Workflow Commands) lists the shell commands
- Section 7 (Spec/Plan Workflow) describes the SpecKit process
- Section 6 (Git & Branching) enforces the branch naming via scripts

When creating AGENTS.md for similar projects, include:
1. The workflow phases (PRD → Spike → SpecKit)
2. The specific commands to run
3. Clear rules for AI agents to follow
4. Checks/gates before proceeding to next phase
