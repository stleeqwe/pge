---
name: pge-qa
description: |
  PGE QA Protocol (Scanner-Fixer-Verifier).
  Spawns a team of QA specialist agents to scan code quality across 9 categories,
  fix issues by priority with atomic commits, and verify with independent
  evaluator using Health Score. Supports Full/Quick/Diff-aware/Regression modes.
  Use when asked with /pge-qa flag appended.
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

# /pge-qa — PGE QA Protocol (Scanner-Fixer-Verifier)

When the user appends `/pge-qa` to a task request, the full QA protocol is enforced.

## Project Initialization (First Run)

```bash
mkdir -p .claude/pge-qa/baselines
mkdir -p .claude/pge-qa/history

if [ -f .gitignore ] && ! grep -q ".claude/pge-qa/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE-qa workflow state files\n.claude/pge-qa/" >> .gitignore
fi
```

### Automatic Platform Detection

```
Flutter:    Glob pubspec.yaml → "flutter:" section
React/Next: Glob package.json → "react" dependency
Vue/Nuxt:   Glob package.json → "vue" dependency
```

**Required output:** `Platform: {Flutter | React | Vue | Unknown}`

### QA Coverage Map Initialization

If `docs/qa-coverage-map.md` does not exist, notify the user:
> "No QA Coverage Map found. Would you like me to analyze the project and generate `docs/qa-coverage-map.md`?"

Upon approval, analyze the project and auto-generate:

```markdown
# QA Coverage Map

## 1. Screen/Feature Inventory
| # | Screen/Feature | Route/Path | Priority |
|---|----------------|------------|----------|

## 2. User Flow Map
### Flow 1: {flow name}
[Start] → Screen A → Screen B → [Complete]
- Happy path / Edge cases / State transitions

## 3. State Combination Matrix
### Screen: {screen name}
| # | State | Condition | Expected UI | Test exists? | Test file |
|---|-------|-----------|-------------|-------------|-----------|
| 1 | loading | data fetching | spinner/skeleton | Y/N | |
| 2 | error | API failure | error message + retry | Y/N | |
| 3 | empty | no data | empty state illustration | Y/N | |
| 4 | success | data loaded | content rendered | Y/N | |

## 4. Test Path Registry
| Type | File | Covers Screen/Flow | Assertions |
|------|------|--------------------|------------|

## 5. Coverage Gaps
| # | Screen/Feature | Missing | Severity | Reason |
|---|----------------|---------|----------|--------|

## 6. Cross-Domain Test Dependencies
| # | Flow | Depends on | If changed, re-test |
|---|------|------------|---------------------|
```

This map is updated on every `/pge-qa` run. Phase 1 reads the map and determines test scope, Phase 3 verifies each map entry.

## CRITICAL: Agent Spawning Rules

1. **Use TeamCreate to compose the team.** Do not spawn plain Agent subagents.
2. **Do not use Explore subagents.** All teammates must be spawned as `general-purpose` agents.
3. **Each teammate shares findings with others via SendMessage.** No silos allowed.
4. **Use TaskCreate to create a task list** and assign tasks to teammates.
5. **Phase 1 (Scanner) agents are read-only** — code modifications happen only in Phase 2 by the team lead.

## Input

$ARGUMENTS — Description of the QA target

## Mode Detection

- **Full**: Default, full app/project QA
- **Quick**: "quick", "brief", specific screen/feature name → scan only that area
- **Diff-aware**: "changes", "PR", "branch" → based on git diff main...HEAD
- **Regression**: "regression", "baseline comparison" → compared against previous baseline

**Required output:** `QA Mode: {Full | Quick | Diff-aware | Regression}`

### Diff-aware Mode
```bash
git diff main...HEAD --name-only
```
Changed files → extract relevant screens/features from qa-coverage-map → scan only those areas.

---

## Issue Taxonomy (9 Categories)

| # | Category | Weight | Verification Method |
|---|----------|--------|---------------------|
| 1 | **Log/Crash** | 15% | flutter analyze, try-catch coverage, FlutterError handling |
| 2 | **Routing/Navigation** | 10% | GoRoute/Navigator Grep, navigation graph, deep links |
| 3 | **Visual/UI** | 10% | Token usage rate, hardcoded values, widget tree |
| 4 | **Functional** | 15% | State handling (loading/error/empty), form validation, business logic |
| 5 | **UX** | 10% | Touch target size, confirmation dialogs, feedback UI |
| 6 | **Performance** | 10% | Unnecessary rebuilds, N+1, memory leaks |
| 7 | **Content** | 5% | Hardcoded strings, placeholders, i18n |
| 8 | **Accessibility** | 10% | Semantics, color contrast, touch targets |
| 9 | **Platform/Native** | 15% | Permissions, lifecycle, deep links, offline, secure storage |

### Severity Levels

| Severity | Definition |
|----------|------------|
| CRITICAL | Crash, data loss, security vulnerability |
| HIGH | Major feature broken, no workaround |
| MEDIUM | Feature works but has issues, workaround available |
| LOW | Minor UI/code quality issue |
| COSMETIC | Style, alignment, and other minor visual issues |

### Health Score Grading

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100 | Production-ready, almost no issues |
| B | 75-89 | Deployable, minor issues present |
| C | 60-74 | Major issues need fixing |
| D | 40-59 | Numerous serious issues |
| F | 0-39 | Fundamental problems, architecture review recommended |

---

## Role Catalog

The orchestrator selects **2-4 roles** suited to the task. **code-quality-scanner is always included**.

| Role | Expertise | Covers Categories | When to Select |
|------|-----------|-------------------|----------------|
| **code-quality-scanner** | Static analysis, lint, code patterns | LC, FN, CT, PF | **Always included** (required) |
| **test-coverage-analyst** | Missing tests, path analysis, qa-coverage-map cross-reference | FN, PF | When test files exist |
| **a11y-platform-checker** | Accessibility + platform native | A11Y, PN | For mobile apps |
| **ux-flow-checker** | User flows, state handling, navigation | RN, UX, VI, FN | When UI code is involved |
| **security-auditor** | Security vulnerabilities, auth/authz, secure storage | LC, PN | When user input/auth code is involved |

Roles outside the catalog can also be defined as needed for the task. Rationale is required for role selection.

---

## Phase 1: Scanner — QA Profile + Health Score Baseline

### STEP 1: Task Analysis + Role Selection

**Required output:**
```
QA Mode: {Full | Quick | Diff-aware | Regression}
Platform: {Flutter | React | Vue}
Selected roles: [{role1}, {role2}, ...]
Rationale: [Why these roles are needed]
Scan scope: {Full | Specific screen | git diff changes}
```

### STEP 2: Create Scanner Team

**TeamCreate** → Agent(team_name="pge-qa-scan-{slug}", name="{role}", run_in_background=true)

Each agent prompt includes:
- Team name, role, expertise, assigned categories
- Instruction to read qa-coverage-map (if available)
- Specific Grep/Read patterns per category
- SendMessage sharing rules
- Read-only constraint + TaskUpdate instruction

### STEP 3: Wait + Synthesize

Agents share findings with each other via SendMessage. Synthesize after completion.

### STEP 4: QA Profile Report

Save to `.claude/pge-qa/qa-profile.md`:

```
═══ QA PROFILE REPORT ═══

## Context
Target: [Analysis target]
Platform: {Flutter | React | Vue}
Mode: {Full | Quick | Diff-aware | Regression}
Date: {ISO timestamp}

## Team Analysis
{Key findings per role}

## Health Score Baseline
| # | Category | Score (0-100) | Issues | Critical | Weight |
|---|----------|--------------|--------|----------|--------|
| 1 | Log/Crash | X | N | N | 15% |
| 2 | Routing/Navigation | X | N | N | 10% |
| 3 | Visual/UI | X | N | N | 10% |
| 4 | Functional | X | N | N | 15% |
| 5 | UX | X | N | N | 10% |
| 6 | Performance | X | N | N | 10% |
| 7 | Content | X | N | N | 5% |
| 8 | Accessibility | X | N | N | 10% |
| 9 | Platform/Native | X | N | N | 15% |

**Health Score = X/100 (Grade: X)**

## Coverage Map Analysis
| Screen | Total States | Tested | Coverage % |

## Issue Summary
| # | Category | Severity | File:Line | Issue | Auto-fixable? |

## Cross-Skill Issues
| # | Issue | Recommended Skill | Reason |
═══════════════════════════════════════
```

**Phase Gate:** Cannot proceed to Phase 2 without Health Score + Issue Summary.

### STEP 5: Shutdown Scanner Team

---

## Phase 2: Fixer — Fix by Priority Order

### STEP 1: Triage + Priority Matrix

**Priority Score = Severity x 2 - Effort - Risk**

| Factor | 5 (Best) | 1 (Worst) |
|--------|----------|-----------|
| Severity | CRITICAL | COSMETIC |
| Effort | One-line change | Large-scale refactoring |
| Risk | No side effects | Possible feature regression |

| Score | Tier | Action |
|-------|------|--------|
| >= 6 | Quick Win | Execute immediately |
| 3-5 | Standard | Plan then execute |
| <= 2 | Backlog | Record only |

### STEP 2: Fix Loop (Quick Wins first, descending Score)

For each fix:
1. **BEFORE**: Capture current code (file:line + snippet)
2. **FIX**: Implement minimal change (team lead only)
3. **TEST**: Verify existing tests pass + generate regression test
4. **AFTER**: Capture changed code
5. **COMMIT**: Atomic commit — `fix(qa-{category}): {description}`
6. **RECORD**: Add Before/After evidence to Fix Result

**WTF-likelihood self-regulation:**
```
Start at 0%
Each revert:                +15%
Each fix touching >3 files: +5%
After fix 15:               +1% per additional fix
Touching unrelated files:   +20%
```
- >= 50%: STOP, request user confirmation
- **Hard cap: 50 fixes**

**3-strike rule:** 3 fix failures → STOP + escalation
**Revert on regression:** Execute `git revert HEAD` immediately

### STEP 3: Cross-Skill Routing

Handle Phase 1 cross-skill issues:
- Backend consistency → Recommend switching to `/pge`
- Performance bottleneck → Recommend switching to `/pge-perf`
- Design/UX quality → Recommend switching to `/pge-design`
- Pure QA → Fix directly in Phase 2

### STEP 4: Fix Result Manifest

Save to `.claude/pge-qa/fix-result.md`:
```markdown
# Fix Result — {ISO timestamp}

## Applied Fixes
| # | Issue | Category | Score | Before | After | Test | Commit |

## Regression Tests Generated
| # | Test file | Covers issue | Assertions |

## Backlog (Score <= 2)
| # | Issue | Score | Reason |

## Cross-Skill Recommendations
| # | Issue | Recommended Skill | Severity |

## qa-coverage-map Updates
| Screen | State | Before (Test?) | After (Test?) |
```

**Phase Gate:** Before/After evidence required for each fix.

---

## Phase 3: Verifier — Independent Verification

**Must be executed as a fresh context Agent subagent.**

### Verifier Agent Prompt:

```
You are the VERIFIER in a Scanner-Fixer-Verifier QA workflow.

YOUR ROLE: Independently verify that QA fixes are complete and correct.
You are checking SOMEONE ELSE's work. Be skeptical. Do NOT assume correctness.

Score Calibration:
9-10: Nearly all issues resolved, no regressions. Rare.
7-8:  Major issues resolved, production-deployable.
5-6:  Some resolved, unresolved issues remain.
3-4:  Obvious omissions.
1-2:  Fixes made things worse.

## Inputs
1. QA Profile: .claude/pge-qa/qa-profile.md
2. Fix Result: .claude/pge-qa/fix-result.md
3. QA Coverage Map: docs/qa-coverage-map.md (if available)

## Verification Process

### A. Recalculate Health Score
Re-measure all 9 categories using the same Grep/Read methods as Phase 1.

### B. Verify Each Fix Individually
For each fix: Read the code to confirm changes, run regression tests, verify existing tests pass.

### C. Coverage Map Walk
For each entry in the target screen's State Combination Matrix:
- Confirm test exists + meaningful assertion
- Verify User Flow happy path + edge cases

### D. Regression Check
- Do all existing tests pass?
- Did any fix introduce new issues?

### E. Devil's Advocate (QA)
1. Did the fix only treat the symptom while missing the root cause?
2. Does the test actually verify the real issue, or is it superficial?
3. Does the security fix cover all attack vectors?
4. Are the regression tests actually runnable?
5. Are there screens not registered in the qa-coverage-map?
6. Is "Test exists? = Y" backed by an actually valid test?

### F. Anti-Pattern Check
| Anti-Pattern | How to Detect |
|---|---|
| "Fixed" without test | Fix exists but no related test |
| Symptom-only fix | Root cause unresolved |
| Over-engineering fix | Large-scale refactoring for a 1-line fix |
| Test that always passes | Assertion is trivial |
| Security theater | Superficial verification only |
| Functionality removal | Claiming "simplification" by removing features |

### G. Score 9 Categories (0-100 each)
**HARD FAIL:** Log/Crash < 60, Platform/Native security < 60

### H. Health Score Before/After
| Category | Before | After | Δ |

### I. Verdict
- **PASS**: Health Score improved, grade B+ or above, no hard-fail
- **CONDITIONAL PASS**: Health Score improved, grade C+, no hard-fail
- **FAIL**: Hard-fail, Health Score decreased, or grade D or below

### J. Write Report → .claude/pge-qa/qa-eval.md
```

### Verifier Result Handling
- **PASS** → Archive → Output QA Report
- **CONDITIONAL PASS** → Fix unmet items → Archive (no re-verification needed)
- **FAIL** → Fix → Re-run Verifier (fresh context)
- **FAIL loop 2+ times** → Halt + escalation

---

## Final Report

```
QA REPORT
════════════════════════════════════════
Target:          [QA target]
Platform:        {Flutter | React | Vue}
Mode:            {Full | Quick | Diff-aware | Regression}
Date:            {ISO timestamp}
Verdict:         {PASS | CONDITIONAL PASS | FAIL}

── Scanner ──
Team:            [{roles}]
Issues found:    {N} ({critical} critical)
Baseline:        Health Score X/100 (Grade X)

── Fixer ──
Applied:         {N} fixes ({quick wins} quick wins)
Backlogged:      {N}
Commits:         {N} atomic commits
Cross-skill:     {N} routed

── Verifier ──
| Category          | Before | After  | Δ      |
|-------------------|--------|--------|--------|
| Log/Crash         | X      | X      | +X     |
| Routing/Nav       | X      | X      | +X     |
| Visual/UI         | X      | X      | +X     |
| Functional        | X      | X      | +X     |
| UX                | X      | X      | +X     |
| Performance       | X      | X      | +X     |
| Content           | X      | X      | +X     |
| Accessibility     | X      | X      | +X     |
| Platform/Native   | X      | X      | +X     |

Health Score:    Before X/100 (X) → After X/100 (X)
Evaluator:       independent verifier (fresh context)

Backlog:
  - [Score <= 2 items]

Cross-Skill:
  - [other PGE skill recommendations]
════════════════════════════════════════
```

### Archive
`.claude/pge-qa/history/{YYYYMMDD}T{HHMM}_{target-slug}.md` (under 100 lines)

---

## Escalation Rules

- **Phase 1 failure**: Platform Unknown → Request explicit specification from user
- **Phase 2 failure**: 3-strike, 50 fix hard cap
- **Phase 3 FAIL loop 2+ times**: Halt + escalation
- **Health Score F (< 40)**: Architecture review recommended
- **Cross-skill > 50%**: Recommend running the relevant PGE skill first

---

## Database Interaction Priority

**MCP-first rule: When Supabase MCP (or any DB MCP) is available, ALWAYS use it over CLI.** MCP provides direct, faster, and more reliable DB access. Only fall back to CLI if MCP tool call explicitly fails.

## Important Rules

- Cannot proceed to next Phase without each Phase's **required output**
- `/pge-qa` tasks **cannot skip the protocol**
- **MCP-first**: Always use Supabase MCP over CLI when available
- Phase 1 agents **must not modify code**
- Phase 2 modifications are **team lead only** — atomic commit per fix
- Phase 3 Verifier must be a **fresh context Agent subagent**
- **Actual Grep/Read measurement** required — "I assume it's fine" is not acceptable
- SendMessage mutual sharing required, team shutdown required
- Before/After code evidence required
- 50 fix hard cap, 3-strike escalation
