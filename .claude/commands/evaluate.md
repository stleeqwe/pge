# /evaluate — PGE Phase 3: Evaluator

Run active, skeptical verification of completed work against the sprint contract.
This skill spawns an Agent subagent with **fresh context** to defeat self-evaluation bias.

## Input

$ARGUMENTS — (optional) Override contract path. Defaults to `.claude/pge/contract.md`

## Procedure

### Step 1: Prepare Evaluation Context

1. Verify these files exist:
   - `.claude/pge/contract.md` (sprint contract from /preflight)
   - `.claude/pge/result.md` (result manifest from Generator phase)
   - `docs/backend-dependency-map.md` (dependency map)
2. If result manifest doesn't exist, tell the user: "No result manifest found. Run the implementation first."

### Step 2: Spawn Evaluator Agent

Spawn an Agent subagent with this prompt structure. The agent runs in fresh context — it has NO knowledge of the Generator's work process, only the artifacts.

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
For each acceptance criterion in the contract:
1. Execute the verification command (SQL query, curl, CLI command)
2. Compare actual result to expected result
3. Record: PASS / FAIL / UNEXPECTED

### B. Dependency Map Walk (Multi-Layer Verification)
For each affected resource listed in the contract, look up ALL dependencies in the dependency map and verify using the appropriate method:

**Layer 1 — Database / Backend**
- Functions: execute with test params → must not error, return expected shape
- Views: query with LIMIT 0 → verify column list
- Triggers/hooks: verify they exist and fire correctly
- Constraints: verify intact (CHECK, FK, UNIQUE)
- Indexes: verify expected indexes present
- Access policies: verify correct permissions

**Layer 2 — Server Functions / API Endpoints**
- Read source code → verify resource references are updated
- Check that queries use correct column/field names
- If function serves HTTP: test endpoint to verify response shape
- Verify deployment configuration

**Layer 3 — Client Code**
- Models: fields match backend schema, serialization keys correct, generated files fresh
- Services: API calls include new/changed fields, JOIN/relation syntax correct
- State management: invalidation covers affected queries, real-time subscriptions parse correctly
- UI: screens reference correct model fields

**Layer 4 — Cross-cutting**
- Check every item in "What Does NOT Change" — confirm truly unaffected
- Verify real-time subscribed resources: payload shape unchanged OR client parsing updated
- Verify generated/compiled files are fresh

### C. Devil's Advocate Checklist
Answer EACH question explicitly. "N/A" only with justification.

1. What dependency did the Generator most likely skip?
2. Is the most fragile query/function still working? (Run it.)
3. Did the Generator DROP views before recreating?
4. Are there new fields that should be in the dependency map but aren't?
5. Did the Generator actually deploy, or just write code?
6. Could this change silently break access policies?
7. Does the migration handle existing data?

### D. Anti-Pattern Check
| Anti-Pattern | How to Detect |
|---|---|
| "Verified" without running queries | No query output in result manifest |
| Updated function but not dependent view | View query returns error |
| Changed real-time table without checking client | Client parsing breaks |
| Updated model but didn't regenerate | Generated files are stale |
| Migration uses IF EXISTS defensively | Hides real errors |
| SQL string interpolation in new code | Grep for string templates in files touching DB |
| TOCTOU race in status transitions | Check if status change uses atomic WHERE old_status = X |
| LLM output written to DB without validation | Check AI/LLM endpoint output handling |
| New enum value not handled by all consumers | Grep for sibling enum values, verify all switch/if chains |
| Fix applied without root cause investigation | Result manifest lacks "Root cause:" section |

### D-bis. Code Quality Review (Informational)
For each changed file in the result manifest, check:
- [ ] No conditional side effects (all branches apply matching side effects)
- [ ] No stale comments contradicting new code
- [ ] No test gaps for new code paths (negative-path + edge cases)
- [ ] No performance regressions (N+1 queries, missing eager loading)

### D-ter. Scope Drift Detection
Compare Sprint Contract scope with actual changes:
1. List all files changed (from result manifest)
2. Compare against "What Changes" table in contract
3. Flag any files changed that are NOT in the contract scope → **SCOPE CREEP**
4. Flag any contract items that were NOT implemented → **INCOMPLETE**

### E. Domain-Specific Review Checklist
<!-- PROJECT-SPECIFIC: The evaluator should check domain-specific items
     defined in this file. Add your project's domain checklists below. -->

For each affected domain, run the domain-specific checklist items.
Each item must be verified with an actual query or code read — not assumed.

<!-- Example domain checklist:
#### Auth Domain
- [ ] Session integrity: auth flow produces valid session
- [ ] Protected fields: trigger blocks direct UPDATE on sensitive columns
- [ ] Token refresh: works without error

#### Data Domain
- [ ] CRUD operations: all work correctly
- [ ] Cascade deletes: FK cascades behave as expected
- [ ] Search/filter: queries return correct results
-->

### F. Score 5 Dimensions (1-10 each)

1. **Schema Integrity** — Migration correct? Data preserved? Constraints intact?
2. **Security / Access Policies** — Policies correct? No unauthorized access? (**HARD FAIL if < 6**)
3. **Dependency Consistency** — ALL dependency map items verified? (**HARD FAIL if < 6**)
4. **Test Coverage** — Tests pass? New tests added? Edge cases covered?
5. **Deployment Completeness** — Everything deployed? Generated files fresh? Analysis clean?

### G. Verdict

- **PASS**: All dimensions >= 7
- **CONDITIONAL PASS**: All >= 6, some < 7. List specific items to fix.
- **FAIL**: Any hard-fail dimension < 6. List specific remediation required.

### H. Write Report
Write full evaluation report to .claude/pge/eval.md with:
- Each acceptance criterion result (PASS/FAIL)
- Dependency map walk results
- Devil's advocate answers
- Anti-pattern check results
- Domain-specific checklist results
- Dimension scores
- Verdict + remediation list (if FAIL/CONDITIONAL)

Then return the verdict and key findings to the main agent.
```

### Step 3: Process Evaluator Result

Based on the evaluator's verdict:

- **PASS**: Archive → report to user. Task complete.
- **CONDITIONAL PASS**: Show findings. Fix specific items. Archive after fixes. No re-evaluation needed.
- **FAIL**: Show findings. Fix all remediation items. Run `/evaluate` again (fresh evaluator).

### Step 4: Archive PGE Record

On PASS or CONDITIONAL PASS, create a history file:

1. Generate filename: `.claude/pge/history/{YYYYMMDD}T{HHMM}_{task-slug}.md`
2. Write a concise summary (under 100 lines):
   ```markdown
   # {task description}
   Date: {ISO timestamp}
   Verdict: {PASS/CONDITIONAL PASS}
   Scores: Schema:{n} Security:{n} Deps:{n} Tests:{n} Deploy:{n}

   ## Scope
   {resources and layers changed}

   ## Blast Radius Boundary
   {what was checked and confirmed safe}

   ## Issues Found
   {any issues, or "None"}

   ## Key Decisions
   {notable judgment calls}
   ```

## Important Rules

- The evaluator Agent MUST run in fresh context — never inline the evaluation.
- The evaluator MUST execute actual verification commands, not just review code.
- "I assume it works" is never acceptable — RUN the verification.
- After a FAIL → fix → re-evaluate cycle, the evaluator gets fresh context again.
