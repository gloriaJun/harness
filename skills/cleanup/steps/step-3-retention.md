# Step 3: Set Retention Period

Ask the user how many days of data to keep:

- Default: **30 days** (files older than 30 days are deleted)
- Option: **0 days** (delete everything in selected categories)
- Option: **Custom** number of days

## Special Rules

- `C7` (history.jsonl): Truncate to keep only last N days of entries, do not delete the file entirely.
  - **timestamp 형식 주의**: `history.jsonl`의 `timestamp` 필드는 ISO 문자열이 아닌 **Unix milliseconds 정수**다.
    예: `{"timestamp": 1775913377966, ...}` — 문자열 비교 불가, 정수 변환 후 처리 필요.
  - 실행 시 `scripts/truncate-history.sh <days>` 스크립트를 사용할 것.
- `X1` (worktrees): Always list each worktree with its branch name and last modified date. Ask for confirmation on each one individually, since worktrees may contain uncommitted work.
- `M1` (Memory audit): 보존 기간이 적용되지 않음. 이슈 유형별로 삭제 여부를 개별 확인한다.
