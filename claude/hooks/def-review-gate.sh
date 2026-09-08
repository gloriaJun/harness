#!/usr/bin/env bash
# PreToolUse(Write|Edit): review gate for AI definition files.
# Emits permissionDecision "ask" so every definition-file write raises a user
# approval prompt, even in acceptEdits mode. Mechanical backstop for the
# definition-file change flow (instructions/references/definition-files.md):
# present the changed parts in Korean in chat, get confirmation, then save in
# English.
set -euo pipefail

input="$(cat)"
source "$(dirname "${BASH_SOURCE[0]}")/hook-input.sh"

# Definition-file scope; returns 0 when $1 is a definition file.
in_scope() {
case "$1" in
  # Definition filenames anywhere.
  */CLAUDE.md|*/AGENTS.md|*/SKILL.md) ;;
  # Claude/Codex config trees (unambiguous).
  */.claude/agents/*|*/.claude/commands/*|*/.claude/instructions/*|*/.claude/hooks/*|*/.claude/skills/*|*/.codex/*) ;;
  # claude/ source trees (grimoire layout); extension-limited to cut false
  # positives from unrelated project dirs named claude/.
  */claude/agents/*.md|*/claude/commands/*.md|*/claude/instructions/*.md|*/claude/hooks/*.sh|*/claude/skills/*.md|*/claude/skills/*.sh|*/claude/skills/*.json|*/claude/claude-only.md|*/claude/settings.*.json) return 0 ;;
  *) return 1 ;;
esac
}

# Marker pass: def-review-approve.sh records paths whose Korean review the
# user approved in chat; unexpired entries skip the prompt (exact path match).
MARKER="$HOME/.claude/.def-review-approvals"
TTL=300
approved() {
  local dir abs ts path now
  [[ -f "$MARKER" ]] || return 1
  now="$(date +%s)"
  dir="$(cd "$(dirname "$1")" 2>/dev/null && pwd)" || return 1
  abs="$dir/$(basename "$1")"
  while IFS=$'\t' read -r ts path; do
    [[ "$ts" =~ ^[0-9]+$ && "$path" == "$abs" ]] && (( now - ts < TTL )) && return 0
  done < "$MARKER"
  return 1
}

# One decision for the whole call: any unapproved definition file -> ask;
# only approved ones -> allow; no definition file -> silent pass.
decision=""
while IFS= read -r file; do
  in_scope "$file" || continue
  if approved "$file"; then
    [[ -z "$decision" ]] && decision="allow"
  else
    decision="ask"
  fi
done < <(hook_files)
[[ -n "$decision" ]] || exit 0

if [[ "$decision" == "allow" ]]; then
  reason="Pre-approved: Korean review for this path was recorded by def-review-approve.sh within the TTL (5 minutes)."
else
  reason="Definition file write. Confirm the changed parts were presented in Korean in chat and approved, and that the file content is English (change flow, instructions/references/definition-files.md)."
fi
jq -cn --arg d "$decision" --arg reason "$reason" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$reason}}'
exit 0
