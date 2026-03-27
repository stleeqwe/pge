---
name: pge-doc
description: |
  PGE Documentation Protocol (Scanner-Generator-Verifier).
  Spawns a team of documentation specialist agents to inventory all docs,
  detect staleness/gaps with freshness scores, generate missing or update
  stale documentation, and verify with independent evaluator using
  Doc Health Score. Maintains freshness for ALL PGE foundation maps.
  Use when asked with /pge-doc flag appended.
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

# /pge-doc — PGE Documentation Protocol (Scanner-Generator-Verifier)

When the user appends `/pge-doc` to a task request, the full documentation protocol is enforced.

"Are all project documents accurate, complete, and fresh?"

## Project Initialization (First Run)

```bash
mkdir -p .claude/pge-doc/history

if [ -f .gitignore ] && ! grep -q ".claude/pge-doc/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE-doc workflow state files\n.claude/pge-doc/" >> .gitignore
fi
```

### Doc Registry Initialization

If `docs/doc-registry.md` does not exist:
> "No Doc Registry found. Would you like me to inventory the project and generate `docs/doc-registry.md`?"

Upon approval, auto-generate:

```markdown
# Doc Registry

## 1. Document Inventory
| # | File | Type | Owner Skill | Last Updated | Related Code Paths | Freshness |

## 2. Foundation Map Registry
| # | Map | Owner Skill | Last Verified | Freshness Score | Status |
|---|-----|-------------|---------------|-----------------|--------|
| 1 | docs/backend-dependency-map.md | /pge | — | — | — |
| 2 | docs/design-system-map.md | /pge-design, /pge-front | — | — | — |
| 3 | docs/qa-coverage-map.md | /pge-qa | — | — | — |
| 4 | docs/architecture-map.md | /pge-archi | — | — | — |
| 5 | docs/doc-registry.md | /pge-doc | — | — | — |

## 3. Cross-Reference Matrix
| Doc File | References | Referenced By |

## 4. CLAUDE.md Tracking
| File | Last Updated | Related Code Changes Since | Freshness | Sections |

## 5. Staleness Alerts
| # | File | Days Since Update | Code Changes Since | Severity | Action Needed |

## 6. Gap Analysis
| # | Code Area | Expected Doc | Exists? | Priority |
```

This registry is updated on every `/pge-doc` run.

## CRITICAL: Agent Spawning Rules

1. **Use TeamCreate to compose the team.** Do not spawn plain Agent subagents.
2. **Do not use Explore subagents.** All teammates must be `general-purpose` agents.
3. **Each teammate shares findings via SendMessage.** No silos allowed.
4. **Use TaskCreate to create a task list** and assign to teammates.
5. **Phase 1 (Scanner) agents are read-only** — doc modifications happen only in Phase 2 by team lead.

## Input

$ARGUMENTS — Description of the documentation target or scope

## Mode Detection

- **Audit**: Default — Phase 1 only (scan and report)
- **Generate**: "generate", "create", "missing" — Phase 1 + 2 (create missing docs)
- **Update**: "update", "refresh", "sync" — Phase 1 + 2 + 3 (update stale + verify)
- **Full**: "full", "all", "complete" — all phases, all documents

**Required output:** `Doc Mode: {Audit | Generate | Update | Full}`

---

## Freshness Score — Per-Document Metric

```bash
# 1. Find last doc update
git log -1 --format="%H %ai" -- <doc-file>

# 2. Count commits to related code since that date
git log --oneline --after="<doc-date>" -- <related-code-paths>

# 3. Assess severity of changes
git diff <doc-commit>..HEAD -- <related-code-paths> | wc -l
```

| Score | Label | Meaning |
|-------|-------|---------|
| 90-100 | FRESH | Updated after most recent related code change |
| 70-89 | CURRENT | Minor code changes since last doc update |
| 50-69 | STALE | Significant code changes not reflected |
| 30-49 | OUTDATED | Major changes, doc unreliable |
| 0-29 | CRITICAL | Severely out of date or contradicts code |

### Related Code Path Resolution

| Doc Type | Related Code Paths |
|----------|-------------------|
| backend-dependency-map.md | supabase/migrations/*, supabase/functions/*, schemas |
| design-system-map.md | theme/*, widgets/*, design tokens |
| qa-coverage-map.md | test/*, *_test.*, *.test.*, *.spec.* |
| architecture-map.md | lib/*, src/*, core module structure |
| CLAUDE.md | Project root, key configs, dependency files |
| README.md | Project root, package/pubspec, setup scripts |

---

## Auto-Update vs Ask Classification

| Classification | Criteria | Action |
|---------------|----------|--------|
| **Auto-update** | Factual, mechanical, verifiable from code | Apply directly |
| **Ask** | Narrative, opinionated, security, or large (>20 lines) | Present diff, ask user |

**Auto examples:** file paths, version numbers, parameter lists, new file entries, coverage numbers
**Ask examples:** README description, architecture rationale, security docs, behavioral instructions, section removal

---

## Doc Health Score (5 Dimensions)

| Dimension | Weight | Measures |
|-----------|--------|----------|
| **Freshness** | 30% | Docs updated when code changes? |
| **Accuracy** | 25% | Docs match current code reality? |
| **Completeness** | 20% | All code areas documented? |
| **Consistency** | 15% | Docs agree with each other? |
| **Discoverability** | 10% | Developers can find the right doc? |

| Grade | Score |
|-------|-------|
| A | 90-100 |
| B | 75-89 |
| C | 60-74 |
| D | 40-59 |
| F | 0-39 |

**Hard-fail:** Freshness < 50 or Accuracy < 50

---

## Role Catalog

**doc-inventory-scanner is always included.** 2-4 roles total.

| Role | Expertise | When to Select |
|------|-----------|----------------|
| **doc-inventory-scanner** | File inventory, freshness calculation, gap detection | **Always** (required) |
| **code-doc-cross-checker** | Code-to-doc accuracy, cross-references | Verifying existing docs |
| **foundation-map-auditor** | PGE foundation map freshness, cross-skill validation | Foundation maps exist |
| **claude-md-specialist** | CLAUDE.md freshness, section accuracy | CLAUDE.md files exist |

Custom roles allowed. Rationale required.

---

## Phase 1: Doc Scanner — Inventory + Freshness Baseline (Team)

### STEP 1: Task Analysis + Role Selection

**Required output:**
```
Doc Mode: {Audit | Generate | Update | Full}
Selected roles: [{role1}, {role2}, ...]
Rationale: [Why]
Scan scope: {Full | Specific area | Foundation maps only}
```

### STEP 2: Create Scanner Team

TeamCreate → Agent(team_name="pge-doc-scan-{slug}", name="{role}", run_in_background=true)

### STEP 3: Per-Agent Scan

- **doc-inventory-scanner**: Glob all .md files, calculate freshness per doc, identify undocumented code areas
- **code-doc-cross-checker**: Extract code references from docs, Grep/Read to verify each, flag contradictions
- **foundation-map-auditor**: Calculate freshness per PGE map, verify structure matches code, cross-check maps
- **claude-md-specialist**: Cross-reference CLAUDE.md instructions with project state, verify paths/commands

### STEP 4: Wait + Synthesize

### STEP 5: Doc Profile Report → `.claude/pge-doc/doc-profile.md`

Includes: Doc Health Score baseline, Document Freshness Table, Foundation Map Status, CLAUDE.md Status, Gap Analysis, Staleness Summary, Cross-Skill Issues.

**Phase Gate:** Doc Health Score + Freshness Table + Gap Analysis required.

### STEP 6: Shutdown Scanner Team

**For Audit mode:** Output report and STOP.

---

## Phase 2: Doc Generator/Updater — Create + Update

### STEP 1: Triage

**Priority Score = Severity × 2 - Effort - Risk** (>= 6: Quick Win, 3-5: Standard, <= 2: Backlog)

### STEP 2: Generate Missing Docs (Generate + Full modes)

For each gap: ANALYZE code → GENERATE doc → VERIFY against code → REGISTER in doc-registry.md

### STEP 3: Update Stale Docs (Update + Full modes)

For each stale doc: BEFORE capture → DIFF code changes → CLASSIFY (auto/ask) → UPDATE → AFTER capture → RECORD

### STEP 4: Foundation Map Maintenance

For each PGE map with Freshness < 70: read map, analyze code changes, apply updates.

| Map | Auto-Update | Ask |
|-----|------------|-----|
| backend-dependency-map.md | New entries | Dependency chain rewrites |
| design-system-map.md | New token/component entries | Design philosophy |
| qa-coverage-map.md | New test entries, coverage numbers | Test strategy |
| architecture-map.md | New module entries, dependency links | Architecture rationale |

### STEP 5: CLAUDE.md Refresh

Special handling: auto-update paths/commands/versions. Ask for behavioral instructions. Never remove security instructions without asking.

### STEP 6: Update Doc Registry

### STEP 7: Result Manifest → `.claude/pge-doc/doc-result.md`

**Phase Gate:** Before/After evidence required. All auto-updates must be verifiable.

**Guardrails:** 3-strike rule, never delete docs without asking, never modify security docs without asking, hard cap 30 updates.

**Cross-Skill Routing:** backend → `/pge`, architecture → `/pge-archi`, QA → `/pge-qa`, frontend → `/pge-front`

**For Generate mode:** Output result and STOP (no Phase 3).

---

## Phase 3: Doc Verifier — Independent Verification

**Must be executed as a fresh context Agent subagent.**

```
You are the DOC VERIFIER. Be skeptical. Do NOT assume correctness.

Score Calibration:
9-10: Nearly all docs fresh and accurate. Rare.
7-8:  Good documentation, trustworthy.
5-6:  Some stale/inaccurate, usable with caution.
3-4:  Obvious gaps.
1-2:  Actively misleading.

Verify: Recalculate Doc Health Score, verify each update against code,
foundation map walk, CLAUDE.md verification, cross-reference integrity.

Devil's Advocate (Documentation):
1. Did the update only fix surface while underlying structure is wrong?
2. Is a "fresh" doc actually accurate, or just recently touched?
3. Are generated docs useful to a new developer?
4. Does the registry reflect reality?
5. Are there undocumented areas not caught by gap analysis?
6. Would a developer trust this documentation enough to act on it?

Anti-Patterns:
- "Updated" without reading code
- Freshness score gaming (touched but unchanged)
- Generated but useless
- Registry drift (says file exists, doesn't)
- Stale cross-references
- Over-documentation (duplicates code comments)

HARD FAIL: Freshness < 50 or Accuracy < 50

Verdict: PASS (grade B+) / CONDITIONAL PASS (grade C+) / FAIL (hard-fail or grade D)
```

→ `.claude/pge-doc/doc-eval.md`

Archive: `.claude/pge-doc/history/{YYYYMMDD}T{HHMM}_{slug}.md`

---

## Final Report

```
DOC REPORT
════════════════════════════════════════
Target:          [Documentation target]
Mode:            {Audit | Generate | Update | Full}
Date:            {ISO timestamp}
Verdict:         {PASS | CONDITIONAL PASS | FAIL}

── Scanner ──
Team:            [{roles}]
Documents:       {N} found, {stale} stale, {gaps} gaps
Baseline:        Doc Health Score X/100 (Grade X)

── Generator/Updater ──
Generated:       {N} new docs
Updated:         {N} ({auto} auto, {ask} asked)
Maps refreshed:  {N}
CLAUDE.md:       {N} sections updated

── Verifier ──
| Dimension       | Before | After  | Δ      |
|-----------------|--------|--------|--------|
| Freshness       | X      | X      | +X     |
| Accuracy        | X      | X      | +X     |
| Completeness    | X      | X      | +X     |
| Consistency     | X      | X      | +X     |
| Discoverability | X      | X      | +X     |

Doc Health Score: Before X/100 (X) → After X/100 (X)

Foundation Maps:
  - backend-dependency-map.md: {FRESH|STALE} ({score})
  - design-system-map.md: {FRESH|STALE} ({score})
  - qa-coverage-map.md: {FRESH|STALE} ({score})
  - architecture-map.md: {FRESH|STALE} ({score})
════════════════════════════════════════
```

---

## Boundary with /ship

`/pge-doc` does NOT handle: git commit/push, PR creation, CHANGELOG, VERSION bump, release notes.
Those belong to `/ship`. `/pge-doc` focuses on project documentation lifecycle.

## Escalation Rules

- No docs found → Offer to generate initial set
- 3-strike, 30 update hard cap
- FAIL loop 2+ → Halt
- Grade F → Recommend comprehensive documentation initiative
- Freshness/Accuracy HARD FAIL → Warn explicitly
- CLAUDE.md critical staleness → Escalate immediately (highest priority)

## Important Rules

- Required output missing → cannot proceed
- Phase 1 agents read-only, Phase 2 team lead only
- Phase 3 fresh context Agent subagent
- Actual Grep/Read/git verification required
- Auto-update vs Ask classification respected
- SendMessage sharing required, team shutdown required
- Before/After evidence for all updates
- Never delete docs without approval
- Foundation maps: /pge-doc maintains freshness, not semantics (owner skill owns content)
- CLAUDE.md freshness is always highest priority
