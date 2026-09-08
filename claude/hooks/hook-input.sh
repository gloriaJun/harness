#!/usr/bin/env bash
# Sourced by the Write|Edit hooks after `input="$(cat)"`: one accessor pair for
# the Claude payload (file_path + content) and the Codex apply_patch payload.

_hook_cwd() { printf '%s' "$input" | jq -r '.cwd // empty'; }
_hook_patch() {
  [[ "$(printf '%s' "$input" | jq -r '.tool_name // empty')" == "apply_patch" ]] || return 0
  printf '%s' "$input" | jq -r '.tool_input.command // empty'
}

# One target path per line: Add/Update File sections plus Move to targets.
hook_files() {
  local fp
  fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"
  if [[ -n "$fp" ]]; then printf '%s\n' "$fp"; return 0; fi
  _hook_patch | awk -v cwd="$(_hook_cwd)" '
    /^\*\*\* ((Add|Update) File|Move to): / {
      p = $0; sub(/^\*\*\* ((Add|Update) File|Move to): /, "", p)
      if (p !~ /^\//) p = cwd "/" p
      print p
    }'
}

# Content newly written to $1: the whole Write content or Edit new_string on
# Claude, the added (+) lines of that file's patch section on Codex.
hook_added_content() {
  local target="$1" c
  c="$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty')"
  if [[ -n "$c" ]]; then printf '%s' "$c"; return 0; fi
  _hook_patch | awk -v cwd="$(_hook_cwd)" -v target="$target" '
    /^\*\*\* (Add|Update) File: / {
      p = $0; sub(/^\*\*\* (Add|Update) File: /, "", p)
      if (p !~ /^\//) p = cwd "/" p
      on = (p == target); next
    }
    /^\*\*\* Move to: / {
      p = $0; sub(/^\*\*\* Move to: /, "", p)
      if (p !~ /^\//) p = cwd "/" p
      if (p == target) on = 1; next
    }
    /^\*\*\* / { on = 0; next }
    on && /^\+/ { print substr($0, 2) }'
}
