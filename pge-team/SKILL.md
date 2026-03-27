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

사용자가 `/pge-team`을 붙이면 오케스트레이터가 task를 분석하여 적합한 역할을 선택하고, 팀을 스폰하여 병렬 조사 후 PGE 프로토콜을 실행한다.

## CRITICAL: Agent Spawning Rules

**반드시 아래 규칙을 따를 것:**

1. **TeamCreate를 사용하여 팀을 구성**할 것. 단순 Agent subagent 스폰이 아닌 TeamCreate → Agent(team_name=..., name=...) 패턴을 사용.
2. **Explore 서브에이전트는 사용하지 말 것.** 모든 teammate는 `general-purpose` agent로 스폰.
3. **각 teammate는 서로 SendMessage로 발견한 내용을 공유**하면서 진행할 것. 사일로 작업 금지.
4. **TaskCreate로 작업 목록을 생성**하고 teammate에게 할당할 것.
5. **모든 teammate는 읽기 전용** — 코드 수정은 team lead (메인 에이전트)만 수행.

## Input

$ARGUMENTS — 작업 설명

---

## STEP 1: Task Analysis + Role Selection

### 1-1. Task Type Detection

작업 설명을 분석하여 유형 판별:
- **Investigation** — 증상/버그/에러 키워드
- **Direct task** — 추가/변경/삭제 키워드
- **Code review** — 리뷰 키워드
- **Architecture/Design** — 설계/구조/리팩토링 키워드

### 1-2. Scope Analysis

작업이 어떤 영역에 걸치는지 파악:
- 영향 받는 레이어 (DB, Server, Client, Network)
- 영향 받는 도메인 수 (단일 vs 크로스 도메인)
- 관련 파일/모듈 범위

### 1-3. Role Selection

아래 **Role Catalog**에서 task에 적합한 역할을 **2~4명** 선택한다.
불필요한 역할은 스폰하지 않는다.

**필수 출력:**
```
PGE Team Mode: {Investigation | Direct | Review | Architecture}
Selected roles: [{role1}, {role2}, ...]
Rationale: [왜 이 역할들이 필요한지 한 줄]
```

---

## Role Catalog

오케스트레이터는 아래 카탈로그에서 task에 맞는 역할을 선택한다. 카탈로그에 없는 역할을 task에 맞게 새로 정의해도 된다.

### Investigation Roles

| Role | 전문 영역 | 언제 선택 |
|------|----------|----------|
| **code-tracer** | 코드 경로 추적, 호출 체인 분석, dependency map 확인 | 버그의 코드 경로가 불명확할 때 |
| **history-checker** | git log, commit diff, PGE history 분석, 회귀 시점 특정 | "갑자기 안 됨", 회귀 의심 시 |
| **state-verifier** | 라이브 DB/서버 상태 SQL 검증, RLS 정책 확인 | DB 상태 불일치, 데이터 문제 의심 시 |
| **log-analyst** | 에러 로그, 스택 트레이스 분석, 패턴 매칭 | 에러 로그가 제공됐을 때 |

### Direct Task Roles

| Role | 전문 영역 | 언제 선택 |
|------|----------|----------|
| **dep-checker** | dependency map 기반 blast radius 분석, contract 누락 확인 | 백엔드 변경 시 |
| **risk-assessor** | High-Risk Change Matrix 대조, 숨은 영향 식별 | CRITICAL/HIGH 리스크 테이블 변경 시 |
| **schema-analyst** | DB 스키마, 마이그레이션, 제약조건 분석 | 스키마 변경 포함 시 |
| **api-analyst** | Edge Function/API 엔드포인트 영향 분석 | 서버 함수 변경 시 |

### Review Roles

| Role | 전문 영역 | 언제 선택 |
|------|----------|----------|
| **security-reviewer** | SQL injection, TOCTOU, RLS, LLM trust boundary | 보안 민감 변경 시 |
| **quality-reviewer** | dead code, test gaps, N+1, 코드 품질 | 일반 코드 리뷰 시 |
| **ux-reviewer** | UI 일관성, 접근성, 사용자 경험 | 프론트엔드 변경 포함 시 |

### Architecture Roles

| Role | 전문 영역 | 언제 선택 |
|------|----------|----------|
| **arch-analyst** | 현재 아키텍처 분석, 패턴 파악, 제약 조건 식별 | 구조 변경/리팩토링 시 |
| **impact-mapper** | 변경의 전체 영향 범위 매핑, 의존성 추적 | 대규모 변경 시 |
| **test-strategist** | 테스트 전략 수립, 커버리지 분석, 테스트 계획 | 테스트 부족 영역 작업 시 |

### Selection Guidelines

- **최소 2명, 최대 4명** — 1명이면 팀이 아니고, 5명 이상이면 조율 오버헤드
- **역할 중복 금지** — 같은 영역을 두 명이 하지 않음
- **교차 검증 가능하도록** — 서로 다른 관점에서 같은 문제를 볼 수 있는 조합
- **카탈로그 외 역할** — task에 딱 맞는 역할이 없으면 새로 정의 가능. 이 경우 role name, 전문 영역, 수행 항목을 명시

---

## STEP 2: Create Team

**TeamCreate**로 팀을 생성하고, 선택된 역할별로 **Agent** tool로 스폰.

모든 Agent 스폰 시 반드시 지정:
- `team_name="pge-team-{task-slug}"`
- `name="{role-name}"`
- `run_in_background=true`

### Agent 프롬프트 템플릿

각 에이전트에게 아래 구조로 프롬프트를 작성:

```
당신은 팀 "{team_name}"의 {role-name}입니다. {전문 영역 한 줄 설명}.

## 임무
{task 설명 + 사용자 제공 정보 (로그, 증상 등)}

## 수행 항목
{해당 역할에 맞는 구체적 수행 항목 3-7개}

## 필수: SendMessage 규칙
분석 완료 후 다른 모든 teammate에게 각각 SendMessage를 보내세요:
- {해당 역할의 핵심 발견사항 형식}

다른 teammate에게서 메시지가 오면 내용을 반영하여 분석을 보강하세요.
코드를 수정하지 마세요. 분석만 하세요.
TaskUpdate로 할당된 Task를 in_progress → completed 처리하세요.
```

---

## STEP 3: Wait for Team Results

모든 에이전트가 SendMessage로 서로 발견사항을 공유하며 분석을 진행한다.
모든 에이전트의 분석이 완료되면 결과를 종합한다.

---

## STEP 4: Synthesize Results

팀 분석 결과를 종합하여 출력:

```
═══ TEAM INVESTIGATION RESULT ═══

{role-1} 발견:
  [핵심 발견사항 요약]

{role-2} 발견:
  [핵심 발견사항 요약]

{role-N} 발견:
  [핵심 발견사항 요약]

═══ SYNTHESIS ═══

Conclusion: [팀 분석을 종합한 결론]
Confidence: {HIGH | MEDIUM | LOW}
Scope: [영향 받는 모듈 경계]
Backend change needed: {Y/N}  (Investigation/Direct 시)
```

**Confidence가 LOW인 경우**: 추가 역할 투입 또는 사용자 에스컬레이션.

---

## STEP 5: Shutdown Team

분석 완료 후 모든 에이전트에게 shutdown_request를 보내고 팀 정리.

---

## STEP 6: Execute

종합된 결과를 기반으로 실행:

### Investigation
- **Backend change needed: Y** → `/pge`의 Planner → Generator → Evaluator
- **Backend change needed: N** → Fix → Test → Analyze → Debug Report

### Direct Task
- Planner → Generator → Evaluator (팀 분석으로 보강된 Sprint Contract 사용)

### Review
- 팀 리뷰 결과 기반으로 이슈 수정 → Evaluator
- 이슈 없으면 완료

### Architecture
- 설계 문서 출력 → 사용자 확인 → 구현

---

## STEP 7: Final Report

```
PGE TEAM REPORT
════════════════════════════════════════
Task:            [작업 설명]
Mode:            {Investigation | Direct | Review | Architecture}
Team:            [{role1}, {role2}, ...]
Date:            {ISO timestamp}

── Team Analysis ──
{각 역할의 핵심 발견 1줄씩}

── Action Taken ──
{수행한 작업 요약}

── Result ──
{결과 요약}

Status:          DONE | DONE_WITH_CONCERNS | BLOCKED
════════════════════════════════════════
```

---

## Important Rules

- 모든 에이전트는 **코드를 수정하지 않음** — 분석/검증만 수행
- 에이전트 간 **SendMessage로 발견사항을 반드시 공유** — 사일로 금지
- 분석 완료 후 **반드시 팀 shutdown** — 리소스 정리
- 수정은 항상 **team lead (메인 에이전트)만 수행**
- 역할 선택에 **Rationale 필수** — 왜 이 역할이 필요한지 명시
- Escalation: 3-strike, PGE FAIL loop 2+회 시 중단
