#!/usr/bin/env bash
# PostToolUse(Write|Edit): flag em/en dashes in newly written markdown content
# (hard rule 8: no em dashes in prose, any language). Checks only the content
# being written, so files merely documenting the rule do not re-trigger.
set -euo pipefail

input="$(cat)"
source "$(dirname "${BASH_SOURCE[0]}")/hook-input.sh"

status=0
while IFS= read -r file; do
  [[ "$file" == *.md ]] || continue
  content="$(hook_added_content "$file")"
  [[ -n "$content" ]] || continue
  # Match by UTF-8 bytes (em dash e2 80 94, en dash e2 80 93), locale-independent.
  hits="$(printf '%s' "$content" | LC_ALL=C grep -nE $'\xe2\x80\x94|\xe2\x80\x93' || true)"
  [[ -n "$hits" ]] || continue
  {
    echo "em/en dash written to $file (hard rule 8: no em dashes in prose, any language):"
    printf '%s\n' "$hits" | head -10
    echo "Replace with ' - ' or rewrite the sentence. If this is a deliberate rule-documentation example, leave it and continue."
  } >&2
  status=2
done < <(hook_files)
exit "$status"
