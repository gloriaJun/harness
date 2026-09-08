#!/usr/bin/env bash
# UserPromptSubmit: nudge the next response away from forced-Korean terms the
# previous response used (20-communication.md, Korean terminology rule).
# Silent when the previous response was clean, so the token cost lands only on
# actual drift. Never blocks: stdout on exit 0 is injected as context.
set -euo pipefail

input="$(cat)"
transcript="$(printf '%s' "$input" | jq -r '.transcript_path // empty')"
[[ -n "$transcript" && -f "$transcript" ]] || exit 0

prompt="$(printf '%s' "$input" | jq -r '.user_prompt // .user_prompt_raw // .prompt // empty')"

# The transcript JSONL layout is internal to Claude Code and can change between
# releases, so parse line by line and drop anything that does not fit. Reading
# only the tail keeps this cheap on multi-MB transcripts.
tail_lines="$(tail -n 200 "$transcript" 2>/dev/null || true)"
prev="$(printf '%s\n' "$tail_lines" | jq -Rr '
  fromjson?
  | select(.type? == "assistant")
  | .message?.content? // [] | .[]?
  | select(.type? == "text") | .text? // empty
' 2>/dev/null | tail -n 20 || true)"

if [[ -z "$prev" ]]; then
  # Canary: assistant records exist but nothing parsed out means the layout moved.
  if printf '%s\n' "$tail_lines" | grep -q '"type":"assistant"'; then
    printf 'ko-term-check: no assistant text parsed from %s\n' "$transcript" \
      > "$HOME/.claude/.ko-term-check-drift"
  fi
  exit 0
fi

# Drop fenced blocks and inline code: identifiers are not prose.
prev="$(printf '%s\n' "$prev" | awk '/^[[:space:]]*```/ {f = !f; next} !f')"
prev="$(printf '%s\n' "$prev" | sed 's/`[^`]*`//g')"
# 표면적 is ordinary Korean, not the surface metaphor.
prev="${prev//표면적/}"

# term|replacement. Allowed by decision, never listed here: 산출물, 정합성,
# 하네스, 상속, 계층, 계약.
dict='배선|연결, 설정
게이트|승인 단계
게이팅|사전 검사
관문|검사 지점
표면|실행 경로
관측성|로그 추적
판정|통과 여부
실측|직접 측정
열렸습니다|시작 가능합니다
이깁니다|우선 적용됩니다
매핑|`mapping`
스코프|`scope`
스코핑|`scope`
워크트리|`worktree`
라우팅|`routing`
페이로드|`payload`
사이드카|`sidecar`
앵커|`anchor`
스모크|`smoke test`
프리플라이트|`preflight`
부트스트랩|`bootstrap`
델타|`delta`'

hits=""
count=0
while IFS='|' read -r term repl; do
  [[ -n "$term" ]] || continue
  case "$prev" in *"$term"*) ;; *) continue ;; esac
  # The user owning the term settles it: do not correct their vocabulary.
  case "$prompt" in *"$term"*) continue ;; esac
  hits+="  \"$term\" -> $repl"$'\n'
  count=$((count + 1))
  (( count >= 3 )) && break
done <<< "$dict"

# Hard rule 8 in chat prose: same byte match as emdash-check.sh.
if printf '%s' "$prev" | LC_ALL=C grep -qE $'\xe2\x80\x94|\xe2\x80\x93'; then
  hits+="  em/en dash -> hyphen, colon, or parentheses (hard rule 8)"$'\n'
fi

[[ -n "$hits" ]] || exit 0

cat <<EOF
Style check on the previous response (CLAUDE.md, HOW TO TALK TO ME / hard rule 8):
$hits
Use the right-hand form from this response on. If the term named an actual
identifier (a file, flag, or command), keep it in backticks and ignore this.
EOF
exit 0
