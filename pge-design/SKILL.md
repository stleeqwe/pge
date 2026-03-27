---
name: pge-design
description: |
  PGE Design Quality Protocol (Analyst-Generator-Evaluator).
  Spawns a team of UI/UX specialist agents to analyze current design state,
  iteratively improve with GAN-inspired Generator-Evaluator loop,
  and verify with independent evaluator using 4 design criteria.
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

# /pge-design — PGE Design Quality Protocol

사용자가 작업 요청에 `/pge-design`을 붙이면 전체 디자인 품질 프로토콜을 강제 실행한다.

## Project Initialization (첫 실행 시)

```bash
mkdir -p .claude/pge-design/history
mkdir -p .claude/pge-design/baselines

if [ -f .gitignore ] && ! grep -q ".claude/pge-design/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE-design workflow state files\n.claude/pge-design/" >> .gitignore
fi
```

### 플랫폼 자동 감지

```
Flutter:    Glob pubspec.yaml → "flutter:" 섹션 존재
React/Next: Glob package.json → "react" 의존성
Vue/Nuxt:   Glob package.json → "vue" 의존성 또는 nuxt.config.*
```

**필수 출력:** `Platform: {Flutter | React | Vue | Unknown}`

### 디자인 시스템 파일 탐지

```
Glob: **/theme/**  |  **/tokens/**  |  **/design-system/**  |  **/styles/**
Grep: ThemeData|ColorScheme|TextTheme  (Flutter)
Grep: --color-|--spacing-|--font-     (Web CSS variables)
Grep: tailwind.config                  (Tailwind)
```

**필수 출력:**
```
Design System: {detected files list or "None detected"}
Token files: {color, typography, spacing, radius, shadow — 각 존재 여부}
```

플랫폼과 디자인 시스템이 감지되지 않으면 다음 Phase 진행 불가.

### Design System Map 초기화

`docs/design-system-map.md`가 없으면 사용자에게 알림:
> "Design System Map이 없습니다. 프로젝트를 분석하여 `docs/design-system-map.md`를 생성할까요?"

사용자가 승인하면 프로젝트를 분석하여 자동 생성:

```markdown
# Design System Map

## Tokens
| Category | File | Tokens | Used By (screens) |
|----------|------|--------|-------------------|
| Color | lib/core/theme/colors.dart | primary, secondary, surface, ... | all |
| Typography | lib/core/theme/typography.dart | heading, body, caption, ... | all |
| Spacing | lib/core/theme/spacing.dart | xs, sm, md, lg, xl, ... | all |
| Radius | lib/core/theme/radius.dart | card, button, chip, sheet, ... | all |

## Shared Components
| Component | File | Used By (screens) | Props/Variants |
|-----------|------|--------------------|----------------|
| LeafitButton | lib/shared/widgets/button.dart | 12 screens | primary, secondary, text |
| ... | ... | ... | ... |

## Screens
| Screen | File | Components Used | Tokens Direct | Status |
|--------|------|----------------|---------------|--------|
| HomeScreen | lib/features/home/... | LeafitButton, ItemCard | 3 hardcoded | needs-review |
| ... | ... | ... | ... | ... |

## Cross-Screen Patterns
| Pattern | Screens | Consistent? |
|---------|---------|------------|
| AppBar style | all | Y/N |
| Card layout | home, profile, chat | Y/N |
| Empty state | feed, search, chat | Y/N |
| Error state | all async screens | Y/N |
```

이 맵은 매 `/pge-design` 실행 시 갱신된다. Phase 1(Analyst)이 맵을 읽고 분석 범위를 결정하고, Phase 3(Evaluator)이 맵 항목별로 검증한다.

## CRITICAL: Agent Spawning Rules

1. **TeamCreate를 사용하여 팀을 구성**할 것. 단순 Agent subagent 스폰이 아닌 TeamCreate → Agent(team_name=..., name=...) 패턴.
2. **Explore 서브에이전트는 사용하지 말 것.** 모든 teammate는 `general-purpose` agent로 스폰.
3. **각 teammate는 서로 SendMessage로 발견한 내용을 공유**하면서 진행할 것. 사일로 금지.
4. **TaskCreate로 작업 목록을 생성**하고 teammate에게 할당할 것.
5. **Phase 1(Analyst)의 에이전트는 읽기 전용** — 코드 수정은 Phase 2에서 team lead만 수행.

## Input

$ARGUMENTS — 디자인 개선 대상 설명 (특정 화면, 컴포넌트, 전체 앱 등)

---

## 4가지 평가 기준

### Criterion 1: Design Quality — "응집된 전체인가?"

**측정 지표:**
- 토큰 사용률 = 토큰_참조 / (토큰_참조 + 하드코딩) × 100
- 스페이싱 일관성: 그리드 기반 값 비율
- 시각적 응집도: 화면 간 구조/패턴 유사성

**Flutter Grep 패턴:**
```
토큰_참조: {ProjectColors}\.|{ProjectTypography}\.|{ProjectSpacing}\.|{ProjectRadius}\.
하드코딩:  Color\(0x|Colors\.|fontSize:\s*\d+|EdgeInsets\.\w+\(\s*\d+|BorderRadius\.circular\(\s*\d+
```

**Web Grep 패턴:**
```
토큰_참조: var\(--color|var\(--spacing|var\(--font
하드코딩:  #[0-9a-fA-F]{3,8}|rgba?\(|\d+px\s*(;|})|font-size:\s*\d+px
```

**점수 가이드:**
- 9-10: 토큰 사용률 95%+, 하드코딩 0건. 전문 디자이너 수준.
- 7-8: 토큰 사용률 85%+, 하드코딩 5건 이하. 프로덕션 배포 가능.
- 5-6: 토큰 사용률 70%+, 하드코딩 다수.
- 3-4: 토큰 사용률 50% 미만.
- 1-2: 디자인 시스템 미사용.

### Criterion 2: Originality — "AI 찌꺼기가 아닌가?"

**안티패턴 테이블:**

| Anti-Pattern | Grep Signature | Match? |
|---|---|---|
| Purple gradient syndrome | `from-purple`, `bg-gradient` (Web) | Y/N |
| Default theme | 커스텀 ThemeData 없이 기본값 (Flutter) | Y/N |
| Template layout | Hero-Features-Pricing-CTA 고정 순서 (Web) | Y/N |
| Stock icons only | 커스텀 아이콘/일러스트 0개 | Y/N |
| Generic copy | Lorem ipsum 또는 placeholder 텍스트 | Y/N |
| Excessive nesting | Container/div 3단+ 중첩, 의미 없는 래핑 | Y/N |
| Uniform spacing | 모든 간격이 단일 값 반복 | Y/N |

### Criterion 3: Craft — "디테일이 살아있는가?"

| # | 항목 | 검증 방법 | 심각도 |
|---|------|----------|--------|
| CR1 | 타이포 계층 완성도 | heading/body/caption 각 레벨 정의 | HIGH |
| CR2 | 간격 그리드 준수 | spacing 값이 4/8px 그리드 | HIGH |
| CR3 | 색상 대비 (WCAG AA) | 텍스트/배경 대비 4.5:1 이상 | CRITICAL |
| CR4 | 아이콘 스타일 통일 | outlined/filled/rounded 혼재율 | MEDIUM |
| CR5 | 애니메이션 일관성 | duration/curve 일관성 | LOW |
| CR6 | border radius 일관성 | 동일 유형 컴포넌트 radius 통일 | MEDIUM |

### Criterion 4: Functionality — "추측 없이 완료할 수 있는가?"

| # | 항목 | 검증 방법 | 심각도 |
|---|------|----------|--------|
| FN1 | 로딩 상태 UI | 비동기 호출마다 loading UI | HIGH |
| FN2 | 에러 상태 처리 | catchError + 에러 UI | HIGH |
| FN3 | 빈 상태 UI | isEmpty + 빈 상태 메시지 | MEDIUM |
| FN4 | 폼 유효성 검사 | validator + 에러 메시지 | HIGH |
| FN5 | 확인 다이얼로그 | 위험 동작 전 showDialog | MEDIUM |
| FN6 | 터치 타겟 크기 | 최소 48dp (모바일) / 44px (웹) | CRITICAL |
| FN7 | 네비게이션 깊이 | 라우트 깊이 3 이상 경고 | LOW |

---

## Role Catalog

오케스트레이터가 task에 맞는 역할을 **2~4명** 선택. **a11y-checker는 항상 포함**.

| Role | 전문 영역 | 언제 선택 |
|------|----------|----------|
| **design-system-auditor** | 토큰/컴포넌트 일관성 | 새 UI 또는 기존 UI 변경 시 |
| **a11y-checker** | 접근성 기준 검증 | **항상 포함** (필수) |
| **ux-flow-analyst** | 사용자 플로우/인터랙션 | 새 화면/기능 추가 시 |
| **visual-consistency-checker** | 시각적 일관성 | UI 관련 모든 변경 시 |
| **responsive-tester** | 반응형/적응형 레이아웃 | 레이아웃 변경 시 |

카탈로그 외 역할도 task에 맞게 정의 가능.

---

## Phase 1: Design Analyst — Baseline + Design Profile

### STEP 1: Task Analysis + Role Selection

**필수 출력:**
```
PGE Design Mode: Design Review
Platform: {Flutter | React | Vue}
Design System: {detected token files}
Selected roles: [{role1}, {role2}, ...]
Rationale: [왜 이 역할들이 필요한지]
```

### STEP 2: Create Analysis Team

**TeamCreate**로 팀 생성, 선택된 역할별로 Agent 스폰. 모든 Agent:
- `team_name="pge-design-{task-slug}"`
- `name="{role-name}"`
- `run_in_background=true`

각 에이전트 프롬프트에 포함할 내용:
- 팀명, 역할, 전문 영역
- 임무 (task 설명 + 프로젝트 컨텍스트)
- 역할별 수행 항목 (Grep 패턴 포함)
- SendMessage 공유 규칙
- 읽기 전용 제약 + TaskUpdate 지시

### STEP 3: Wait + Synthesize

에이전트들이 SendMessage로 발견사항을 상호 공유하며 분석. 완료 후 종합.

### STEP 4: Design Profile Report

`.claude/pge-design/design-profile.md`에 저장:

```
═══ DESIGN PROFILE REPORT ═══

## Context
Target: [분석 대상]
Platform: {Flutter | React | Vue}
Date: {ISO timestamp}

## Team Analysis
{각 역할별 핵심 발견사항}

## Baseline Scores
| Criterion | Score (1-10) | Key Issue |
|-----------|-------------|-----------|
| Design Quality | X | ... |
| Originality | X | ... |
| Craft | X | ... |
| Functionality | X | ... |

## DQI (Design Quality Index)
DQI = (토큰_사용률 × 0.3) + (재사용률 × 0.2) + (접근성_점수 × 0.3) + (상태_완전성 × 0.2)
**DQI = X**

## Issue Summary
| # | Category | File:Line | Issue | Severity | Criterion |

## Anti-Pattern Matches
| Anti-Pattern | Match? | Evidence |

Baseline DQI: [현재 수치]
═══════════════════════════════════════
```

**필수 출력** — `Baseline Scores`, `DQI`, `Issue Summary`가 없으면 Phase 2 진행 불가.

### STEP 5: Shutdown Analysis Team

---

## Phase 2: Design Generator — 반복 루프 (GAN 패턴)

### STEP 1: Design Sprint Contract

`.claude/pge-design/contract.md`에 작성:
- Scope (What Changes / What Does NOT Change)
- Target Scores (4기준 각각 Baseline → Target ≥ 7)
- Acceptance Criteria (코드 분석으로 검증 가능한 지표)
- Quality Aspirations (Generator 프롬프트에 삽입하여 품질 기대 수준 설정):
  - Design Quality: "모든 요소가 하나의 이야기를 말하는 것처럼 느껴지는 분리 불가한 전체"
  - Originality: "한 눈에 AI가 만들었다고 알 수 있다면 실패"
  - Craft: "1px의 차이가 아마추어와 전문가를 나눈다"
  - Functionality: "할머니가 3초 안에 무엇을 해야 하는지 알 수 있어야 한다"

### STEP 2: Iterative Design Loop (최대 5회)

#### A. Generate/Improve

- **iteration 1**: Sprint Contract 기반 초기 구현
- **iteration 2+**: 이전 mini-eval 피드백 기반, **가장 낮은 점수 기준에 집중**

#### B. Mini-Evaluation

각 반복 후 코드 분석으로 4기준 점수. **내부 목표 = 실제 목표 + 1** (자기 평가 편향 보정).

```
═══ ITERATION {N} MINI-EVAL ═══
Design Quality:  [score]/10 — [피드백 + 토큰 사용률]
Originality:     [score]/10 — [피드백 + 안티패턴 수]
Craft:           [score]/10 — [피드백 + 대비율/간격]
Functionality:   [score]/10 — [피드백 + 상태 완전성]

Lowest: {가장 낮은 기준}
Action: {CONTINUE | EXIT (모든 기준 ≥ 8 내부 목표)}
```

**반드시 실제 Grep/Read로 측정** — "looks good" 금지.

#### C. Loop Decision

| 조건 | 행동 |
|------|------|
| 모든 기준 ≥ 8 (내부) | EXIT → Phase 3 |
| 점수 정체 2회 연속 | PIVOT — 다른 기준부터 공략 |
| 5회 도달 | FORCE EXIT → Phase 3 |
| 어떤 기준 하락 | ROLLBACK → 이전 상태 복원 |

Score Tracking을 `.claude/pge-design/iterations.md`에 기록.

### STEP 3: Result Manifest

`.claude/pge-design/result.md`에 저장:
- Applied Changes (file, change, criterion, before, after)
- Iterations (총 횟수, exit reason)
- Final Mini-Eval Scores
- Self-Assessment Weaknesses (Evaluator에게 공유 금지)

---

## Phase 3: Design Evaluator — 독립 검증

**반드시 fresh context Agent subagent으로 실행.**

### Evaluator 페르소나

```
You are a DESIGN CRITIC. Your reputation depends on catching flaws.
Your default assumption: this design has at least 3 serious problems you haven't found yet.
Score inflation is YOUR failure — if everything gets 8+, you are not doing your job.

Score Calibration:
9-10: 전문 디자이너 수준. 거의 불가능.
7-8:  프로덕션 배포 가능. 이것이 목표.
5-6:  기능적이지만 디자인 약함.
3-4:  명백한 문제.
1-2:  기본값/템플릿 상태.

⚠️ Do NOT read "Self-Assessment Weaknesses" in result.md — score independently first.
```

### Evaluator 검증 프로세스

**A. 4기준 독립 평가** — 실제 Grep/Read로 측정
**B. Before/After 비교** — Design Profile baseline 대비
**C. Devil's Advocate (Design):**
1. 토큰 사용률이 실제로 올랐는가, 하드코딩을 다른 하드코딩으로 교체한 건 아닌가?
2. 접근성 개선이 형식적 Semantics 래핑인가?
3. 컴포넌트 재사용이 불필요한 래핑인가?
4. 에러/빈 상태 UI가 placeholder 텍스트인가?
5. 스타일 변경이 기존 화면 일관성을 깨뜨리지 않았는가?
6. "개선"이 코드로 검증 가능한가?

**D. Anti-Pattern Check:**

| Anti-Pattern | How to Detect |
|---|---|
| "Improved" without measurement | Before/After 수치 없음 |
| Token replacement theater | 토큰으로 바꿨지만 값이 디자인 시스템과 불일치 |
| Semantics spam | 무의미한 Semantics 래핑 |
| Over-abstraction | 한 곳에서만 쓰이는 공유 위젯 |
| Style regression | 대상 개선하며 연관 화면 깨뜨림 |
| Functionality removal | 기능 제거로 "간결해짐" 주장 |

**E. Score + DQI + Verdict:**
- **PASS**: 모든 기준 ≥ 7, DQI ≥ 85
- **CONDITIONAL PASS**: 모든 기준 ≥ 5, DQI ≥ 70
- **FAIL**: hard-fail 기준 < 5, 또는 DQI < 70

Hard-fail: Design Quality < 5, Craft < 5, Functionality < 5

### Evaluator 결과 처리

- **PASS**: Archive → Design Quality Report 출력
- **CONDITIONAL PASS**: 미달 항목 수정 → Archive (재검증 불필요)
- **FAIL**: 수정 → Evaluator 재실행 (fresh context)

---

## Final Report

```
DESIGN QUALITY REPORT
════════════════════════════════════════
Target:          [디자인 개선 대상]
Platform:        {Flutter | React | Vue}
Date:            {ISO timestamp}
Verdict:         {PASS | CONDITIONAL PASS | FAIL}

── Analysis ──
Team:            [{roles}]
Baseline DQI:    X

── Generation ──
Iterations:      {N}회
Exit reason:     {reason}

── Evaluation ──
| Criterion        | Before | After  | Δ      |
|------------------|--------|--------|--------|
| Design Quality   | X/10   | X/10   | +X     |
| Originality      | X/10   | X/10   | +X     |
| Craft            | X/10   | X/10   | +X     |
| Functionality    | X/10   | X/10   | +X     |

DQI:             Before X → After X (Δ: +X)
Evaluator:       independent design critic (fresh context)
════════════════════════════════════════
```

### Archive
`.claude/pge-design/history/{YYYYMMDD}T{HHMM}_{task-slug}.md` (under 100 lines).

---

## Escalation Rules

- **Phase 1 실패**: 디자인 시스템 미감지 → 사용자에게 토큰 파일 위치 확인
- **Phase 2 실패**: 점수 정체 3회 연속 → STOP + 방향 확인
- **Phase 3 FAIL loop 2+회**: 중단 + 에스컬레이션
- **DQI < 50**: 디자인 시스템 구축을 먼저 권고
- **플랫폼 Unknown**: 사용자에게 명시 요청

---

## Important Rules

- 각 Phase의 **필수 출력**이 없으면 다음 Phase 진행 불가
- `/pge-design` 작업은 **프로토콜 스킵 불가**
- Phase 1 에이전트는 **코드 수정 금지** — 분석/측정만
- Phase 2 코드 수정은 **team lead만**
- Phase 3 Evaluator는 **fresh context Agent subagent**
- **실제 Grep/Read 측정** 필수 — "I assume it looks good" 불가
- Evaluator에게 Generator 자기평가 점수 **보여주지 않기** (편향 방지)
- Mini-eval **내부 목표 = 실제 목표 + 1** (자기 평가 편향 보정)
- SendMessage 상호 공유 필수, 팀 shutdown 필수
