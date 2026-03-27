---
name: pge-design
description: |
  PGE Design Creative Protocol (Research-Generator-Critic).
  Spawns a team of design specialist agents to research brand direction,
  iteratively create/improve designs with GAN-inspired loop,
  and evaluate with independent design critic using 4 aesthetic criteria.
  Focus: visual identity, branding, aesthetic quality — not technical compliance.
  Technical checks → use /pge-front instead.
  Use when asked with /pge-design flag appended.
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

# /pge-design — PGE Design Creative Protocol

When the user appends `/pge-design` to a task request, the full design creative protocol is enforced.
**Technical checks (token usage, accessibility, state handling) belong to `/pge-front`.** This skill focuses on aesthetic judgment.

## Project Initialization (First Run)

```bash
mkdir -p .claude/pge-design/history .claude/pge-design/baselines

if [ -f .gitignore ] && ! grep -q ".claude/pge-design/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE-design workflow state files\n.claude/pge-design/" >> .gitignore
fi
```

### Automatic Platform Detection
```
Flutter:    Glob pubspec.yaml → "flutter:" section
React/Next: Glob package.json → "react" dependency
Vue/Nuxt:   Glob package.json → "vue" dependency
```
**Required output:** `Platform: {Flutter | React | Vue | Unknown}`

### Design System Map Reference (Read-Only)

Reference `docs/design-system-map.md` as **read-only**. Update permissions belong to `/pge-front`.
If not found: "Design System Map does not exist. Run `/pge-front` first to generate it."

## CRITICAL: Agent Spawning Rules

1. **TeamCreate** usage is mandatory.
2. **Do not use Explore subagents.** General-purpose only.
3. **Must share via SendMessage** between agents.
4. **TaskCreate** for task lists + teammate assignment.
5. **Phase 1 agents are read-only** — only the Phase 2 team lead may implement changes.

## Input

$ARGUMENTS — the design improvement target

## Collaboration Flow

```
Existing UI improvement:  /pge-front (audit) → /pge-design (improve) → /pge-front (re-audit)
New design:               /pge-design (create) → /pge-front (audit)
```

---

## 4 Aesthetic Evaluation Criteria

### Criterion 1: Cohesion — "Do all elements tell a single story?"

- Do color, typography, layout, and imagery form a unified mood/identity?
- Is it an inseparable whole rather than a collection of parts?
- Is the brand identity consistently felt across all screens?

**Hard-fail if < 5**

### Criterion 2: Originality — "Is this more than AI slop?"

- Are there traces of custom design decisions?
- Is it free from default AI patterns like "purple gradients"?
- Does it have a visual language unique to the brand?
- Does it have a visual identity that differentiates it from competing services?

### Criterion 3: Craft — "Are the details alive?"

- Does the typographic hierarchy naturally guide the eye flow?
- Does the color harmony convey emotional intent?
- Is negative space used intentionally?
- Is there a consistent philosophy in fine details (shadow, radius, transition)?

**Hard-fail if < 5**

### Criterion 4: Intuitiveness — "Is it understood within 3 seconds?"

- Does the eye flow naturally toward the core CTA?
- Is the information hierarchy clear enough to allow scanning?
- Can the user tell what action to take without guessing?

### DAI (Design Aesthetic Index)

```
DAI = (Cohesion × 0.3) + (Originality × 0.25) + (Craft × 0.25) + (Intuitiveness × 0.2)
```

**Score Guide:**
- 9-10: Museum-worthy. Nearly impossible.
- 7-8: Professional designer level. This is the target.
- 5-6: Functional but aesthetically unremarkable.
- 3-4: Clear aesthetic problems.
- 1-2: AI defaults as-is.

---

## Role Catalog

The orchestrator selects **2-4 roles** suited to the task. **brand-analyst is mandatory**.

| Role | Expertise | Required? |
|------|----------|------|
| **brand-analyst** | Branding, mood, tone & manner, color palette interpretation | **Required** |
| **ux-strategist** | User persona, UX direction, information hierarchy | Optional |
| **visual-researcher** | Analysis of existing patterns in the project, visual trends | Optional |
| **layout-architect** | Layout structure, grid systems, spatial distribution | Optional |

Roles outside the catalog may also be defined.

---

## Phase 0: Platform UI/UX Landscape — Research Latest Libraries/Frameworks

Before implementing designs, research the **latest UI/UX libraries, standard frameworks, and trends** for the target platform. "What should I use to build the most advanced UI on this platform right now?"

### STEP 1: Platform-Specific Research

Based on the detected platform, research the latest information via WebSearch:

#### Flutter
```
WebSearch: "Flutter best UI libraries 2025 2026"
WebSearch: "Flutter animation library advanced 2025"
WebSearch: "Flutter design system package comparison"
WebSearch: "Flutter Material 3 vs custom design system"
```

Research items:
| Area | Research Content |
|------|----------|
| Design system | Latest Material 3 changes, Cupertino updates, custom theme approaches |
| Animation | flutter_animate, rive, lottie, native AnimationController comparison |
| Layout | Sliver patterns, CustomScrollView, adaptive layout |
| Components | shadcn_flutter, forui, other modern UI kits |
| Interaction | Gesture libraries, haptic feedback, spring physics |
| Dark/Light theme | ThemeExtension patterns, dynamic color |
| Typography | Google Fonts, variable fonts, text scaling |
| Icons | HugeIcons, Phosphor, custom SVG approaches |

#### Swift (iOS)
```
WebSearch: "SwiftUI best UI libraries 2025 2026"
WebSearch: "iOS design trends advanced animations 2025"
WebSearch: "SwiftUI vs UIKit modern app design"
WebSearch: "iOS design system architecture best practices"
```

Research items:
| Area | Research Content |
|------|----------|
| Framework | Latest SwiftUI APIs, UIKit interop, TCA pattern |
| Animation | SwiftUI animation, UIViewPropertyAnimator, Core Animation, Lottie |
| Layout | LazyVStack/HStack, GeometryReader, Layout protocol |
| Components | Latest Apple HIG components, SF Symbols usage |
| Interaction | Haptics (UIFeedbackGenerator), gesture combinations, scroll physics |
| Dark/Light | Asset Catalog, semantic colors, dynamic type |
| Typography | SF Pro, variable fonts, Dynamic Type |
| Icons | Latest SF Symbols version, custom symbols |

#### React / Web (if applicable)
```
WebSearch: "React UI library best 2025 2026"
WebSearch: "CSS animation library modern 2025"
WebSearch: "React design system comparison radix shadcn"
```

### STEP 2: Landscape Report

Save to `.claude/pge-design/landscape.md`:

```
═══ PLATFORM UI/UX LANDSCAPE ═══

Platform: {Flutter | Swift | React}
Date: {ISO timestamp}

## Currently Used in Project
| Area | Currently Using | Version |
|------|----------|------|
| Design system | {e.g., Material 3 custom} | ... |
| Animation | {e.g., flutter_animate} | ... |
| Icons | {e.g., Material Icons} | ... |
| ... | ... | ... |

## Latest Platform Trends
| Area | Latest Approach | Applicable to Project? | Impact |
|------|-----------|-------------------|--------|
| ... | ... | Y/N | HIGH/MEDIUM/LOW |

## Recommended Libraries/Approaches
| # | Library/Approach | Purpose | Advantage Over Current | Migration Difficulty |
|---|-----------------|------|--------------|-------------------|

## Project Application Recommendations
- Immediately applicable: [list]
- Experiment in Phase 2: [list]
- Requires separate work: [list — recommend performance impact check via /pge-front]

═══════════════════════════════════════
```

**Required output:** `Landscape report generated` — Phase 1 cannot proceed without this report.

Phase 1 (Design Research) references this Landscape Report to incorporate the latest libraries/approaches into the design direction.

---

## Phase 1: Design Research — Direction Exploration

### STEP 1: Task Analysis + Role Selection

**Required output:**
```
Design Mode: Creative
Platform: {Flutter | React | Vue}
Selected roles: [{role1}, {role2}, ...]
Rationale: [reason for selection]
```

### STEP 2: Create Research Team

TeamCreate → Agent(team_name="pge-design-{slug}", name="{role}", run_in_background=true)

Each agent:
- Analyzes the current design direction (branding, mood, tone)
- References the design-system-map (current state assessment)
- Derives design direction suited to target users/persona
- Analyzes existing visual patterns within the project

### STEP 3: Wait + Synthesize

### STEP 4: Design Research Brief

Save to `.claude/pge-design/research-brief.md`:

```
═══ DESIGN RESEARCH BRIEF ═══

## Context
Target: [design target]
Platform: {Flutter | React | Vue}
Date: {ISO timestamp}

## Current Design Identity
- Brand direction: [current brand direction]
- Mood/Tone: [current mood/tone]
- Visual language: [current visual language]

## Baseline Scores (4 Aesthetic Criteria)
| Criterion | Score (1-10) | Key Observation |
|-----------|-------------|-----------------|
| Cohesion | X | ... |
| Originality | X | ... |
| Craft | X | ... |
| Intuitiveness | X | ... |

**DAI = X**

## Strengths (to preserve)
- ...

## Weaknesses (to improve)
- ...

## Improvement Direction
- ...
═══════════════════════════════════════
```

**Phase Gate:** Phase 2 cannot proceed without DAI + Improvement Direction.

### STEP 5: Shutdown Research Team

---

## Phase 2: Design Generator — GAN Iterative Loop (max 5 rounds)

### STEP 1: Design Sprint Contract

Write to `.claude/pge-design/contract.md`:
- Scope (What Changes / What Does NOT Change)
- Target Scores (each of the 4 criteria >= 7)
- Quality Aspirations:
  - Cohesion: "An inseparable whole where every element feels like it tells a single story"
  - Originality: "If it's immediately recognizable as AI-generated, it's a failure"
  - Craft: "The difference of 1px separates amateur from professional"
  - Intuitiveness: "Your grandmother should know what to do within 3 seconds"

### STEP 2: Iterative Design Loop

#### A. Generate/Improve
- **iteration 1**: Initial implementation based on the Contract
- **iteration 2+**: Based on previous mini-eval feedback, **focus on the lowest-scoring criterion**

#### B. Mini-Evaluation
After each iteration, score 4 criteria from an aesthetic perspective. **Internal target = actual target + 1** (self-evaluation bias correction).

```
═══ ITERATION {N} MINI-EVAL ═══
Cohesion:      [score]/10 — [feedback]
Originality:   [score]/10 — [feedback]
Craft:         [score]/10 — [feedback]
Intuitiveness: [score]/10 — [feedback]

Lowest: {lowest-scoring criterion}
Action: {CONTINUE | EXIT (all criteria >= 8 internal target)}
```

#### C. Loop Decision

| Condition | Action |
|------|------|
| All criteria >= 8 (internal) | EXIT → Phase 3 |
| Scores stagnant 2 consecutive rounds | PIVOT — attack a different criterion first |
| 5 rounds reached | FORCE EXIT → Phase 3 |
| Any criterion regressed | ROLLBACK → restore previous state |

Score Tracking → `.claude/pge-design/iterations.md`

### STEP 3: Result Manifest → `.claude/pge-design/result.md`

---

## Phase 3: Design Critic — Independent Aesthetic Evaluation

**Fresh context Agent subagent is mandatory.**

### Critic Persona

```
You are a DESIGN CRITIC. Your reputation depends on catching aesthetic flaws.
Your default assumption: this design has at least 3 serious aesthetic problems.
Score inflation is YOUR failure — if everything gets 8+, you are not doing your job.

You judge AESTHETICS and UX INTUITION, not technical compliance.
Technical checks (token usage, accessibility, state handling) are /pge-front's job.

Score Calibration:
9-10: Museum-worthy. Nearly impossible.
7-8:  Professional designer level. This is the target.
5-6:  Functional but aesthetically unremarkable.
3-4:  Clear aesthetic problems.
1-2:  AI defaults as-is.

⚠️ Do NOT read "Self-Assessment Weaknesses" in result.md.
```

### Verification

**A. Independent evaluation of 4 criteria** — aesthetic judgment via code analysis
**B. Before/After comparison** — against the Research Brief baseline
**C. Devil's Advocate (Creative):**
1. Does the color palette convey emotional intent, or is it just a "pretty" combination?
2. Does the typographic hierarchy naturally guide the eye flow?
3. Is the whitespace intentional, or simply empty?
4. Does the layout suit the content's characteristics, or is it forced into a generic grid?
5. Did the style changes break consistency with existing screens?
6. Did the "improvement" produce a visually comparable difference?

**D. Anti-Pattern (Creative):**

| Anti-Pattern | How to Detect |
|---|---|
| "Improved" without visual difference | Minimal visual change in Before/After comparison |
| Style regression | Destroyed visual consistency with related screens |
| Mood inconsistency | Conflicting moods coexisting within a single screen |
| Typography hierarchy collapse | Ambiguous heading/body distinction |
| Color palette bloat | Indiscriminate colors beyond brand palette |
| Whitespace neglect | Packed without breathing room, no visual respiration |

**Verdict:**
- **PASS**: All criteria >= 7, DAI >= 7.0
- **CONDITIONAL PASS**: All criteria >= 5, DAI >= 5.5
- **FAIL**: Hard-fail (Cohesion < 5 or Craft < 5), or DAI < 5.5

→ `.claude/pge-design/eval.md`

Archive: `.claude/pge-design/history/{YYYYMMDD}T{HHMM}_{slug}.md`

---

## Final Report

```
DESIGN CREATIVE REPORT
════════════════════════════════════════
Target:          [design target]
Platform:        {Flutter | React | Vue}
Date:            {ISO timestamp}
Verdict:         {PASS | CONDITIONAL PASS | FAIL}

── Research ──
Team:            [{roles}]
Direction:       [improvement direction in one line]

── Generation ──
Iterations:      {N} rounds
Exit reason:     {reason}

── Critic ──
| Criterion      | Before | After  | Δ      |
|----------------|--------|--------|--------|
| Cohesion       | X/10   | X/10   | +X     |
| Originality    | X/10   | X/10   | +X     |
| Craft          | X/10   | X/10   | +X     |
| Intuitiveness  | X/10   | X/10   | +X     |

DAI:             Before X → After X (Δ: +X)
Evaluator:       independent design critic (fresh context)

💡 For technical checks, run /pge-front.
════════════════════════════════════════
```

## Escalation Rules

- DAI < 3.0: Recommend rebuilding design foundations
- Scores stagnant 3 consecutive rounds → STOP + confirm direction
- FAIL loop 2+ times → halt
- If technical issues found → recommend switching to `/pge-front`

## Important Rules

- Cannot proceed to the next Phase without required outputs
- Phase 1 is read-only; only the Phase 2 team lead may modify
- Phase 3 requires fresh context
- Focus on **aesthetic judgment** — technical checks belong to `/pge-front`
- Do not show Generator self-assessment to the Evaluator
- Mini-eval internal target = actual target + 1
- design-system-map is **read-only** (updates belong to /pge-front)
