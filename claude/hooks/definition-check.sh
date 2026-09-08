#!/usr/bin/env bash
# PostToolUse(Write|Edit): mechanical floor for definition files.
# Enforces the checkable rules from definition-files.md and skill-authoring.md.
# Non-mechanical rules (orchestrator quality, persona fit) stay instruction-level.
set -euo pipefail

input="$(cat)"
source "$(dirname "${BASH_SOURCE[0]}")/hook-input.sh"

problems=""
check_file() {
local file="$1" budget type size hangul claude_root assembled frag
# Scope and per-type budgets (chars; tokens ~= chars/4). Non-matches pass.
# Order matters: templates/ must match before the generic references/ pattern.
case "$file" in
  */claude/CLAUDE.md|"$HOME/.claude/CLAUDE.md"|"$HOME/.claude/AGENTS.md") budget=14000; type="assembled-global" ;;
  */instructions/shared/*.md)                     budget=5000;  type="shared-fragment" ;;
  */claude/claude-only.md)                        budget=5000;  type="claude-only" ;;
  */instructions/references/templates/*.md)       budget=9000;  type="template" ;;
  */instructions/references/*.md)                 budget=5000;  type="reference" ;;
  */skills/*/SKILL.md)                            budget=3000;  type="SKILL.md" ;;
  */skills/*/steps/*.md)                          budget=6000;  type="step" ;;
  */skills/*/references/*.md)                     budget=5000;  type="skill-reference" ;;
  */agents/*.md)                                  budget=2000;  type="agent" ;;
  # Any other CLAUDE.md / AGENTS.md / SKILL.md (outside the grimoire layout):
  # English-only check only; size budgets are grimoire policy (budget=0 skips).
  */CLAUDE.md|*/AGENTS.md|*/SKILL.md)             budget=0;     type="generic-definition" ;;
  *) return 0 ;;
esac
[[ -f "$file" ]] || return 0

size="$(wc -c < "$file" | tr -d ' ')"
if (( budget > 0 && size > budget )); then
  problems+="- size ${size} chars > budget ${budget} for ${type}. Split or trim per instructions/references/definition-files.md, or justify the overage in the commit body.\n"
fi

# English-only policy. Hangul is allowed only as quoted examples or template
# skeleton labels inside code fences - verify each flagged line against that
# exception before dismissing.
hangul="$(perl -CSD -ne 'print "$.:$_" if /\p{Hangul}/' "$file" 2>/dev/null | head -5 || true)"
if [[ -n "$hangul" ]]; then
  problems+="- Hangul found (English-only policy; allowed only as quoted examples or fenced template labels):\n${hangul}\n"
fi

if [[ "$type" == "SKILL.md" ]]; then
  grep -q '^```mermaid' "$file" \
    || problems+="- no mermaid diagram (required by instructions/references/skill-authoring.md).\n"
  [[ -f "$(dirname "$file")/README.md" ]] \
    || problems+="- no README.md next to SKILL.md (required by instructions/references/skill-authoring.md).\n"
fi

# Loaded CLAUDE.md budget: per-fragment compliance does not guarantee the
# loaded total. Mirrors sync.sh: 12 chars for the `@AGENTS.md` stub line, then
# each file + one newline.
if [[ "$type" == "shared-fragment" || "$type" == "claude-only" ]]; then
  if [[ "$type" == "shared-fragment" ]]; then
    claude_root="$(cd "$(dirname "$file")/../.." && pwd)"
  else
    claude_root="$(cd "$(dirname "$file")" && pwd)"
  fi
  # claude-only.md absent (e.g. the live ~/.claude mirror): repo-only check, skip.
  if [[ -f "$claude_root/claude-only.md" ]]; then
    assembled=12
    for frag in "$claude_root/instructions/shared/"*.md "$claude_root/claude-only.md"; do
      [[ -f "$frag" ]] || continue
      assembled=$(( assembled + $(wc -c < "$frag") + 1 ))
    done
    if (( assembled > 14000 )); then
      problems+="- CLAUDE.md would load ${assembled} chars (AGENTS.md + claude-only.md) > budget 14000. Apply one-in-one-out per instructions/references/definition-files.md, or justify the overage in the commit body.\n"
    fi
  fi
fi

}

while IFS= read -r f; do
  problems=""
  check_file "$f"
  if [[ -n "$problems" ]]; then
    {
      echo "definition-check: $f"
      printf '%b' "$problems"
      echo "Fix now, or state the justification explicitly before proceeding."
    } >&2
    status=2
  fi
done < <(hook_files)
exit "${status:-0}"
