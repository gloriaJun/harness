# Step 4: Dry Run (Default)

**Always show a dry-run preview first.** Never delete without showing what will be removed.

For each selected category, list:
- Number of files to be deleted
- Total size to be freed
- Sample file paths (up to 5)

## Size Calculation

파일 목록을 먼저 수집한 뒤 `du -ch`로 합산한다. `xargs du -ch`는 파일 수가 많을 때 중복 계산이 발생하므로 아래 패턴을 사용한다:

```bash
FILES=$(find <path> -type f -mtime +<days> 2>/dev/null)
COUNT=$(echo "$FILES" | wc -l | tr -d ' ')
SIZE=$(echo "$FILES" | xargs du -ch 2>/dev/null | tail -1 | cut -f1)
```

## Output Format

```
=== Dry Run Preview ===

[C9] Shell snapshots: 128 files, 28.5M to free
  ~/.claude/shell-snapshots/abc123.json (2025-06-12)
  ~/.claude/shell-snapshots/def456.json (2025-06-15)
  ... and 126 more

[C3] Project sessions: 465 files, 214M to free
  ~/.claude/projects/-*-GitHubLine-one/*.jsonl
  ... and 463 more
  ※ 빈 프로젝트 디렉토리(memory/ 없는 것)도 함께 제거됨

[C7] History: 1,035 entries to drop, 603 entries to keep
  scripts/truncate-history.sh <days> 로 실행

[X1] Worktrees: 3 worktrees to remove, 520.0M to free
  ~/.codex/worktrees/0dc9/ (branch: feature/foo, last modified: 2025-11-03)
  ~/.codex/worktrees/3741/ (branch: fix/bar, last modified: 2025-12-20)
  ~/.codex/worktrees/7006/ (branch: refactor/baz, last modified: 2026-01-15)

[M1] Memory issues: 4 items
  ORPHANED     GitHub-grimoire          → /Users/.../GitHub/grimoire
  ORPHANED     GitHubLine-one          → /Users/.../GitHubLine/one
  BROKEN_LINK  GitHubPrivate-...       → user_github_multi_account.md
  DUPLICATE    GitHub-grimoire          → same repo as GitHubPrivate-grimoire

Total: 548.5M to be freed

Proceed with cleanup? [y/N]
```
