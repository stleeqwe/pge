---
name: pge-team
description: |
  PGE Full Protocol with Team Investigation. Orchestrator analyzes the task,
  selects appropriate specialist roles from a catalog, and spawns a team using
  TeamCreate. Agents investigate in parallel, share findings via SendMessage,
  then synthesize results. Use for complex bugs, cross-domain issues, or
  large-scale tasks that benefit from parallel analysis.
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

# /pge-team — PGE Full Protocol with Team Investigation

When the user appends `/pge-team`, the orchestrator analyzes the task, selects appropriate roles, spawns a team, conducts parallel investigation, and then executes the PGE protocol.

## CRITICAL: Agent Spawning Rules

**The following rules must be strictly followed:**

1. **Use TeamCreate to compose the team.** Use the TeamCreate → Agent(team_name=..., name=...) pattern, not simple Agent subagent spawning.
2. **Do not use Explore subagents.** All teammates must be spawned as `general-purpose` agents.
3. **Each teammate must share findings with others via SendMessage** as they proceed. Siloed work is prohibited.
4. **Create a task list with TaskCreate** and assign tasks to teammates.
5. **All teammates are read-only** — only the team lead (main agent) performs code modifications.

## Input

$ARGUMENTS — Task description

---

## STEP 1: Task Analysis + Role Selection

### 1-1. Task Type Detection

Analyze the task description to determine its type:
- **Investigation** — Symptom/bug/error keywords
- **Direct task** — Add/change/delete keywords
- **Code review** — Review keywords
- **Architecture/Design** — Design/structure/refactoring keywords

### 1-2. Scope Analysis

Determine which areas the task spans:
- Affected layers (DB, Server, Client, Network)
- Number of affected domains (single vs cross-domain)
- Range of related files/modules

### 1-3. Role Selection

Select **2 to 4** roles appropriate for the task from the **Role Catalog** below.
Do not spawn unnecessary roles.

**Required output:**
```
PGE Team Mode: {Investigation | Direct | Review | Architecture}
Selected roles: [{role1}, {role2}, ...]
Rationale: [One-line explanation of why these roles are needed]
```

---

## Role Catalog

The orchestrator selects roles suited to the task from the catalog below. Custom roles not in the catalog may also be defined to fit the task.

### Investigation Roles

| Role | Specialty | When to Select |
|------|-----------|----------------|
| **code-tracer** | Code path tracing, call chain analysis, dependency map verification | When the bug's code path is unclear |
| **history-checker** | git log, commit diff, PGE history analysis, regression point identification | "Suddenly stopped working", suspected regression |
| **state-verifier** | Live DB/server state SQL verification, RLS policy inspection | Suspected DB state inconsistency or data issues |
| **log-analyst** | Error log and stack trace analysis, pattern matching | When error logs are provided |

### Direct Task Roles

| Role | Specialty | When to Select |
|------|-----------|----------------|
| **dep-checker** | Blast radius analysis based on dependency map, contract gap identification | When backend changes are involved |
| **risk-assessor** | Cross-reference with High-Risk Change Matrix, hidden impact identification | When modifying CRITICAL/HIGH risk tables |
| **schema-analyst** | DB schema, migration, and constraint analysis | When schema changes are included |
| **api-analyst** | Edge Function/API endpoint impact analysis | When server functions are modified |

### Review Roles

| Role | Specialty | When to Select |
|------|-----------|----------------|
| **security-reviewer** | SQL injection, TOCTOU, RLS, LLM trust boundary | When security-sensitive changes are involved |
| **quality-reviewer** | Dead code, test gaps, N+1, code quality | For general code review |
| **ux-reviewer** | UI consistency, accessibility, user experience | When frontend changes are included |

### Architecture Roles

| Role | Specialty | When to Select |
|------|-----------|----------------|
| **arch-analyst** | Current architecture analysis, pattern identification, constraint discovery | For structural changes/refactoring |
| **impact-mapper** | Full impact scope mapping of changes, dependency tracking | For large-scale changes |
| **test-strategist** | Test strategy formulation, coverage analysis, test planning | When working in areas with insufficient tests |

### Selection Guidelines

- **Minimum 2, maximum 4** — 1 person is not a team, 5 or more creates coordination overhead
- **No role duplication** — Two people should not cover the same area
- **Enable cross-verification** — Combine roles that can view the same problem from different perspectives
- **Custom roles outside the catalog** — If no existing role fits the task perfectly, a new one may be defined. In this case, specify the role name, specialty, and action items

---

## STEP 2: Create Team

Create the team with **TeamCreate**, then spawn agents for each selected role using the **Agent** tool.

All Agent spawns must specify:
- `team_name="pge-team-{task-slug}"`
- `name="{role-name}"`
- `run_in_background=true`

### Agent Prompt Template

Write prompts for each agent using the following structure:

```
You are the {role-name} of team "{team_name}". {One-line description of specialty}.

## Mission
{Task description + user-provided information (logs, symptoms, etc.)}

## Action Items
{3-7 specific action items appropriate for the role}

## Required: SendMessage Rules
After completing your analysis, send a SendMessage to each of the other teammates:
- {Format for the role's key findings}

When you receive messages from other teammates, incorporate their content to strengthen your analysis.
Do not modify code. Only perform analysis.
Use TaskUpdate to transition your assigned Task from in_progress to completed.
```

---

## STEP 3: Wait for Team Results

All agents proceed with analysis while sharing findings with each other via SendMessage.
Once all agents have completed their analysis, synthesize the results.

---

## STEP 4: Synthesize Results

Synthesize the team analysis results into the following output:

```
=== TEAM INVESTIGATION RESULT ===

{role-1} findings:
  [Summary of key findings]

{role-2} findings:
  [Summary of key findings]

{role-N} findings:
  [Summary of key findings]

=== SYNTHESIS ===

Conclusion: [Conclusion synthesized from team analysis]
Confidence: {HIGH | MEDIUM | LOW}
Scope: [Affected module boundaries]
Backend change needed: {Y/N}  (For Investigation/Direct)
```

**If Confidence is LOW**: Deploy additional roles or escalate to the user.

---

## STEP 5: Shutdown Team

After analysis is complete, send a shutdown_request to all agents and clean up the team.

---

## STEP 6: Execute

Execute based on the synthesized results:

### Investigation
- **Backend change needed: Y** → `/pge` Planner → Generator → Evaluator
- **Backend change needed: N** → Fix → Test → Analyze → Debug Report

### Direct Task
- Planner → Generator → Evaluator (using Sprint Contract enriched by team analysis)

### Review
- Fix issues based on team review results → Evaluator
- If no issues found, complete

### Architecture
- Output design document → User confirmation → Implementation

---

## STEP 7: Final Report

```
PGE TEAM REPORT
========================================
Task:            [Task description]
Mode:            {Investigation | Direct | Review | Architecture}
Team:            [{role1}, {role2}, ...]
Date:            {ISO timestamp}

-- Team Analysis --
{One line of key findings per role}

-- Action Taken --
{Summary of work performed}

-- Result --
{Result summary}

Status:          DONE | DONE_WITH_CONCERNS | BLOCKED
========================================
```

---

## Important Rules

- All agents **do not modify code** — they only perform analysis/verification
- Agents **must share findings via SendMessage** — siloed work is prohibited
- After analysis is complete, **the team must be shut down** — clean up resources
- Modifications are always **performed only by the team lead (main agent)**
- Role selection **requires a Rationale** — state why each role is needed
- Escalation: 3-strike rule, halt if PGE FAIL loop occurs 2+ times
