---
name: pge-perf
description: |
  PGE Performance Optimization Protocol (Profiler-Optimizer-Benchmarker).
  Spawns a team of specialist agents (query-profiler, code-analyzer, load-tester)
  to profile bottlenecks across 4 layers (DB, Server, Client, Network),
  apply optimizations by priority, and benchmark before/after with independent
  evaluator. Use when asked with /pge-perf flag appended.
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

# /pge-perf — PGE Performance Optimization Protocol

사용자가 작업 요청에 `/pge-perf`를 붙이면 전체 성능 최적화 프로토콜을 강제 실행한다.

## Project Initialization (첫 실행 시)

프로젝트에 PGE-perf 파일이 없으면 자동 생성:

```bash
mkdir -p .claude/pge-perf/baselines
mkdir -p .claude/pge-perf/history

if [ -f .gitignore ] && ! grep -q ".claude/pge-perf/" .gitignore 2>/dev/null; then
  echo -e "\n# PGE-perf workflow state files\n.claude/pge-perf/" >> .gitignore
fi
```

## CRITICAL: Agent Spawning Rules

**반드시 아래 규칙을 따를 것:**

1. **TeamCreate를 사용하여 팀을 구성**할 것. 단순 Agent subagent 스폰이 아닌 TeamCreate → Agent(team_name=..., name=...) 패턴을 사용.
2. **Explore 서브에이전트는 사용하지 말 것.** 모든 teammate는 `general-purpose` agent로 스폰.
3. **각 teammate는 서로 SendMessage로 발견한 내용을 공유**하면서 진행할 것. 사일로 작업 금지.
4. **TaskCreate로 작업 목록을 생성**하고 teammate에게 할당할 것.
5. **Phase 1(Profiler)의 에이전트는 읽기 전용** — 최적화 구현은 Phase 2에서 team lead (메인 에이전트)만 수행.

## Input

$ARGUMENTS — 성능 최적화 대상 설명 (특정 화면, API, 쿼리 등)

---

## Phase 1: Profiler — Baseline 측정 + Bottleneck 식별

### STEP 1: Create Profiling Team

**TeamCreate**로 팀을 생성하고, **Agent** tool로 3명의 전문가를 스폰한다. 반드시 `team_name` 파라미터를 지정할 것.

```
Team: pge-perf-profile
Agents:
  1. query-profiler  — DB 레이어 프로파일링 (Layer 1)
  2. code-analyzer   — Server + Client 코드 분석 (Layer 2 + 3)
  3. load-tester     — Network 패턴 분석 (Layer 4)
```

#### Agent 1: query-profiler

Agent tool 호출 시 반드시 `team_name="pge-perf-profile"`, `name="query-profiler"`, `run_in_background=true` 지정.

스폰 지시:
```
당신은 팀 "pge-perf-profile"의 query-profiler입니다. DB 레이어의 성능 병목을 프로파일링하는 전문가입니다.

## 임무
대상: {사용자가 제공한 최적화 대상}

다음 7개 체크 항목을 순서대로 수행하세요:

### D1: Slow Query 식별
- 대상 기능과 관련된 주요 쿼리를 코드에서 Read/Grep으로 찾기
- 각 쿼리를 `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)`로 감싸 실행
- cost, actual time, rows 비교. Seq Scan on large table이면 경고

### D2: Top-N Slow Queries
SELECT query, calls, mean_exec_time, total_exec_time, rows
FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 20;

### D3: 누락 인덱스
SELECT schemaname, relname, seq_scan, seq_tup_read, idx_scan, n_live_tup
FROM pg_stat_user_tables
WHERE seq_scan > 100 AND n_live_tup > 1000 ORDER BY seq_tup_read DESC;

### D4: N+1 쿼리 패턴
- 코드에서 Grep으로 루프 내 `.from(`, `.select(`, `.rpc(` 패턴 탐지
- 발견 시 code-analyzer에게 SendMessage로 해당 위치 공유

### D5: 불필요한 JOIN
- EXPLAIN ANALYZE 결과에서 Nested Loop/Hash Join rows가 실제 사용 대비 과도하면 경고

### D6: Index Usage 분석
SELECT t.relname, indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes ui JOIN pg_stat_user_tables t ON ui.relid = t.relid
ORDER BY idx_scan ASC;

### D7: 트랜잭션 잠금 경합
SELECT pid, wait_event_type, wait_event, state, query
FROM pg_stat_activity WHERE wait_event_type = 'Lock';

## 필수: 분석 완료 후 반드시 SendMessage로 공유
code-analyzer와 load-tester에게 각각 SendMessage를 보내세요:
- DB Profiling Results 전체
- 발견된 slow query 목록과 원인
- 누락 인덱스 + 추천 인덱스
- N+1 패턴 발견 위치

출력 형식:
## DB Profiling Results
### Slow Queries (Top 5)
| Rank | Query (truncated) | Mean Time | Calls | Issue |
### Missing Indexes
| Table | seq_scan | idx_scan | Recommendation |
### Lock Contention
(없으면 "No lock contention detected")

다른 teammate에게서 메시지가 오면 내용을 반영하여 분석을 보강하세요.
코드를 수정하지 마세요. 분석만 하세요.
TaskUpdate로 할당된 Task를 in_progress → completed 처리하세요.
```

#### Agent 2: code-analyzer

Agent tool 호출 시 반드시 `team_name="pge-perf-profile"`, `name="code-analyzer"`, `run_in_background=true` 지정.

스폰 지시:
```
당신은 팀 "pge-perf-profile"의 code-analyzer입니다. Server 및 Client 코드의 성능 병목을 분석하는 전문가입니다.

## 임무
대상: {사용자가 제공한 최적화 대상}

### Layer 2: Server 분석

#### S1: 콜드스타트 시간
- Edge Function / API route의 top-level import 분석
- 무거운 라이브러리 여부 체크

#### S2: 응답 페이로드 크기
- 응답 데이터 구조 분석, 불필요한 필드 포함 여부

#### S3: 외부 API 호출 대기
- Grep으로 fetch(, axios, got( 탐지
- await 체인 직렬 여부 확인

#### S4: 직렬→병렬 전환 가능
- 연속된 await → Promise.all 전환 가능 여부

#### S5: 불필요한 재시도
- 지수 백오프 없는 재시도 루프 경고

#### S6: 미들웨어 오버헤드
- RLS 정책 수, auth 미들웨어 체인 길이 분석

### Layer 3: Client 분석

#### C1: 불필요한 리빌드/리렌더
- Flutter: setState 빈도, Consumer/Watch 범위, build() 내 비용 큰 연산
- React: useEffect deps 누락, 불필요한 state 변경

#### C2: 과도한 Provider Invalidation
- ref.invalidate, ref.refresh 연쇄 갱신 패턴

#### C3: 메모리 누수
- StreamSubscription/Timer/AnimationController의 dispose() 해제 여부

#### C4: 이미지/에셋 최적화
- Glob으로 이미지 파일 탐색 → 크기 확인

#### C5: 초기 로딩 동시 호출 수
- 앱 시작점에서 초기화 시 API 호출 수 카운트. 5개 이상이면 경고

## Grep 패턴 참고
N+1:          for.*\n.*\.from\(  |  \.forEach.*\n.*\.from\(
SELECT *:     \.select\(\s*\)  |  \.select\('\*'\)
직렬 await:   const \w+ = await.*\n\s*const \w+ = await
리빌드:       setState\(\s*\(\)\s*\{
메모리누수:   StreamSubscription|\.listen\(  → dispose()+cancel() 확인
Invalidation: ref\.invalidate\(|ref\.refresh\(

## 필수: 분석 완료 후 반드시 SendMessage로 공유
query-profiler와 load-tester에게 각각 SendMessage를 보내세요:
- Server Issues 목록 (file:line + impact)
- Client Issues 목록 (file:line + impact)
- N+1 패턴 교차 확인 결과

출력 형식:
## Code Analysis Results
### Server Issues
| # | File:Line | Issue | Category | Impact | Suggested Fix |
### Client Issues
| # | File:Line | Issue | Category | Impact | Suggested Fix |

다른 teammate에게서 메시지가 오면 내용을 반영하여 분석을 보강하세요.
코드를 수정하지 마세요. 분석만 하세요.
TaskUpdate로 할당된 Task를 in_progress → completed 처리하세요.
```

#### Agent 3: load-tester

Agent tool 호출 시 반드시 `team_name="pge-perf-profile"`, `name="load-tester"`, `run_in_background=true` 지정.

스폰 지시:
```
당신은 팀 "pge-perf-profile"의 load-tester입니다. Network 레이어의 성능 패턴을 분석하는 전문가입니다.

## 임무
대상: {사용자가 제공한 최적화 대상}

### N1: 중복 API 호출
- Grep으로 동일 .from('table') 호출이 여러 파일에 분산되어 있으면 경고
- 같은 화면에서 여러 컴포넌트가 각각 fetch하는지 확인

### N2: 배치 가능한 단건 호출
- 루프 내 개별 .insert(), .update(), .upsert() → 배치 전환 가능 여부

### N3: 캐싱 누락
- fetch 호출 시 cache, revalidate 설정 여부
- 로컬 캐시 레이어 존재 여부

### N4: Realtime Subscription 오버헤드
- .channel(, .on('postgres_changes' 탐지
- 필터 없는 전체 테이블 구독, 채널 미해제

### N5: 페이지네이션 누락
- .select() 호출에 .range() 또는 .limit() 없는 패턴 탐지

### N6: 압축/직렬화
- 응답 헤더에 gzip 설정 여부
- JSON 직렬화 시 불필요한 필드 포함 여부

## 필수: 분석 완료 후 반드시 SendMessage로 공유
query-profiler와 code-analyzer에게 각각 SendMessage를 보내세요:
- Network Issues 전체 목록
- 중복 호출 맵 (endpoint → call sites)
- 배치 가능 목록
- 페이지네이션 누락 위치

출력 형식:
## Network Analysis Results
### Duplicate Calls
| Endpoint/Table | Call Sites | Est. Redundancy |
### Missing Pagination
| Query | Est. Rows | Location |
### Batching Opportunities
| Pattern | Locations | Potential Reduction |
### Caching Gaps
| Endpoint | Current | Recommendation |
### Subscription Issues
| Channel | Filter | Issue |

다른 teammate에게서 메시지가 오면 내용을 반영하여 분석을 보강하세요.
코드를 수정하지 마세요. 분석만 하세요.
TaskUpdate로 할당된 Task를 in_progress → completed 처리하세요.
```

### STEP 2: Wait for Team Results + Synthesize

3명의 에이전트가 SendMessage로 서로 발견사항을 공유하며 분석을 진행한다.
모든 에이전트의 분석이 완료되면 결과를 종합한다.

### STEP 3: Performance Profile Report

3명의 분석 결과를 종합하여 `.claude/pge-perf/perf-target.md`에 저장:

```
═══ PERFORMANCE PROFILE REPORT ═══

## Profiling Summary
Target: [최적화 대상]
Date: {ISO timestamp}

## query-profiler 발견 (Layer 1: Database):
  [slow query 목록 + 누락 인덱스 + N+1]

## code-analyzer 발견 (Layer 2: Server + Layer 3: Client):
  [서버 병목 + 클라이언트 병목]

## load-tester 발견 (Layer 4: Network):
  [중복 호출 + 캐싱 누락 + 페이지네이션]

## Baseline Metrics
| Category | Metric | Current Value | Measured By |

## Bottleneck Summary
| # | Layer | Issue | File:Line | Severity | Baseline |

Bottleneck identified: [가장 심각한 병목]
Layer: {DB | Server | Client | Network}
Baseline metric: [현재 수치]
═══════════════════════════════════
```

### Performance Anti-Pattern Matching

| Pattern | Signature | Match? |
|---------|-----------|--------|
| N+1 query | 루프 내 DB 호출, 다수 쿼리 | Y/N |
| Missing index | Full table scan, slow WHERE | Y/N |
| SELECT * | 과도한 페이로드, 불필요 컬럼 | Y/N |
| Sequential await | 직렬 독립 호출, 증가된 레이턴시 | Y/N |
| Excessive rebuild | 빈번한 setState/rerender | Y/N |
| Missing pagination | 전체 데이터 로드, OOM 위험 | Y/N |
| Bundle bloat | 큰 import, 콜드스타트 지연 | Y/N |

**필수 출력** — `Bottleneck identified`, `Layer`, `Baseline metric`, `Anti-pattern match`가 없으면 Phase 2 진행 불가.

### STEP 4: Shutdown Profiling Team

분석 완료 후 모든 에이전트에게 shutdown_request를 보내고 팀 정리.

---

## Phase 2: Optimizer — Impact 순서로 최적화 구현

### STEP 1: Build Optimization Priority Matrix

**점수 기준 (각 1-5):**

| Factor | 5 (Best) | 1 (Worst) |
|--------|----------|-----------|
| Impact | 응답 시간 50%+ 감소 | 5% 미만 |
| Effort | 한 줄 변경 | 대규모 리팩토링 |
| Risk | 부작용 없음 | 데이터 손실 가능 |

**우선순위 공식:** `Priority Score = Impact × 2 - Effort - Risk`

- Score >= 6: **즉시 수행** (Quick Win)
- Score 3-5: **계획 후 수행**
- Score <= 2: **백로그 등록**

출력:
```markdown
## Optimization Priority Matrix
| Rank | Issue | Layer | Impact | Effort | Risk | Score | Action |
```

### STEP 2: Execute Optimizations (Score >= 6 먼저, 내림차순)

각 최적화마다:
1. **Before**: 해당 메트릭 현재 값 기록
2. **Implement**: 변경 구현 (team lead가 직접 수행)
3. **After**: 동일 메트릭 재측정
4. **Record**: 결과를 `.claude/pge-perf/optimization-result.md`에 추가

### STEP 3: Optimization Result

`.claude/pge-perf/optimization-result.md`에 저장:

```markdown
# Optimization Result — {ISO timestamp}

## Applied Optimizations
| # | Issue | Change | File(s) | Before | After | Δ% |

## Backlog (Score <= 2)
| # | Issue | Score | Reason for Deferral |
```

**필수 출력** — 각 최적화에 `Before`, `After`, `Δ%`가 없으면 Phase 3 진행 불가.

### Optimizer Rules
- Quick Win (Score >= 6)을 **반드시 먼저** 처리
- 각 최적화 후 **기존 테스트가 통과**하는지 확인
- Risk 4-5 항목은 구현 전 사용자 확인 요청
- 8개 이상 파일 변경 시 분할 가능 여부 검토

---

## Phase 3: Benchmarker — Before/After 비교 증명

**반드시 fresh context Agent subagent으로 실행** (독립 검증).

### Benchmarker Agent 프롬프트:

```
You are the BENCHMARKER in a Profiler-Optimizer-Benchmarker workflow.

YOUR ROLE: Independently verify that performance optimizations actually improved metrics.
You are checking SOMEONE ELSE's work. Be skeptical. Do NOT assume improvement.

## Inputs (read these files first)
1. Performance profile: .claude/pge-perf/perf-target.md
2. Optimization result: .claude/pge-perf/optimization-result.md

## Verification Process

### A. Re-measure ALL Baseline Metrics
For each metric in perf-target.md, re-measure using the SAME method:
- DB queries: Re-run EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) on same queries
- Server: Re-measure response time/size if applicable
- Client: Re-analyze code for rebuild/rerender count changes
- Network: Re-count API calls, check pagination, caching

### B. Before/After Comparison
| # | Optimization | Metric | Before | After | Δ | Δ% |
Δ must be measured, not estimated.

### C. Measurement Quality Check
- Same conditions? Same data? Same parameters?
- DB queries run 3x → use median
- Results reproducible?

### D. Regression Check
- All existing tests still pass?
- No new errors in logs?
- No functionality removed to "improve" performance?

### D-bis. Devil's Advocate Checklist (Performance)
1. 가장 측정이 누락되었을 가능성이 높은 layer는?
2. Baseline 측정이 신뢰할 수 있는 조건에서 수행되었는가?
3. 최적화가 기능 회귀를 유발하지 않았는가?
4. Before/After 측정이 동일 조건인가? (같은 데이터, 같은 파라미터)
5. 실제 측정했는가, 코드 분석만 했는가?

### D-ter. Anti-Pattern Check (Performance)
| Anti-Pattern | How to Detect |
|---|---|
| "Improved" without measurement | No before/after numbers in result |
| Optimized query but not client code | Client still fetches excess data |
| Added index but didn't verify usage | Index not used in EXPLAIN |
| Claimed latency reduction without repeat measurement | Single run, no median |
| Removed functionality to "improve" perf | Feature regression |

### E. Score 5 Dimensions (1-10)
1. Query Performance — DB 쿼리 개선도
2. Response Time — API 레이턴시 개선도
3. Client Performance — 렌더링/번들 개선도
4. Measurement Quality — 측정 방법의 신뢰성 (**HARD FAIL if < 6**)
5. Regression Safety — 기능 회귀 없음 (**HARD FAIL if < 6**)

### F. Verdict
- **IMPROVED**: All >= 7, at least one metric improved >= 20%
- **MARGINAL**: All >= 6, improvements < 20%
- **NO_CHANGE**: Measurements within noise margin (< 5%)
- **REGRESSION**: Any metric worsened > 5% OR any hard-fail < 6

### G. Write Report
Write to .claude/pge-perf/benchmark-eval.md.
Return verdict + key findings.
```

### Benchmarker 결과 처리

- **IMPROVED**: Archive → Performance Optimization Report 출력
- **MARGINAL**: Archive → Report 출력 + 추가 최적화 안내
- **NO_CHANGE**: 원인 분석 → Phase 2 재실행 또는 에스컬레이션
- **REGRESSION**: 롤백 → 원인 분석 → Phase 2 재실행 (fresh context)

---

## Final Report: Performance Optimization Report

```
PERFORMANCE OPTIMIZATION REPORT
════════════════════════════════════════
Target:          [최적화 대상]
Date:            {ISO timestamp}
Verdict:         {IMPROVED | MARGINAL | NO_CHANGE | REGRESSION}

── Profiling ──
Bottlenecks:     [식별된 병목 수]
Layers affected: {DB, Server, Client, Network}

── Optimization ──
Applied:         [적용된 최적화 수]
Quick Wins:      [Score >= 6 항목 수]
Backlogged:      [Score <= 2 항목 수]

── Benchmark ──
| Metric             | Before  | After   | Δ%     |

Scores:
  Query Performance:     X/10
  Response Time:         X/10
  Client Performance:    X/10
  Measurement Quality:   X/10
  Regression Safety:     X/10

Contributors:    query-profiler, code-analyzer, load-tester
Evaluator:       independent benchmarker (fresh context)

Backlog:
  - [Score <= 2 항목들]
════════════════════════════════════════
```

### Archive

`.claude/pge-perf/history/{YYYYMMDD}T{HHMM}_{target-slug}.md` 생성 (under 100 lines).

---

## Escalation Rules

- **Phase 1 실패**: 프로파일링 도구 접근 불가 시 → 에스컬레이션 + 코드 분석만 수행
- **Phase 2 실패**: 3-strike rule — 최적화 3회 시도 후 개선 없으면 STOP
- **Phase 3 REGRESSION**: 즉시 롤백 → 원인 분석 → 사용자 확인 후 재시도
- **FAIL loop 2+회**: 중단 + 사용자 에스컬레이션
- **성능 개선 불가**: "ALREADY_OPTIMIZED" verdict + 현재 상태 보고서 출력

---

## Important Rules

- 각 Phase의 **필수 출력**이 없으면 다음 Phase 진행 불가
- `/pge-perf` 작업은 **프로토콜 스킵 불가**
- Phase 1 에이전트는 **코드를 수정하지 않음** — 분석/측정만 수행
- 에이전트 간 **SendMessage로 발견사항을 반드시 공유** — 사일로 금지
- 분석 완료 후 **반드시 팀 shutdown** — 리소스 정리
- Phase 2 최적화는 **team lead (메인 에이전트)만 수행**
- Phase 3 Benchmarker는 **반드시 fresh context Agent subagent**으로 실행
- **실제 측정 실행** 필수 — "I assume it improved" 불가
