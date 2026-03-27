---
name: pge-build
description: |
  PGE Build Protocol (Spec-Builder-Acceptor).
  Parses PRD/spec/design documents, extracts implementable units,
  generates Sprint Contracts per unit, executes sequential build sprints
  with embedded PGE quality gates, and verifies with independent
  acceptance evaluator. Multi-sprint feature implementation from spec
  with ordered execution and cross-skill awareness.
  Use when asked with /pge-build flag appended.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - TeamCreate
  - SendMessage
  - TaskCreate
  - TaskUpdate
  - TaskList
---

# /pge-build — PGE Build Protocol (Spec-Builder-Acceptor)

When the user appends `/pge-build` to a task request, the full build protocol is enforced.

"Given a spec, build it completely — one sprint at a time."

## Key Differentiator

- `/pge` = single task (fix bug, add endpoint, review code) with blast radius verification
- `/pge-build` = multi-sprint feature implementation from spec, with ordered execution and cross-skill awareness

## Project Initialization (First Run)

```bash
mkdir -p .claude/pge-build/history .claude/pge-build/sprints

if [ -f .gitignore ] && ! grep -q ".claude/pge-build/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE-build workflow state files\n.claude/pge-build/" >> .gitignore
fi
```

### Foundation Map Check

Check for PGE foundation maps and notify if missing:

| Map | Owner | If Missing |
|-----|-------|------------|
| `docs/backend-dependency-map.md` | /pge | "No dependency map found. Run `/pge` to generate." |
| `docs/architecture-map.md` | /pge-archi | "No architecture map found. Run `/pge-archi` to generate." |
| `docs/design-system-map.md` | /pge-front | "No design system map found. Run `/pge-front` to generate." |
| `docs/qa-coverage-map.md` | /pge-qa | "No QA coverage map found. Run `/pge-qa` to generate." |

Missing maps do not block execution — they reduce quality gate coverage.

### Automatic Platform Detection

```
Flutter:    Glob pubspec.yaml → "flutter:" section
React/Next: Glob package.json → "react" dependency
Swift/iOS:  Glob *.xcodeproj or Package.swift
Vue/Nuxt:   Glob package.json → "vue" dependency
```

**Required output:** `Platform: {Flutter | Swift | React | Vue | Unknown}`

## CRITICAL: Agent Spawning Rules

1. **Use TeamCreate to compose the Phase 0 team.** Do not spawn plain Agent subagents.
2. **Do not use Explore subagents.** All teammates must be `general-purpose` agents.
3. **Each teammate shares findings via SendMessage.** No silos allowed.
4. **Use TaskCreate to create a task list** and assign tasks to teammates.
5. **Phase 0 agents are read-only** — code modifications happen only in Phase 1 by the team lead.

## Input

$ARGUMENTS — Spec/PRD description or path to spec document

## Mode Detection

- **Full Build**: Default — all 3 phases (Phase 0 + 1 + 2)
- **Plan Only**: "plan", "analyze", "scope" — Phase 0 only
- **Resume**: "resume", "continue" — pick up from last completed sprint in Phase 1
- **Single Sprint**: specific feature/screen name — Phase 1 for one sprint only

**Required output:** `Build Mode: {Full Build | Plan Only | Resume | Single Sprint}`

---

## Build Principles

These principles guide all code generation during Phase 1.

### Decision Classification

- **Mechanical decisions** (one right answer — auto-decide): file location, import style, naming convention, which existing util to reuse
- **Taste decisions** (reasonable disagreement — surface to user): API shape, state management approach, component decomposition strategy, data model design

### 6 Code Generation Principles

1. **Choose completeness**: Each sprint produces a complete, working unit. No partial features.
2. **Boil lakes**: When modifying a file, fix everything in blast radius (modified files + direct importers).
3. **Pragmatic**: When two approaches solve the same thing, pick the cleaner one.
4. **DRY**: Before writing new code, check if functionality already exists. Mandatory reuse check before each sprint.
5. **Explicit over clever**: 10-line obvious implementation > 200-line abstraction.
6. **Bias toward action**: Don't over-deliberate mechanical decisions. Decide and move.

### Quality Aspirations

- Every function has a single responsibility
- Error paths are explicit, not swallowed
- No magic numbers or hardcoded values
- State mutations are predictable and traceable
- Dependencies flow in one direction

---

## Phase 0: Spec Analysis — Extract + Plan (Team)

### STEP 1: Task Analysis + Role Selection

**Required output:**
```
Build Mode: {Full Build | Plan Only | Resume | Single Sprint}
Platform: {Flutter | Swift | React | Vue}
Selected roles: [{role1}, {role2}, ...]
Rationale: [Why these roles are needed]
```

### STEP 2: Create Spec Analysis Team

**TeamCreate** → Agent(team_name="pge-build-{slug}", name="{role}", run_in_background=true)

### Role Catalog

**spec-parser and arch-planner are always included.** 2-4 roles total.

| Role | Specialty | When to Select |
|------|-----------|----------------|
| **spec-parser** | Parse PRD → extract features, user stories, acceptance criteria | **Always** (required) |
| **arch-planner** | Map features to architecture (which modules, which layers), determine build order | **Always** (required) |
| **ui-planner** | Parse screen designs → extract screens, components, interactions | When UI/screen designs are provided |
| **dependency-resolver** | Determine build order based on feature dependencies, identify parallelizable sprints | When >5 implementable units |

Custom roles allowed. Rationale required.

### Agent Prompt Template

```
You are the {role-name} of team "{team_name}". {One-line specialty description}.

## Mission
Analyze the following spec/PRD and extract implementable units for a build plan.

Spec: {user-provided spec content or path}
Platform: {detected platform}

## Available Foundation Maps (read if they exist)
- docs/backend-dependency-map.md
- docs/architecture-map.md
- docs/design-system-map.md
- docs/qa-coverage-map.md

## Action Items
{3-7 specific action items for the role}

## Required: SendMessage Rules
After completing your analysis, share key findings with all teammates via SendMessage.
Do not modify code. Analysis only.
Use TaskUpdate to mark your assigned Task as completed.
```

### STEP 3: Wait + Synthesize

Agents share findings via SendMessage. Synthesize after all complete.

### STEP 4: Generate Implementation Plan

Save to `.claude/pge-build/plan.md`:

```markdown
# Implementation Plan
Generated: {ISO timestamp}

## Spec Summary
Source: {PRD path or description}
Platform: {Flutter | Swift | React | Vue}
Total units: {N}
Estimated sprints: {N}

## Implementable Units
| # | Unit | Type | Dependencies | Sprint |
|---|------|------|-------------|--------|
| 1 | {feature/screen name} | {model/service/screen/...} | None | 1 |
| 2 | {feature/screen name} | {model/service/screen/...} | Unit 1 | 2 |

## Build Order
{Platform-specific build sequence with justification}

## Sprint Contracts
(Generated in Step 5)

## Alternatives Considered
| Decision | Chosen | Alternative | Why Chosen |
|----------|--------|------------|------------|
```

### STEP 5: Generate Sprint Contracts

For each implementable unit, write to `.claude/pge-build/sprints/sprint-{N}-{slug}.md`:

```markdown
# Sprint Contract: {feature/screen name}
Sprint: {N}/{total}
Spec reference: {PRD section / screen design page}

## What to Build
- [ ] {specific deliverable 1}
- [ ] {specific deliverable 2}

## What NOT to Build (explicit exclusions)
- {out of scope item}

## Acceptance Criteria
- [ ] {testable criterion 1}
- [ ] {testable criterion 2}

## Dependencies
- Requires: {other sprint outputs}
- Blocked by: {prerequisites}

## Quality Gates
- Backend: /pge blast radius check needed? Y/N
- Frontend: /pge-front categories to check? {list}
- Tests: minimum coverage for this sprint
- Architecture: module boundary check needed? Y/N

## Approach
{Brief description of implementation approach}
```

### Build Order Templates (defaults, overridable by arch-planner)

**Flutter:**
```
1. Models (Freezed classes)
2. Services (Supabase/API calls)
3. Providers (Riverpod state management)
4. Shared Widgets (design system components)
5. Feature Screens (UI implementation)
6. Routing (GoRouter)
7. Integration (provider → service → UI wiring)
8. Polish (animations, transitions, edge cases)
```

**Swift (iOS):**
```
1. Data Models (Swift structs/classes, Core Data/Realm)
2. Networking Layer (API clients, request/response types)
3. Business Logic (Services, use cases)
4. UI Components (reusable views, design system)
5. Screens (feature screens using components)
6. Navigation (routing, deep links)
7. Integration (connecting screens to services)
8. Polish (animations, transitions, edge cases)
```

**React/Next.js:**
```
1. Types/Interfaces (TypeScript types, API contracts)
2. API Layer (fetch clients, server actions)
3. State Management (stores, context, server state)
4. Shared Components (design system, primitives)
5. Feature Pages (page components)
6. Routing (Next.js app router, layouts)
7. Integration (data flow wiring)
8. Polish (animations, transitions, edge cases)
```

### STEP 6: Complexity Gate

| Condition | Action |
|-----------|--------|
| <= 8 sprints | Proceed to Phase 1 |
| 9-15 sprints | Proceed with caution, confirm with user |
| > 15 sprints | Recommend splitting into multiple /pge-build runs. Halt until confirmed |

### STEP 7: Shutdown Analysis Team

**For Plan Only mode:** Output plan and STOP.

**Phase Gate:** Implementation Plan + all Sprint Contracts required to proceed.

---

## Phase 1: Builder — Sequential Sprint Execution

### Execution Model

Execute sprints sequentially in the order defined by the Implementation Plan. Each sprint follows:

```
1. READ Sprint Contract
2. REUSE CHECK — Does this already exist in the project?
3. WRITE failing test (from acceptance criteria)
4. IMPLEMENT feature
5. TEST passes
6. REFACTOR if needed
7. VERIFY acceptance criteria
8. UPDATE progress tracker
```

Not strict TDD — but tests must exist before sprint completion.

### Per-Sprint Quality Gates (Embedded PGE Principles)

/pge-build does NOT invoke other skills. It EMBEDS their principles inline:

| Build Step | Embedded Principle | Source | Action |
|------------|-------------------|--------|--------|
| Schema/migration | Blast radius check | /pge | Read `docs/backend-dependency-map.md`, identify affected dependencies, verify "What Does NOT Change" |
| API endpoint | RLS/policy awareness | /pge | Server Boundary Checkpoint: run 1-2 key queries after deploy |
| UI component | Token compliance, a11y | /pge-front | No hardcoded values, Semantics labels, touch target >= 44pt |
| Screen layout | Design system reference | /pge-design | Reference `docs/design-system-map.md` |
| Test writing | Coverage + regression | /pge-qa | Reference `docs/qa-coverage-map.md`, new test for every change |
| Module structure | Boundary discipline | /pge-archi | Reference `docs/architecture-map.md`, dependency direction |
| Documentation | Map freshness | /pge-doc | Note if foundation maps need post-build updating |

### Sprint Execution Loop

For each sprint (1 to N):

#### A. Pre-Sprint
1. Read Sprint Contract from `.claude/pge-build/sprints/sprint-{N}-{slug}.md`
2. Read relevant foundation maps for this sprint's scope
3. **Reuse check**: Grep/Read to verify no existing code covers this functionality
4. Surface any **taste decisions** to user before coding

#### B. Build
1. Follow platform-specific build order WITHIN the sprint
2. Apply 6 Code Generation Principles
3. Apply relevant quality gates per layer
4. Write tests alongside implementation

#### C. Post-Sprint
1. Run all acceptance criteria checks from Sprint Contract
2. Verify quality gates passed
3. Update progress tracker

### Progress Tracking

Update `.claude/pge-build/progress.md` after each sprint:

```
BUILD PROGRESS
═══════════════════════════════════════
Spec: {PRD/spec name}
Platform: {Flutter | Swift | React}
Date: {ISO timestamp}

Sprint 1/8: Data Models        [████████████] DONE
Sprint 2/8: Services           [████████░░░░] IN PROGRESS (75%)
Sprint 3/8: Providers          [░░░░░░░░░░░░] PENDING
Sprint 4/8: Shared Widgets     [░░░░░░░░░░░░] PENDING
Sprint 5/8: Feature Screens    [░░░░░░░░░░░░] PENDING
Sprint 6/8: Routing            [░░░░░░░░░░░░] PENDING
Sprint 7/8: Integration        [░░░░░░░░░░░░] PENDING
Sprint 8/8: Polish             [░░░░░░░░░░░░] PENDING

Current Sprint: 2/8 — Services
Acceptance Criteria: 3/5 met
Quality Gates: Backend OK | Tests OK | Lint OK
═══════════════════════════════════════
```

### Sprint Failure Handling

- **3-strike rule per sprint**: 3 failures on the same sprint → STOP + escalate to user
- **Sprint with >8 files changing**: Challenge whether it should be split
- **Regression detected**: Revert last change, investigate before proceeding
- **Blocked by dependency**: Skip to next non-blocked sprint if possible, otherwise STOP

### Result Manifest

After all sprints complete, write to `.claude/pge-build/result.md`:

```markdown
# Build Result
Completed: {ISO timestamp}

## Sprints Summary
| # | Sprint | Status | Files Changed | Tests Added |
|---|--------|--------|--------------|-------------|

## Quality Gate Results
| Sprint | Backend | Frontend | Tests | Architecture |
|--------|---------|----------|-------|-------------|

## Noticed Issues (out of scope)
- {issues observed but not fixed}

## Foundation Map Updates Needed
- {maps that need refreshing post-build}

## Self-Assessment Weaknesses
- {areas where implementation is weakest}
```

**Phase Gate:** All Sprint Contracts completed + Result Manifest required to proceed.

---

## Phase 2: Acceptor — Independent Verification

**Must be executed as a fresh context Agent subagent.**

### Acceptor Agent Prompt

```
You are the BUILD ACCEPTOR in a Spec-Builder-Acceptor workflow.

YOUR ROLE: Independently verify that the full build matches the original spec.
You are checking SOMEONE ELSE's work. Be skeptical. Do NOT assume correctness.

Score Calibration:
9-10: Pixel-perfect spec match, comprehensive tests. Rare.
7-8:  Spec met, production-deployable, minor gaps.
5-6:  Core features work, notable gaps or missing edge cases.
3-4:  Major spec items missing.
1-2:  Build doesn't match spec.

## Inputs (read these files first)
1. Implementation plan: .claude/pge-build/plan.md
2. Sprint contracts: .claude/pge-build/sprints/*.md
3. Build result: .claude/pge-build/result.md
4. Foundation maps: docs/*.md (if they exist)

## Verification Process

### A. Spec Compliance Check
For EVERY feature/requirement in the implementation plan:
- [ ] Feature implemented? (Read actual code to verify)
- [ ] Acceptance criteria met? (Run tests or verify by reading code)
- [ ] Edge cases handled? (error, empty, loading states)

### B. Sprint Contract Walk
For EVERY Sprint Contract:
- Verify all acceptance criteria checkboxes
- Verify quality gates were met
- Check dependencies were satisfied

### C. Cross-Feature Integration
- Do features work together correctly?
- Is the navigation flow complete?
- Does data flow end-to-end (model → service → UI)?

### D. Quality Gate Verification
- Backend: blast radius boundaries respected?
- Frontend: design system compliance?
- Tests: coverage adequate per sprint?
- Foundation maps: updated where needed?

### E. Devil's Advocate (Build)
1. Which spec requirement was most likely missed or partially implemented?
2. Are there screens/flows that work in isolation but break when connected?
3. Were edge cases (empty, error, loading states) actually implemented?
4. Is the test coverage real or superficial?
5. Were foundation maps updated to reflect the new code?
6. Could a user complete the core flow without hitting a dead end?

### F. Anti-Pattern Check
| Anti-Pattern | How to Detect |
|---|---|
| "Built" without matching spec | Compare spec items to actual code |
| Happy path only | No error/empty/loading state handling |
| Tests that don't test | Trivial assertions, always-pass |
| UI without state management | Hardcoded data, no loading states |
| Navigation dead ends | Routes that lead nowhere |
| Spec drift | Built something different from what was specified |
| Partial sprint | Sprint marked DONE but deliverables missing |

### G. Score 5 Dimensions (1-10)
1. Spec Compliance (**HARD FAIL if < 6**)
2. Code Quality
3. Test Coverage
4. Integration Completeness (**HARD FAIL if < 6**)
5. Foundation Map Currency

### H. Build Acceptance Score (BAS)
BAS = (Spec x 0.30) + (Quality x 0.20) + (Tests x 0.20) + (Integration x 0.20) + (Maps x 0.10)

### I. Verdict
- **PASS**: All >= 7, BAS >= 7.0
- **CONDITIONAL PASS**: All >= 6, BAS >= 6.0
- **FAIL**: Any hard-fail < 6

### J. Write Report
Write to .claude/pge-build/acceptance-eval.md. Return verdict + key findings.
```

### Handling Acceptor Results

- **PASS**: Archive → Output Build Report
- **CONDITIONAL PASS**: Fix items → Archive (no re-evaluation needed)
- **FAIL**: Fix items → Re-run Acceptor (fresh context)
- **FAIL loop 2+ times**: Halt + escalation

### Archive

Create `.claude/pge-build/history/{YYYYMMDD}T{HHMM}_{slug}.md` (under 100 lines).

---

## Final Report

```
BUILD REPORT
════════════════════════════════════════
Spec:            [PRD/spec name]
Platform:        {Flutter | Swift | React | Vue}
Mode:            {Full Build | Plan Only | Resume | Single Sprint}
Date:            {ISO timestamp}
Verdict:         {PASS | CONDITIONAL PASS | FAIL}

── Phase 0: Spec Analysis ──
Team:            [{roles}]
Units extracted: {N} features/screens
Build order:     {N} sprints planned

── Phase 1: Build Sprints ──
Completed:       {N}/{total} sprints
Quality gates:   {N} passed, {N} flagged
Tests added:     {N}

── Phase 2: Acceptance ──
| Dimension          | Score |
|--------------------|-------|
| Spec Compliance    | X/10  |
| Code Quality       | X/10  |
| Test Coverage      | X/10  |
| Integration        | X/10  |
| Foundation Maps    | X/10  |

BAS:             X/10
Evaluator:       independent acceptor (fresh context)

Post-Build Recommendations:
  - [ ] Run /pge-qa for comprehensive QA scan
  - [ ] Run /pge-front for frontend quality audit
  - [ ] Run /pge-archi for architecture review
  - [ ] Run /pge-doc to update foundation maps
════════════════════════════════════════
```

---

## PGE Skill Orchestration

```
              ┌─────────────┐
              │  /pge-build  │  ORCHESTRATOR
              └──────┬──────┘
                     │
      ┌──────────────┼──────────────┐
      │              │              │
┌─────▼──────┐ ┌────▼─────┐ ┌─────▼──────┐
│ READS FROM  │ │ PRODUCES │ │ HANDS OFF   │
└─────┬──────┘ └────┬─────┘ └─────┬──────┘
      │              │              │
  Foundation    Working code   Post-build:
  maps (all)    + tests +      → /pge-qa
                sprint         → /pge-front
                history        → /pge-archi
                               → /pge-doc
```

### Orchestration Rules

1. **Pre-build**: Read all foundation maps. Reference their artifacts, don't invoke skills.
2. **During build**: Embed PGE quality principles inline per layer (see quality gates table).
3. **Post-build**: Recommend (don't auto-invoke) relevant review skills based on what was built.
4. **Foundation map updates**: Note which maps need refreshing for /pge-doc.

---

## Escalation Rules

- Phase 0: >15 implementable units → recommend splitting into multiple /pge-build runs
- Phase 1: 3-strike rule per sprint (3 failures → STOP + escalate)
- Phase 1: Sprint with >8 files changing → challenge whether to split
- Phase 2: FAIL loop 2+ times → Halt + escalation
- Cross-skill: >50% issues in one domain → recommend running that PGE skill first
- Platform Unknown → request explicit specification from user

## Important Rules

- Cannot proceed to the next Phase without each Phase's **required output**
- `/pge-build` tasks **cannot skip the protocol**
- Phase 0 agents **must not modify code** — analysis only
- Phase 1 modifications are **team lead only**
- Phase 2 Acceptor must be a **fresh context Agent subagent**
- **Actual Read/Grep verification** required — "I assume it works" is not acceptable
- SendMessage sharing required in Phase 0, team shutdown required after Phase 0
- Tests must be written alongside implementation, not after
- Reuse check mandatory before each sprint
- Taste decisions must be surfaced to user, mechanical decisions auto-decided
