---
name: pge-build
description: |
  PGE Build Protocol (Spec-Builder-Acceptor).
  Turns requirements into tested, reviewed, production-ready code.
  Parses spec documents (PRD, architecture, screen designs) into
  implementable units, executes sequential build sprints with quality
  gates and 6 Build Principles, and verifies with independent acceptance
  against original spec. The ONLY PGE skill that creates new code from
  scratch. Embeds principles from other PGE skills during build without
  invoking them. Use when asked with /pge-build flag appended.
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

**"Turn requirements into tested, reviewed, production-ready code."**

## Core Identity

This is the **ONLY** PGE skill that creates new code from scratch. All other PGE skills analyze, review, or optimize existing code.

| Skill | Purpose | Creates Code? |
|-------|---------|---------------|
| `/pge` | Single task with blast radius verification | Modifies existing |
| `/pge-build` | Multi-sprint feature from spec | **Creates new** |
| `/pge-archi` | Architecture review + improvement | Refactors existing |
| `/pge-qa` | Code quality scan + fix | Fixes existing |
| `/pge-front` | Frontend quality audit + fix | Fixes existing |
| `/pge-design` | Visual/brand creative improvement | Improves existing |

## Project Initialization (First Run)

```bash
mkdir -p .claude/pge-build/history .claude/pge-build/sprints

if [ -f .gitignore ] && ! grep -q ".claude/pge-build/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE-build workflow state files\n.claude/pge-build/" >> .gitignore
fi
```

### Automatic Platform Detection
```
Flutter:    Glob pubspec.yaml → "flutter:" section
iOS/Swift:  Glob *.xcodeproj or Package.swift
React/Next: Glob package.json → "react" dependency
Vue/Nuxt:   Glob package.json → "vue" dependency
```
**Required output:** `Platform: {Flutter | Swift | React | Vue | Unknown}`

### Foundation Map Check

Read existing PGE foundation maps (all optional — build adapts):

| Map | Owner | Purpose for Build |
|-----|-------|-------------------|
| `docs/backend-dependency-map.md` | `/pge` | Know existing tables/functions before creating new |
| `docs/architecture-map.md` | `/pge-archi` | Respect module boundaries |
| `docs/design-system-map.md` | `/pge-front` | Reuse tokens/components |
| `docs/qa-coverage-map.md` | `/pge-qa` | Know existing test patterns |

Log which maps exist. Missing maps do not block — build proceeds and notes them for post-build updates.

## CRITICAL: Agent Spawning Rules

1. **Use TeamCreate for Phase 0 team.** Do not spawn plain Agent subagents (except Phase 2 Acceptor).
2. **Do not use Explore subagents.** All teammates must be `general-purpose` agents.
3. **Each teammate shares findings via SendMessage.** No silos allowed.
4. **Use TaskCreate to create a task list** and assign to teammates.
5. **Phase 0 agents are read-only** — code creation happens only in Phase 1 by team lead.

## Input

$ARGUMENTS — Task description + spec document references

### Spec Document Types

The skill adapts to **any combination** of provided specs. Minimum 1 required.

| Type | Abbreviation | Contains |
|------|-------------|----------|
| Product Requirements | PRD | User stories, features, acceptance criteria |
| System Architecture | ARCH | Data models, APIs, system flow |
| Screen Design | SCREEN | UI layout, interactions, navigation |
| API Specification | API | Endpoints, request/response schemas |
| Database Schema | DB | Tables, relations, constraints |

## Mode Detection

- **Full Build**: Default — all 3 phases (Phase 0 + 1 + 2)
- **Plan Only**: "plan", "analyze", "scope" — Phase 0 only
- **Resume**: "resume", "continue" — pick up from last completed sprint
- **Single Sprint**: specific feature/screen name — Phase 1 for one sprint only

**Required output:** `Build Mode: {Full Build | Plan Only | Resume | Single Sprint}`

---

## 6 Build Principles

These principles govern ALL code creation during build sprints. **Violations are sprint blockers.**

| # | Principle | Rule | Violation Check |
|---|-----------|------|-----------------|
| 1 | **Completeness** | Implement the whole feature, not a stub | Grep for TODO, FIXME, placeholder returns — none allowed |
| 2 | **Reuse** | Check existing code before writing new | Mandatory Grep for similar functionality before each sprint |
| 3 | **Pragmatic** | Simplest approach that satisfies the spec | No over-engineering beyond spec requirements |
| 4 | **DRY** | No duplication of existing functionality | Grep for duplicate patterns after writing |
| 5 | **Explicit** | Readable code over clever abstractions | No magic numbers, no implicit side effects |
| 6 | **Test-Alongside** | Write tests WITH code, not after | Every sprint deliverable includes its tests |

### Decision Classification

- **Mechanical decisions** (one right answer — auto-decide): file location, import style, naming convention, which existing util to reuse
- **Taste decisions** (reasonable disagreement — surface to user): API shape, state management approach, component decomposition strategy, data model design

---

## Platform-Aware Build Order

Each platform has a natural build sequence. Follow within each sprint.

### Flutter
```
models (Freezed) → repositories → services/providers (Riverpod) → shared widgets → screens → routing (GoRouter) → integration → tests
```

### Swift (iOS)
```
models → networking/services → ViewModels → Views (SwiftUI) → navigation → integration → tests
```

### React / Next.js
```
types/interfaces → API hooks/server actions → state management → shared components → pages → routing → integration → tests
```

### Backend (Supabase / Server)
```
migrations (schema) → RLS policies → server functions → edge functions → type generation → tests
```

**Full-stack rule:** Backend MUST be stable before frontend code begins. Server Boundary Checkpoint after backend deploys.

---

## PGE Skill Embedding

During build, embed principles from other PGE skills **inline** — do NOT invoke them as separate protocols.

| Code Layer | Embedded From | What to Check |
|------------|---------------|---------------|
| Backend / DB | `/pge` | Blast radius — trace dependency chains before schema changes. Read `backend-dependency-map.md`. Server Boundary Checkpoint: run 1-2 key queries after deploy |
| Frontend UI | `/pge-front` | Token compliance — use design system tokens, not hardcoded values. Touch targets >= 44pt. Semantics/aria labels |
| Architecture | `/pge-archi` | Module boundaries — respect layer separation, check coupling direction. Dependencies flow one way |
| Tests | `/pge-qa` | Coverage principles — test alongside, cover states (loading, error, empty, success). Reference `qa-coverage-map.md` |
| Design | `/pge-design` | Aesthetic coherence — follow brand direction from `design-system-map.md` if present |
| Documentation | `/pge-doc` | Map awareness — note which foundation maps need post-build updating |

**Embedding is lightweight.** Apply relevant checks per code layer. Full sub-protocol invocation is prohibited during build.

---

## Phase 0: Spec Analysis — Parse, Decompose, Order (Team)

### STEP 1: Task Analysis + Role Selection

**Required output:**
```
Build Mode: {Full Build | Plan Only | Resume | Single Sprint}
Platform: {Flutter | Swift | React | Vue}
Spec documents: [{list of provided specs with types}]
Selected roles: [{role1}, {role2}, ...]
Rationale: [Why these roles]
```

### STEP 2: Create Analysis Team

**TeamCreate** → Agent(team_name="pge-build-{slug}", name="{role}", run_in_background=true)

### Role Catalog

**spec-parser is always included.** 2-4 roles total.

| Role | Expertise | When to Select |
|------|-----------|----------------|
| **spec-parser** | Parse PRD → extract features, user stories, acceptance criteria | **Always** (required) |
| **arch-planner** | Map features to architecture layers, determine build order | ARCH spec or multi-module build |
| **ui-planner** | Parse screen designs → extract screens, components, interactions | SCREEN spec provided |
| **dependency-resolver** | Determine optimal build sequence, identify parallelizable units | > 8 implementable units |

Custom roles allowed. Rationale required.

### STEP 3: Spec Parsing

Each agent parses assigned spec documents with the following trust levels:

| Document | Trust Level | Approach |
|----------|------------|----------|
| PRD | **Accept** — source of truth for business intent | Parse as-is, extract features and acceptance criteria |
| Architecture | **Verify + Refine** — likely rough, needs detail | Validate feasibility, decompose into concrete modules/APIs |
| Screen Designs | **Accept structure, Reinterpret implementation** | Respect layout/flow, choose optimal technical approach |

Extraction per document:
1. **Implementable Units** — discrete, independently buildable pieces
2. **Data Models** — schemas, types, interfaces required
3. **Dependencies** — what each unit needs from other units or existing code
4. **Acceptance Criteria** — from PRD or derived from spec
5. **UI Components** — screens, widgets, interactions (if SCREEN spec)
6. **API Surface** — endpoints, contracts (if API/ARCH spec)

### STEP 4: Architecture Validation + Refinement

The architecture spec is rarely build-ready. Refine it before generating Sprint Contracts.

**4a. Validate Architecture Against PRD**
- Does the architecture cover ALL features in the PRD?
- Are there features with no clear architectural home?
- Are there architectural components not required by any feature?

**4b. Decompose Rough → Detailed**
Turn high-level architecture decisions into concrete specifications:

| Rough (input) | Detailed (output) |
|---------------|-------------------|
| "Use Supabase" | Table schemas, RLS policies, RPC list, Edge Functions |
| "MVVM pattern" | Module dependency graph, layer boundaries, file structure |
| "REST API" | Endpoint list, request/response types, error codes |
| "Auth system" | OAuth flow, token management, session architecture |
| "Real-time features" | Subscription channels, payload shapes, reconnection strategy |

**4c. 4-Section Architecture Review** (embedded from /pge-archi)
1. System Architecture — module boundaries, dependency graph, data flow
2. Code Architecture — file structure, naming, error propagation patterns
3. Test Architecture — coverage strategy, E2E decision matrix
4. Performance Architecture — bottleneck prediction, caching strategy

Apply relevant Cognitive Patterns: Boring by Default? Blast Radius contained? Essential complexity only?

**4d. Output: architecture-map.md**
Generate or update `docs/architecture-map.md` with the refined architecture.

**Required output:**
```
Architecture validation: {ACCEPTED_AS_IS | REFINED | MAJOR_REDESIGN}
Changes from original: [list of refinements]
```

### STEP 5: Platform Landscape + Design System Setup

**5a. Platform UI/UX Landscape** (embedded from /pge-design Phase 0)

Research the latest libraries/frameworks for the detected platform via WebSearch:

| Platform | Research Topics |
|----------|----------------|
| Swift/iOS | SwiftUI vs UIKit, animation libraries, component kits, SF Symbols, HIG |
| Flutter | Material 3, flutter_animate, Riverpod patterns, adaptive layout |
| React | UI library (shadcn/radix), state management, CSS approach |

**5b. Design System Setup**

Based on screen designs + landscape research, determine:
- Design tokens (colors, typography, spacing, radius)
- Reusable component list (buttons, cards, inputs, etc.)
- Animation/interaction patterns
- Icon system

Generate or update `docs/design-system-map.md`.

**Required output:**
```
Platform: {Swift | Flutter | React}
Key libraries: [{chosen libraries with rationale}]
Design system: {generated | existing | updated}
landscape.md: generated
```

### STEP 6: Wait + Synthesize

Agents share findings via SendMessage. Synthesize into unified analysis after all complete.

### STEP 7: Build Plan

Save to `.claude/pge-build/plan.md`:

```markdown
# Build Plan: {feature name}
Generated: {ISO timestamp}
Platform: {platform}

## Spec Sources
| # | Document | Type | Key Extractions |
|---|----------|------|-----------------|

## Implementable Units
| # | Unit | Type | Dependencies | Sprint | Est. Files |
|---|------|------|-------------|--------|------------|
| 1 | {name} | {model/service/screen} | None | S1 | N |
| 2 | {name} | {model/service/screen} | Unit 1 | S1 | N |
| 3 | {name} | {model/service/screen} | Unit 1, 2 | S2 | N |

## Sprint Assignments
### Sprint 1: {theme — e.g., "Data Layer + Core Services"}
- Units: [1, 2]
- Build order: {platform-specific order}
- Deliverables: [list]

### Sprint 2: {theme}
- Units: [3, 4]
- Deliverables: [list]

## Existing Code Reuse
| # | Existing Asset | Location | Reuse For |
|---|---------------|----------|-----------|

## Acceptance Criteria (from spec)
| # | Criterion | Source | Verification Method |
|---|-----------|--------|---------------------|

## Foundation Map Impact
| Map | Expected Changes | Update After |
|-----|-----------------|--------------|
| backend-dependency-map.md | {new tables/functions} | Phase 2 acceptance |
| design-system-map.md | {new components/tokens} | Phase 2 acceptance |
| architecture-map.md | {new modules} | Phase 2 acceptance |
| qa-coverage-map.md | {new test entries} | Phase 2 acceptance |

## Taste Decisions (surface to user)
| # | Decision | Options | Recommendation | Rationale |
|---|----------|---------|---------------|-----------|
```

### STEP 8: Sprint Contract Generation

For each sprint, write to `.claude/pge-build/sprints/sprint-{N}-{slug}.md`:

```markdown
# Sprint Contract: {theme}
Sprint: {N}/{total}
Spec reference: {PRD section / screen design page}

## What to Build
| # | Layer | Target | Description | File |
|---|-------|--------|-------------|------|
| 1 | Model | {name} | {desc} | {path} |
| 2 | Service | {name} | {desc} | {path} |
| 3 | UI | {name} | {desc} | {path} |
| 4 | Test | {name} | {desc} | {path} |

## What NOT to Build (Boundary)
- {existing module}: {why safe} → no change needed

## Acceptance Criteria
- [ ] {testable criterion 1} → Verification: {command or check}
- [ ] {testable criterion 2} → Verification: {command or check}

## Dependencies
- Requires: {sprint N-1 outputs}
- Blocked by: {prerequisites}

## Quality Gates
- Backend: /pge blast radius check needed? Y/N
- Frontend: /pge-front token check needed? Y/N
- Architecture: /pge-archi boundary check needed? Y/N
- Test minimum: {coverage target}
```

### STEP 9: Complexity Gate

| Condition | Action |
|-----------|--------|
| <= 8 sprints | Proceed to Phase 1 |
| 9-15 sprints | Proceed with caution — confirm with user |
| > 15 sprints | Recommend splitting into multiple /pge-build runs. Halt until confirmed |
| > 12 files in single sprint | Split the sprint |

### STEP 10: Shutdown Analysis Team

**For Plan Only mode:** Output plan and STOP.

**Phase Gate:** Build Plan + all Sprint Contracts + Acceptance Criteria required to proceed.

---

## Phase 1: Build Sprints — Sequential Execution with Quality Gates

### Execution Model

Sprints execute **sequentially** in build plan order. Never parallel.

```
For each Sprint:
  1. READ Sprint Contract
  2. REUSE CHECK — Grep for existing similar code
  3. BUILD — Follow platform order, apply 6 principles
  4. TEST — Write tests alongside (not after)
  5. GATE — Quality check + acceptance criteria
  6. COMMIT — Atomic: feat(build-s{N}): {description}
  7. INTEGRATE — Verify with previous sprints
  8. PROGRESS — Update tracker
```

### Per-Sprint Execution Loop

#### A. Pre-Sprint

1. Read Sprint Contract from `.claude/pge-build/sprints/sprint-{N}-{slug}.md`
2. Read relevant foundation maps for this sprint's scope
3. **Reuse check**: Grep/Read to verify no existing code covers this functionality
4. Surface any **taste decisions** to user before coding

#### B. Build — Follow Platform Order

For each unit in the sprint, following platform-aware build order:

1. **Create** the artifact (model, service, component, etc.)
2. **Write test** immediately after creation (Test-Alongside principle)
3. **Run tests** to confirm the unit works in isolation
4. **Apply embedded quality gates:**

| After Creating... | Check (Embedded) |
|-------------------|------------------|
| DB migration / schema | Read dependency map → trace blast radius → verify "What NOT to Build" boundary |
| Server function / API | Server Boundary Checkpoint: run 1-2 key queries to verify |
| UI component / screen | No hardcoded colors/sizes → use design system tokens |
| Any new module | Verify dependency direction matches architecture map |
| Test file | Covers loading + error + empty + success states |

5. **Commit** atomically: `feat(build-s{N}): {unit description}`

#### C. Sprint Gate — Quality Check

After all units in the sprint are built:

```
═══ SPRINT {N} GATE ═══

## Unit Status
| # | Unit | Built | Test | Commit |
|---|------|-------|------|--------|

## 6 Principles Check
| Principle | Status | Evidence |
|-----------|--------|----------|
| Completeness | ✓/✗ | {no TODOs / issue} |
| Reuse | ✓/✗ | {reused X / checked, none available} |
| Pragmatic | ✓/✗ | {simplest approach / justification} |
| DRY | ✓/✗ | {no duplication / issue} |
| Explicit | ✓/✗ | {readable / issue} |
| Test-Alongside | ✓/✗ | {all units have tests / missing} |

## Acceptance Criteria
- [x/] {criterion} → {PASS/FAIL: evidence}

## Build Verification
- [ ] All tests pass
- [ ] Static analysis clean
- [ ] No regressions in existing tests

Sprint {N}: {PASS | BLOCKED}
═══════════════════════════
```

**Sprint blockers (cannot close if):**
- Any of the 6 principles fails
- Any acceptance criterion fails
- Tests fail or static analysis has errors

**On BLOCKED:** Fix → re-run gate. 3 consecutive blocks on same sprint → STOP + escalate.

#### D. Inter-Sprint Integration

Before starting Sprint N+1:
- Verify Sprint N deliverables integrate with previous sprints
- Run full test suite (not just current sprint tests)
- If integration fails → fix before proceeding

### Progress Tracking

Update `.claude/pge-build/progress.md` after each sprint:

```
═══ BUILD PROGRESS ═══
Feature: {name}
Platform: {platform}
Updated: {ISO timestamp}

Sprint 1/N: {theme}     ████████████████████ PASS ✓
Sprint 2/N: {theme}     ████████████░░░░░░░░ IN PROGRESS (3/5 units)
Sprint 3/N: {theme}     ░░░░░░░░░░░░░░░░░░░░ PENDING

Units:    {completed}/{total}
Tests:    {passed}/{total}
Commits:  {N}
═══════════════════════
```

### Sprint Failure Handling

- **3-strike rule**: 3 failures on same sprint → STOP + escalate
- **> 8 files in sprint**: Challenge whether to split
- **Regression detected**: Revert last change, investigate before proceeding
- **Blocked by dependency**: Skip to next non-blocked sprint if possible, otherwise STOP

### Result Manifest

After all sprints complete, write to `.claude/pge-build/result.md`:

```markdown
# Build Result: {feature name}
Completed: {ISO timestamp}

## Sprint Summary
| # | Sprint | Theme | Units | Tests | Commits | Status |
|---|--------|-------|-------|-------|---------|--------|

## Files Created
| # | File | Type | Sprint | Description |
|---|------|------|--------|-------------|

## Tests Created
| # | Test File | Covers | Assertions | Sprint |
|---|-----------|--------|------------|--------|

## Spec Traceability
| # | Spec Criterion | Implementation | Test | Status |
|---|---------------|----------------|------|--------|

## Self-Assessment Weaknesses
- {areas where implementation is weakest — be honest}
- {fragile spots that could break under edge cases}

## Foundation Map Updates Needed
| Map | New Entries | Details |
|-----|------------|---------|

## Noticed Issues (out of scope)
- {issues observed but not fixed — record for follow-up}
```

**Phase Gate:** All sprints PASS + Result Manifest required to proceed.

---

## Phase 2: Acceptance — Independent Verification Against Original Spec

**Must be executed as a fresh context Agent subagent.**

### Acceptor Agent Prompt

```
You are the BUILD ACCEPTOR in a Spec-Builder-Acceptor workflow.

YOUR ROLE: Independently verify that the built feature matches the original spec.
You are checking SOMEONE ELSE's work. Be skeptical. Do NOT assume correctness.
You verify against the SPEC, not against the builder's self-assessment.

⚠️ Do NOT read "Self-Assessment Weaknesses" in result.md until after your own analysis.

Score Calibration:
9-10: Spec fully implemented, comprehensive tests, production-ready. Rare.
7-8:  Spec mostly implemented, minor gaps, deployable.
5-6:  Core features present, notable gaps or quality issues.
3-4:  Significant spec requirements missing.
1-2:  Build does not satisfy the spec.

## Inputs (read these files first)
1. Build plan: .claude/pge-build/plan.md
2. Sprint contracts: .claude/pge-build/sprints/sprint-*.md
3. Build result: .claude/pge-build/result.md
4. Foundation maps: docs/*.md (if they exist)

## Verification Process

### A. Spec Traceability Walk
For EVERY acceptance criterion in the build plan:
- Find the implementing code (Read actual files)
- Find the corresponding test
- Verify the test actually tests the criterion
- Record: PASS / FAIL / PARTIAL / NOT FOUND

### B. 6 Principles Audit
| Principle | Verification |
|-----------|-------------|
| Completeness | Grep for TODO, FIXME, stub returns, placeholder text |
| Reuse | Check for duplicated patterns vs existing codebase |
| Pragmatic | Flag over-engineering beyond spec |
| DRY | Grep for repeated code blocks |
| Explicit | Flag magic numbers, implicit side effects |
| Test-Alongside | Every created file has a corresponding test |

### C. Platform Build Order Verification
- Were layers built in the correct platform order?
- Are there dependency violations (UI depending on unbuilt service)?

### D. Cross-Feature Integration
- Do features work together correctly?
- Is navigation flow complete?
- Does data flow end-to-end (model → service → UI)?
- Run full test suite

### E. Devil's Advocate (Build)
1. Which spec requirement was most likely missed?
2. Are there edge cases the tests don't cover?
3. Does the build handle error states (loading, error, empty)?
4. Are new database tables properly secured (RLS/policies)?
5. Does the UI match the screen design spec?
6. Are API contracts actually validated, not just assumed?
7. Would a new developer understand this code without the spec?

### F. Anti-Pattern Check
| Anti-Pattern | How to Detect |
|---|---|
| Stub implementation | Functions that return hardcoded/mock data |
| Test theater | Tests that always pass (trivial assertions) |
| Spec drift | Implementation diverges from spec without rationale |
| Missing error handling | No try-catch, no error UI states |
| Hardcoded everything | Magic strings, numbers, URLs |
| Tests without assertions | Test exists but verifies nothing meaningful |
| Over-build | Features built that spec didn't ask for |
| Copy-paste coding | Duplicate blocks across files |
| Navigation dead ends | Routes that lead nowhere |
| Happy path only | No error/empty/loading state handling |

### G. Build Acceptance Score (BAS) — 5 Dimensions (1-10)

| Dimension | Weight | Measures | Hard-fail |
|-----------|--------|----------|-----------|
| **Spec Fidelity** | 30% | Does code match spec requirements? | < 6 |
| **Code Quality** | 20% | 6 principles compliance | — |
| **Test Coverage** | 20% | Test-alongside, state coverage | — |
| **Integration** | 20% | Tests pass, features connect, no regressions | < 6 |
| **Completeness** | 10% | No stubs, TODOs, placeholder — foundation maps noted | — |

BAS = Σ (Dimension Score × Weight)

| Grade | Score |
|-------|-------|
| A | 9.0-10 |
| B | 7.0-8.9 |
| C | 5.0-6.9 |
| D | 3.0-4.9 |
| F | 1.0-2.9 |

### H. Verdict
- **PASS**: All >= 7, BAS >= 7.0
- **CONDITIONAL PASS**: All >= 6, BAS >= 6.0
- **FAIL**: Any hard-fail (Spec Fidelity < 6 or Integration < 6)

### I. Write Report → .claude/pge-build/acceptance-eval.md
```

### Handling Acceptor Results

- **PASS** → Foundation Map Update → Archive → Final Report
- **CONDITIONAL PASS** → Fix items → Foundation Map Update → Archive (no re-evaluation)
- **FAIL** → Fix items → Re-run Acceptor (fresh context)
- **FAIL loop 2+** → Halt + escalation

### Foundation Map Updates (Post-Acceptance)

After PASS or CONDITIONAL PASS, update relevant PGE foundation maps:

| Map | Update When | What to Add |
|-----|------------|-------------|
| `docs/backend-dependency-map.md` | New tables, functions, policies created | Full dependency chain entries |
| `docs/design-system-map.md` | New components, tokens used | Component + token entries |
| `docs/architecture-map.md` | New modules, data flows added | Module dependency entries |
| `docs/qa-coverage-map.md` | New screens, test files created | Screen states + test registry |

Only update maps that exist. For missing maps, note in Final Report.

### Archive

`.claude/pge-build/history/{YYYYMMDD}T{HHMM}_{feature-slug}.md` (under 150 lines)

---

## Final Report

```
BUILD REPORT
════════════════════════════════════════
Feature:         {feature name}
Platform:        {platform}
Mode:            {Full Build | Plan Only | Resume | Single Sprint}
Date:            {ISO timestamp}
Verdict:         {PASS | CONDITIONAL PASS | FAIL}

── Phase 0: Spec Analysis ──
Team:            [{roles}]
Spec documents:  {N} ({types})
Units extracted: {N}
Sprints planned: {N}

── Phase 1: Build Sprints ──
| Sprint | Theme          | Units | Tests | Status |
|--------|----------------|-------|-------|--------|
| S1     | {theme}        | N     | N     | PASS   |
| S2     | {theme}        | N     | N     | PASS   |

Total commits:   {N}
Files created:   {N}
Tests created:   {N}

── Phase 2: Acceptance ──
| Dimension          | Score  |
|--------------------|--------|
| Spec Fidelity      | X/10   |
| Code Quality       | X/10   |
| Test Coverage      | X/10   |
| Integration        | X/10   |
| Completeness       | X/10   |

BAS:             X/10 (Grade: X)
Evaluator:       independent acceptor (fresh context)

Foundation Maps Updated:
  - {map}: {N entries added}

Post-Build Recommendations:
  - Run /pge-qa for comprehensive QA scan
  - Run /pge-front for frontend quality audit
  - Run /pge-archi for architecture validation
  - Run /pge-doc to refresh all foundation maps
════════════════════════════════════════
```

---

## PGE Skill Orchestration

```
              ┌─────────────┐
              │  /pge-build  │  Creates new code from spec
              └──────┬──────┘
                     │
      ┌──────────────┼──────────────┐
      │              │              │
┌─────▼──────┐ ┌────▼─────┐ ┌─────▼──────┐
│ READS FROM  │ │ PRODUCES │ │ HANDS OFF   │
└─────┬──────┘ └────┬─────┘ └─────┬──────┘
      │              │              │
  Foundation    Working code   Post-build:
  maps (all)    + tests +      → /pge-qa   (QA scan)
  for context   sprint         → /pge-front (frontend audit)
                history        → /pge-archi (architecture review)
                               → /pge-doc  (map freshness)
```

### Orchestration Rules

1. **Pre-build**: Read all foundation maps. Reference artifacts, don't invoke skills.
2. **During build**: Embed PGE quality principles inline per layer (see Embedding table).
3. **Post-build**: Recommend (don't auto-invoke) relevant review skills based on what was built.
4. **Foundation maps**: Note which need updating → update after acceptance, or recommend /pge-doc.

---

## Escalation Rules

- **Phase 0**: Spec contradictory or unreadable → Halt, ask user
- **Phase 0**: > 15 units → Recommend splitting into multiple /pge-build runs
- **Phase 1**: 3-strike rule per sprint → STOP + escalate
- **Phase 1**: > 8 files in sprint → Challenge whether to split
- **Phase 1**: Regression in existing tests → Fix before next sprint
- **Phase 2**: Spec Fidelity < 6 → Major rework needed
- **Phase 2**: FAIL loop 2+ → Halt + escalation
- **Phase 2**: BAS Grade F → Feature may need redesign
- **Any phase**: Platform Unknown → Ask user to specify
- **Cross-skill**: > 50% issues in one domain → Recommend that PGE skill first

## Important Rules

- Cannot proceed to next Phase without required outputs
- `/pge-build` tasks cannot skip the protocol
- Phase 0 agents are read-only — no code creation
- Phase 1: team lead builds sequentially — no parallel sprints
- Phase 2 Acceptor: fresh context Agent subagent mandatory
- **6 Build Principles are sprint blockers** — all must pass per sprint gate
- **Test-Alongside is non-negotiable**: every unit ships with tests
- PGE skill embedding is lightweight — do NOT invoke full sub-protocols
- Foundation maps updated only after acceptance, not during build
- Spec is the source of truth — not assumptions, not similar projects
- Atomic commits per unit: `feat(build-s{N}): {description}`
- Taste decisions surfaced to user; mechanical decisions auto-decided
- SendMessage sharing required in Phase 0, team shutdown required
- Reuse check mandatory before each sprint
