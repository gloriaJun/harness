#!/usr/bin/env bash
# Audits ~/.claude/projects/*/memory/ for cleanup candidates.
# Outputs structured lines: TYPE|PROJECT_DIR|DETAIL
#
# Types:
#   ORPHANED      - memory/ exists but corresponding local path does not
#   BROKEN_LINK   - MEMORY.md references a file that doesn't exist in memory/
#   DUPLICATE     - another project dir has memory/ for the same apparent repo
#   OK            - no issues detected
#
# Path reconstruction:
#   Claude Code sanitizes /Users/<u>/Documents/<workspace>/<repo>
#                      → -Users-<u>-Documents-<workspace>-<repo>
#   We split at a fixed depth of 4 segments (Users/user/Documents/workspace)
#   and treat the remainder as the repo name (which may contain hyphens).

PROJECTS_DIR="${HOME}/.claude/projects"

reconstruct_path() {
  local proj_name="$1"
  # Split on hyphen; leading '-' produces empty first element
  IFS='-' read -ra parts <<< "$proj_name"
  # parts: [0]="" [1]="Users" [2]=<user> [3]="Documents" [4]=<workspace> [5..]=repo segments
  if [ "${#parts[@]}" -lt 5 ]; then
    echo ""
    return
  fi
  local base="/${parts[1]}/${parts[2]}/${parts[3]}/${parts[4]}"
  if [ "${#parts[@]}" -gt 5 ]; then
    # Rejoin remaining parts with hyphens to restore repo name
    local repo
    repo=$(printf '%s-' "${parts[@]:5}")
    repo="${repo%-}"  # strip trailing hyphen
    echo "${base}/${repo}"
  else
    echo "$base"
  fi
}

declare -A seen_repos

for mem_dir in "${PROJECTS_DIR}"/*/memory; do
  [ -d "$mem_dir" ] || continue

  proj_dir=$(dirname "$mem_dir")
  proj_name=$(basename "$proj_dir")
  local_path=$(reconstruct_path "$proj_name")
  issues=0

  # 1. Orphaned: reconstructed local path doesn't exist
  if [ -n "$local_path" ] && [ ! -d "$local_path" ]; then
    echo "ORPHANED|${proj_name}|${local_path}"
    issues=$((issues + 1))
  fi

  # 2. Broken links in MEMORY.md (portable grep, no -P flag)
  if [ -f "${mem_dir}/MEMORY.md" ]; then
    while IFS= read -r link; do
      [[ "$link" == http* ]] && continue
      [[ "$link" == \#* ]] && continue
      link="${link%%#*}"   # strip anchor
      [ -z "$link" ] && continue
      if [ ! -f "${mem_dir}/${link}" ]; then
        echo "BROKEN_LINK|${proj_name}|${link}"
        issues=$((issues + 1))
      fi
    done < <(grep -oE '\[[^]]+\]\([^)]+\)' "${mem_dir}/MEMORY.md" 2>/dev/null \
               | sed 's/.*](\([^)]*\)).*/\1/')
  fi

  # 3. Duplicate: same reconstructed path seen in a prior project dir
  if [ -n "$local_path" ]; then
    if [ -n "${seen_repos[$local_path]+_}" ]; then
      echo "DUPLICATE|${proj_name}|same repo as ${seen_repos[$local_path]}"
      issues=$((issues + 1))
    else
      seen_repos["$local_path"]="$proj_name"
    fi
  fi

  if [ "$issues" -eq 0 ]; then
    echo "OK|${proj_name}|"
  fi
done
