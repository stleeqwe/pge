---
name: pge-archi
description: |
  PGE Architecture Protocol (Analyzer-Implementer-Validator).
  Spawns a team of architecture specialist agents to deep-review system,
  code, test, and performance architecture across 4 sections, apply
  improvements by priority, and validate with independent evaluator
  using Architecture Health Score. Diagrams are first-class artifacts.
  Use when asked with /pge-archi flag appended.
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

# /pge-archi — PGE Architecture Protocol (Analyzer-Implementer-Validator)

When the user appends `/pge-archi` to a task request, the full architecture protocol is enforced.

"Is this architecture sound, scalable, and maintainable?"

## Project Initialization (First Run)

```bash
mkdir -p .claude/pge-archi/history .claude/pge-archi/diagrams

if [ -f .gitignore ] && ! grep -q ".claude/pge-archi/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE-archi workflow state files\n.claude/pge-archi/" >> .gitignore
fi
```

### Architecture Map Initialization

If `docs/architecture-map.md` does not exist:
> "No Architecture Map found. Would you like me to analyze the project and generate one?"

Upon approval, auto-generate:

```markdown
# Architecture Map

## 1. Module Dependencies
| Module | Depends On | Depended By | Coupling Level |

## 2. Data Flow
(ASCII diagram: Client → Server → DB with state management and policies)

## 3. External Integrations
| Service | Purpose | Interface | Failure Mode |

## 4. State Management
| Store/Provider | Scope | Shared? | Invalidation Strategy |

## 5. Layer Boundaries
(ASCII diagram: Presentation → Application → Domain → Infrastructure)

## 6. Technology Decisions
| Decision | Choice | Rationale | Alternatives Considered |

## 7. Cross-Domain Impact Chains
| Trigger | Affected Domains | Cascade Path |
```

This map is updated on every `/pge-archi` run. Phase 1 reads the map to scope the review, Phase 3 validates map accuracy.

## CRITICAL: Agent Spawning Rules

1. **Use TeamCreate to compose the team.** Do not spawn plain Agent subagents.
2. **Do not use Explore subagents.** All teammates must be `general-purpose` agents.
3. **Each teammate shares findings via SendMessage.** No silos allowed.
4. **Use TaskCreate to create a task list** and assign to teammates.
5. **Phase 1 (Analyzer) agents are read-only** — modifications happen only in Phase 2 by team lead.

## Input

$ARGUMENTS — Description of the architecture review/improvement target

## Mode Detection

- **Review**: Default. Full architecture review of target area
- **Scope Check**: "scope", "blast radius", "impact" — Phase 0 only
- **Improve**: "improve", "refactor", "restructure" — full review + implementation
- **Validate**: "validate", "verify", "check" — Phase 3 only against existing architecture

**Required output:** `Architecture Mode: {Review | Scope Check | Improve | Validate}`

---

## 15 Cognitive Patterns — Architecture Review Lens

These are a thinking framework, not a mechanical checklist. Reviewers name the 2-3 most relevant patterns per finding.

| # | Pattern | Core Question |
|---|---------|---------------|
| 1 | **Blast Radius Instinct** | What is the worst-case scope of this change? |
| 2 | **Boring by Default** | Does this use the simplest technology that works? |
| 3 | **Systems over Heroes** | Does the system function without relying on specific individuals? |
| 4 | **Reversibility Bias** | Can this decision be undone cheaply? |
| 5 | **Failure Mode Fluency** | What does this look like when it breaks in production? |
| 6 | **Load Awareness** | Does this hold up at 10x current scale? |
| 7 | **Dependency Gravity** | Does every dependency earn its weight? |
| 8 | **Boundary Discipline** | Are module responsibilities clearly separated? |
| 9 | **Observable by Default** | Can you tell what this system is doing without reading code? |
| 10 | **Data Lifecycle Thinking** | Where does this data live, move, expire, and get deleted? |
| 11 | **Security as Architecture** | Is security a structural property, not a bolt-on? |
| 12 | **Contract-First Mentality** | Are interfaces defined before implementations? |
| 13 | **Migration Awareness** | How does this deploy without downtime or data loss? |
| 14 | **Test Architecture Fitness** | Does the test structure reflect the system structure? |
| 15 | **Simplicity Entropy** | Is this system getting simpler or more complex over time? |

---

## Phase 0: Scope Challenge — Complexity Check

### Step 1: Complexity Check

| Dimension | Threshold |
|-----------|-----------|
| Files involved | > 20 = HIGH |
| Cross-domain impact | > 3 domains = HIGH |
| Dependency depth | > 5 = HIGH |
| State mutations | > 10 = HIGH |

**Required output:**
```
Complexity: {LOW | MEDIUM | HIGH | EXTREME}
Files: N
Domains: [list]
Max dependency depth: N
```

### Step 2: Existing Code Audit

Read `docs/architecture-map.md`, cross-verify with actual code. Flag all discrepancies.

### Step 3: Minimum Change Set

- What MUST change vs what COULD change
- Which changes are independent (parallelizable)
- Which are coupled (sequential)

### Step 4: Scope Gate

| Complexity | Action |
|-----------|--------|
| LOW | Proceed to Phase 1 |
| MEDIUM | Proceed with caution |
| HIGH | Require user confirmation |
| EXTREME | Recommend splitting. Halt until confirmed |

**For Scope Check mode:** Output Phase 0 results and STOP.

---

## Phase 1: Architecture Analyzer — 4-Section Deep Review

### STEP 1: Task Analysis + Role Selection

**Required output:**
```
Architecture Mode: {Review | Improve | Validate}
Complexity: {LOW | MEDIUM | HIGH | EXTREME}
Selected roles: [{role1}, {role2}, ...]
Rationale: [Why these roles are needed]
```

### STEP 2: Create Analyzer Team

**TeamCreate** → Agent(team_name="pge-archi-review-{slug}", name="{role}", run_in_background=true)

### STEP 3: 4-Section Deep Review

#### Section 1: System Architecture
Module boundaries, dependency graph, data flow, scaling, security, external integrations.
**Required diagram:** Module Dependency Graph (ASCII)
**Per finding:** One realistic production failure scenario

#### Section 2: Code Architecture
Organization, DRY, error handling, complexity hotspots, over/under-engineering.
**Required diagram:** Code Complexity Heatmap (ASCII)

#### Section 3: Test Architecture
Coverage mapping, unit/integration/E2E balance, E2E decision matrix, regression rule, test isolation.
**Required diagram:** Test Coverage Map (ASCII)

#### Section 4: Performance Architecture
N+1 patterns, memory management, caching strategy, bottlenecks, bundle/payload size.
**Required diagram:** Data Flow + Bottleneck Map (ASCII)

### STEP 4: Architecture Health Score (AHS)

| Dimension | Weight | Hard-fail |
|-----------|--------|-----------|
| **Modularity** | 25% | < 5 |
| **Testability** | 20% | — |
| **Scalability** | 20% | — |
| **Security** | 20% | < 5 |
| **Maintainability** | 15% | — |

| Grade | Score |
|-------|-------|
| A | 9.0-10 |
| B | 7.0-8.9 |
| C | 5.0-6.9 |
| D | 3.0-4.9 |
| F | 1.0-2.9 |

### STEP 5: Architecture Profile Report → `.claude/pge-archi/archi-profile.md`

**Phase Gate:** AHS + Issue Summary required to proceed.

### STEP 6: Shutdown Analyzer Team

**For Review mode:** Output report and STOP.

---

## Phase 2: Implementer — Apply Architecture Improvements

**Only entered in Improve mode.**

**Priority Score = Severity × 2 - Effort - Risk** (>= 6: Quick Win, 3-5: Standard, <= 2: Backlog)

Improvement Loop: BEFORE → IMPROVE → TEST → AFTER → COMMIT (`refactor(archi-{section}): {desc}`)

**Cognitive Pattern self-check before each change:**
- Reversibility Bias: Can this be undone if wrong?
- Blast Radius Instinct: What else could this break?
- Boring by Default: Is this the simplest fix?

**Guardrails:**
- 8+ files → STOP, split into phases
- 3-strike rule → STOP + escalate
- Revert on regression
- Hard cap: 30 improvements

Cross-Skill Routing: backend → `/pge`, performance → `/pge-perf`, code quality → `/pge-qa`, frontend → `/pge-front`, design → `/pge-design`

Result Manifest → `.claude/pge-archi/improvement-result.md`

---

## Phase 3: Architecture Validator — Independent Verification

**Must be executed as a fresh context Agent subagent.**

```
You are the ARCHITECTURE VALIDATOR.
Be skeptical. Do NOT assume correctness.

Score Calibration:
9-10: Exemplary, almost no issues. Rare.
7-8:  Sound architecture, production-ready.
5-6:  Functional, significant gaps remain.
3-4:  Obvious omissions.
1-2:  Analysis is misleading or improvements worsened things.

Verify: Recalculate AHS, verify each diagram against code, improvement verification,
architecture map walk, Devil's Advocate (7 questions), Anti-Pattern check (7 items),
cognitive pattern audit.

Devil's Advocate (Architecture):
1. Which module boundary is most likely to be violated next?
2. Is the most coupled component identified and addressed?
3. Are there circular dependencies not shown in the diagram?
4. Does the test architecture reflect the system architecture?
5. Are security boundaries enforced or aspirational?
6. Could a new developer add a feature without violating the architecture?
7. What happens when the most-depended-on module has an outage?

Anti-Patterns:
- "Reviewed" without reading code (no file:line refs)
- Diagram doesn't match code
- Over-engineering recommendation
- Security theater
- Test gap dismissed
- Improvement without test
- Aspirational architecture (diagram shows future, not current)

HARD FAIL: Modularity < 5 or Security < 5

Verdict: PASS (all >= 7) / CONDITIONAL PASS (all >= 5) / FAIL (hard-fail)
```

→ `.claude/pge-archi/archi-eval.md`

Archive: `.claude/pge-archi/history/{YYYYMMDD}T{HHMM}_{slug}.md`

---

## Role Catalog

**system-architect is always included.** 2-4 roles total.

| Role | Expertise | Sections | Required? |
|------|-----------|----------|-----------|
| **system-architect** | Module boundaries, dependency graph, data flow, security | S1, S2, S4 | **Required** |
| **data-flow-analyst** | Data lifecycle, state management, caching, real-time | S1, S4 | Data flow changes |
| **security-reviewer** | Trust boundaries, auth architecture, access control | S1, S2 | Auth/security changes |
| **test-architect** | Coverage analysis, test strategy, E2E decisions | S3 | Test architecture in scope |
| **dependency-auditor** | Import chains, circular deps, coupling metrics | S1, S2 | High dependency complexity |

Custom roles allowed. Rationale required.

---

## ASCII Diagram Philosophy

**Diagrams are first-class artifacts, not decoration.**

Every Phase 1 review MUST produce at minimum:
1. Module Dependency Graph
2. Code Complexity Heatmap
3. Test Coverage Map
4. Data Flow + Bottleneck Map

Diagrams must reflect CURRENT code, be verifiable, include a legend, and be stored in `.claude/pge-archi/diagrams/`.

---

## Escalation Rules

- Phase 0 EXTREME → Halt, recommend splitting
- Architecture Map missing → Offer to regenerate
- Phase 2: 3-strike, 30 improvement hard cap
- Phase 3 FAIL loop 2+ → Halt + escalation
- AHS Grade F → Fundamental redesign recommended
- Security HARD FAIL → Mandatory remediation
- Cross-skill > 50% → Run relevant PGE skill first

## Important Rules

- Required output missing → cannot proceed to next Phase
- `/pge-archi` tasks cannot skip the protocol
- Phase 1 agents must not modify code
- Phase 2: team lead only, atomic commits
- Phase 3: fresh context Agent subagent
- Actual Read/Grep verification required
- ASCII diagrams are mandatory
- SendMessage sharing required, team shutdown required
- Before/After evidence required
- 30 improvement cap, 3-strike escalation
- Cognitive patterns are a lens — name relevant ones per finding
- Every architectural decision includes one realistic failure scenario
