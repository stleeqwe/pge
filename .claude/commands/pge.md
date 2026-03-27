# /pge — Full PGE Protocol (강제 모드)

사용자가 작업 요청에 `/pge`를 붙이면 전체 PGE 프로토콜을 강제 실행한다.

## Input

$ARGUMENTS — 작업 설명 (e.g., "팔로워 끊으면 상대방 갱신 안됨", "items에 color 추가")

## Task Type Detection

작업 설명을 분석하여 유형을 판별:

- **Investigation** — 증상/버그/에러 키워드 ("안됨", "느림", "왜", "broken", "error", "bug", "fix")
- **Direct task** — 추가/변경/삭제 키워드 ("추가", "변경", "삭제", "add", "update", "remove", "implement")
- **Code review** — 리뷰 키워드 ("리뷰", "review", "check", "점검")

판별 결과를 출력: `PGE Mode: {Investigation | Direct | Review}`

---

## Investigation Mode

### STEP 1: Systematic Debugging Protocol (4-phase, 모든 단계 필수)

#### Phase 1: Root Cause Investigation
1. 사용자가 제공한 증상/로그를 정리
2. 관련 코드 경로를 Read로 추적 (Explore 사용 가능)
3. `git log --oneline -20 -- <affected-files>` 실행
4. 재현 가능 여부 판단

**필수 출력:**
```
Root cause hypothesis: [구체적이고 검증 가능한 주장]
Affected files: [파일 목록]
```

이 출력이 없으면 다음 단계로 진행 불가.

#### Phase 2: Pattern Analysis
아래 패턴 테이블과 대조하여 매칭 결과를 출력:

| Pattern | Signature | Match? |
|---------|-----------|--------|
| Race condition | Intermittent, timing-dependent | Y/N |
| Nil/null propagation | TypeError, NoSuchMethodError | Y/N |
| State corruption | Inconsistent data, partial updates | Y/N |
| Integration failure | Timeout, unexpected response | Y/N |
| Configuration drift | Works locally, fails remote | Y/N |
| Stale cache | Shows old data | Y/N |

**필수 출력:** `Pattern match: {매칭된 패턴 또는 "신규 패턴"}`

#### Phase 3: Hypothesis Testing
1. 가설을 검증할 수 있는 방법 제시 (로그, assertion, SQL 등)
2. 가능하면 실행하여 검증
3. 3-strike rule: 3회 실패 시 STOP + 에스컬레이션

**필수 출력:** `Hypothesis verified: {Y/N} — {근거}`

#### Phase 4: Scope Lock + Backend/Frontend 판정
**필수 출력:**
```
Scope: [영향 받는 모듈 경계]
Backend change needed: {Y/N}
```

### STEP 2: 분기

- **Backend change needed: Y** → /preflight 실행 → Generator (13-step) → /evaluate 실행
- **Backend change needed: N** → Fix → Test → Analyze → Debug Report 출력

### STEP 3: Debug Report (Investigation 완료 시)
```
DEBUG REPORT
════════════════════════════════════════
Symptom:         [사용자가 보고한 증상]
Root cause:      [실제 원인]
Pattern:         [매칭된 패턴]
Fix:             [변경 내용, file:line 참조]
Evidence:        [테스트 결과, 재현 확인]
Regression test: [새로 추가된 테스트 file:line]
Status:          DONE | DONE_WITH_CONCERNS | BLOCKED
════════════════════════════════════════
```

---

## Direct Task Mode

### STEP 1: /preflight
Sprint Contract 생성 (Phase 1: Planner)

### STEP 2: Generator
13-step 실행 순서 따름. Server Boundary Checkpoint 필수.

### STEP 3: /evaluate
독립 Evaluator Agent로 검증 (Phase 3)

---

## Review Mode

### STEP 1: Pre-Landing Review Checklist

**Pass 1 — CRITICAL:**
- [ ] SQL injection (string interpolation in queries)
- [ ] TOCTOU races (non-atomic status transitions)
- [ ] LLM output trust boundary
- [ ] Enum completeness

**Pass 2 — INFORMATIONAL:**
- [ ] Conditional side effects
- [ ] Dead code / stale comments
- [ ] Test gaps
- [ ] Performance (N+1 queries)

**Fix-First Heuristic:**
- AUTO-FIX: dead code, N+1, stale comments, magic numbers
- ASK: security, race conditions, design decisions, >20 lines

### STEP 2: /evaluate (Phase 3 only)
Domain-specific checklists로 검증

### STEP 3: 이슈 발견 시
자동으로 Direct Task Mode 전환 → /preflight → Generator → /evaluate

---

## Important Rules

- 각 Phase의 **필수 출력**이 없으면 다음 Phase로 진행하지 말 것
- `/pge`가 붙은 작업은 **어떤 경우에도 프로토콜을 스킵하지 않음**
- Escalation Rules 적용: 3-strike, PGE FAIL loop 2+회 시 중단
