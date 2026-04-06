# Audit-Skill v2: Multi-Model Delegation

**Date:** 2026-04-06
**Status:** Approved
**Skill:** `skills/my-claude-audit/`

## Summary

Extend the existing Claude Code audit skill to support external CLI models (Gemini, OpenAI, Codex) for the insights aggregation phase, add session log anomaly detection with 5 tagged patterns, and present findings through a "Cold Tech Lead" persona. Uses hybrid delegation: Claude handles all data collection internally, external models provide objective analysis.

## Architecture

### Delegation Model: Hybrid

- **Phases 1-2** (Discovery + Parallel Subagents): Always Claude internal — requires local file access
- **Phase 3** (Insights Aggregation): Routed to user-selected external model OR Claude fallback
- **Phases 4-6** (HTML generation, browser, summary): Always Claude internal

### Updated Workflow

```
Phase 0: Scope Selection (existing) + Model Selection (NEW)
Phase 1: Discovery (existing) + Session Log Discovery (NEW)
Phase 2: Parallel Subagents (existing 2) + Session Anomaly Tagger (NEW, 3rd parallel)
Phase 3: Insights Aggregation → external CLI tool OR Claude fallback
Phase 4: HTML Report (existing) + "Analyzed by" badge (NEW)
Phase 5: Browser open (existing)
Phase 6: Terminal summary (existing)
```

## Phase 0: Model Selection

### Environment Scan

After scope selection, scan for available CLI tools:

```bash
which gemini 2>/dev/null   # Gemini CLI
which openai 2>/dev/null   # OpenAI CLI
which codex 2>/dev/null    # Codex CLI
```

Check corresponding env vars for API key presence (existence only, not validity):

| Tool | Command | Env Var | Auth Check |
|------|---------|---------|------------|
| Gemini CLI | `gemini` | `GEMINI_API_KEY` | `gemini --version` |
| OpenAI CLI | `openai` | `OPENAI_API_KEY` | `openai --version` |
| Codex CLI | `codex` | `OPENAI_API_KEY` | `codex --version` |
| Claude Code | (internal) | — | Always available |
| Custom | User-provided | — | `<cmd> --version` |

### Interactive Selection

Present via AskUserQuestion. Only show tools that are installed. Mark tools with detected API keys. Always include Claude Code (internal) and custom input option.

**Language:** Korean for labels and messages (target audience is Korean developers). All user-facing strings including fallback messages use Korean.

Example:
```
"분석을 수행할 도구를 선택해주세요:"
[1] Gemini CLI (설치됨, API 키 감지)
[2] Codex CLI (설치됨)
[3] Claude Code (내장)
[4] 직접 입력
```

Store selection in `meta.analyzer` field for report attribution.

## Phase 1: Discovery (Updated)

### Existing Discovery (unchanged)

- Read `~/.claude/settings.json` → extract pluginMarketplaces, hooks, permissions, MCP servers, env vars
- Glob `~/.claude/*.md` for global config files
- Read project-level configs if scope includes project

### New: Session Log Discovery

- Resolve current project's session directory: `~/.claude/projects/<encoded-cwd>/`
- List `*.jsonl` files (exclude `subagents/` subdirectories)
- Sort by modification time, select most recent 5 sessions
- Pass file paths to the new session anomaly tagger agent

## Phase 2: Parallel Subagents (Updated)

Three agents dispatched in parallel:

```
Agent 1: token-and-config.md    + discovery data     (existing)
Agent 2: skills-ecosystem.md    + plugin data         (existing)
Agent 3: session-anomaly-tagger.md + session JSONL paths (NEW)
```

### New Agent: Session Anomaly Tagger

**File:** `analyzer-prompts/session-anomaly-tagger.md`

**Input:** List of JSONL session file paths (max 5 most recent)

**Analysis per session:**
- Parse `user` type messages: count, average content length, timestamp gaps
- Parse `assistant` type messages: count, tool use patterns
- Parse `progress` type messages: detect verification tool executions between turns
- Detect machine-generated text ratio in user messages

**Verification tool detection in `progress` messages:**
A `progress` message counts as a "verification execution" if its `data` field contains tool invocations matching these patterns:
- Tool name contains: `test`, `lint`, `check`, `build`, `run`, `exec`, `jest`, `vitest`, `pytest`, `eslint`, `tsc`
- Or the Bash tool command contains: `npm test`, `npm run`, `yarn test`, `pnpm test`, `make test`, `cargo test`, `go test`, `python -m pytest`

**Machine-generated text detection heuristic:**
User input is classified as "machine-generated" when it matches these patterns:
- Lines starting with common stack trace prefixes: `at `, `Error:`, `Traceback`, `File "`, `  at `, `Caused by:`
- Lines matching log patterns: timestamp prefixes (`[2026-`, `2026-04-`), log levels (`[ERROR]`, `[WARN]`, `DEBUG`)
- Average line length >120 chars (typical of log output, not human prose)
- Ratio = (lines matching above patterns) / (total lines in user message)

**Anomaly Tags:**

| Tag | Trigger | Detection Criteria |
|-----|---------|-------------------|
| `TAG_ERR_DUMP` | Error log dumping | Machine-generated text ratio >80% in user input AND content >100 lines |
| `TAG_ONESHOT_WAR` | One-shot complex requests | Single user message references 3+ distinct file paths (detected by path-like patterns: `src/`, `.ts`, `.js`, `.py` etc.) |
| `TAG_CTX_HOARD` | Context hoarding | >20 consecutive `user` messages without any `system` message containing `/clear` or `/compact`, measured as consecutive turn count |
| `TAG_SILENT_FIX` | No-context commands | User message content length <30 chars, no words indicating constraints (because, should, must, when, if, error, bug, test) |
| `TAG_BLIND_FOLLOW` | No verification | Between an `assistant` message containing code (detected by code fence markers) and the next `user` message, zero `progress` messages match verification tool patterns |

**Output format:**
```json
{
  "category": "session-anomaly",
  "findings": [
    {
      "severity": "warning",
      "category": "session-anomaly",
      "title": "Context hoarding detected",
      "detail": "Session 8700f461 ran 45 turns without /clear. 78% of context was stale.",
      "suggestion": "Use /clear when switching tasks"
    }
  ],
  "metrics": {
    "sessionsAnalyzed": 5,
    "totalTurns": 142,
    "avgPromptLength": 67,
    "anomalyTags": ["TAG_CTX_HOARD", "TAG_SILENT_FIX"]
  },
  "sessionBreakdown": [
    {
      "sessionId": "8700f461-...",
      "turns": 45,
      "anomalies": ["TAG_CTX_HOARD"],
      "stats": {
        "user_input_avg_len": 38,
        "max_gap_without_clear": 32,
        "machine_text_ratio": 0.15,
        "verification_rate": 0.3
      }
    }
  ]
}
```

## Phase 3: Insights Aggregation (Updated)

### Input

Receives 3 JSON outputs:
1. `token-and-config` (Agent 1)
2. `skills-ecosystem` (Agent 2)
3. `session-anomaly` (Agent 3 — new)

### Two Insight Personas

The insights aggregator applies two sequential personas to session-related findings:

#### Persona 1: Cold Tech Lead (Diagnosis)

- **Tone:** Cynical, direct, technically precise. No praise or softening.
- **Required sections in output:**
  - `[Status]`: One-sentence sarcastic assessment of developer's AI usage level
  - `[Critical Issues]`: Technical critique per anomaly tag with data backing
  - `[Prescription]`: Single immediate improvement action, delivered as a command

#### Persona 2: System Instruction Patch Designer (Remediation)

- **Role:** Designs enforceable instruction patches that prevent detected bad habits from recurring.
- **Output:** For each detected anomaly tag, generate a concrete instruction patch in Markdown format that can be appended to the user's `CLAUDE.md` or project instructions.
- **Design principles:**
  - **Enforcement over suggestion:** "거절하거나 다시 물으세요" not "노력하세요". Instructions must command Claude to refuse or redirect, not merely advise.
  - **Explicit triggers:** Each patch specifies the exact condition (e.g., log >50 lines without summary, prompt <30 chars without constraints).
  - **Token-efficient:** Core logic only, as a concise Markdown list. No verbose explanations.

**Tag-to-Patch mapping:**

| Anomaly Tag | Patch Target | Enforcement Rule |
|-------------|-------------|-----------------|
| `TAG_ERR_DUMP` | Raw log handling | "사용자가 분석이나 요약 없이 50라인 이상의 로그를 입력할 경우, 즉시 분석을 중단하고 '로그의 핵심 에러 5줄과 발생 맥락을 요약해서 다시 주십시오'라고 요청하십시오." |
| `TAG_SILENT_FIX` | Vague fix requests | "의도가 불분명한 '고쳐줘', '수정해', '바꿔봐' 등 30자 미만의 수정 요청에는 '어떤 부작용을 고려해야 하는지, 기대하는 결과가 무엇인지' 되물으십시오." |
| `TAG_CTX_HOARD` | Session hygiene | "대화가 15턴이 넘어가면 사용자에게 세션 요약 후 `/clear` 할 것을 강력히 권고하십시오. 20턴 초과 시 매 응답 앞에 경고를 표시하십시오." |
| `TAG_BLIND_FOLLOW` | Verification gate | "코드를 생성한 직후, 사용자가 테스트나 실행 없이 바로 다음 구현을 요청하면 '이전 변경사항을 먼저 검증하셨나요? `npm test` 또는 관련 명령을 실행해 주세요'라고 요청하십시오." |
| `TAG_ONESHOT_WAR` | Scope control | "한 번의 요청으로 3개 이상의 파일을 동시 수정하려 할 경우, 작업을 단계별로 분리하도록 제안하십시오. 각 단계마다 검증 후 다음으로 진행하십시오." |

### External Model Delegation

When an external model is selected:

1. Combine all 3 agent JSONs + updated insights-aggregator prompt (including Cold Tech Lead instructions) + scope
2. Write combined prompt to `/tmp/claude-audit-prompt-<timestamp>.txt`
3. Execute: `scripts/delegate.sh <cli-tool> <prompt-file>`
4. Parse JSON response from stdout
5. On failure (exit code 1): notify user, fall back to Claude internal agent

### Fallback Logic

```
External CLI invoked
├─ Exit 0 + valid JSON → use result
├─ Exit 0 + invalid JSON → notify user, fallback to Claude
└─ Exit 1 (or timeout) → notify user, fallback to Claude
```

Fallback message: "외부 도구({tool})에서 오류가 발생했습니다. Claude Code 내부 분석으로 전환합니다."

### Updated Output Schema

Adds `sessionInsights` block:

```json
{
  "category": "insights",
  "findings": [...],
  "metrics": {...},
  "recommendations": [...],
  "optimizationScore": {...},
  "missedCommands": [...],
  "automationOpportunities": [...],
  "crossLayerInsights": [...],
  "sessionInsights": {
    "status": "토큰을 불태워 난로를 떼는 원시인 수준이군요.",
    "criticalIssues": [
      {
        "tag": "TAG_CTX_HOARD",
        "critique": "세션을 32턴이나 끌고 가는 건...",
        "evidence": "Session 8700f461: 45 turns, 0 /clear calls"
      }
    ],
    "prescription": "/clear 습관화: 매 작업 전환 시 반드시 실행",
    "anomalyTagsSummary": ["TAG_CTX_HOARD", "TAG_SILENT_FIX"],
    "instructionPatches": [
      {
        "targetProblem": "컨텍스트 비대화",
        "triggerTag": "TAG_CTX_HOARD",
        "principle": "강제 세션 위생 관리",
        "patch": "- [조건]: 대화가 15턴을 초과할 경우.\n- [행동]: 사용자에게 세션 요약 후 `/clear` 할 것을 강력히 권고하십시오. 20턴 초과 시 매 응답 앞에 경고를 표시하십시오.",
        "scenario": "20턴 이상 대화 지속 시 → 자동 경고 + /clear 권유"
      }
    ]
  }
}
```

## Phase 4: HTML Template Changes

### Header Badge

Add "Analyzed by" badge in the report header, sourced from `meta.analyzer`:

```html
<span class="analyzer-badge">Insights by: Gemini 2.5 Pro</span>
```

Styling: small pill badge, subtle color differentiation per provider.

### New Card: Session Analysis

A new dashboard card showing:
- Anomaly tags as colored pills (red for critical, yellow for warning)
- Cold Tech Lead `[Status]` quote prominently displayed
- `[Critical Issues]` list with expandable details
- `[Prescription]` as a highlighted action box
- Per-session breakdown table (session ID, turns, anomalies, stats)

### New Card: Instruction Patches

A second new card showing auto-generated remediation patches:
- Table layout: Anomaly Tag | Target Problem | Patch Content
- Each patch displayed in a code block with copy-to-clipboard button
- "Apply to CLAUDE.md" action hint per patch (informational — actual application is manual)
- Scenario example shown as a collapsible detail for each patch

### Combined Report Object (Phase 4 Assembly)

The combined object written to the HTML template (replaces v1 structure):

```json
{
  "meta": {
    "timestamp": "<ISO 8601>",
    "scope": "both|global|project",
    "version": "2.0.0",
    "analyzer": "gemini|openai|codex|claude-code|custom",
    "analyzerCommand": "gemini",
    "fallbackUsed": false
  },
  "tokenAndConfig": {},
  "skillsEcosystem": {},
  "sessionAnomaly": {},
  "insights": {
    "...existing fields...",
    "sessionInsights": {
      "status": "...",
      "criticalIssues": [],
      "prescription": "...",
      "anomalyTagsSummary": [],
      "instructionPatches": []
    }
  }
}
```

`sessionInsights` is nested inside `insights` because it is produced by the insights aggregator (Phase 3), not a separate agent. The `sessionAnomaly` top-level key holds raw anomaly data from Agent 3.

## CLI Delegation Script

**File:** `skills/my-claude-audit/scripts/delegate.sh` (discovered at runtime via the skill's directory path, never hardcoded)

The script uses a per-tool invocation map because each CLI tool has different argument conventions:

```bash
#!/bin/bash
# Delegates prompt to external CLI tool with per-tool invocation
# Usage: delegate.sh <cli-tool-name> <prompt-file> [timeout]
# Returns: stdout text, exit 0 on success, exit 1 on failure

set -euo pipefail

CLI_TOOL="$1"
PROMPT_FILE="$2"
TIMEOUT="${3:-120}"

# Verify tool exists
if ! command -v "$CLI_TOOL" &>/dev/null; then
    echo "Error: $CLI_TOOL not found in PATH" >&2
    exit 1
fi

# Per-tool invocation map
invoke_tool() {
    local tool="$1"
    local file="$2"
    local t="$3"

    case "$tool" in
        gemini)
            # Gemini CLI accepts prompt via stdin
            timeout "$t" gemini < "$file" 2>/dev/null
            ;;
        openai)
            # OpenAI CLI: pass via stdin to chat mode
            timeout "$t" openai api chat.completions.create \
                -m gpt-4o -M "$(cat "$file")" 2>/dev/null
            ;;
        codex)
            # Codex CLI: pass prompt as positional argument
            timeout "$t" codex "$(cat "$file")" 2>/dev/null
            ;;
        *)
            # Custom tool: try stdin first, then --prompt flag
            local result
            result=$(timeout "$t" "$tool" < "$file" 2>/dev/null) || true
            if [ -n "$result" ]; then
                echo "$result"
                return 0
            fi
            result=$(timeout "$t" "$tool" --prompt "$file" 2>/dev/null) || true
            if [ -n "$result" ]; then
                echo "$result"
                return 0
            fi
            return 1
            ;;
    esac
}

RESULT=$(invoke_tool "$CLI_TOOL" "$PROMPT_FILE" "$TIMEOUT") || true
if [ -n "$RESULT" ]; then
    echo "$RESULT"
    exit 0
fi

exit 1
```

**Progress indication:** While the external tool runs (up to 120s timeout), Claude prints a status message: "외부 모델 분석 중... ({tool})" before invocation. If timeout is reached, the fallback triggers with an explanation.

## File Changes Summary

| File | Change |
|------|--------|
| `SKILL.md` | Update workflow: add Phase 0 model selection, Phase 1 session discovery, Phase 2 third agent, Phase 3 delegation logic |
| `analyzer-prompts/session-anomaly-tagger.md` | **New** — session log anomaly detection prompt |
| `analyzer-prompts/insights-aggregator.md` | Update — add session-anomaly input, Cold Tech Lead persona, sessionInsights output |
| `scripts/delegate.sh` | **New** — CLI delegation script with auto-detect invocation |
| `templates/report-template.html` | Update — add analyzer badge, session analysis card |

## JSONL Session Log Structure

Based on discovery, session logs contain these message types:

| Type | Content | Relevance |
|------|---------|-----------|
| `user` | User prompts with content and timestamps | Primary analysis target |
| `assistant` | Model responses | Tool use pattern detection |
| `progress` | Tool execution events with toolUseID | Verification detection (test/lint/run) |
| `system` | System messages and reminders | Context management detection |
| `queue-operation` | Queue state changes | Session lifecycle |

## Future Extension: Checklist Service

A web service integration point (out of scope for v2):
- "Short Intro Card" on the web service linking to this skill's repository
- Installation command guidance for connecting web reports with local analysis
- Deferred to a separate spec when the web service is ready
