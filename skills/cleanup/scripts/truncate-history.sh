#!/usr/bin/env bash
# Truncates ~/.claude/history.jsonl, keeping entries from the last N days.
# Usage: truncate-history.sh <days>
#
# IMPORTANT: history.jsonl uses Unix milliseconds (integer) for timestamps,
# NOT ISO 8601 strings. Example: {"timestamp": 1775913377966, ...}

set -euo pipefail

DAYS="${1:?Usage: truncate-history.sh <days>}"
HISTORY="${HOME}/.claude/history.jsonl"

if [ ! -f "$HISTORY" ]; then
  echo "history.jsonl not found: $HISTORY"
  exit 0
fi

CUTOFF_MS=$(python3 -c "import time; print(int((time.time() - ${DAYS} * 86400) * 1000))")
TMP="${HISTORY}.tmp.$$"

python3 - <<EOF
import json, sys

cutoff = ${CUTOFF_MS}
kept = []
dropped = 0

with open('${HISTORY}') as f:
    for line in f:
        line = line.rstrip('\n')
        if not line:
            continue
        try:
            d = json.loads(line)
            ts = d.get('timestamp', cutoff + 1)
            if isinstance(ts, (int, float)) and ts < cutoff:
                dropped += 1
            else:
                kept.append(line)
        except Exception:
            # Unparseable lines: keep them (safer)
            kept.append(line)

with open('${TMP}', 'w') as f:
    for line in kept:
        f.write(line + '\n')

print(f'kept={len(kept)}, dropped={dropped}')
EOF

mv "${TMP}" "${HISTORY}"
