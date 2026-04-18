# Step 5: Execute Cleanup

Only after user confirms.

## Prerequisites

Read `references/protected-paths.md` and double-check every path against the protected list before deletion.

## Process

1. Delete files matching the retention criteria in each selected category.
2. For directories: use `rm -rf` on individual old items, NOT on the parent directory itself.
3. For `C3` (project sessions): delete only `.jsonl` files, NEVER `memory/` directories. After deletion, remove empty project dirs that have no `memory/` subdir:
   ```bash
   find ~/.claude/projects -name "*.jsonl" -not -path "*/memory/*" -mtime +<days> | xargs rm -f
   find ~/.claude/projects -mindepth 2 -type d -empty -not -name "memory" -delete 2>/dev/null
   find ~/.claude/projects -mindepth 1 -maxdepth 1 -type d | while read dir; do
     [ ! -d "$dir/memory" ] && [ -z "$(ls -A "$dir" 2>/dev/null)" ] && rm -rf "$dir"
   done
   ```
4. For `C7` (history.jsonl): use the script — do NOT inline the truncation logic:
   ```bash
   bash ~/.claude/skills/cleanup/scripts/truncate-history.sh <days>
   ```
5. For `M1` (Memory audit): re-run `scripts/audit-memory.sh` and for each issue:
   - `ORPHANED`: delete the entire `memory/` dir (it has no live project)
   - `BROKEN_LINK`: delete only the missing-referenced file entry from MEMORY.md (edit, not delete)
   - `DUPLICATE`: delete the older/smaller memory dir after confirming with user which to keep
6. For `X1` (worktrees): use `git worktree remove` if inside a git repo, otherwise `rm -rf`.

## Output Format

Report results as each category is cleaned:

```
[C9] Shell snapshots: deleted 128 files, freed 28.5M
[C3] Project sessions: deleted 465 files + 3 empty dirs, freed 214M
[C7] History: truncated (kept=603, dropped=1035)
[M1] Memory: removed 2 orphaned dirs, fixed 1 broken link
[X1] Worktrees: removed 3 worktrees, freed 520.0M
...

Cleanup complete. Total freed: 548.5M
```
