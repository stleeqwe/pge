# PGE — Planner-Generator-Evaluator for Claude Code

Backend consistency and performance optimization skills for [Claude Code](https://claude.ai/code). Plan the blast radius, execute in strict order, verify with independent evaluator agents.

## Install

```bash
git clone https://github.com/stleeqwe/pge.git /tmp/pge
bash /tmp/pge/install.sh
rm -rf /tmp/pge
```

This installs three global skills to `~/.claude/skills/`. They work in **every project** — no per-project setup needed.

## Usage

Append a flag to any task:

```
# Single agent — full protocol
fix the follow sync bug /pge

# Team investigation — 3 agents in parallel
fix the follow sync bug /pge-team

# Performance optimization — profile, optimize, benchmark
optimize the chat list /pge-perf
```

Without the flag, Claude works autonomously (fast mode).

## Skills

### `/pge` — Single Agent Protocol

Detects task type and runs the appropriate workflow:

| Task Type | Trigger | Workflow |
|-----------|---------|---------|
| Investigation | "bug", "broken", "why", "fix" | 4-phase debugging → Planner → Generator → Evaluator |
| Direct task | "add", "update", "remove" | Planner → Generator → Evaluator |
| Code review | "review", "check" | 2-pass checklist → Evaluator |

Each phase has **mandatory outputs** — Claude cannot skip ahead.

**Investigation (4-phase Systematic Debugging):**
1. Root Cause Investigation — symptoms, code trace, git log, reproduce
2. Pattern Analysis — match against 6 known bug patterns
3. Hypothesis Testing — 3 strikes → escalate
4. Scope Lock — backend → full PGE / frontend → quick fix

**Direct Task (Plan → Generate → Evaluate):**
- Planner reads dependency map, writes Sprint Contract with runnable acceptance criteria
- Generator executes in strict order with server boundary checkpoint
- Evaluator runs in fresh agent context, executes actual queries, scores 5 dimensions

### `/pge-team` — Team Investigation

Same protocol, but spawns a **team of 3 specialist agents** using TeamCreate:

| Agent | Role |
|-------|------|
| code-tracer | Traces code paths + dependency chains |
| history-checker | Analyzes git log + PGE history for regressions |
| state-verifier | Runs live queries to verify DB/server state |

Agents share findings via **SendMessage** and converge on root cause before the fix.

### `/pge-perf` — Performance Optimization

Three-phase protocol: **Profile → Optimize → Benchmark**

Always runs as a team (TeamCreate):

| Agent | Layer | Role |
|-------|-------|------|
| query-profiler | DB | EXPLAIN ANALYZE, missing indexes, N+1, lock contention |
| code-analyzer | Server + Client | Cold starts, payload size, rebuilds, memory leaks |
| load-tester | Network | Duplicate calls, missing pagination, caching gaps |

**Phase 1 (Profiler):** Team profiles 4 layers in parallel → Performance Profile Report
**Phase 2 (Optimizer):** Priority Matrix (Impact×2 - Effort - Risk) → Quick Wins first
**Phase 3 (Benchmarker):** Fresh context agent re-measures all metrics → before/after proof

Verdicts: IMPROVED / MARGINAL / NO_CHANGE / REGRESSION

## First Run

On first `/pge` in a new project, it auto-creates:
- `.claude/pge/` — state directory (gitignored)
- Prompts to generate `docs/backend-dependency-map.md` if missing

The dependency map is updated on every PGE run as new dependencies are discovered.

## Key Features

- **Server Boundary Checkpoint** — verify deployment before touching client code
- **Rollback Protocol** — concrete recovery for partial deployments
- **Scope Drift Detection** — contract vs actual changes comparison
- **Complexity Gate** — 8+ files triggers split challenge
- **Escalation Rules** — 3-strike, 2+ FAILs → stop
- **Devil's Advocate** — 7 questions targeting the most common mistakes

## File Structure

```
~/.claude/skills/
├── pge/
│   └── SKILL.md       # /pge skill
├── pge-team/
│   └── SKILL.md       # /pge-team skill
└── pge-perf/
    └── SKILL.md       # /pge-perf skill

your-project/          # Auto-created on first run
├── .claude/pge/       # PGE state (gitignored)
│   ├── contract.md
│   ├── result.md
│   ├── eval.md
│   └── history/
├── .claude/pge-perf/  # Perf state (gitignored)
│   ├── perf-target.md
│   ├── optimization-result.md
│   ├── benchmark-eval.md
│   └── history/
└── docs/
    └── backend-dependency-map.md
```

## Origin

Built for [LEAFIT](https://leafit.app) — a clothing exchange platform where a single column rename could break 10+ RPCs, 5 admin views, and the real-time chat system.

Based on [Anthropic's PGE harness pattern](https://www.anthropic.com/engineering/harness-design-long-running-apps).

## License

MIT
