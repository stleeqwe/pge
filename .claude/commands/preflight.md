# /preflight — Sprint Contract Generator (PGE Phase 1: Planner)

Analyze the blast radius of a requested task **before modifying any code**, then produce a Sprint Contract with testable acceptance criteria.

## Input

$ARGUMENTS — Task description (e.g., "add color field to items", "implement follow notifications")

## Procedure

### Step 1: Identify Affected Resources

1. Read `docs/backend-dependency-map.md`.
2. From the task description, identify all **affected tables/resources**.
3. For each, extract the full dependency chain:
   - Access policies (RLS, RBAC, etc.)
   - Server functions (RPCs, API endpoints, stored procedures)
   - Views / aggregations
   - Server-side functions (Edge Functions, Lambda, API routes)
   - Triggers / hooks
   - Client services / state management
   - Real-time subscriptions
   - Foreign keys / cascades
4. Check whether any **cross-domain impact chains** apply.

### Step 2: Verify Current State

5. Read the **actual current code** of identified functions, views, and endpoints:
   - Database functions: grep latest definition in migrations
   - Views: find latest CREATE OR REPLACE statement
   - Server functions: read the endpoint source code
   - Client: read relevant service/provider/model files
6. Cross-verify that the dependency map matches current code. Flag any discrepancies.

### Step 3: Write Sprint Contract

Write the contract to `.claude/pge/contract.md` AND display it to the user:

```markdown
# Sprint Contract: {task description}
Generated: {ISO timestamp}

## 1. Scope

### What Changes
| # | Layer | Target | Change | File |
|---|-------|--------|--------|------|
| 1 | Schema | ... | ... | ... |
| 2 | Function | ... | ... | ... |
| ... | ... | ... | ... | ... |

### What Does NOT Change (Blast Radius Boundary)
For each dependency checked and cleared:
- {dependency}: {why it's safe} → no change needed

## 2. Acceptance Criteria

Each criterion MUST have a specific, runnable verification command.

### Schema Verification
- [ ] `{query to verify schema change}`
  - Expected: {specific result}

### Function Verification
- [ ] `{query to verify function works}`
  - Expected: {specific result shape}

### Access Policy Verification
- [ ] `{query to verify permissions}`
  - Expected: {access result}

### View Verification
- [ ] `{query to verify view}`
  - Expected: {column list without error}

### Endpoint Verification
- [ ] `{curl or similar command}`
  - Expected: {response shape}

### Regression Checks (things that must NOT break)
- [ ] `{query for most fragile dependency}`
  - Expected: {normal result}

### Code Quality Verification
- [ ] No SQL string interpolation in new code (use parameterized queries)
- [ ] Status transitions use atomic `WHERE old_status = X` clause
- [ ] New enum values handled by all consumers (grep sibling values)

### Tests & Deploy
- [ ] All tests pass
- [ ] Static analysis clean
- [ ] Migrations applied
- [ ] Server functions deployed (if applicable)

## 3. Failure Criteria

What would indicate breakage:
- {symptom} → {root cause from dependency map}

## 4. Affected Domains
- [ ] {Domain 1}
- [ ] {Domain 2}
- [ ] ...

## 5. Cross-Domain Chains
(List any applicable chains from the dependency map)

## 6. Change Order
1. Schema — Create migration
2. Policies — Update access policies (if needed)
3. Functions — Update server functions (if needed)
4. Views — Recreate views (if needed)
5. Server functions — Update and deploy (if needed)
6. Apply migrations / deploy
7. Client models — Update data classes
8. Client services — Update API calls
9. State management — Update providers/stores
10. UI — Update screens
11. Tests — Write/update + run full suite
12. Analysis — Static analysis must be clean
```

### Step 4: Complexity Gate

7. If the Sprint Contract lists **8+ files** in "What Changes":
   - Challenge: can this be split into smaller changes?
   - If not splittable, note in contract: `Complexity: HIGH — N files, cannot be reduced because [reason]`
   - Evaluator will apply stricter verification for high-complexity contracts.

### Step 5: Proceed Immediately

8. After outputting the contract, **proceed directly to Phase 2 (Generator)** without waiting for user approval. The contract is informational — the user will intervene if they want changes.
9. If the user interrupts with changes, update the contract and restart.

## Important Rules

- Every acceptance criterion MUST be a runnable command, not a vague statement.
- Always include your project's most fragile query as a regression check.
- Never underestimate impact. **Overestimation is safer than underestimation.**
- Views typically require DROP + CREATE when columns change (DB constraint).
- If new dependencies are discovered not in the map, note them for post-task map update.
