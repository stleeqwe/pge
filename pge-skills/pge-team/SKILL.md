---
name: pge-team
description: |
  PGE Full Protocol with Team Investigation. Spawns a team of specialist agents
  (code-tracer, history-checker, state-verifier) using TeamCreate that investigate
  in parallel, share findings via SendMessage, then synthesize root cause.
  Use for complex bugs, cross-domain issues, or unclear failures.
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

사용자가 `/pge-team`을 붙이면 팀 에이전트를 스폰하여 병렬 조사 후 PGE 프로토콜을 실행한다.
복잡한 버그, 크로스 도메인 이슈, 원인 불명 장애에 사용.

## CRITICAL: Agent Spawning Rules

**반드시 아래 규칙을 따를 것:**

1. **TeamCreate를 사용하여 팀을 구성**할 것. 단순 Agent subagent 스폰이 아닌 TeamCreate → Agent(team_name=..., name=...) 패턴을 사용.
2. **Explore 서브에이전트는 사용하지 말 것.** 모든 teammate는 `general-purpose` agent로 스폰.
3. **각 teammate는 서로 SendMessage로 발견한 내용을 공유**하면서 진행할 것. 사일로 작업 금지.
4. **TaskCreate로 작업 목록을 생성**하고 teammate에게 할당할 것.
5. **모든 teammate는 읽기 전용** — 코드 수정은 team lead (메인 에이전트)만 수행.

## Input

$ARGUMENTS — 작업 설명

## Task Type Detection

`/pge`와 동일한 방식으로 유형 판별:
- **Investigation** — 증상/버그/에러 키워드
- **Direct task** — 추가/변경/삭제 키워드
- **Code review** — 리뷰 키워드

판별 결과를 출력: `PGE Team Mode: {Investigation | Direct | Review}`

---

## Investigation Mode (Team)

### STEP 1: Create Investigation Team

**TeamCreate**로 팀을 생성하고, **Agent** tool로 3명의 전문가를 스폰한다. 반드시 `team_name` 파라미터를 지정할 것.

```
Team: pge-investigate
Agents:
  1. code-tracer    — 코드 경로 추적 + 의존성 분석
  2. history-checker — git/변경 이력 + PGE history 분석
  3. state-verifier  — 라이브 상태 검증 (DB 쿼리, 서버 상태)
```

#### Agent 1: code-tracer

Agent tool 호출 시 반드시 `team_name="pge-investigate"`, `name="code-tracer"`, `run_in_background=true` 지정.

스폰 지시:
```
당신은 팀 "pge-investigate"의 code-tracer입니다. 버그의 코드 경로를 추적하는 전문가입니다.

## 임무
증상: {사용자가 제공한 증상/로그}

다음을 수행하세요:
1. 증상에서 언급된 파일/함수를 Read로 읽기
2. 해당 함수의 호출 체인을 Grep으로 추적 (caller → callee)
3. docs/backend-dependency-map.md를 읽고, 영향 받는 테이블의 전체 의존성 체인 파악
4. 의심되는 코드 경로와 잠재적 결함 지점 식별

## 필수: 분석 완료 후 반드시 SendMessage로 공유
history-checker와 state-verifier에게 각각 SendMessage를 보내세요:
- 추적한 코드 경로 (함수 호출 순서)
- 의심 지점 (file:line + 이유)
- 관련 의존성 목록 (dependency map 기반)

다른 teammate에게서 메시지가 오면 내용을 반영하여 분석을 보강하세요.
코드를 수정하지 마세요. 분석만 하세요.
TaskUpdate로 할당된 Task를 in_progress → completed 처리하세요.
```

#### Agent 2: history-checker

Agent tool 호출 시 반드시 `team_name="pge-investigate"`, `name="history-checker"`, `run_in_background=true` 지정.

스폰 지시:
```
당신은 팀 "pge-investigate"의 history-checker입니다. 변경 이력에서 회귀 원인을 찾는 전문가입니다.

## 임무
증상: {사용자가 제공한 증상/로그}

다음을 수행하세요:
1. git log --oneline -30 — 최근 커밋 확인
2. 증상과 관련된 파일의 최근 변경: git log --oneline -20 -- <affected-files>
3. 의심 커밋의 diff 확인: git show <commit>
4. .claude/pge/history/ 디렉토리가 있으면 최근 PGE 기록 확인 — 이전 작업이 원인일 수 있음
5. 회귀 시점 특정 (언제부터 깨졌는가?)

## 필수: 분석 완료 후 반드시 SendMessage로 공유
code-tracer와 state-verifier에게 각각 SendMessage를 보내세요:
- 의심 커밋 목록 (hash + 요약 + 이유)
- 회귀 시점 추정 ("commit X 이후 깨진 것으로 추정")
- PGE history에서 발견한 관련 기록 (있으면)

다른 teammate에게서 메시지가 오면 내용을 반영하여 분석을 보강하세요.
코드를 수정하지 마세요. 분석만 하세요.
TaskUpdate로 할당된 Task를 in_progress → completed 처리하세요.
```

#### Agent 3: state-verifier

Agent tool 호출 시 반드시 `team_name="pge-investigate"`, `name="state-verifier"`, `run_in_background=true` 지정.

스폰 지시:
```
당신은 팀 "pge-investigate"의 state-verifier입니다. 라이브 시스템 상태를 검증하는 전문가입니다.

## 임무
증상: {사용자가 제공한 증상/로그}

다음을 수행하세요:
1. 증상과 관련된 DB 상태를 SQL로 검증 (MCP execute_sql 또는 CLI)
2. 관련 서버 함수 실행하여 정상 동작 여부 확인
3. 접근 정책이 올바른지 확인
4. API 엔드포인트가 관련되면 curl로 응답 확인
5. 앱 상태 관련이면 서비스/상태관리 코드에서 쿼리 패턴 확인

## 필수: 분석 완료 후 반드시 SendMessage로 공유
code-tracer와 history-checker에게 각각 SendMessage를 보내세요:
- 실행한 쿼리 + 결과
- 정상/비정상 판별
- 발견한 불일치 (스키마 vs 코드, 정책 vs 기대)

다른 teammate에게서 메시지가 오면 내용을 반영하여 분석을 보강하세요.
코드를 수정하지 마세요. 검증만 하세요.
TaskUpdate로 할당된 Task를 in_progress → completed 처리하세요.
```

### STEP 2: Wait for Team Results

3명의 에이전트가 SendMessage로 서로 발견사항을 공유하며 분석을 진행한다.
모든 에이전트의 분석이 완료되면 결과를 종합한다.

### STEP 3: Synthesize Root Cause

3명의 분석 결과를 종합하여 다음을 출력:

```
═══ TEAM INVESTIGATION RESULT ═══

code-tracer 발견:
  [코드 경로 요약 + 의심 지점]

history-checker 발견:
  [회귀 시점 + 의심 커밋]

state-verifier 발견:
  [라이브 상태 검증 결과]

═══ ROOT CAUSE SYNTHESIS ═══

Root cause hypothesis: [3명의 분석을 종합한 최종 가설]
Confidence: {HIGH | MEDIUM | LOW}
Pattern match: {매칭된 패턴}
Scope: [영향 받는 모듈 경계]
Backend change needed: {Y/N}
```

**Confidence가 LOW인 경우**: 에이전트를 추가 투입하거나 사용자에게 에스컬레이션.

### STEP 4: Shutdown Team

분석 완료 후 모든 에이전트에게 shutdown_request를 보내고 팀 정리.

### STEP 5: Execute Fix

종합된 Root cause를 기반으로 `/pge`의 해당 모드 실행:
- **Backend change needed: Y** → Planner → Generator → Evaluator
- **Backend change needed: N** → Fix → Test → Analyze

### STEP 6: Debug Report

```
DEBUG REPORT (Team Investigation)
════════════════════════════════════════
Symptom:         [사용자가 보고한 증상]
Root cause:      [팀이 종합한 실제 원인]
Pattern:         [매칭된 패턴]
Contributors:    code-tracer, history-checker, state-verifier
Fix:             [변경 내용, file:line 참조]
Evidence:        [테스트 결과, 재현 확인]
Regression test: [새로 추가된 테스트 file:line]
Status:          DONE | DONE_WITH_CONCERNS | BLOCKED
════════════════════════════════════════
```

---

## Direct Task Mode (Team)

대규모 직접 작업에서 팀을 활용한다.

### STEP 1: Sprint Contract 생성
`/pge`의 Planner 절차를 따라 Sprint Contract 작성.

### STEP 2: Team Blast Radius Verification
**TeamCreate**로 2명의 에이전트를 스폰하여 contract를 교차 검증:

```
Agent 1: dep-checker  — dependency map 기반으로 contract 누락 확인
Agent 2: risk-assessor — High-Risk Change Matrix 대조, 숨은 영향 식별
```

두 에이전트가 SendMessage로 발견사항을 공유하고, contract 보완 필요 시 수정.

### STEP 3: Generator
`/pge`의 Generator 절차를 따라 실행. Server Boundary Checkpoint 필수.

### STEP 4: Evaluator
독립 Evaluator Agent로 검증.

---

## Review Mode (Team)

### STEP 1: Team Code Review
**TeamCreate**로 2명의 에이전트를 스폰하여 병렬 리뷰:

```
Agent 1: security-reviewer — Pass 1 CRITICAL 항목 집중 (SQL injection, TOCTOU, LLM trust)
Agent 2: quality-reviewer  — Pass 2 INFORMATIONAL 항목 집중 (dead code, test gaps, perf)
```

두 에이전트가 SendMessage로 발견사항을 공유하고, 종합 리뷰 결과를 출력.

### STEP 2: Evaluator (Phase 3 only)
Domain-specific checklists로 검증.

### STEP 3: 이슈 발견 시
자동으로 Direct Task Mode 전환.

---

## Important Rules

- 모든 에이전트는 **코드를 수정하지 않음** — 분석/검증만 수행
- 에이전트 간 **SendMessage로 발견사항을 반드시 공유** — 사일로 금지
- 분석 완료 후 **반드시 팀 shutdown** — 리소스 정리
- 수정은 항상 **team lead (메인 에이전트)가 수행** — 에이전트는 읽기 전용
- Escalation Rules 동일 적용: 3-strike, PGE FAIL loop 2+회 시 중단
