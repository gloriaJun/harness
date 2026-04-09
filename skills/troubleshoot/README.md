# g-troubleshoot

Unified troubleshooting skill for error analysis, debugging, and performance diagnosis. Handles error logs, stack traces, Sentry alerts, OpenSearch logs, and local development errors. Replaces the former `g-debug-process` skill.

## Features

- **3 Diagnostic Modes** — Automatically detects: error-analysis, debug, or performance mode based on input
- **Parallel Codebase Exploration** — Dispatches Explore agents in Step 0 to search relevant code paths concurrently
- **Root Cause Analysis** — Traces errors to their origin with structured cause chain
- **User-Friendly Explanation** — Translates technical findings into clear, actionable descriptions
- **Fix Implementation** — Proposes and applies fixes with user confirmation
- **Defensive Test Writing** — Generates tests to prevent regression, with escalation to `/g-test-writer` for broader coverage
- **Optional Cross-Review** — Offers code-reviewer agent or Codex validation of fixes

## Usage

```
/g-troubleshoot
```

Also triggers on natural language inputs:
- Error logs or stack traces pasted into the conversation
- Korean triggers: "에러 고쳐줘", "왜 안 돼", "디버깅 해줘", "왜 느리지"

## How It Works

```
/g-troubleshoot (or natural language trigger)
  → Step 0: Triage + auto-detect mode
    ├── Dispatch Explore agents (parallel codebase search)
    └── Classify: error-analysis / debug / performance
  → Step 1: Root cause analysis
  → Step 2: User-friendly explanation
  → Step 3: Fix implementation (with user confirmation)
  → Step 4: Defensive test writing
    └── Escalate to /g-test-writer if broader coverage needed
```

### Mode Detection

| Mode | Triggers |
|------|----------|
| error-analysis | Stack traces, error logs, Sentry alerts |
| debug | "왜 안 돼", unexpected behavior descriptions |
| performance | "왜 느리지", slow response reports, latency data |

## Requirements

- Claude Code CLI
- code-reviewer agent (optional — for cross-review)
- Codex CLI (optional — alternative cross-review)

## License

MIT
