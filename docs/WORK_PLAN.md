# Harness 구성 일원화 작업 계획

## 배경

- SuperClaude 플러그인이 `~/.claude/`에 14개 `.md` 파일을 직접 설치하여 매 세션마다 컨텍스트에 로드
- 대부분 불필요하거나 skill/plugin과 중복되어 토큰 낭비
- 커스텀 지침 없이 기본 설치 상태로 사용 중
- 목표: harness 레포를 단일 소스로, `$HOME`에는 심링크로 배포

## 공통 규칙

- Agent 사용 시 model: "sonnet" 권장 (비용 효율)
- 외부 플러그인/skill 조합 시 **래핑 방식**: task-process가 워크플로우를 오케스트레이션하고, 각 단계의 실행은 외부 skill에 위임. 외부 skill을 fork하지 않고, 사용 가능 여부를 확인 후 호출하며, 필요한 오버라이드만 task-process에서 정의.

## Skill 트리거 충돌 방지

자체 skill과 외부 플러그인 skill의 트리거가 중복될 수 있다. 다음 규칙으로 충돌을 방지한다:

- **자체 skill (task-process 등)은 명시적 호출 전용으로 설계**: SKILL.md의 description에 자동 트리거 조건을 넣지 않고, `/task-process`와 같이 사용자가 직접 호출하는 방식으로만 동작하도록 정의
- **외부 skill의 자동 트리거는 그대로 유지**: 외부 플러그인이 제공하는 brainstorming, writing-plans 등의 자동 활성화는 간섭하지 않음
- **task-process 내부에서 외부 skill을 래핑 호출할 때**: task-process가 활성화된 상태에서는 외부 skill의 자동 트리거를 무시하고, task-process의 워크플로우 순서에 따라 명시적으로 호출
- **Phase 2에서 SuperClaude 비활성화 후**: 외부 skill이 제거되면 task-process의 트리거 조건을 자동 활성화로 확장 가능. 이 시점에 사용자와 트리거 범위를 재논의할 것

## 작업 단위

---

### Phase 1: `$HOME/.claude` 구조 설계 및 구현

> Harness 레포에 원본을 두고 심링크로 배포하는 구조 완성.

#### 지침 정의 (설계 완료)

- [x] **1-1. `claude/CLAUDE.md` 작성**
  - 핵심 원칙만 포함 (짧게)
  - 한국어 응답 선호
  - 코드 변경 전 확인 필수, 근거/설명 포함
  - 자율적 코드 수정 금지
  - Agent 사용 시 model: "sonnet" 권장
  - `@instructions/tech-stack.md`, `@instructions/git-workflow.md` 참조
  - task-process는 `@` import하지 않음 (skill로 분리)

  ```markdown
  # Claude Code Instructions

  ## Core Principles
  - Respond in Korean
  - Never modify code without user confirmation
  - Provide rationale and explanation for every proposed change
  - Review first, then proceed — no autonomous code modifications
  - When using Agent tool, prefer model: "sonnet" for cost efficiency

  ## References
  @instructions/tech-stack.md
  @instructions/git-workflow.md
  ```

- [x] **1-2. `claude/instructions/tech-stack.md` 작성**
  - 패키지 매니저: pnpm 선호
  - 프로젝트별 기술 스택은 각 레포의 CLAUDE.md에서 정의

  ```markdown
  # Tech Stack Preferences

  ## Package Manager
  - pnpm preferred for all projects

  ## General
  - Specific frameworks and libraries are defined per project in each repo's CLAUDE.md
  - This file covers cross-project preferences only
  ```

- [x] **1-3. `claude/instructions/git-workflow.md` 작성**
  - `~/.gitmessage.txt` 파일을 직접 참조 (내용 복제 금지)
  - Co-Authored-By 선택적, amend 금지, 개별 파일 스테이징

  ```markdown
  # Git Workflow

  ## Commit Message Convention
  - Follow the convention defined in ~/.gitmessage.txt
  - Always read ~/.gitmessage.txt before writing commit messages

  ## Rules
  - Co-Authored-By line is optional — include only when user requests
  - Always create new commits, never amend unless explicitly asked
  - Stage specific files, avoid `git add -A`
  ```

- [x] **1-4. `skills/task-process/SKILL.md` 작성**
  - skill로 분리하여 호출 시에만 컨텍스트 로드 (레이지 로딩)
  - 워크플로우: 요구사항 발견 → PRD → TRD(조건부) → Feature 분할 → 실행 → 완료
  - 매 단계 사용자 확인 필수
  - TRD 생략 조건: UI/디자인 변경 없고 단일 시스템 내 로직 변경인 경우
  - Feature 분할 원칙: 단일 세션에서 완료 가능한 크기
  - 작업 문서 위치 자동 판별:
    - 경로에 `GitHubWork` 포함 → `~/Documents/GitHubWork/_claude-work/`
    - 경로에 `GitHubPrivate` 포함 → `~/Documents/GitHubPrivate/_claude-work/`
  - PRD/TRD 위치: 프로젝트에 `docs/` 있으면 해당 위치, 없으면 `_claude-work/` 임시
  - `_index.md`로 진행 중인 작업 관리, 새 세션 시작 시 반드시 읽기
  - 외부 skill 연동 (래핑 방식):
    - `brainstorming` skill 사용 가능 시 Step 1에서 활용
    - `writing-plans` skill 사용 가능 시 Step 4에서 활용
    - 외부 skill 부재 시 자체 로직으로 fallback
  - 임시 파일은 remote push 금지, 전체 완료 후 사용자 확인받고 삭제
  - 전체 완료 시 PRD/TRD 최종 업데이트

  ```
  skills/task-process/SKILL.md 내용은 위 명세 기반으로 작성
  YAML frontmatter:
    name: task-process
    description: >
      /task-process command only. Structured task workflow with PRD,
      TRD, and feature breakdown. Manual invocation only — do NOT
      auto-trigger. Use when user explicitly calls /task-process.
  ```

#### 인프라 작업

- [ ] **1-5. `setup.sh` 업데이트**
  - `claude/CLAUDE.md` → `~/.claude/CLAUDE.md` 심링크
  - `claude/instructions/` → `~/.claude/instructions/` 폴더 심링크
  - `skills/task-process/` → `~/.claude/skills/task-process` 심링크
  - 기존 hooks, skills 심링크 유지

- [ ] **1-6. SuperClaude 설치 파일 정리**
  - `~/.claude/`에서 SuperClaude가 설치한 `.md` 파일 14개 백업 후 제거
  - 제거 대상: `MODE_*.md`, `MCP_*.md`, `BUSINESS_*.md`, `RTK.md`
  - `.superclaude-metadata.json` 백업 후 제거
  - 기존 `CLAUDE.md` (SuperClaude entry point) 백업 후 harness 심링크로 교체

- [ ] **1-7. 동작 검증**
  - 새 세션에서 CLAUDE.md 로드 확인
  - `@instructions/*.md` 참조 정상 동작 확인
  - hooks, skills 심링크 정상 동작 확인
  - task-process skill 호출 테스트

---

### Phase 2: SuperClaude 플러그인 정리

> Phase 1 완료 후 진행. 플러그인 비활성화 및 대안 탐색.

- [ ] **2-1. SuperClaude 플러그인 의존성 분석**
  - 현재 활성화된 Superpowers 플러그인이 제공하는 skill/agent 목록 정리
  - 어떤 skill이 SuperClaude `.md` 파일에 의존하는지 확인
  - 독립적으로 동작하는 skill과 의존적인 skill 분류

- [ ] **2-2. 유지할 skill/agent 결정**
  - brainstorming, writing-plans, TDD 등 개발 워크플로우 skill 평가
  - code-review, debugging 등 품질 관련 skill 평가
  - 사용 빈도 및 실제 유용성 기준으로 선별
  - task-process에서 래핑할 외부 skill 최종 목록 확정

- [ ] **2-3. 플러그인 비활성화/교체**
  - `settings.json`의 `enabledPlugins`에서 SuperClaude 비활성화
  - 대안 플러그인 탐색 및 테스트
  - 필요 시 자체 skill로 대체 (harness/skills/에 추가)

- [ ] **2-4. settings.json 정리**
  - 불필요한 permissions 정리 (일회성 허용들 제거)
  - `extraKnownMarketplaces` 정리
  - 템플릿화 (`templates/settings.json.example` 업데이트)

---

### Phase 3: 프로젝트/폴더별 설정 분리

> Phase 1, 2 완료 후 진행. 회사/개인 프로젝트별 MCP 및 지침 분리.

- [ ] **3-1. 공통 vs 프로젝트별 MCP 분류**
  - 글로벌 MCP (모든 프로젝트 공통): settings.json에 유지
  - 회사 전용 MCP (Jira, Confluence, Slack 등): 프로젝트별 `.mcp.json`
  - 개인 전용 MCP: 프로젝트별 `.mcp.json`

- [ ] **3-2. 회사 프로젝트 공통 템플릿 작성**
  - GitHubWork 하위 프로젝트용 CLAUDE.md 템플릿
  - GitHubWork 하위 프로젝트용 .mcp.json 템플릿
  - harness/templates/에 관리

- [ ] **3-3. 개인 프로젝트 공통 템플릿 작성**
  - GitHubPrivate 하위 프로젝트용 CLAUDE.md 템플릿
  - GitHubPrivate 하위 프로젝트용 .mcp.json 템플릿

- [ ] **3-4. MCP 공통 정의 중복 방지 방안 구현**
  - 글로벌 settings.json에 공통 MCP 정의
  - 프로젝트별 `.mcp.json`은 추가/오버라이드만 정의
  - 불필요한 MCP가 로드되지 않도록 비활성화 방법 문서화

---

## 파일 구조 (Phase 1 완료 후 목표)

```
harness/
  claude/
    CLAUDE.md                     ← 엔트리포인트
    instructions/
      tech-stack.md               ← 공통 기술 선호도
      git-workflow.md             ← 커밋/PR 규칙
  hooks/
    rtk-rewrite.sh                ← 기존 유지
  skills/
    my-claude-audit/              ← 기존 유지
    task-process/                 ← NEW: 작업 워크플로우 skill
      SKILL.md
  templates/
    settings.json.example         ← 설정 참조용 (Phase 2에서 업데이트)
  docs/
    WORK_PLAN.md                  ← 이 문서
  setup.sh                        ← 심링크 생성 스크립트
  CLAUDE.md                       ← 레포 자체의 프로젝트 지침 (변경 없음)
```

`~/.claude/` (심링크 결과):
```
~/.claude/
  CLAUDE.md            → harness/claude/CLAUDE.md
  instructions/        → harness/claude/instructions/
  hooks/
    rtk-rewrite.sh     → harness/hooks/rtk-rewrite.sh
  skills/
    my-claude-audit/   → harness/skills/my-claude-audit/
    task-process/      → harness/skills/task-process/
```

## 작업 문서 구조 (_claude-work)

```
~/Documents/GitHubWork/_claude-work/        ← 회사 프로젝트
  _index.md                                  ← 진행 중 작업 목록
  YYYY-MM-DD-<repo>-<task-name>/
    features.md                              ← feature 분할 목록
    feature-01-<name>.md                     ← 세션별 작업 지시서
    prd.md                                   ← 프로젝트에 docs/ 없을 때만
    trd.md                                   ← 프로젝트에 docs/ 없을 때만

~/Documents/GitHubPrivate/_claude-work/     ← 개인 프로젝트
  (동일 구조)
```

`_index.md` 형식:
```markdown
## <repo> - <task name>
- PRD: <path> (committed / temporary)
- TRD: <path> (committed / temporary / skipped)
- Work dir: <relative path>
- Status: <current step and progress>
```

---

## 원칙

- **harness 레포가 단일 소스**: `$HOME`에는 원본을 두지 않음
- **CLAUDE.md는 최소화**: 상시 로드되므로 토큰 비용에 민감
- **세부 지침은 분리**: `instructions/`에서 `@` import, 무거운 것은 skill로
- **반복 정의 금지**: 공통은 글로벌, 차이만 프로젝트별로
- **외부 skill 래핑**: fork하지 않고, 사용 가능 여부 확인 후 호출, 오버라이드만 자체 정의
- **Agent는 sonnet**: 비용 효율을 위해 Agent 사용 시 model: "sonnet" 권장
- **단계적 진행**: Phase 1 → 2 → 3 순서, 각 단계 검증 후 다음 진행
