#!/usr/bin/env bash
# PostToolUse(Write|Edit): flag comment blocks over 3 lines in newly written
# code (the per-block cap in tech-stack.md). Checks only the content being
# written, so a file holding older verbose comments does not re-trigger.
set -euo pipefail

input="$(cat)"
source "$(dirname "${BASH_SOURCE[0]}")/hook-input.sh"

status=0
while IFS= read -r file; do
  case "$file" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.vue|*.svelte) ;;
    *) continue ;;
  esac
  content="$(hook_added_content "$file")"
  [[ -n "$content" ]] || continue
  hits="$(printf '%s' "$content" | awk '
    /^[[:space:]]*(\/\/|\*|\/\*)/ { n++; next }
    { if (n>3) print n" line comment block ending at line "NR-1; n=0 }
    END { if (n>3) print n" line comment block at end of content" }
  ')"
  [[ -n "$hits" ]] || continue
  {
    echo "comment block over 3 lines written to $file (tech-stack.md: 1-3 lines per block):"
    printf '%s\n' "$hits" | head -10
    echo "Cut it to 3 lines or delete it. Comment only what the code cannot say."
  } >&2
  status=2
done < <(hook_files)
exit "$status"
