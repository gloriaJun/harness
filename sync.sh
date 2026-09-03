#!/usr/bin/env bash
# One-way sync: <repo>/claude/ -> ~/.claude/
#
# Ownership rules:
#   - AGENTS.md                       : assembled at ~/.claude root from
#                                       instructions/shared/*.md (shared body)
#   - CLAUDE.md                       : stub: "@AGENTS.md" import + claude-only.md
#   - instructions/, hooks/, agents/  : wholly owned -> full mirror (rsync --delete)
#   - skills/                         : shared namespace. Only "g-*" entries are
#                                       managed here. "l-*" belongs to the company
#                                       repo; anything else is unmanaged (warn only).
#   - settings.json                   : only the .hooks and .statusLine keys are
#                                       owned (merged from claude/settings.*.json)
#   - settings.mcpServers.json        : source of truth for user-scope MCP
#                                       servers; applied by bootstrap.sh via the
#                                       claude CLI, drift-checked here (Claude
#                                       reads them from ~/.claude.json only)
#   - <repo>/ccstatusline/            : rendered to ~/.config/ccstatusline/
#                                       ({{HOME}} placeholder substituted)
#
# Usage: sync.sh [--dry-run]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/claude"
DEST="$HOME/.claude"

OWNED_DIRS=(instructions hooks agents)
SKILL_PREFIX="g-"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

RSYNC_OPTS=(-a --delete)
if [[ "$DRY_RUN" -eq 1 ]]; then
  RSYNC_OPTS+=(-n)
fi

log()  { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] $*"
  else
    "$@"
  fi
}

# Guards: never operate outside the expected destination
if [[ -z "${HOME:-}" || "$DEST" != "$HOME/.claude" ]]; then
  echo "ABORT: unexpected DEST '$DEST'" >&2
  exit 1
fi
if [[ ! -d "$SRC" ]]; then
  echo "ABORT: source '$SRC' not found" >&2
  exit 1
fi

run mkdir -p "$DEST"

# Remove a legacy symlink at a managed destination path so we never
# write through it into another repo (symlink-era leftovers).
clear_symlink() {
  local path="$1"
  if [[ -L "$path" ]]; then
    warn "replacing legacy symlink: $path -> $(readlink "$path")"
    run rm "$path"
  fi
}

# 1. AGENTS.md = shared fragments (sorted); CLAUDE.md = stub that @imports it
#    and appends claude-only.md. Budget: warn when the loaded total exceeds
#    14000 chars (~3,500 tok, definition-files.md).
CLAUDE_BUDGET=14000
clear_symlink "$DEST/AGENTS.md"
clear_symlink "$DEST/CLAUDE.md"
assemble_agents_md() {
  local f
  for f in "$SRC/instructions/shared/"*.md; do
    [[ -f "$f" ]] || { warn "assembly source missing: $f"; continue; }
    cat "$f"
    printf '\n'
  done
}
assemble_claude_md() {
  # Relative import resolves against the importing file, i.e. ~/.claude/.
  printf '@AGENTS.md\n\n'
  if [[ -f "$SRC/claude-only.md" ]]; then
    cat "$SRC/claude-only.md"
    printf '\n'
  else
    warn "assembly source missing: $SRC/claude-only.md"
  fi
}
agents_size="$(assemble_agents_md | wc -c | tr -d ' ')"
claude_size="$(assemble_claude_md | wc -c | tr -d ' ')"
loaded_size=$(( agents_size + claude_size ))
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "[dry-run] assemble instructions/shared/*.md -> $DEST/AGENTS.md (${agents_size} chars)"
  log "[dry-run] assemble @AGENTS.md + claude-only.md -> $DEST/CLAUDE.md (${claude_size} chars, ${loaded_size} loaded)"
else
  tmp_agents="$(mktemp)"
  assemble_agents_md > "$tmp_agents"
  mv "$tmp_agents" "$DEST/AGENTS.md"
  tmp_claude="$(mktemp)"
  assemble_claude_md > "$tmp_claude"
  mv "$tmp_claude" "$DEST/CLAUDE.md"
fi
if (( loaded_size > CLAUDE_BUDGET )); then
  warn "CLAUDE.md loads ${loaded_size} chars (AGENTS.md + claude-only.md) > budget ${CLAUDE_BUDGET}"
fi

# 2. Wholly owned dirs: full mirror. A top-level dir that disappeared from
#    the repo is NOT auto-deleted (likely a mistake) - warn instead.
for d in "${OWNED_DIRS[@]}"; do
  if [[ -d "$SRC/$d" ]]; then
    clear_symlink "$DEST/$d"
    extra_opts=()
    # shared/ fragments only feed the CLAUDE.md/AGENTS.md assembly; the live
    # tree has no consumer for standalone copies.
    [[ "$d" == "instructions" ]] && extra_opts=(--exclude=shared/)
    run rsync "${RSYNC_OPTS[@]}" "${extra_opts[@]}" "$SRC/$d/" "$DEST/$d/"
  elif [[ -e "$DEST/$d" ]]; then
    warn "owned dir '$d' exists in $DEST but not in repo - remove it manually if intended"
  fi
done

# 3. Skills: install/update g-* entries (per-entry mirror)
if [[ -d "$SRC/skills" ]]; then
  run mkdir -p "$DEST/skills"
  for src_skill in "$SRC/skills/$SKILL_PREFIX"*/; do
    [[ -d "$src_skill" ]] || continue
    name="$(basename "$src_skill")"
    clear_symlink "$DEST/skills/$name"
    run rsync "${RSYNC_OPTS[@]}" "$src_skill" "$DEST/skills/$name/"
  done
fi

# 4. Skills: orphan cleanup, strictly scoped to our prefix
if [[ -d "$DEST/skills" ]]; then
  for dest_skill in "$DEST/skills/$SKILL_PREFIX"*/; do
    [[ -d "$dest_skill" ]] || continue
    name="$(basename "$dest_skill")"
    # belt-and-suspenders: only ever delete inside skills/ with our prefix
    [[ "$name" == "$SKILL_PREFIX"* ]] || continue
    if [[ ! -d "$SRC/skills/$name" ]]; then
      log "removing orphan skill: skills/$name"
      run rm -rf "${DEST:?}/skills/${name:?}"
    fi
  done

  # 5. Report unmanaged entries (no g-/l- prefix), except third-party skills
  #    declared in external.json (installed by bootstrap.sh on purpose)
  EXTERNAL_DIRS=""
  if [[ -f "$REPO_DIR/external.json" ]] && command -v jq >/dev/null 2>&1; then
    EXTERNAL_DIRS="$(jq -r '.skills[].dir' "$REPO_DIR/external.json" 2>/dev/null | tr '\n' ' ')"
  fi
  for entry in "$DEST/skills/"*/; do
    [[ -d "$entry" ]] || continue
    name="$(basename "$entry")"
    if [[ "$name" != g-* && "$name" != l-* ]]; then
      [[ " $EXTERNAL_DIRS " == *" $name "* ]] && continue
      warn "unmanaged skill (no g-/l- prefix): skills/$name"
    fi
  done
fi

# 6. Hooks config: merge the repo-managed "hooks" key into live settings.json.
#    Only .hooks is owned; runtime keys (enabledPlugins, marketplaces, ...) are
#    preserved. settings.hooks.json itself is never copied to $DEST.
HOOKS_SRC="$SRC/settings.hooks.json"
SETTINGS="$DEST/settings.json"
if [[ -f "$HOOKS_SRC" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not found - hooks config NOT merged into settings.json"
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] merge $HOOKS_SRC -> $SETTINGS (.hooks key only)"
  else
    tmp="$(mktemp)"
    if [[ -f "$SETTINGS" ]]; then
      jq --slurpfile h "$HOOKS_SRC" '.hooks = $h[0]' "$SETTINGS" > "$tmp"
    else
      jq -n --slurpfile h "$HOOKS_SRC" '{hooks: $h[0]}' > "$tmp"
    fi
    mv "$tmp" "$SETTINGS"
    log "merged hooks config into settings.json"
  fi
fi

# 7. Statusline config: merge the repo-managed "statusLine" key into live
#    settings.json, same ownership model as the hooks key.
STATUSLINE_SRC="$SRC/settings.statusline.json"
if [[ -f "$STATUSLINE_SRC" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not found - statusLine config NOT merged into settings.json"
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] merge $STATUSLINE_SRC -> $SETTINGS (.statusLine key only)"
  else
    tmp="$(mktemp)"
    if [[ -f "$SETTINGS" ]]; then
      jq --slurpfile s "$STATUSLINE_SRC" '.statusLine = $s[0]' "$SETTINGS" > "$tmp"
    else
      jq -n --slurpfile s "$STATUSLINE_SRC" '{statusLine: $s[0]}' > "$tmp"
    fi
    mv "$tmp" "$SETTINGS"
    log "merged statusLine config into settings.json"
  fi
fi

# 8. Permissions config: merge the repo-managed "permissions" key into live
#    settings.json, same ownership model as the hooks key.
PERMISSIONS_SRC="$SRC/settings.permissions.json"
if [[ -f "$PERMISSIONS_SRC" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not found - permissions config NOT merged into settings.json"
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] merge $PERMISSIONS_SRC -> $SETTINGS (.permissions key only)"
  else
    tmp="$(mktemp)"
    if [[ -f "$SETTINGS" ]]; then
      jq --slurpfile p "$PERMISSIONS_SRC" '.permissions = $p[0]' "$SETTINGS" > "$tmp"
    else
      jq -n --slurpfile p "$PERMISSIONS_SRC" '{permissions: $p[0]}' > "$tmp"
    fi
    mv "$tmp" "$SETTINGS"
    log "merged permissions config into settings.json"
  fi
fi

# 9. MCP servers: claude/settings.mcpServers.json is the source of truth,
#    but Claude Code reads user-scope MCP servers ONLY from ~/.claude.json
#    (docs: code.claude.com/docs/en/mcp.md#user-scope); settings.json has no
#    mcpServers key. ~/.claude.json also carries runtime state, so sync
#    never writes it - bootstrap.sh applies missing entries via
#    `claude mcp add-json --scope user`. Here: drift check only.
MCPSERVERS_SRC="$SRC/settings.mcpServers.json"
CLAUDE_JSON="$HOME/.claude.json"
if [[ -f "$MCPSERVERS_SRC" ]] && command -v jq >/dev/null 2>&1; then
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    if ! jq -e --arg n "$name" '.mcpServers | has($n)' "$CLAUDE_JSON" >/dev/null 2>&1; then
      warn "mcp server '$name' declared but not installed - run ./bootstrap.sh"
    fi
  done < <(jq -r '.mcpServers // {} | to_entries[] | select(.value.disabled != true) | .key' "$MCPSERVERS_SRC")
fi

# 10. ccstatusline app config: render into ~/.config/ccstatusline. The repo
#    copy keeps a {{HOME}} placeholder (no hardcoded username); substitute it
#    at install time. The widget script is copied verbatim, executable.
CCS_SRC="$REPO_DIR/ccstatusline"
CCS_DEST="$HOME/.config/ccstatusline"
if [[ -d "$CCS_SRC" ]]; then
  run mkdir -p "$CCS_DEST"
  clear_symlink "$CCS_DEST/settings.json"
  clear_symlink "$CCS_DEST/worktree-widget.sh"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] render $CCS_SRC/settings.json -> $CCS_DEST/settings.json ({{HOME}} substituted)"
    log "[dry-run] install $CCS_SRC/worktree-widget.sh -> $CCS_DEST/worktree-widget.sh"
  else
    tmp_ccs="$(mktemp)"
    sed "s|{{HOME}}|$HOME|g" "$CCS_SRC/settings.json" > "$tmp_ccs"
    mv "$tmp_ccs" "$CCS_DEST/settings.json"
    install -m 0755 "$CCS_SRC/worktree-widget.sh" "$CCS_DEST/worktree-widget.sh"
    log "installed ccstatusline config"
  fi
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "sync dry-run complete: $SRC -> $DEST (nothing written)"
else
  log "sync complete: $SRC -> $DEST"
fi
