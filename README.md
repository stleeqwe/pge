# PGE — Planner-Generator-Evaluator for Claude Code

A drop-in framework that makes Claude Code verify its own backend changes. Plan the blast radius, execute in strict order, then let an independent evaluator agent prove it works.

Born from [Anthropic's PGE harness pattern](https://www.anthropic.com/engineering/harness-design-long-running-apps), adapted for real-world [Claude Code](https://claude.ai/code) workflows.

## The Problem

When Claude Code modifies one part of your backend, other parts silently break:

- RPC function references a renamed column → **500 at runtime**
- View wasn't DROP'd before recreate → **stale column list**
- RLS policy doesn't cover the new table → **data leak**
- Realtime subscription parses old payload shape → **client crash**
- Migration adds NOT NULL without DEFAULT → **deploy fails on existing data**

You won't catch these in code review. You'll catch them in production.

## The Solution

Every backend change goes through three phases:

```
                            /pge
                              │
   ┌──────────────────────────▼──────────────────────────────┐
   │                                                          │
   │  ┌────────────┐   ┌────────────┐   ┌────────────────┐  │
   │  │  PLANNER   │──▶│ GENERATOR  │──▶│   EVALUATOR    │  │
   │  │            │   │            │   │                │  │
   │  │ Dependency │   │ Strict     │   │ Fresh context  │  │
   │  │ map + blast│   │ order +    │   │ Run ALL queries│  │
   │  │ radius     │   │ server     │   │ Walk dep map   │  │
   │  │ = Contract │   │ checkpoint │   │ Devil's advoc. │  │
   │  └────────────┘   └────────────┘   └────────────────┘  │
   │                                            │            │
   └────────────────────────────────────────────┼────────────┘
                                         PASS / FAIL
```

**The evaluator runs in a separate agent with fresh context** — it doesn't know what the generator intended, only what it produced. This defeats the self-evaluation bias that makes AI miss its own mistakes.

## Quick Start

```bash
# From your project root:
bash <(curl -s https://raw.githubusercontent.com/stleeqwe/pge/main/setup.sh)

# Or clone and run locally:
git clone https://github.com/stleeqwe/pge.git
cd your-project
bash ../pge/setup.sh
```

Then tell Claude Code:

> Analyze this project and fill in the PGE dependency map and domain checklists

That's it. PGE activates automatically on backend tasks.

## What Gets Installed

```
your-project/
├── .claude/
│   ├── commands/
│   │   ├── pge.md         # /pge      — Full protocol (single agent)
│   │   └── pge-team.md    # /pge-team — Full protocol (team investigation)
│   └── pge/               # Ephemeral state (gitignored)
│       ├── contract.md
│       ├── result.md
│       ├── eval.md
│       └── history/       # Archived PGE records
├── docs/
│   └── backend-dependency-map.md
└── CLAUDE.md              # PGE protocol section appended
```

## Usage

### Default: Autonomous

Claude decides what level of rigor is needed:

```
"Add color field to items"        → Quick fix (autonomous)
"Fix this button color"           → Quick fix → test → analyze
"Why is the chat list slow?"      → Investigate → fix → test
```

### Forced: `/pge` Flag

Append `/pge` to any task to force the full protocol:

```
"Fix the follow sync bug /pge"
```

This forces:
- **Investigation tasks**: 4-phase debugging protocol (symptoms → patterns → hypotheses → scope lock)
- **Direct tasks**: Full /preflight → Generator → /evaluate cycle
- **Code review**: 2-pass checklist → /evaluate

Each phase has **mandatory outputs** — Claude cannot skip ahead.

## Three Entry Paths

### Path A: Direct Backend Task

```
"add X to Y /pge" → Planner → Generator → Evaluator (all within /pge)
```

The generator executes in strict order with a **server boundary checkpoint** — it verifies the deployment works before touching client code.

### Path B: Investigation

```
"why is X broken?"
  Phase 1: Root Cause Investigation  → git log, code trace, reproduce
  Phase 2: Pattern Analysis          → match against 6 known patterns
  Phase 3: Hypothesis Testing        → 3 strikes → escalate
  Phase 4: Scope Lock                → backend? → PGE : quick fix
```

### Path C: Code Review

```
"review this"
  Pass 1 — CRITICAL:      SQL injection, TOCTOU races, LLM trust, enum completeness
  Pass 2 — INFORMATIONAL: dead code, test gaps, N+1 queries
  Fix-First Heuristic:    auto-fix trivial issues, ask for design decisions
  → /evaluate (domain checklists)
```

## Key Features

### Server Boundary Checkpoint
After deploying migrations/functions (step 6-7), PGE runs a smoke test before touching client code. Catches server failures early instead of after 13 steps.

### Rollback Protocol
Concrete recovery steps for partial deployments — migration repair, function rollback, server-first recovery order.

### Scope Drift Detection
The evaluator compares the Sprint Contract scope against actual changes. Flags scope creep and incomplete implementations.

### Complexity Gate
If a Sprint Contract lists 8+ files, the planner challenges whether the change can be split smaller.

### Escalation Rules
3 failed fix attempts → stop. 2+ consecutive evaluator FAILs → stop. Cannot reproduce → stop. No silent loops.

### Devil's Advocate Checklist
7 questions the evaluator must answer, targeting the most common mistakes:
1. What dependency was most likely skipped?
2. Is the most fragile query still working?
3. Were views DROP'd before recreate?
4. New columns in the dependency map?
5. Actually deployed, or just wrote code?
6. Could this silently break access policies?
7. Does the migration handle existing data?

## Updating

```bash
bash path/to/pge/setup.sh --update
```

This overwrites skills and replaces the CLAUDE.md PGE section while preserving your project-specific content above it.

## Works With

PGE is backend-agnostic. It works with any stack that has:
- A database with migrations (Postgres, MySQL, SQLite, Prisma, Drizzle, Django ORM...)
- Server-side functions (Edge Functions, Lambda, API Routes, Express, FastAPI...)
- A client layer (React, Next.js, Vue, Flutter, iOS, Android...)

The dependency map and domain checklists are templates — fill them in for your stack.

## Origin

Built for [LEAFIT](https://leafit.app) (Flutter + Supabase), a clothing exchange platform where a single column rename could break 10+ RPCs, 5 admin views, and the real-time chat system.

After the third time a "simple" migration silently broke `get_chat_list`, we stopped trusting ourselves and built PGE to verify every change with actual SQL queries in an independent agent context.

## License

MIT
