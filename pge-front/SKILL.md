---
name: pge-front
description: |
  PGE Frontend Quality Protocol (Scanner-Fixer-Verifier).
  Spawns a team of frontend specialist agents to audit UI code quality
  across 8 categories (tokens, originality, craft, state, a11y, responsive,
  navigation, frontend performance), fix issues by priority, and verify
  with independent evaluator using Front Health Score.
  Core focus: design choices that kill performance and real-time responsiveness.
  Use when asked with /pge-front flag appended.
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

# /pge-front — PGE Frontend Quality Protocol

사용자가 작업 요청에 `/pge-front`를 붙이면 전체 프론트엔드 QA 프로토콜을 강제 실행한다.

## Project Initialization (첫 실행 시)

```bash
mkdir -p .claude/pge-front/history .claude/pge-front/baselines

if [ -f .gitignore ] && ! grep -q ".claude/pge-front/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE-front workflow state files\n.claude/pge-front/" >> .gitignore
fi
```

### 플랫폼 자동 감지
```
Flutter:    Glob pubspec.yaml → "flutter:" 섹션
React/Next: Glob package.json → "react" 의존성
Vue/Nuxt:   Glob package.json → "vue" 의존성
```
**필수 출력:** `Platform: {Flutter | React | Vue | Unknown}`

### 디자인 시스템 + Design System Map 탐지

`docs/design-system-map.md`가 없으면:
> "Design System Map이 없습니다. 프로젝트를 분석하여 생성할까요?"

승인 시 자동 생성 (Tokens, Shared Components, Screens, Cross-Screen Patterns).
이 맵은 `/pge-front`가 **갱신 권한** 보유. `/pge-design`은 읽기 전용.

**필수 출력:**
```
Design System: {detected files or "None"}
Token files: {color, typography, spacing, radius — 존재 여부}
```
플랫폼/디자인 시스템 미감지 시 다음 Phase 진행 불가.

## CRITICAL: Agent Spawning Rules

1. **TeamCreate** 사용 필수. 단순 Agent subagent 금지.
2. **Explore 서브에이전트 사용 금지.** general-purpose만.
3. **SendMessage로 상호 공유** 필수. 사일로 금지.
4. **TaskCreate** 작업 목록 생성 + teammate 할당.
5. **Phase 1 에이전트는 읽기 전용** — 수정은 Phase 2 team lead만.

## Input

$ARGUMENTS — 프론트엔드 점검 대상

## Mode Detection

- **Full**: 전체 앱 프론트엔드 QA
- **Quick**: 특정 화면/기능만
- **Diff-aware**: git diff main...HEAD 변경분만

**필수 출력:** `Front Mode: {Full | Quick | Diff-aware}`

---

## 8개 점검 영역 + Front Health Score

### Category 1: Design Token Compliance (15%)

| # | 항목 | Grep 패턴 | 심각도 |
|---|------|----------|--------|
| DT1 | 하드코딩 색상 | `Color\(0x\|Colors\.\|#[0-9a-fA-F]{3,8}\|rgba?\(` | HIGH |
| DT2 | 하드코딩 폰트 | `fontSize:\s*\d+\|font-size:\s*\d+px` | HIGH |
| DT3 | 하드코딩 간격 | `EdgeInsets\.\w+\(\s*\d+\|\d+px\s*(;\|})` | MEDIUM |
| DT4 | 하드코딩 반지름 | `BorderRadius\.circular\(\s*\d+\|border-radius:\s*\d+px` | MEDIUM |
| DT5 | 토큰 참조율 | 토큰_참조 / (토큰_참조 + 하드코딩) × 100 | — |

### Category 2: Originality Check (5%)

| # | Anti-Pattern | Grep Signature |
|---|---|---|
| OR1 | Purple gradient | `from-purple`, `bg-gradient` |
| OR2 | Default theme | 커스텀 ThemeData 없이 기본값 |
| OR3 | Template layout | Hero-Features-Pricing-CTA 패턴 |
| OR4 | Stock icons only | 커스텀 아이콘 0개 |
| OR5 | Generic copy | Lorem ipsum, placeholder |
| OR6 | Excessive nesting | 3단+ 의미 없는 래핑 |
| OR7 | Uniform spacing | 모든 간격 단일 값 |

### Category 3: Craft Quality (10%)

| # | 항목 | 심각도 |
|---|------|--------|
| CR1 | 타이포 계층 완성도 | HIGH |
| CR2 | 간격 그리드 준수 (4/8px) | HIGH |
| CR3 | 색상 대비 WCAG AA 4.5:1 | CRITICAL |
| CR4 | 아이콘 스타일 통일 | MEDIUM |
| CR5 | 애니메이션 일관성 | LOW |
| CR6 | border radius 일관성 | MEDIUM |

### Category 4: State Completeness (15%)

| # | 항목 | 심각도 |
|---|------|--------|
| ST1 | 로딩 상태 UI | HIGH |
| ST2 | 에러 상태 처리 | HIGH |
| ST3 | 빈 상태 UI | MEDIUM |
| ST4 | 폼 유효성 검사 | HIGH |
| ST5 | 확인 다이얼로그 | MEDIUM |

### Category 5: Accessibility (10%)

| # | 항목 | 심각도 |
|---|------|--------|
| A1 | Semantics/aria-label | HIGH |
| A2 | 색상 대비 4.5:1 | CRITICAL |
| A3 | 터치 타겟 48dp/44px | CRITICAL |
| A4 | 스크린 리더 지원 | HIGH |
| A5 | 포커스 관리 | MEDIUM |

### Category 6: Responsive Layout (8%)

| # | 항목 | 심각도 |
|---|------|--------|
| RL1 | MediaQuery/LayoutBuilder 사용 | HIGH |
| RL2 | 고정 크기 남용 | MEDIUM |
| RL3 | overflow 처리 | HIGH |
| RL4 | 텍스트 오버플로 | MEDIUM |

### Category 7: Navigation Consistency (7%)

| # | 항목 | 심각도 |
|---|------|--------|
| NV1 | 라우트 정의 일관성 | HIGH |
| NV2 | 뒤로가기 처리 | MEDIUM |
| NV3 | 딥링크 지원 | LOW |
| NV4 | 라우트 깊이 3+ 경고 | LOW |
| NV5 | 네비게이션 가드 | HIGH |

### Category 8: Frontend Performance (30%) — CRITICAL

**핵심: "디자인 선택이 성능을 저하시키는가?"**

`/pge-perf`와의 경계: `/pge-perf` = "코드가 느린가?" (DB, 서버). `/pge-front` = "디자인 선택이 느리게 만드는가?" (리빌드, 에셋, 라이브러리).

| # | 항목 | 심각도 |
|---|------|--------|
| FP1 | 무거운 라이브러리 (번들 크기, 미사용 import, 경량 대체) | HIGH |
| FP2 | 불필요한 리빌드 (setState 빈도, Consumer/Watch 범위) | CRITICAL |
| FP3 | 과도한 애니메이션 (AnimationController 동시 수) | MEDIUM |
| FP4 | 위젯 트리 깊이 (10단+ 중첩) | HIGH |
| FP5 | 이미지/에셋 미최적화 (원본 로딩, WebP 미사용, 캐싱 없음) | HIGH |
| FP6 | Provider/State 연쇄 갱신 (ref.invalidate 체인) | CRITICAL |
| FP7 | 메모리 누수 디자인 (dispose 누락, ListView.builder 미사용) | CRITICAL |
| FP8 | GPU 오버드로우 (ClipRRect, Opacity, BackdropFilter 남용) | MEDIUM |

**Flutter Grep:**
```
FP2: setState\(\s*\(\)\s*\{  |  ref\.watch\(  |  Consumer\(
FP5: Image\.asset\(  |  Image\.network\(
FP6: ref\.invalidate\(  |  ref\.refresh\(  |  notifyListeners\(
FP7: StreamSubscription  |  \.listen\(  |  Timer\(  → dispose() 확인
FP8: ClipRRect\(  |  Opacity\(  |  BackdropFilter\(
```

**Hard-fail: < 40**

---

## Front Health Score

```
Score = Σ (Category Score × Weight)
```

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100 | 프론트 품질 우수 |
| B | 75-89 | 양호 |
| C | 60-74 | 주요 이슈 수정 필요 |
| D | 40-59 | 심각 |
| F | 0-39 | 디자인 시스템 재구축 권고 |

**Hard-fail:** Frontend Performance < 40, Accessibility < 40

---

## Role Catalog

**필수 3명 항상 포함.** 최대 5명.

| Role | 담당 | 필수? |
|------|------|------|
| **design-token-auditor** | DT, OR, CR | **필수** |
| **a11y-auditor** | A11Y, CR(CR3) | **필수** |
| **front-perf-auditor** | FP 전체 | **필수** |
| **state-flow-checker** | ST, NV, RL | UI 코드 시 |
| **ux-pattern-reviewer** | ST, NV, OR | 새 화면 시 |

---

## Phase 1: Scanner — Front Profile + Baseline

### STEP 1: Task Analysis + Role Selection
```
필수 출력:
Front Mode: {Full | Quick | Diff-aware}
Platform: {Flutter | React | Vue}
Selected roles: [{role1}, {role2}, ...]
Rationale: [선택 이유]
```

### STEP 2: Create Scanner Team
TeamCreate → Agent(team_name="pge-front-scan-{slug}", name="{role}", run_in_background=true)

### STEP 3: Wait + Synthesize

### STEP 4: Front Profile Report → `.claude/pge-front/front-profile.md`

**Phase Gate:** Front Health Score + Issue Summary 없으면 Phase 2 진행 불가.

### STEP 5: Shutdown Scanner Team

---

## Phase 2: Fixer — Priority 순서로 수정

**Priority Score = Severity × 2 - Effort - Risk** (>= 6: Quick Win, 3-5: Standard, <= 2: Backlog)

Fix Loop: BEFORE → FIX → TEST → AFTER → COMMIT (`fix(front-{cat}): {desc}`)

WTF-likelihood: revert +15%, >3 files +5%, after 15th +1%/fix, unrelated +20%. >= 50% STOP. 하드캡 50.

Cross-Skill Routing: backend → `/pge`, backend perf → `/pge-perf`, creative → `/pge-design`, code quality → `/pge-qa`

Fix Result → `.claude/pge-front/fix-result.md`

---

## Phase 3: Verifier — 독립 검증

**fresh context Agent subagent 필수.**

```
You are the VERIFIER in a frontend QA workflow.
Be skeptical. Do NOT assume correctness.

Verify: Health Score 재계산, fix 개별 검증, Design System Map walk, regression check.

Devil's Advocate (Frontend):
1. 토큰 교체가 실제 디자인 시스템 값인가?
2. 접근성 개선이 형식적 래핑인가?
3. 컴포넌트 추출이 재사용 가능한가?
4. 에러/빈 상태 UI가 placeholder인가?
5. 성능 개선이 기능 회귀를 유발하지 않았는가?
6. ListView.builder 내부 무거운 연산이 남아있지 않은가?
7. 이미지 최적화 시 해상도가 수용 가능한가?

Anti-Pattern: Token theater, Semantics spam, Over-abstraction,
Functionality removal, Builder without benefit, Animation overkill,
Import bloat, Dispose amnesia

HARD FAIL: Frontend Performance < 40, Accessibility < 40

Verdict:
- PASS: improved, grade B+, no hard-fail
- CONDITIONAL PASS: improved, grade C+, no hard-fail
- FAIL: hard-fail, decreased, or grade D
```

→ `.claude/pge-front/front-eval.md`

Archive: `.claude/pge-front/history/{YYYYMMDD}T{HHMM}_{slug}.md`

---

## Escalation Rules

- 플랫폼/디자인 시스템 미감지 → 사용자 확인
- 3-strike, 50 fix 하드캡
- FAIL loop 2+회 → 중단
- Grade F → 디자인 시스템 재구축 권고
- Cross-skill > 50% → 해당 skill 먼저 실행
- 크리에이티브 이슈 다수 → `/pge-design` 전환 권고

## Important Rules

- 필수 출력 없으면 다음 Phase 불가
- Phase 1 읽기 전용, Phase 2 team lead만 수정
- Phase 3 fresh context 필수
- 실제 Grep/Read 측정 필수
- Before/After 증거 필수
- design-system-map 갱신 권한 보유
