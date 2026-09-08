#!/usr/bin/env bash
# Codex SessionStart: inject <ws>/CLAUDE.md only when cwd is under <ws> ($1).
# Claude reads parent CLAUDE.md natively; Codex never walks above the repo root.
set -euo pipefail

ws="${1:-}"
[[ -n "$ws" && -f "$ws/CLAUDE.md" ]] || exit 0
input="$(cat)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
[[ -n "$cwd" && ( "$cwd" == "$ws" || "$cwd" == "$ws"/* ) ]] || exit 0

jq -cn --arg ws "$ws" --rawfile body "$ws/CLAUDE.md" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: ("# Workspace rules for " + $ws + " (this session runs inside it)\n\n" + $body)
  }
}'
