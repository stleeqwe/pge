---
name: pge
description: |
  PGE Full Protocol (Planner-Generator-Evaluator). Backend consistency
  verification: plan blast radius, execute in strict order, verify with
  independent evaluator agent. Use when asked with /pge flag appended.
  Covers Investigation (4-phase debugging), Direct task (plan→generate→evaluate),
  and Code review (2-pass checklist→evaluate).
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - TaskCreate
  - TaskUpdate
  - TaskList
---

# /pge — PGE Full Protocol (Planner-Generator-Evaluator)

When the user appends `/pge` to a task request, the full PGE protocol is enforced.

## Project Initialization (First Run)

If PGE files do not exist in the project, create them automatically:

```bash
# PGE state directory
mkdir -p .claude/pge/history

# Add to .gitignore
if [ -f .gitignore ] && ! grep -q ".claude/pge/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE workflow state files (ephemeral per-task)\n.claude/pge/" >> .gitignore
fi
```

If `docs/backend-dependency-map.md` does not exist, notify the user:
> "No dependency map found. Would you like me to analyze the project and generate `docs/backend-dependency-map.md`?"
> If the user approves, analyze the project's DB schema, functions, policies, and views to auto-generate it.

## Input

$ARGUMENTS — Task description

## Task Type Detection

Analyze the task description to determine its type:

- **Investigation** — Symptom/bug/error keywords ("broken", "slow", "why", "error", "bug", "fix")
- **Direct task** — Add/change/delete keywords ("add", "update", "remove", "implement", "change", "delete")
- **Code review** — Review keywords ("review", "check", "inspect")

Output the detection result: `PGE Mode: {Investigation | Direct | Review}`

---

## Investigation Mode

### STEP 1: Systematic Debugging Protocol (4-phase, all steps mandatory)

#### Phase 1: Root Cause Investigation
1. Organize the symptoms/logs provided by the user
2. Trace related code paths using Read
3. Run `git log --oneline -20 -- <affected-files>`
4. Determine whether the issue is reproducible

**Required output:**
```
Root cause hypothesis: [Specific, verifiable claim]
Affected files: [File list]
```

Cannot proceed to the next step without this output.

#### Phase 2: Pattern Analysis

| Pattern | Signature | Match? |
|---------|-----------|--------|
| Race condition | Intermittent, timing-dependent | Y/N |
| Nil/null propagation | TypeError, NoSuchMethodError | Y/N |
| State corruption | Inconsistent data, partial updates | Y/N |
| Integration failure | Timeout, unexpected response | Y/N |
| Configuration drift | Works locally, fails remote | Y/N |
| Stale cache | Shows old data | Y/N |

**Required output:** `Pattern match: {Matched pattern or "New pattern"}`

#### Phase 3: Hypothesis Testing
1. Propose a method to verify the hypothesis (logs, assertions, SQL, etc.)
2. Execute verification if possible
3. 3-strike rule: STOP + escalate after 3 failures

**Required output:** `Hypothesis verified: {Y/N} — {Evidence}`

#### Phase 4: Scope Lock + Backend/Frontend Determination
**Required output:**
```
Scope: [Affected module boundaries]
Backend change needed: {Y/N}
```

### STEP 2: Branch

- **Backend change needed: Y** → Phase 1: Planner → Phase 2: Generator → Phase 3: Evaluator
- **Backend change needed: N** → Fix → Test → Analyze → Output Debug Report

### STEP 3: Debug Report
```
DEBUG REPORT
════════════════════════════════════════
Symptom:         [Symptom reported by user]
Root cause:      [Actual cause]
Pattern:         [Matched pattern]
Fix:             [Changes made, file:line references]
Evidence:        [Test results, reproduction confirmation]
Regression test: [Newly added test file:line]
Status:          DONE | DONE_WITH_CONCERNS | BLOCKED
════════════════════════════════════════
```

---

## Direct Task Mode

### Phase 1: Planner — Generate Sprint Contract

#### Step 1: Identify Affected Resources

1. Read `docs/backend-dependency-map.md`.
2. From the task description, identify all **affected tables/resources**.
3. For each, extract the full dependency chain:
   - Access policies (RLS, RBAC, etc.)
   - Server functions (RPCs, stored procedures)
   - Views / aggregations
   - Server-side functions (API endpoints, Edge Functions, Lambda)
   - Triggers / hooks
   - Client services / state management
   - Real-time subscriptions
   - Foreign keys / cascades
4. Check whether any **cross-domain impact chains** apply.

#### Step 2: Verify Current State

5. Read the **actual current code** of identified functions, views, and endpoints.
6. Cross-verify that the dependency map matches current code. Flag discrepancies.

#### Step 3: Write Sprint Contract

Write to `.claude/pge/contract.md` AND display:

```markdown
# Sprint Contract: {task description}
Generated: {ISO timestamp}

## 1. Scope

### What Changes
| # | Layer | Target | Change | File |
|---|-------|--------|--------|------|
| 1 | Schema | ... | ... | ... |

### What Does NOT Change (Blast Radius Boundary)
- {dependency}: {why it's safe} → no change needed

## 2. Acceptance Criteria
Each criterion MUST have a specific, runnable verification command.

### Schema Verification
- [ ] `{query}` → Expected: {result}

### Function Verification
- [ ] `{query}` → Expected: {result}

### Access Policy Verification
- [ ] `{query}` → Expected: {result}

### Regression Checks (things that must NOT break)
- [ ] `{most fragile query}` → Expected: {normal result}

### Code Quality Verification
- [ ] No SQL string interpolation (use parameterized queries)
- [ ] Status transitions use atomic WHERE clause
- [ ] New enum values handled by all consumers

### Tests & Deploy
- [ ] All tests pass
- [ ] Static analysis clean
- [ ] Migrations applied
- [ ] Server functions deployed (if applicable)

## 3. Failure Criteria
- {symptom} → {root cause}

## 4. Affected Domains
- [ ] {domain list}

## 5. Cross-Domain Chains
(from dependency map)

## 6. Change Order
(project-specific execution order — schema → policies → functions → deploy → client)
```

#### Step 4: Complexity Gate

If **8+ files** in "What Changes": challenge whether it can be split.

#### Planner Rules

- Every acceptance criterion MUST be a runnable command.
- Always include the most fragile query as a regression check.
- Never underestimate impact. **Overestimation is safer.**
- Views typically require DROP + CREATE when columns change.
- Note new dependencies for post-task map update.

Proceed **immediately to Phase 2** after outputting the contract.

---

### Phase 2: Generator — Execution

Follow the Change Order from the Sprint Contract.

**Server Boundary Checkpoint** (after deploy):
- Run 1-2 key queries from the acceptance criteria
- If they fail, STOP → fix server-side → redeploy
- Proceed to client code only after server verification passes

**Rollback Protocol** (on deploy failure):
- **Migration failure**: repair command, fix, re-apply
- **Partial migration**: Do NOT rollback successful ones. Fix failing and re-apply.
- **Server function deploy failure**: Previous version active. Fix and re-deploy.
- **Both server + client modified**: Server rollback first, then revert client.

After completion, write the **Result Manifest** to `.claude/pge/result.md`:
- List of changed files with descriptions
- Deployment results
- Test results
- Self-assessment of fragile areas
- **Noticed Issues** (out of scope): record unrelated issues observed

---

### Phase 3: Evaluator — Independent Verification

**Spawn an Agent subagent with fresh context**.

Evaluator Agent prompt:

```
You are the EVALUATOR in a Planner-Generator-Evaluator workflow.

YOUR ROLE: Independently verify that implementation work is complete and correct.
You are checking SOMEONE ELSE's work. Be skeptical. Do NOT assume correctness.

## Inputs (read these files first)
1. Sprint contract: .claude/pge/contract.md
2. Result manifest: .claude/pge/result.md
3. Dependency map: docs/backend-dependency-map.md

## Verification Process

### A. Run ALL Acceptance Criteria
Execute each verification command. Compare actual vs expected. Record: PASS / FAIL / UNEXPECTED.

### B. Dependency Map Walk
For each affected resource, verify all dependencies:
- **Layer 1 — Database**: functions, views, triggers, constraints, indexes, policies
- **Layer 2 — Server**: endpoint code, API response verification
- **Layer 3 — Client**: models match schema, services query correctly, state management invalidates
- **Layer 4 — Cross-cutting**: "What Does NOT Change" confirmed, real-time payloads, generated files fresh

### C. Devil's Advocate Checklist
1. What dependency was most likely skipped?
2. Is the most fragile query still working? (Run it.)
3. Were views DROP'd before recreate?
4. New fields missing from dependency map?
5. Actually deployed, or just wrote code?
6. Could this silently break access policies?
7. Migration handles existing data? (NOT NULL needs DEFAULT.)

### D. Anti-Pattern Check
| Anti-Pattern | How to Detect |
|---|---|
| "Verified" without running queries | No query output in manifest |
| Updated function but not dependent view | View query errors |
| Changed real-time table without checking client | Client parsing breaks |
| Updated model but didn't regenerate | Generated files stale |
| Migration uses IF EXISTS defensively | Hides real errors |
| SQL string interpolation | Grep for string templates |
| TOCTOU race in status transitions | No atomic WHERE |
| New enum not handled by all consumers | Grep sibling values |
| Fix without root cause investigation | Manifest lacks "Root cause:" |

### D-bis. Code Quality Review
- [ ] No conditional side effects
- [ ] No stale comments
- [ ] No test gaps
- [ ] No performance regressions

### D-ter. Scope Drift Detection
Compare contract scope vs actual changes. Flag SCOPE CREEP or INCOMPLETE.

### E. Domain-Specific Review Checklist
Run for every affected domain. Read domain checklists from dependency map or CLAUDE.md.
Each item must be verified with actual query or code read — not assumed.

### F. Score 5 Dimensions (1-10)
1. Schema Integrity
2. Security / Access Policies (**HARD FAIL if < 6**)
3. Dependency Consistency (**HARD FAIL if < 6**)
4. Test Coverage
5. Deployment Completeness

### G. Verdict
- **PASS**: All ≥ 7
- **CONDITIONAL PASS**: All ≥ 6, some < 7
- **FAIL**: Any hard-fail < 6

### H. Write Report
Write to .claude/pge/eval.md. Return verdict + key findings.
```

#### Handling Evaluator Results

- **PASS**: Archive → done
- **CONDITIONAL PASS**: Fix items → Archive → done (no re-evaluation needed)
- **FAIL**: Fix items → Re-run Evaluator (fresh context)

#### Archive

Create `.claude/pge/history/{YYYYMMDD}T{HHMM}_{task-slug}.md` (under 100 lines).

#### Evaluator Rules

- **Must be run as a fresh context Agent subagent**
- **Running actual queries is mandatory**
- "I assume it works" is not acceptable
- On FAIL → fix → re-evaluate, create a fresh context again

---

## Review Mode

### STEP 1: Pre-Landing Review Checklist

**Pass 1 — CRITICAL:**
- [ ] SQL injection
- [ ] TOCTOU races
- [ ] LLM output trust boundary
- [ ] Enum completeness

**Pass 2 — INFORMATIONAL:**
- [ ] Conditional side effects
- [ ] Dead code / stale comments
- [ ] Test gaps
- [ ] Performance (N+1)

**Fix-First Heuristic:**
- AUTO-FIX: dead code, N+1, stale comments, magic numbers
- ASK: security, race conditions, design decisions, >20 lines

### STEP 2: Evaluator (Phase 3 only)
Verify using domain-specific checklists

### STEP 3: When Issues Are Found
Automatically transition to Direct Task Mode → Planner → Generator → Evaluator

---

## Database Interaction Priority

**MCP-first rule: When Supabase MCP (or any DB MCP) is available, ALWAYS use it over CLI.**

| Operation | MCP Available | MCP Unavailable |
|-----------|--------------|-----------------|
| Schema queries | `execute_sql` | `supabase db` CLI |
| RLS/policy check | `execute_sql` | `supabase db` CLI |
| RPC verification | `execute_sql` | `supabase db` CLI |
| Migration apply | `apply_migration` | `supabase db push` |
| Function deploy | MCP deploy tool | `supabase functions deploy` |
| View verification | `execute_sql` | `supabase db` CLI |
| Data queries | `execute_sql` | `supabase db` CLI |

**Never default to CLI when MCP is connected.** MCP provides direct, faster, and more reliable DB access. Only fall back to CLI if MCP tool call explicitly fails.

This rule applies to ALL phases: Planner (blast radius verification), Generator (deployment), and Evaluator (acceptance criteria execution).

## Important Rules

- Cannot proceed to the next Phase without each Phase's **required output**
- `/pge` tasks **cannot skip the protocol**
- **MCP-first**: Always use Supabase MCP over CLI when available
- Escalation: Stop after 3-strike or 2+ PGE FAIL loops
