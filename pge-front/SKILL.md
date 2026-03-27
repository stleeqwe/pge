---
name: pge-front
description: |
  PGE Frontend Quality Protocol (Scanner-Fixer-Verifier).
  Spawns a team of frontend specialist agents to audit UI code quality
  across 8 categories (tokens, originality, craft, state, a11y, responsive,
  navigation, frontend performance), fix issues by priority, and verify
  with independent evaluator using Front Health Score.
  Core focus: design choices that kill performance and real-time responsiveness.
  Use when asked with /pge-front flag appended.
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

# /pge-front — PGE Frontend Quality Protocol

When the user appends `/pge-front` to a task request, force-execute the full frontend QA protocol.

## Project Initialization (First Run)

```bash
mkdir -p .claude/pge-front/history .claude/pge-front/baselines

if [ -f .gitignore ] && ! grep -q ".claude/pge-front/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE-front workflow state files\n.claude/pge-front/" >> .gitignore
fi
```

### Automatic Platform Detection
```
Flutter:    Glob pubspec.yaml → "flutter:" section
React/Next: Glob package.json → "react" dependency
Vue/Nuxt:   Glob package.json → "vue" dependency
```
**Required output:** `Platform: {Flutter | React | Vue | Unknown}`

### Design System + Design System Map Detection

If `docs/design-system-map.md` does not exist:
> "No Design System Map found. Shall I analyze the project and generate one?"

On approval, auto-generate (Tokens, Shared Components, Screens, Cross-Screen Patterns).
This map is owned by `/pge-front` with **update permissions**. `/pge-design` has read-only access.

**Required output:**
```
Design System: {detected files or "None"}
Token files: {color, typography, spacing, radius — presence status}
```
Cannot proceed to next Phase if platform/design system is not detected.

## CRITICAL: Agent Spawning Rules

1. **Must use TeamCreate.** Simple Agent subagent is prohibited.
2. **Do not use Explore subagents.** General-purpose only.
3. **Must share via SendMessage.** Silos are prohibited.
4. **TaskCreate** to generate task lists + assign to teammates.
5. **Phase 1 agents are read-only** — only Phase 2 team lead may modify.

## Input

$ARGUMENTS — Frontend inspection target

## Mode Detection

- **Full**: Full app frontend QA
- **Quick**: Specific screen/feature only
- **Diff-aware**: Changed files from git diff main...HEAD only

**Required output:** `Front Mode: {Full | Quick | Diff-aware}`

---

## 8 Inspection Categories + Front Health Score

### Category 1: Design Token Compliance (15%)

| # | Item | Grep Pattern | Severity |
|---|------|----------|--------|
| DT1 | Hardcoded colors | `Color\(0x\|Colors\.\|#[0-9a-fA-F]{3,8}\|rgba?\(` | HIGH |
| DT2 | Hardcoded fonts | `fontSize:\s*\d+\|font-size:\s*\d+px` | HIGH |
| DT3 | Hardcoded spacing | `EdgeInsets\.\w+\(\s*\d+\|\d+px\s*(;\|})` | MEDIUM |
| DT4 | Hardcoded radii | `BorderRadius\.circular\(\s*\d+\|border-radius:\s*\d+px` | MEDIUM |
| DT5 | Token reference rate | token_refs / (token_refs + hardcoded) × 100 | — |

### Category 2: Originality Check (5%)

| # | Anti-Pattern | Grep Signature |
|---|---|---|
| OR1 | Purple gradient | `from-purple`, `bg-gradient` |
| OR2 | Default theme | Using default values without custom ThemeData |
| OR3 | Template layout | Hero-Features-Pricing-CTA pattern |
| OR4 | Stock icons only | Zero custom icons |
| OR5 | Generic copy | Lorem ipsum, placeholder |
| OR6 | Excessive nesting | 3+ levels of meaningless wrapping |
| OR7 | Uniform spacing | All spacing uses a single value |

### Category 3: Craft Quality (10%)

| # | Item | Severity |
|---|------|--------|
| CR1 | Typography hierarchy completeness | HIGH |
| CR2 | Spacing grid adherence (4/8px) | HIGH |
| CR3 | Color contrast WCAG AA 4.5:1 | CRITICAL |
| CR4 | Icon style consistency | MEDIUM |
| CR5 | Animation consistency | LOW |
| CR6 | Border radius consistency | MEDIUM |

### Category 4: State Completeness (15%)

| # | Item | Severity |
|---|------|--------|
| ST1 | Loading state UI | HIGH |
| ST2 | Error state handling | HIGH |
| ST3 | Empty state UI | MEDIUM |
| ST4 | Form validation | HIGH |
| ST5 | Confirmation dialogs | MEDIUM |

### Category 5: Accessibility (10%)

| # | Item | Severity |
|---|------|--------|
| A1 | Semantics/aria-label | HIGH |
| A2 | Color contrast 4.5:1 | CRITICAL |
| A3 | Touch target 48dp/44px | CRITICAL |
| A4 | Screen reader support | HIGH |
| A5 | Focus management | MEDIUM |

### Category 6: Responsive Layout (8%)

| # | Item | Severity |
|---|------|--------|
| RL1 | MediaQuery/LayoutBuilder usage | HIGH |
| RL2 | Fixed size overuse | MEDIUM |
| RL3 | Overflow handling | HIGH |
| RL4 | Text overflow | MEDIUM |

### Category 7: Navigation Consistency (7%)

| # | Item | Severity |
|---|------|--------|
| NV1 | Route definition consistency | HIGH |
| NV2 | Back navigation handling | MEDIUM |
| NV3 | Deep link support | LOW |
| NV4 | Route depth 3+ warning | LOW |
| NV5 | Navigation guards | HIGH |

### Category 8: Frontend Performance (30%) — CRITICAL

**Core question: "Are design choices degrading performance?"**

Boundary with `/pge-perf`: `/pge-perf` = "Is the code slow?" (DB, server). `/pge-front` = "Are design choices making it slow?" (rebuilds, assets, libraries).

| # | Item | Severity |
|---|------|--------|
| FP1 | Heavy libraries (bundle size, unused imports, lightweight alternatives) | HIGH |
| FP2 | Unnecessary rebuilds (setState frequency, Consumer/Watch scope) | CRITICAL |
| FP3 | Excessive animations (concurrent AnimationController count) | MEDIUM |
| FP4 | Widget tree depth (10+ levels of nesting) | HIGH |
| FP5 | Unoptimized images/assets (raw loading, no WebP, no caching) | HIGH |
| FP6 | Provider/State cascading updates (ref.invalidate chains) | CRITICAL |
| FP7 | Memory leak design (missing dispose, not using ListView.builder) | CRITICAL |
| FP8 | GPU overdraw (ClipRRect, Opacity, BackdropFilter overuse) | MEDIUM |

**Flutter Grep:**
```
FP2: setState\(\s*\(\)\s*\{  |  ref\.watch\(  |  Consumer\(
FP5: Image\.asset\(  |  Image\.network\(
FP6: ref\.invalidate\(  |  ref\.refresh\(  |  notifyListeners\(
FP7: StreamSubscription  |  \.listen\(  |  Timer\(  → verify dispose()
FP8: ClipRRect\(  |  Opacity\(  |  BackdropFilter\(
```

**Hard-fail: < 40**

---

## Front Health Score

```
Score = Σ (Category Score × Weight)
```

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100 | Excellent frontend quality |
| B | 75-89 | Good |
| C | 60-74 | Major issues need fixing |
| D | 40-59 | Severe |
| F | 0-39 | Design system rebuild recommended |

**Hard-fail:** Frontend Performance < 40, Accessibility < 40

---

## Role Catalog

**Always include the 3 required roles.** Maximum 5.

| Role | Responsibility | Required? |
|------|------|------|
| **design-token-auditor** | DT, OR, CR | **Required** |
| **a11y-auditor** | A11Y, CR(CR3) | **Required** |
| **front-perf-auditor** | All FP | **Required** |
| **state-flow-checker** | ST, NV, RL | When UI code present |
| **ux-pattern-reviewer** | ST, NV, OR | When new screens present |

---

## Phase 1: Scanner — Front Profile + Baseline

### STEP 1: Task Analysis + Role Selection
```
Required output:
Front Mode: {Full | Quick | Diff-aware}
Platform: {Flutter | React | Vue}
Selected roles: [{role1}, {role2}, ...]
Rationale: [Selection reason]
```

### STEP 2: Create Scanner Team
TeamCreate → Agent(team_name="pge-front-scan-{slug}", name="{role}", run_in_background=true)

### STEP 3: Wait + Synthesize

### STEP 4: Front Profile Report → `.claude/pge-front/front-profile.md`

**Phase Gate:** Cannot proceed to Phase 2 without Front Health Score + Issue Summary.

### STEP 5: Shutdown Scanner Team

---

## Phase 2: Fixer — Fix in Priority Order

**Priority Score = Severity × 2 - Effort - Risk** (>= 6: Quick Win, 3-5: Standard, <= 2: Backlog)

Fix Loop: BEFORE → FIX → TEST → AFTER → COMMIT (`fix(front-{cat}): {desc}`)

WTF-likelihood: revert +15%, >3 files +5%, after 15th +1%/fix, unrelated +20%. >= 50% STOP. Hard cap 50.

Cross-Skill Routing: backend → `/pge`, backend perf → `/pge-perf`, creative → `/pge-design`, code quality → `/pge-qa`

Fix Result → `.claude/pge-front/fix-result.md`

---

## Phase 3: Verifier — Independent Verification

**Fresh context Agent subagent is required.**

```
You are the VERIFIER in a frontend QA workflow.
Be skeptical. Do NOT assume correctness.

Verify: Recalculate Health Score, verify each fix individually, walk Design System Map, regression check.

Devil's Advocate (Frontend):
1. Are token replacements actual design system values?
2. Are accessibility improvements just superficial wrapping?
3. Are extracted components actually reusable?
4. Are error/empty state UIs just placeholders?
5. Did performance improvements cause functional regressions?
6. Are there still heavy computations inside ListView.builder?
7. Is the resolution acceptable after image optimization?

Anti-Pattern: Token theater, Semantics spam, Over-abstraction,
Functionality removal, Builder without benefit, Animation overkill,
Import bloat, Dispose amnesia

HARD FAIL: Frontend Performance < 40, Accessibility < 40

Verdict:
- PASS: improved, grade B+, no hard-fail
- CONDITIONAL PASS: improved, grade C+, no hard-fail
- FAIL: hard-fail, decreased, or grade D
```

→ `.claude/pge-front/front-eval.md`

Archive: `.claude/pge-front/history/{YYYYMMDD}T{HHMM}_{slug}.md`

---

## Escalation Rules

- Platform/design system not detected → User confirmation required
- 3-strike, 50 fix hard cap
- FAIL loop 2+ times → Stop
- Grade F → Design system rebuild recommended
- Cross-skill > 50% → Run that skill first
- Multiple creative issues → Recommend switching to `/pge-design`

## Important Rules

- Cannot proceed to next Phase without required outputs
- Phase 1 is read-only, only Phase 2 team lead may modify
- Phase 3 requires fresh context
- Actual Grep/Read measurements required
- Before/After evidence required
- Has update permissions for design-system-map
