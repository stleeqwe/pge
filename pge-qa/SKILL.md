---
name: pge-qa
description: |
  PGE QA Protocol (Scanner-Fixer-Verifier).
  Spawns a team of QA specialist agents to scan code quality across 9 categories,
  fix issues by priority with atomic commits, and verify with independent
  evaluator using Health Score. Supports Full/Quick/Diff-aware/Regression modes.
  Use when asked with /pge-qa flag appended.
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

# /pge-qa — PGE QA Protocol (Scanner-Fixer-Verifier)

사용자가 작업 요청에 `/pge-qa`를 붙이면 전체 QA 프로토콜을 강제 실행한다.

## Project Initialization (첫 실행 시)

```bash
mkdir -p .claude/pge-qa/baselines
mkdir -p .claude/pge-qa/history

if [ -f .gitignore ] && ! grep -q ".claude/pge-qa/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE-qa workflow state files\n.claude/pge-qa/" >> .gitignore
fi
```

### 플랫폼 자동 감지

```
Flutter:    Glob pubspec.yaml → "flutter:" 섹션
React/Next: Glob package.json → "react" 의존성
Vue/Nuxt:   Glob package.json → "vue" 의존성
```

**필수 출력:** `Platform: {Flutter | React | Vue | Unknown}`

### QA Coverage Map 초기화

`docs/qa-coverage-map.md`가 없으면 사용자에게 알림:
> "QA Coverage Map이 없습니다. 프로젝트를 분석하여 `docs/qa-coverage-map.md`를 생성할까요?"

승인 시 프로젝트를 분석하여 자동 생성:

```markdown
# QA Coverage Map

## 1. Screen/Feature Inventory
| # | Screen/Feature | Route/Path | Priority |
|---|----------------|------------|----------|

## 2. User Flow Map
### Flow 1: {플로우명}
[시작] → Screen A → Screen B → [완료]
- Happy path / Edge cases / State transitions

## 3. State Combination Matrix
### Screen: {화면명}
| # | State | Condition | Expected UI | Test exists? | Test file |
|---|-------|-----------|-------------|-------------|-----------|
| 1 | loading | data fetching | spinner/skeleton | Y/N | |
| 2 | error | API failure | error message + retry | Y/N | |
| 3 | empty | no data | empty state illustration | Y/N | |
| 4 | success | data loaded | content rendered | Y/N | |

## 4. Test Path Registry
| Type | File | Covers Screen/Flow | Assertions |
|------|------|--------------------|------------|

## 5. Coverage Gaps
| # | Screen/Feature | Missing | Severity | Reason |
|---|----------------|---------|----------|--------|

## 6. Cross-Domain Test Dependencies
| # | Flow | Depends on | If changed, re-test |
|---|------|------------|---------------------|
```

이 맵은 매 `/pge-qa` 실행 시 갱신된다. Phase 1이 맵을 읽고 테스트 범위를 결정, Phase 3이 맵 항목별 검증.

## CRITICAL: Agent Spawning Rules

1. **TeamCreate를 사용하여 팀을 구성**할 것. 단순 Agent subagent 스폰 금지.
2. **Explore 서브에이전트 사용 금지.** 모든 teammate는 `general-purpose` agent로 스폰.
3. **각 teammate는 서로 SendMessage로 발견사항 공유.** 사일로 금지.
4. **TaskCreate로 작업 목록 생성**하고 teammate에게 할당.
5. **Phase 1(Scanner) 에이전트는 읽기 전용** — 코드 수정은 Phase 2에서 team lead만.

## Input

$ARGUMENTS — QA 대상 설명

## Mode Detection

- **Full**: 기본값, 전체 앱/프로젝트 QA
- **Quick**: "빠르게", "간단히", 특정 화면/기능명 → 해당 영역만
- **Diff-aware**: "변경분", "PR", "branch" → git diff main...HEAD 기반
- **Regression**: "회귀", "baseline 비교" → 이전 baseline 대비

**필수 출력:** `QA Mode: {Full | Quick | Diff-aware | Regression}`

### Diff-aware Mode
```bash
git diff main...HEAD --name-only
```
변경 파일 → qa-coverage-map에서 해당 화면/기능 추출 → 해당 영역만 Scanner 대상.

---

## Issue Taxonomy (9 Categories)

| # | Category | Weight | 검증 방법 |
|---|----------|--------|----------|
| 1 | **Log/Crash** | 15% | flutter analyze, try-catch 범위, FlutterError 핸들링 |
| 2 | **Routing/Navigation** | 10% | GoRoute/Navigator Grep, 네비게이션 그래프, 딥링크 |
| 3 | **Visual/UI** | 10% | 토큰 사용률, 하드코딩, 위젯 트리 |
| 4 | **Functional** | 15% | 상태 처리(loading/error/empty), 폼 유효성, 비즈니스 로직 |
| 5 | **UX** | 10% | 터치 타겟 크기, 확인 다이얼로그, 피드백 UI |
| 6 | **Performance** | 10% | 불필요한 리빌드, N+1, 메모리 누수 |
| 7 | **Content** | 5% | 하드코딩 문자열, placeholder, i18n |
| 8 | **Accessibility** | 10% | Semantics, 색상 대비, 터치 타겟 |
| 9 | **Platform/Native** | 15% | 권한, 생명주기, 딥링크, 오프라인, 보안 저장소 |

### Severity Levels

| Severity | Definition |
|----------|------------|
| CRITICAL | 크래시, 데이터 손실, 보안 취약점 |
| HIGH | 주요 기능 작동 불가, 우회 불가 |
| MEDIUM | 기능 작동하지만 문제 있음, 우회 가능 |
| LOW | 사소한 UI/코드 품질 이슈 |
| COSMETIC | 스타일, 정렬 등 미세 이슈 |

### Health Score Grading

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100 | 프로덕션 배포 가능, 거의 이슈 없음 |
| B | 75-89 | 배포 가능, 사소한 이슈 존재 |
| C | 60-74 | 주요 이슈 수정 필요 |
| D | 40-59 | 심각한 이슈 다수 |
| F | 0-39 | 근본적 문제, 아키텍처 재검토 권고 |

---

## Role Catalog

오케스트레이터가 task에 맞는 역할을 **2~4명** 선택. **code-quality-scanner는 항상 포함**.

| Role | 전문 영역 | 커버 카테고리 | 언제 선택 |
|------|----------|-------------|----------|
| **code-quality-scanner** | 정적 분석, lint, 코드 패턴 | LC, FN, CT, PF | **항상 포함** (필수) |
| **test-coverage-analyst** | 테스트 누락, 경로 분석, qa-coverage-map 대조 | FN, PF | 테스트 파일 존재 시 |
| **a11y-platform-checker** | 접근성 + 플랫폼 네이티브 | A11Y, PN | 모바일 앱 시 |
| **ux-flow-checker** | 사용자 플로우, 상태 처리, 네비게이션 | RN, UX, VI, FN | UI 코드 포함 시 |
| **security-auditor** | 보안 취약점, 인증/인가, 보안 저장소 | LC, PN | 사용자 입력/인증 코드 시 |

카탈로그 외 역할도 task에 맞게 정의 가능. 역할 선택에 Rationale 필수.

---

## Phase 1: Scanner — QA Profile + Health Score Baseline

### STEP 1: Task Analysis + Role Selection

**필수 출력:**
```
QA Mode: {Full | Quick | Diff-aware | Regression}
Platform: {Flutter | React | Vue}
Selected roles: [{role1}, {role2}, ...]
Rationale: [왜 이 역할들이 필요한지]
Scan scope: {전체 | 특정 화면 | git diff 변경분}
```

### STEP 2: Create Scanner Team

**TeamCreate** → Agent(team_name="pge-qa-scan-{slug}", name="{role}", run_in_background=true)

각 에이전트 프롬프트에 포함:
- 팀명, 역할, 전문 영역, 담당 카테고리
- qa-coverage-map 읽기 지시 (있을 경우)
- 카테고리별 구체적 Grep/Read 패턴
- SendMessage 공유 규칙
- 읽기 전용 제약 + TaskUpdate 지시

### STEP 3: Wait + Synthesize

에이전트들이 SendMessage로 발견사항 상호 공유. 완료 후 종합.

### STEP 4: QA Profile Report

`.claude/pge-qa/qa-profile.md`에 저장:

```
═══ QA PROFILE REPORT ═══

## Context
Target: [분석 대상]
Platform: {Flutter | React | Vue}
Mode: {Full | Quick | Diff-aware | Regression}
Date: {ISO timestamp}

## Team Analysis
{각 역할별 핵심 발견사항}

## Health Score Baseline
| # | Category | Score (0-100) | Issues | Critical | Weight |
|---|----------|--------------|--------|----------|--------|
| 1 | Log/Crash | X | N | N | 15% |
| 2 | Routing/Navigation | X | N | N | 10% |
| 3 | Visual/UI | X | N | N | 10% |
| 4 | Functional | X | N | N | 15% |
| 5 | UX | X | N | N | 10% |
| 6 | Performance | X | N | N | 10% |
| 7 | Content | X | N | N | 5% |
| 8 | Accessibility | X | N | N | 10% |
| 9 | Platform/Native | X | N | N | 15% |

**Health Score = X/100 (Grade: X)**

## Coverage Map Analysis
| Screen | Total States | Tested | Coverage % |

## Issue Summary
| # | Category | Severity | File:Line | Issue | Auto-fixable? |

## Cross-Skill Issues
| # | Issue | Recommended Skill | Reason |
═══════════════════════════════════════
```

**Phase Gate:** Health Score + Issue Summary가 없으면 Phase 2 진행 불가.

### STEP 5: Shutdown Scanner Team

---

## Phase 2: Fixer — Priority 순서로 수정

### STEP 1: Triage + Priority Matrix

**Priority Score = Severity × 2 - Effort - Risk**

| Factor | 5 (Best) | 1 (Worst) |
|--------|----------|-----------|
| Severity | CRITICAL | COSMETIC |
| Effort | 한 줄 변경 | 대규모 리팩토링 |
| Risk | 부작용 없음 | 기능 회귀 가능 |

| Score | Tier | Action |
|-------|------|--------|
| >= 6 | Quick Win | 즉시 수행 |
| 3-5 | Standard | 계획 후 수행 |
| <= 2 | Backlog | 기록만 |

### STEP 2: Fix Loop (Quick Win 먼저, Score 내림차순)

각 fix마다:
1. **BEFORE**: 현재 코드 캡처 (file:line + 스니펫)
2. **FIX**: 최소 변경 구현 (team lead만)
3. **TEST**: 기존 테스트 통과 확인 + regression test 생성
4. **AFTER**: 변경 코드 캡처
5. **COMMIT**: atomic commit — `fix(qa-{category}): {설명}`
6. **RECORD**: Fix Result에 Before/After 증거 추가

**WTF-likelihood 자기 조절:**
```
Start at 0%
Each revert:                +15%
Each fix touching >3 files: +5%
After fix 15:               +1% per additional fix
Touching unrelated files:   +20%
```
- >= 50%: STOP, 사용자 확인 요청
- **하드캡: 50 fixes**

**3-strike rule:** 3회 fix 실패 → STOP + 에스컬레이션
**Revert on regression:** `git revert HEAD` 즉시 실행

### STEP 3: Cross-Skill Routing

Phase 1 cross-skill 이슈 처리:
- Backend consistency → `/pge` 전환 권고
- Performance bottleneck → `/pge-perf` 전환 권고
- Design/UX quality → `/pge-design` 전환 권고
- Pure QA → Phase 2에서 직접 fix

### STEP 4: Fix Result Manifest

`.claude/pge-qa/fix-result.md`에 저장:
```markdown
# Fix Result — {ISO timestamp}

## Applied Fixes
| # | Issue | Category | Score | Before | After | Test | Commit |

## Regression Tests Generated
| # | Test file | Covers issue | Assertions |

## Backlog (Score <= 2)
| # | Issue | Score | Reason |

## Cross-Skill Recommendations
| # | Issue | Recommended Skill | Severity |

## qa-coverage-map Updates
| Screen | State | Before (Test?) | After (Test?) |
```

**Phase Gate:** 각 fix에 Before/After 증거 필수.

---

## Phase 3: Verifier — 독립 검증

**반드시 fresh context Agent subagent으로 실행.**

### Verifier Agent 프롬프트:

```
You are the VERIFIER in a Scanner-Fixer-Verifier QA workflow.

YOUR ROLE: Independently verify that QA fixes are complete and correct.
You are checking SOMEONE ELSE's work. Be skeptical. Do NOT assume correctness.

Score Calibration:
9-10: 거의 모든 이슈 해결, regression 없음. 드물다.
7-8:  주요 이슈 해결, 프로덕션 배포 가능.
5-6:  일부 해결, 미해결 이슈 존재.
3-4:  명백한 누락.
1-2:  fix가 문제를 악화시킴.

## Inputs
1. QA Profile: .claude/pge-qa/qa-profile.md
2. Fix Result: .claude/pge-qa/fix-result.md
3. QA Coverage Map: docs/qa-coverage-map.md (있을 경우)

## Verification Process

### A. Health Score 재계산
9개 카테고리 모두 Phase 1과 동일한 Grep/Read 방법으로 재측정.

### B. Fix 개별 검증
각 fix: 코드 Read로 변경 확인, regression test 실행, 기존 테스트 통과.

### C. Coverage Map Walk
대상 화면의 State Combination Matrix 항목별:
- 테스트 존재 + meaningful assertion 확인
- User Flow happy path + edge case 확인

### D. Regression Check
- 기존 모든 테스트 통과?
- fix로 인해 새 이슈 발생?

### E. Devil's Advocate (QA)
1. fix가 증상만 치료하고 근본 원인을 놓치지 않았는가?
2. test가 실제 이슈를 검증하는가, 형식적인가?
3. security fix가 모든 attack vector를 커버하는가?
4. regression test가 실제로 실행 가능한가?
5. qa-coverage-map에 등록 안 된 화면이 있지 않은가?
6. "Test exists? = Y"가 실제 유효한 테스트인가?

### F. Anti-Pattern Check
| Anti-Pattern | How to Detect |
|---|---|
| "Fixed" without test | Fix 있지만 관련 테스트 없음 |
| Symptom-only fix | 근본 원인 미해결 |
| Over-engineering fix | 1줄 fix를 위한 대규모 리팩토링 |
| Test that always passes | assertion이 trivial |
| Security theater | 형식적 검증만 |
| Functionality removal | 기능 제거로 "간결해짐" 주장 |

### G. Score 9 Categories (0-100 each)
**HARD FAIL:** Log/Crash < 60, Platform/Native security < 60

### H. Health Score Before/After
| Category | Before | After | Δ |

### I. Verdict
- **PASS**: Health Score improved, grade B+ 이상, no hard-fail
- **CONDITIONAL PASS**: Health Score improved, grade C+, no hard-fail
- **FAIL**: Hard-fail, Health Score decreased, or grade D 이하

### J. Write Report → .claude/pge-qa/qa-eval.md
```

### Verifier 결과 처리
- **PASS** → Archive → QA Report 출력
- **CONDITIONAL PASS** → 미달 항목 수정 → Archive (재검증 불필요)
- **FAIL** → 수정 → Verifier 재실행 (fresh context)
- **FAIL loop 2+회** → 중단 + 에스컬레이션

---

## Final Report

```
QA REPORT
════════════════════════════════════════
Target:          [QA 대상]
Platform:        {Flutter | React | Vue}
Mode:            {Full | Quick | Diff-aware | Regression}
Date:            {ISO timestamp}
Verdict:         {PASS | CONDITIONAL PASS | FAIL}

── Scanner ──
Team:            [{roles}]
Issues found:    {N} ({critical} critical)
Baseline:        Health Score X/100 (Grade X)

── Fixer ──
Applied:         {N} fixes ({quick wins} quick wins)
Backlogged:      {N}
Commits:         {N} atomic commits
Cross-skill:     {N} routed

── Verifier ──
| Category          | Before | After  | Δ      |
|-------------------|--------|--------|--------|
| Log/Crash         | X      | X      | +X     |
| Routing/Nav       | X      | X      | +X     |
| Visual/UI         | X      | X      | +X     |
| Functional        | X      | X      | +X     |
| UX                | X      | X      | +X     |
| Performance       | X      | X      | +X     |
| Content           | X      | X      | +X     |
| Accessibility     | X      | X      | +X     |
| Platform/Native   | X      | X      | +X     |

Health Score:    Before X/100 (X) → After X/100 (X)
Evaluator:       independent verifier (fresh context)

Backlog:
  - [Score <= 2 items]

Cross-Skill:
  - [other PGE skill recommendations]
════════════════════════════════════════
```

### Archive
`.claude/pge-qa/history/{YYYYMMDD}T{HHMM}_{target-slug}.md` (under 100 lines)

---

## Escalation Rules

- **Phase 1 실패**: 플랫폼 Unknown → 사용자에게 명시 요청
- **Phase 2 실패**: 3-strike, 50 fix 하드캡
- **Phase 3 FAIL loop 2+회**: 중단 + 에스컬레이션
- **Health Score F (< 40)**: 아키텍처 재검토 권고
- **Cross-skill > 50%**: 해당 PGE skill 먼저 실행 권고

---

## Important Rules

- 각 Phase **필수 출력** 없으면 다음 Phase 진행 불가
- `/pge-qa` 작업은 **프로토콜 스킵 불가**
- Phase 1 에이전트는 **코드 수정 금지**
- Phase 2 수정은 **team lead만** — atomic commit per fix
- Phase 3 Verifier는 **fresh context Agent subagent**
- **실제 Grep/Read 측정** 필수 — "I assume it's fine" 불가
- SendMessage 상호 공유 필수, 팀 shutdown 필수
- Before/After 코드 증거 필수
- 50 fix 하드캡, 3-strike escalation
