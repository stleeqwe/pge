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

사용자가 작업 요청에 `/pge-design`을 붙이면 전체 디자인 크리에이티브 프로토콜을 강제 실행한다.
**기술적 점검(토큰 사용률, 접근성, 상태 처리)은 `/pge-front` 영역.** 이 skill은 미적 판단에 집중.

## Project Initialization (첫 실행 시)

```bash
mkdir -p .claude/pge-design/history .claude/pge-design/baselines

if [ -f .gitignore ] && ! grep -q ".claude/pge-design/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE-design workflow state files\n.claude/pge-design/" >> .gitignore
fi
```

### 플랫폼 자동 감지
```
Flutter:    Glob pubspec.yaml → "flutter:" 섹션
React/Next: Glob package.json → "react" 의존성
Vue/Nuxt:   Glob package.json → "vue" 의존성
```
**필수 출력:** `Platform: {Flutter | React | Vue | Unknown}`

### Design System Map 참조 (읽기 전용)

`docs/design-system-map.md`를 **읽기 전용**으로 참조. 갱신 권한은 `/pge-front`.
없으면: "Design System Map이 없습니다. `/pge-front`를 먼저 실행하여 생성하세요."

## CRITICAL: Agent Spawning Rules

1. **TeamCreate** 사용 필수.
2. **Explore 서브에이전트 사용 금지.** general-purpose만.
3. **SendMessage로 상호 공유** 필수.
4. **TaskCreate** 작업 목록 + teammate 할당.
5. **Phase 1 에이전트는 읽기 전용** — 구현은 Phase 2 team lead만.

## Input

$ARGUMENTS — 디자인 개선 대상

## 협업 흐름

```
기존 UI 개선:  /pge-front (점검) → /pge-design (개선) → /pge-front (재점검)
신규 디자인:   /pge-design (생성) → /pge-front (점검)
```

---

## 4가지 미적 평가 기준

### Criterion 1: Cohesion (응집도) — "모든 요소가 하나의 이야기를 하는가?"

- 색상, 타이포, 레이아웃, 이미지가 통일된 무드/정체성을 형성하는가?
- 여러 부분의 집합이 아닌 분리 불가한 전체인가?
- 브랜드 아이덴티티가 모든 화면에서 일관되게 느껴지는가?

**Hard-fail if < 5**

### Criterion 2: Originality (독창성) — "AI 찌꺼기가 아닌가?"

- 커스텀 디자인 결정의 흔적이 있는가?
- "보라색 그래디언트" 같은 AI 기본 패턴이 아닌가?
- 브랜드 고유의 시각 언어가 있는가?
- 경쟁 서비스와 차별화되는 시각적 아이덴티티가 있는가?

### Criterion 3: Craft (완성도) — "디테일이 살아있는가?"

- 타이포그래피 계층이 시선 흐름을 자연스럽게 유도하는가?
- 색상 하모니가 감정적 의도를 전달하는가?
- 여백(negative space)이 의도적으로 활용되는가?
- 미세한 디테일(shadow, radius, transition)에 일관된 철학이 있는가?

**Hard-fail if < 5**

### Criterion 4: Intuitiveness (직관성) — "3초 안에 이해하는가?"

- 시선 흐름이 자연스럽게 핵심 CTA로 향하는가?
- 정보 계층이 명확하여 스캔이 가능한가?
- 사용자가 어떤 동작을 해야 하는지 추측 없이 알 수 있는가?

### DAI (Design Aesthetic Index)

```
DAI = (응집도 × 0.3) + (독창성 × 0.25) + (완성도 × 0.25) + (직관성 × 0.2)
```

**점수 가이드:**
- 9-10: 박물관에 걸릴 수준. 거의 불가능.
- 7-8: 전문 디자이너 수준. 이것이 목표.
- 5-6: 기능적이지만 디자인 평범.
- 3-4: 명백한 미적 문제.
- 1-2: AI 기본값 그대로.

---

## Role Catalog

오케스트레이터가 task에 맞는 역할을 **2~4명** 선택. **brand-analyst 필수**.

| Role | 전문 영역 | 필수? |
|------|----------|------|
| **brand-analyst** | 브랜딩, 무드, 톤앤매너, 컬러 팔레트 해석 | **필수** |
| **ux-strategist** | 사용자 페르소나, UX 방향성, 정보 계층 | 선택 |
| **visual-researcher** | 프로젝트 내 기존 패턴 분석, 시각적 트렌드 | 선택 |
| **layout-architect** | 레이아웃 구조, 그리드 시스템, 공간 배분 | 선택 |

카탈로그 외 역할도 정의 가능.

---

## Phase 1: Design Research — 방향성 탐색

### STEP 1: Task Analysis + Role Selection

**필수 출력:**
```
Design Mode: Creative
Platform: {Flutter | React | Vue}
Selected roles: [{role1}, {role2}, ...]
Rationale: [선택 이유]
```

### STEP 2: Create Research Team

TeamCreate → Agent(team_name="pge-design-{slug}", name="{role}", run_in_background=true)

각 에이전트는:
- 현재 디자인 방향성 분석 (브랜딩, 무드, 톤)
- design-system-map 참조 (현황 파악)
- 타겟 사용자/페르소나에 맞는 디자인 방향 도출
- 프로젝트 내 기존 시각적 패턴 분석

### STEP 3: Wait + Synthesize

### STEP 4: Design Research Brief

`.claude/pge-design/research-brief.md`에 저장:

```
═══ DESIGN RESEARCH BRIEF ═══

## Context
Target: [디자인 대상]
Platform: {Flutter | React | Vue}
Date: {ISO timestamp}

## Current Design Identity
- Brand direction: [현재 브랜드 방향]
- Mood/Tone: [현재 무드/톤]
- Visual language: [현재 시각 언어]

## Baseline Scores (4 미적 기준)
| Criterion | Score (1-10) | Key Observation |
|-----------|-------------|-----------------|
| Cohesion | X | ... |
| Originality | X | ... |
| Craft | X | ... |
| Intuitiveness | X | ... |

**DAI = X**

## Strengths (유지할 것)
- ...

## Weaknesses (개선할 것)
- ...

## Improvement Direction
- ...
═══════════════════════════════════════
```

**Phase Gate:** DAI + Improvement Direction 없으면 Phase 2 진행 불가.

### STEP 5: Shutdown Research Team

---

## Phase 2: Design Generator — GAN 반복 루프 (최대 5회)

### STEP 1: Design Sprint Contract

`.claude/pge-design/contract.md`에 작성:
- Scope (What Changes / What Does NOT Change)
- Target Scores (4기준 각각 ≥ 7)
- Quality Aspirations:
  - 응집도: "모든 요소가 하나의 이야기를 말하는 것처럼 느껴지는 분리 불가한 전체"
  - 독창성: "한 눈에 AI가 만들었다고 알 수 있다면 실패"
  - 완성도: "1px의 차이가 아마추어와 전문가를 나눈다"
  - 직관성: "할머니가 3초 안에 무엇을 해야 하는지 알 수 있어야 한다"

### STEP 2: Iterative Design Loop

#### A. Generate/Improve
- **iteration 1**: Contract 기반 초기 구현
- **iteration 2+**: 이전 mini-eval 피드백 기반, **가장 낮은 기준에 집중**

#### B. Mini-Evaluation
각 반복 후 미적 관점에서 4기준 점수. **내부 목표 = 실제 목표 + 1** (자기 평가 편향 보정).

```
═══ ITERATION {N} MINI-EVAL ═══
Cohesion:      [score]/10 — [피드백]
Originality:   [score]/10 — [피드백]
Craft:         [score]/10 — [피드백]
Intuitiveness: [score]/10 — [피드백]

Lowest: {가장 낮은 기준}
Action: {CONTINUE | EXIT (모든 기준 ≥ 8 내부 목표)}
```

#### C. Loop Decision

| 조건 | 행동 |
|------|------|
| 모든 기준 ≥ 8 (내부) | EXIT → Phase 3 |
| 점수 정체 2회 연속 | PIVOT — 다른 기준부터 공략 |
| 5회 도달 | FORCE EXIT → Phase 3 |
| 어떤 기준 하락 | ROLLBACK → 이전 상태 복원 |

Score Tracking → `.claude/pge-design/iterations.md`

### STEP 3: Result Manifest → `.claude/pge-design/result.md`

---

## Phase 3: Design Critic — 독립 미적 평가

**fresh context Agent subagent 필수.**

### Critic 페르소나

```
You are a DESIGN CRITIC. Your reputation depends on catching aesthetic flaws.
Your default assumption: this design has at least 3 serious aesthetic problems.
Score inflation is YOUR failure — if everything gets 8+, you are not doing your job.

You judge AESTHETICS and UX INTUITION, not technical compliance.
Technical checks (token usage, accessibility, state handling) are /pge-front's job.

Score Calibration:
9-10: 박물관에 걸릴 수준. 거의 불가능.
7-8:  전문 디자이너 수준. 이것이 목표.
5-6:  기능적이지만 디자인 평범.
3-4:  명백한 미적 문제.
1-2:  AI 기본값 그대로.

⚠️ Do NOT read "Self-Assessment Weaknesses" in result.md.
```

### Verification

**A. 4기준 독립 평가** — 코드 분석으로 미적 판단
**B. Before/After 비교** — Research Brief baseline 대비
**C. Devil's Advocate (Creative):**
1. 색상 팔레트가 감정적 의도를 전달하는가, 그냥 "예쁜" 조합인가?
2. 타이포그래피 계층이 시선 흐름을 자연스럽게 유도하는가?
3. 여백이 의도적인가, 그냥 비어있는가?
4. 레이아웃이 콘텐츠 특성에 맞는가, 범용 그리드에 끼워넣은 건 아닌가?
5. 스타일 변경이 기존 화면 일관성을 깨뜨리지 않았는가?
6. "개선"이 시각적으로 비교 가능한 차이를 만들었는가?

**D. Anti-Pattern (Creative):**

| Anti-Pattern | How to Detect |
|---|---|
| "Improved" without visual difference | Before/After 시각적 변화 미미 |
| Style regression | 연관 화면 시각적 일관성 파괴 |
| Mood inconsistency | 한 화면 내 상충하는 무드 혼재 |
| Typography hierarchy collapse | heading/body 구분 모호 |
| Color palette bloat | 브랜드 컬러 외 무분별한 색상 |
| Whitespace neglect | 여백 없이 빽빽, 시각적 숨결 부재 |

**Verdict:**
- **PASS**: 모든 기준 ≥ 7, DAI ≥ 7.0
- **CONDITIONAL PASS**: 모든 기준 ≥ 5, DAI ≥ 5.5
- **FAIL**: hard-fail (응집도 < 5 or 완성도 < 5), 또는 DAI < 5.5

→ `.claude/pge-design/eval.md`

Archive: `.claude/pge-design/history/{YYYYMMDD}T{HHMM}_{slug}.md`

---

## Final Report

```
DESIGN CREATIVE REPORT
════════════════════════════════════════
Target:          [디자인 대상]
Platform:        {Flutter | React | Vue}
Date:            {ISO timestamp}
Verdict:         {PASS | CONDITIONAL PASS | FAIL}

── Research ──
Team:            [{roles}]
Direction:       [개선 방향 한 줄]

── Generation ──
Iterations:      {N}회
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

💡 기술적 점검은 /pge-front를 실행하세요.
════════════════════════════════════════
```

## Escalation Rules

- DAI < 3.0: 디자인 기초 재구축 권고
- 점수 정체 3회 연속 → STOP + 방향 확인
- FAIL loop 2+회 → 중단
- 기술적 이슈 발견 시 → `/pge-front` 전환 권고

## Important Rules

- 필수 출력 없으면 다음 Phase 불가
- Phase 1 읽기 전용, Phase 2 team lead만 수정
- Phase 3 fresh context 필수
- **미적 판단** 집중 — 기술적 점검은 `/pge-front` 영역
- Evaluator에게 Generator 자기평가 보여주지 않기
- Mini-eval 내부 목표 = 실제 목표 + 1
- design-system-map **읽기 전용** (갱신은 /pge-front)
