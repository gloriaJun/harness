# Step 1: Enumerate, Mark, Extract

## A. Enumerate the definition layer

```bash
CLAUDE_ROOT="$HOME/.claude"
CODEX_ROOT="${CODEX_HOME:-$HOME/.codex}"
find "$CLAUDE_ROOT/CLAUDE.md" "$CLAUDE_ROOT/instructions" \
  "$CLAUDE_ROOT/skills" "$CLAUDE_ROOT/agents" "$CLAUDE_ROOT/hooks" \
  "$CODEX_ROOT/AGENTS.md" "$CODEX_ROOT/skills" "$CODEX_ROOT/agents" \
  "$CODEX_ROOT/prompts" "$CODEX_ROOT/config.toml" \
  -type f \( -name 'CLAUDE.md' -o -name 'AGENTS.md' -o -name 'SKILL.md' \
  -o -name '*.md' -o -name '*.sh' -o -name '*.toml' \) 2>/dev/null
jq -c '.hooks // {} | to_entries[]' "$CLAUDE_ROOT/settings.json" 2>/dev/null
```

A missing directory is noted and skipped, never an abort (an empty layer can
itself become a D finding).

## Input by entry point

- Standalone `/g-insight`: the current conversation is the evidence source.
- Invoked from another skill as a subagent: the task summary passed in IS the
  conversation for sections B and C; mark exercised only what the summary
  names, and skip hook/agent marking the summary does not mention.

## B. Mark what this session exercised

From the conversation, mark each artifact `exercised` when any holds:

- AGENTS.md or CLAUDE.md: mark the guidance files loaded into this session as
  exercised; when the loaded file list is unavailable, mark them `미확인` and
  state how to verify it.
- an on-demand reference file read this session
- a skill invoked (Skill tool, slash command, or `$name` mention)
- a hook that fired (hook feedback visible in this session)
- an agent type dispatched (Agent tool or a Codex subagent)
- a memory file recalled into this session (system-reminder recall)

Output a two-column list: artifact -> exercised (how) / not exercised.

## C. Extract session evidence

From the current conversation only, collect with verbatim quotes:

- hand-given instructions no loaded definition covers
- corrections: the user rejecting or fixing an output
- the same convention applied manually 2+ times
- workflows (3+ steps) repeated 2+ times or clearly recurring
- friction inside an exercised skill/hook/agent: a moment that forced
  improvisation beyond its written procedure
- tool friction: redundant reads, wrong tool choice, oversized raw dumps

Each entry must quote the exact user message or name the exact tool call.
No quote, no entry.

## Termination

No exercised artifacts beyond CLAUDE.md AND zero evidence entries: run the
Step 2 "B mechanical check" once on CLAUDE.md only. No MISSING lines: output
exactly `No suggestions.` and end the skill. MISSING lines found: proceed to
Step 2 with those as B findings.

Otherwise load `steps/step-2-diagnose.md`.
