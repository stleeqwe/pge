---
name: pge-perf
description: |
  PGE Performance Optimization Protocol (Profiler-Optimizer-Benchmarker).
  Spawns a team of specialist agents (query-profiler, code-analyzer, load-tester)
  to profile bottlenecks across 4 layers (DB, Server, Client, Network),
  apply optimizations by priority, and benchmark before/after with independent
  evaluator. Use when asked with /pge-perf flag appended.
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

# /pge-perf — PGE Performance Optimization Protocol

When the user appends `/pge-perf` to a task request, the full performance optimization protocol is enforced.

## Project Initialization (On First Run)

If PGE-perf files do not exist in the project, create them automatically:

```bash
mkdir -p .claude/pge-perf/baselines
mkdir -p .claude/pge-perf/history

if [ -f .gitignore ] && ! grep -q ".claude/pge-perf/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE-perf workflow state files\n.claude/pge-perf/" >> .gitignore
fi
```

## CRITICAL: Agent Spawning Rules

**The following rules must be strictly followed:**

1. **Use TeamCreate to form the team.** Use the TeamCreate → Agent(team_name=..., name=...) pattern, not simple Agent subagent spawning.
2. **Do not use Explore subagents.** All teammates must be spawned as `general-purpose` agents.
3. **Each teammate must share findings with others via SendMessage** as they proceed. Siloed work is prohibited.
4. **Use TaskCreate to create a task list** and assign tasks to teammates.
5. **Phase 1 (Profiler) agents are read-only** — optimization implementation is performed only by the team lead (main agent) in Phase 2.

## Input

$ARGUMENTS — Description of the performance optimization target (specific screen, API, query, etc.)

---

## Phase 1: Profiler — Baseline Measurement + Bottleneck Identification

### STEP 1: Create Profiling Team

Create a team with **TeamCreate** and spawn 3 specialists using the **Agent** tool. The `team_name` parameter must always be specified.

```
Team: pge-perf-profile
Agents:
  1. query-profiler  — DB layer profiling (Layer 1)
  2. code-analyzer   — Server + Client code analysis (Layer 2 + 3)
  3. load-tester     — Network pattern analysis (Layer 4)
```

#### Agent 1: query-profiler

When calling the Agent tool, always specify `team_name="pge-perf-profile"`, `name="query-profiler"`, `run_in_background=true`.

Spawn instructions:
```
You are the query-profiler on team "pge-perf-profile". You are a specialist in profiling performance bottlenecks at the DB layer.

## Mission
Target: {optimization target provided by the user}

Perform the following 7 check items in order:

### D1: Identify Slow Queries
- Use Read/Grep to find the main queries related to the target feature in the code
- Wrap each query in `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)` and execute
- Compare cost, actual time, and rows. Flag if Seq Scan on large table

### D2: Top-N Slow Queries
SELECT query, calls, mean_exec_time, total_exec_time, rows
FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 20;

### D3: Missing Indexes
SELECT schemaname, relname, seq_scan, seq_tup_read, idx_scan, n_live_tup
FROM pg_stat_user_tables
WHERE seq_scan > 100 AND n_live_tup > 1000 ORDER BY seq_tup_read DESC;

### D4: N+1 Query Patterns
- Use Grep to detect patterns like `.from(`, `.select(`, `.rpc(` inside loops
- If found, share the locations with code-analyzer via SendMessage

### D5: Unnecessary JOINs
- Flag if Nested Loop/Hash Join rows in EXPLAIN ANALYZE results are excessive relative to actual usage

### D6: Index Usage Analysis
SELECT t.relname, indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes ui JOIN pg_stat_user_tables t ON ui.relid = t.relid
ORDER BY idx_scan ASC;

### D7: Transaction Lock Contention
SELECT pid, wait_event_type, wait_event, state, query
FROM pg_stat_activity WHERE wait_event_type = 'Lock';

## Required: Share results via SendMessage after analysis is complete
Send a SendMessage to both code-analyzer and load-tester with:
- Full DB Profiling Results
- List of discovered slow queries and their causes
- Missing indexes + recommended indexes
- N+1 pattern locations found

Output format:
## DB Profiling Results
### Slow Queries (Top 5)
| Rank | Query (truncated) | Mean Time | Calls | Issue |
### Missing Indexes
| Table | seq_scan | idx_scan | Recommendation |
### Lock Contention
(If none: "No lock contention detected")

If you receive messages from other teammates, incorporate their findings to enhance your analysis.
Do not modify code. Analysis only.
Use TaskUpdate to mark your assigned Task from in_progress → completed.
```

#### Agent 2: code-analyzer

When calling the Agent tool, always specify `team_name="pge-perf-profile"`, `name="code-analyzer"`, `run_in_background=true`.

Spawn instructions:
```
You are the code-analyzer on team "pge-perf-profile". You are a specialist in analyzing performance bottlenecks in Server and Client code.

## Mission
Target: {optimization target provided by the user}

### Layer 2: Server Analysis

#### S1: Cold Start Time
- Analyze top-level imports of Edge Functions / API routes
- Check for heavy library imports

#### S2: Response Payload Size
- Analyze response data structures, check for unnecessary field inclusion

#### S3: External API Call Waits
- Use Grep to detect fetch(, axios, got(
- Check for sequential await chains

#### S4: Sequential-to-Parallel Conversion Opportunities
- Check if consecutive awaits can be converted to Promise.all

#### S5: Unnecessary Retries
- Flag retry loops without exponential backoff

#### S6: Middleware Overhead
- Analyze RLS policy count and auth middleware chain length

### Layer 3: Client Analysis

#### C1: Unnecessary Rebuilds/Rerenders
- Flutter: setState frequency, Consumer/Watch scope, expensive computations inside build()
- React: Missing useEffect deps, unnecessary state changes

#### C2: Excessive Provider Invalidation
- ref.invalidate, ref.refresh cascading update patterns

#### C3: Memory Leaks
- Check whether StreamSubscription/Timer/AnimationController are properly released in dispose()

#### C4: Image/Asset Optimization
- Use Glob to search for image files → check sizes

#### C5: Concurrent Calls During Initial Load
- Count API calls at app entry point during initialization. Flag if 5 or more

## Grep Pattern Reference
N+1:          for.*\n.*\.from\(  |  \.forEach.*\n.*\.from\(
SELECT *:     \.select\(\s*\)  |  \.select\('\*'\)
Sequential await:   const \w+ = await.*\n\s*const \w+ = await
Rebuilds:       setState\(\s*\(\)\s*\{
Memory leaks:   StreamSubscription|\.listen\(  → check for dispose()+cancel()
Invalidation: ref\.invalidate\(|ref\.refresh\(

## Required: Share results via SendMessage after analysis is complete
Send a SendMessage to both query-profiler and load-tester with:
- Server Issues list (file:line + impact)
- Client Issues list (file:line + impact)
- N+1 pattern cross-verification results

Output format:
## Code Analysis Results
### Server Issues
| # | File:Line | Issue | Category | Impact | Suggested Fix |
### Client Issues
| # | File:Line | Issue | Category | Impact | Suggested Fix |

If you receive messages from other teammates, incorporate their findings to enhance your analysis.
Do not modify code. Analysis only.
Use TaskUpdate to mark your assigned Task from in_progress → completed.
```

#### Agent 3: load-tester

When calling the Agent tool, always specify `team_name="pge-perf-profile"`, `name="load-tester"`, `run_in_background=true`.

Spawn instructions:
```
You are the load-tester on team "pge-perf-profile". You are a specialist in analyzing performance patterns at the Network layer.

## Mission
Target: {optimization target provided by the user}

### N1: Duplicate API Calls
- Use Grep to flag if identical .from('table') calls are scattered across multiple files
- Check if multiple components on the same screen each fetch separately

### N2: Single Calls That Could Be Batched
- Check if individual .insert(), .update(), .upsert() calls inside loops can be converted to batch operations

### N3: Missing Caching
- Check for cache/revalidate settings on fetch calls
- Check for local cache layer existence

### N4: Realtime Subscription Overhead
- Detect .channel(, .on('postgres_changes'
- Flag full table subscriptions without filters, unreleased channels

### N5: Missing Pagination
- Detect .select() calls without .range() or .limit()

### N6: Compression/Serialization
- Check for gzip settings in response headers
- Check for unnecessary field inclusion during JSON serialization

## Required: Share results via SendMessage after analysis is complete
Send a SendMessage to both query-profiler and code-analyzer with:
- Full Network Issues list
- Duplicate call map (endpoint → call sites)
- Batchable items list
- Missing pagination locations

Output format:
## Network Analysis Results
### Duplicate Calls
| Endpoint/Table | Call Sites | Est. Redundancy |
### Missing Pagination
| Query | Est. Rows | Location |
### Batching Opportunities
| Pattern | Locations | Potential Reduction |
### Caching Gaps
| Endpoint | Current | Recommendation |
### Subscription Issues
| Channel | Filter | Issue |

If you receive messages from other teammates, incorporate their findings to enhance your analysis.
Do not modify code. Analysis only.
Use TaskUpdate to mark your assigned Task from in_progress → completed.
```

### STEP 2: Wait for Team Results + Synthesize

The 3 agents share their findings with each other via SendMessage while conducting analysis.
Once all agents complete their analysis, synthesize the results.

### STEP 3: Performance Profile Report

Consolidate the analysis results from all 3 agents and save to `.claude/pge-perf/perf-target.md`:

```
═══ PERFORMANCE PROFILE REPORT ═══

## Profiling Summary
Target: [optimization target]
Date: {ISO timestamp}

## query-profiler Findings (Layer 1: Database):
  [slow query list + missing indexes + N+1]

## code-analyzer Findings (Layer 2: Server + Layer 3: Client):
  [server bottlenecks + client bottlenecks]

## load-tester Findings (Layer 4: Network):
  [duplicate calls + missing caching + pagination]

## Baseline Metrics
| Category | Metric | Current Value | Measured By |

## Bottleneck Summary
| # | Layer | Issue | File:Line | Severity | Baseline |

Bottleneck identified: [most severe bottleneck]
Layer: {DB | Server | Client | Network}
Baseline metric: [current measurement]
═══════════════════════════════════
```

### Performance Anti-Pattern Matching

| Pattern | Signature | Match? |
|---------|-----------|--------|
| N+1 query | DB calls inside loops, excessive queries | Y/N |
| Missing index | Full table scan, slow WHERE | Y/N |
| SELECT * | Excessive payload, unnecessary columns | Y/N |
| Sequential await | Serial independent calls, increased latency | Y/N |
| Excessive rebuild | Frequent setState/rerender | Y/N |
| Missing pagination | Loading all data, OOM risk | Y/N |
| Bundle bloat | Large imports, cold start delay | Y/N |

**Required output** — If `Bottleneck identified`, `Layer`, `Baseline metric`, or `Anti-pattern match` is missing, Phase 2 cannot proceed.

### STEP 4: Shutdown Profiling Team

After analysis is complete, send shutdown_request to all agents and clean up the team.

---

## Phase 2: Optimizer — Implement Optimizations in Impact Order

### STEP 1: Build Optimization Priority Matrix

**Scoring criteria (1-5 each):**

| Factor | 5 (Best) | 1 (Worst) |
|--------|----------|-----------|
| Impact | 50%+ response time reduction | Less than 5% |
| Effort | Single line change | Major refactoring |
| Risk | No side effects | Potential data loss |

**Priority formula:** `Priority Score = Impact × 2 - Effort - Risk`

- Score >= 6: **Execute immediately** (Quick Win)
- Score 3-5: **Plan then execute**
- Score <= 2: **Add to backlog**

Output:
```markdown
## Optimization Priority Matrix
| Rank | Issue | Layer | Impact | Effort | Risk | Score | Action |
```

### STEP 2: Execute Optimizations (Score >= 6 first, descending order)

For each optimization:
1. **Before**: Record the current value of the relevant metric
2. **Implement**: Implement the change (performed directly by the team lead)
3. **After**: Re-measure the same metric
4. **Record**: Append results to `.claude/pge-perf/optimization-result.md`

### STEP 3: Optimization Result

Save to `.claude/pge-perf/optimization-result.md`:

```markdown
# Optimization Result — {ISO timestamp}

## Applied Optimizations
| # | Issue | Change | File(s) | Before | After | Δ% |

## Backlog (Score <= 2)
| # | Issue | Score | Reason for Deferral |
```

**Required output** — If any optimization is missing `Before`, `After`, or `Δ%`, Phase 3 cannot proceed.

### Optimizer Rules
- Quick Wins (Score >= 6) must be processed **first**
- After each optimization, **verify that existing tests pass**
- Request user confirmation before implementing Risk 4-5 items
- If 8+ files are changed, review whether the change can be split

---

## Phase 3: Benchmarker — Prove Before/After Comparison

**Must be run as a fresh context Agent subagent** (independent verification).

### Benchmarker Agent Prompt:

```
You are the BENCHMARKER in a Profiler-Optimizer-Benchmarker workflow.

YOUR ROLE: Independently verify that performance optimizations actually improved metrics.
You are checking SOMEONE ELSE's work. Be skeptical. Do NOT assume improvement.

## Inputs (read these files first)
1. Performance profile: .claude/pge-perf/perf-target.md
2. Optimization result: .claude/pge-perf/optimization-result.md

## Verification Process

### A. Re-measure ALL Baseline Metrics
For each metric in perf-target.md, re-measure using the SAME method:
- DB queries: Re-run EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) on same queries
- Server: Re-measure response time/size if applicable
- Client: Re-analyze code for rebuild/rerender count changes
- Network: Re-count API calls, check pagination, caching

### B. Before/After Comparison
| # | Optimization | Metric | Before | After | Δ | Δ% |
Δ must be measured, not estimated.

### C. Measurement Quality Check
- Same conditions? Same data? Same parameters?
- DB queries run 3x → use median
- Results reproducible?

### D. Regression Check
- All existing tests still pass?
- No new errors in logs?
- No functionality removed to "improve" performance?

### D-bis. Devil's Advocate Checklist (Performance)
1. Which layer is most likely to have a missing measurement?
2. Was the baseline measured under reliable conditions?
3. Did the optimization introduce any functional regression?
4. Were the before/after measurements taken under identical conditions? (same data, same parameters)
5. Were actual measurements performed, or was it code analysis only?

### D-ter. Anti-Pattern Check (Performance)
| Anti-Pattern | How to Detect |
|---|---|
| "Improved" without measurement | No before/after numbers in result |
| Optimized query but not client code | Client still fetches excess data |
| Added index but didn't verify usage | Index not used in EXPLAIN |
| Claimed latency reduction without repeat measurement | Single run, no median |
| Removed functionality to "improve" perf | Feature regression |

### E. Score 5 Dimensions (1-10)
1. Query Performance — Degree of DB query improvement
2. Response Time — Degree of API latency improvement
3. Client Performance — Degree of rendering/bundle improvement
4. Measurement Quality — Reliability of measurement methodology (**HARD FAIL if < 6**)
5. Regression Safety — No functional regression (**HARD FAIL if < 6**)

### F. Verdict
- **IMPROVED**: All >= 7, at least one metric improved >= 20%
- **MARGINAL**: All >= 6, improvements < 20%
- **NO_CHANGE**: Measurements within noise margin (< 5%)
- **REGRESSION**: Any metric worsened > 5% OR any hard-fail < 6

### G. Write Report
Write to .claude/pge-perf/benchmark-eval.md.
Return verdict + key findings.
```

### Benchmarker Result Handling

- **IMPROVED**: Archive → Output Performance Optimization Report
- **MARGINAL**: Archive → Output Report + provide guidance for further optimization
- **NO_CHANGE**: Analyze root cause → Re-run Phase 2 or escalate
- **REGRESSION**: Rollback → Analyze root cause → Re-run Phase 2 (fresh context)

---

## Final Report: Performance Optimization Report

```
PERFORMANCE OPTIMIZATION REPORT
════════════════════════════════════════
Target:          [optimization target]
Date:            {ISO timestamp}
Verdict:         {IMPROVED | MARGINAL | NO_CHANGE | REGRESSION}

── Profiling ──
Bottlenecks:     [number of identified bottlenecks]
Layers affected: {DB, Server, Client, Network}

── Optimization ──
Applied:         [number of applied optimizations]
Quick Wins:      [number of Score >= 6 items]
Backlogged:      [number of Score <= 2 items]

── Benchmark ──
| Metric             | Before  | After   | Δ%     |

Scores:
  Query Performance:     X/10
  Response Time:         X/10
  Client Performance:    X/10
  Measurement Quality:   X/10
  Regression Safety:     X/10

Contributors:    query-profiler, code-analyzer, load-tester
Evaluator:       independent benchmarker (fresh context)

Backlog:
  - [Score <= 2 items]
════════════════════════════════════════
```

### Archive

Create `.claude/pge-perf/history/{YYYYMMDD}T{HHMM}_{target-slug}.md` (under 100 lines).

---

## Escalation Rules

- **Phase 1 failure**: If profiling tools are inaccessible → escalate + perform code analysis only
- **Phase 2 failure**: 3-strike rule — STOP after 3 optimization attempts with no improvement
- **Phase 3 REGRESSION**: Immediately rollback → analyze root cause → retry after user confirmation
- **FAIL loop 2+ times**: Halt + escalate to user
- **Performance cannot be improved**: Issue "ALREADY_OPTIMIZED" verdict + output current state report

---

## Database Interaction Priority

**MCP-first rule: When Supabase MCP (or any DB MCP) is available, ALWAYS use it over CLI.** MCP provides direct, faster, and more reliable DB access. Only fall back to CLI if MCP tool call explicitly fails. This applies to all profiling queries (EXPLAIN ANALYZE, pg_stat_statements, index usage, etc.).

## Important Rules

- If the **required output** for any Phase is missing, the next Phase cannot proceed
- `/pge-perf` tasks **cannot skip the protocol**
- **MCP-first**: Always use Supabase MCP over CLI when available
- Phase 1 agents **do not modify code** — analysis/measurement only
- Agents **must share findings via SendMessage** — siloed work is prohibited
- After analysis is complete, **the team must be shut down** — clean up resources
- Phase 2 optimizations are **performed only by the team lead (main agent)**
- Phase 3 Benchmarker **must be run as a fresh context Agent subagent**
- **Actual measurement execution** is required — "I assume it improved" is not acceptable
