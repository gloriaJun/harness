#!/usr/bin/env bash
# setup.sh — Create symlinks from $HOME config dirs to harness repo
# Usage:
#   ./setup.sh              Full setup (symlinks + AGENTS.md + plugin info)
#   ./setup.sh --dry-run    Preview changes without modifying anything
#   ./setup.sh --regenerate Regenerate ~/.codex/AGENTS.md only
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
CODEX_HOME="$HOME/.codex"
DRY_RUN=false
REGENERATE_ONLY=false
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# --- Parse flags ---
for arg in "$@"; do
    case "$arg" in
        --dry-run)    DRY_RUN=true ;;
        --regenerate) REGENERATE_ONLY=true ;;
        --help|-h)
            head -5 "$0" | tail -4 | sed 's/^# //'
            exit 0
            ;;
    esac
done

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
skip() { echo -e "${DIM}[SKIP]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
dry()  { echo -e "${YELLOW}[DRY]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# --- safe_link: backup existing file, then create symlink ---
# Idempotent — updates existing symlinks, backs up regular files
safe_link() {
    local src="$1"
    local dst="$2"

    if [ ! -e "$src" ] && [ ! -L "$src" ]; then
        skip "Source not found: $src"
        return
    fi

    if $DRY_RUN; then
        if [ -L "$dst" ]; then
            local current_target
            current_target="$(readlink "$dst")"
            if [ "$current_target" = "$src" ]; then
                skip "$dst (already correct)"
            else
                dry "Update symlink: $dst -> $src (was $current_target)"
            fi
        elif [ -e "$dst" ]; then
            dry "Backup $dst -> ${dst}.backup.${TIMESTAMP}, then symlink"
        else
            dry "Create symlink: $dst -> $src"
        fi
        return
    fi

    if [ -L "$dst" ]; then
        local current_target
        current_target="$(readlink "$dst")"
        if [ "$current_target" = "$src" ]; then
            skip "$dst (already linked)"
            return
        fi
        ln -sfn "$src" "$dst"
        log "Updated: $dst -> $src"
    elif [ -e "$dst" ]; then
        local backup="${dst}.backup.${TIMESTAMP}"
        mv "$dst" "$backup"
        ln -sfn "$src" "$dst"
        log "Backed up & linked: $dst"
    else
        mkdir -p "$(dirname "$dst")"
        ln -sfn "$src" "$dst"
        log "Created: $dst -> $src"
    fi
}

# --- generate_agents_md: merge claude instructions into AGENTS.md ---
# Combines CLAUDE.md + instructions/*.md so Codex CLI follows the same rules
generate_agents_md() {
    local output="$CODEX_HOME/AGENTS.md"
    local claude_md="$HARNESS_DIR/claude/CLAUDE.md"
    local instructions_dir="$HARNESS_DIR/claude/instructions"

    if $DRY_RUN; then
        dry "Generate $output from CLAUDE.md + instructions/*.md"
        return
    fi

    mkdir -p "$CODEX_HOME"
    cat > "$output" << 'HEADER'
# Codex CLI Instructions
# Auto-generated from harness/claude/ — DO NOT EDIT DIRECTLY
# Run: setup.sh --regenerate to update
HEADER
    echo "# Generated: $(date +%Y-%m-%d)" >> "$output"
    echo "" >> "$output"

    # Include CLAUDE.md (strip @import lines — they are inlined below)
    if [ -f "$claude_md" ]; then
        grep -v '^@instructions/' "$claude_md" >> "$output"
        echo "" >> "$output"
    fi

    # Inline all instruction files
    if [ -d "$instructions_dir" ]; then
        for f in "$instructions_dir"/*.md; do
            [ -e "$f" ] || continue
            echo "---" >> "$output"
            echo "" >> "$output"
            cat "$f" >> "$output"
            echo "" >> "$output"
        done
    fi

    log "Generated: $output ($(wc -c < "$output" | tr -d ' ') bytes)"
}

# --- show_plugin_info: display plugin manifest for manual setup ---
show_plugin_info() {
    local plugins_file="$HARNESS_DIR/plugins.json"
    if [ ! -f "$plugins_file" ]; then
        skip "plugins.json not found"
        return
    fi

    echo ""
    info "=== Plugin Manifest ==="
    info "The following plugins are tracked in plugins.json."
    info "Configure them in ~/.claude/settings.json under pluginMarketplaces and enabledPlugins."
    echo ""

    # Parse and display marketplaces
    if command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('$plugins_file') as f:
    data = json.load(f)

claude = data.get('claude', {})
print('  Claude Code Marketplaces:')
for mp in claude.get('marketplaces', []):
    print(f\"    - {mp['name']}: {mp['source']}\")
    print(f\"      {mp['description']}\")
print()
print('  Enabled Plugins:')
for p in claude.get('plugins', []):
    print(f'    - {p}')
print()

codex = data.get('codex', {})
if codex.get('mcp_servers'):
    print('  Codex MCP Servers:')
    for s in codex['mcp_servers']:
        print(f'    - {s}')
"
    else
        info "Install python3 to see formatted plugin list, or view plugins.json directly."
    fi
}

# =====================
# Main
# =====================

if $REGENERATE_ONLY; then
    echo "=== Regenerating AGENTS.md ==="
    generate_agents_md
    exit 0
fi

echo "=== Harness Setup ==="
echo "Repo: $HARNESS_DIR"
if $DRY_RUN; then
    echo -e "${YELLOW}(dry run — no changes will be made)${NC}"
fi
echo ""

# --- 0. RTK binary check ---
echo "--- RTK binary check ---"
if ! command -v rtk &>/dev/null; then
    warn "rtk not found. Install: cargo install rtk"
else
    RTK_VER="$(rtk --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    if [ -n "$RTK_VER" ]; then
        RTK_MAJOR="$(echo "$RTK_VER" | cut -d. -f1)"
        RTK_MINOR="$(echo "$RTK_VER" | cut -d. -f2)"
        if [ "$RTK_MAJOR" -eq 0 ] && [ "$RTK_MINOR" -lt 23 ]; then
            warn "rtk $RTK_VER is too old (need >= 0.23.0). Upgrade: cargo install rtk"
        else
            info "rtk $RTK_VER OK"
        fi
    else
        warn "Could not determine rtk version"
    fi
fi
echo ""

# --- 1. Claude Code: custom instruction files ---
echo "--- Claude Code: custom instruction files ---"
for f in "$HARNESS_DIR"/claude/*.md; do
    [ -e "$f" ] || continue
    fname="$(basename "$f")"
    safe_link "$f" "$CLAUDE_HOME/$fname"
done

# --- 1b. Claude Code: instructions directory ---
if [ -d "$HARNESS_DIR/claude/instructions" ]; then
    safe_link "$HARNESS_DIR/claude/instructions" "$CLAUDE_HOME/instructions"
fi

# --- 1c. Claude Code: settings.json (source of truth in harness) ---
if [ -f "$HARNESS_DIR/claude/settings.json" ]; then
    safe_link "$HARNESS_DIR/claude/settings.json" "$CLAUDE_HOME/settings.json"
fi

# --- 2. Claude Code: hooks ---
echo ""
echo "--- Claude Code: hooks ---"
mkdir -p "$CLAUDE_HOME/hooks" 2>/dev/null || true
for f in "$HARNESS_DIR"/hooks/*; do
    [ -e "$f" ] || continue
    fname="$(basename "$f")"
    safe_link "$f" "$CLAUDE_HOME/hooks/$fname"
done

# --- 3. Claude Code: skills ---
echo ""
echo "--- Claude Code: skills ---"
mkdir -p "$CLAUDE_HOME/skills" 2>/dev/null || true
for d in "$HARNESS_DIR"/skills/*/; do
    [ -d "$d" ] || continue
    dname="$(basename "$d")"
    safe_link "$d" "$CLAUDE_HOME/skills/$dname"
done

# --- 4. Claude Code: agents ---
echo ""
echo "--- Claude Code: agents ---"
mkdir -p "$CLAUDE_HOME/agents" 2>/dev/null || true
for f in "$HARNESS_DIR"/agents/*.md; do
    [ -e "$f" ] || continue
    fname="$(basename "$f")"
    safe_link "$f" "$CLAUDE_HOME/agents/$fname"
done

# --- 5. Codex CLI: skills ---
echo ""
echo "--- Codex CLI: skills ---"
if [ -d "$CODEX_HOME" ]; then
    mkdir -p "$CODEX_HOME/skills" 2>/dev/null || true
    for d in "$HARNESS_DIR"/skills/*/; do
        [ -d "$d" ] || continue
        dname="$(basename "$d")"
        safe_link "$d" "$CODEX_HOME/skills/$dname"
    done
else
    skip "Codex home not found ($CODEX_HOME)"
fi

# --- 6. Codex CLI: rules ---
# default.rules is NOT managed by harness — Codex writes session-approved
# commands there automatically. Managing it via symlink would commit internal
# URLs to the repo. Each machine maintains its own ~/.codex/rules/default.rules.

# --- 7. Codex CLI: generate AGENTS.md ---
echo ""
echo "--- Codex CLI: AGENTS.md ---"
if [ -d "$CODEX_HOME" ]; then
    generate_agents_md
else
    skip "Codex home not found ($CODEX_HOME)"
fi

# --- 8. Plugin info ---
show_plugin_info

# --- 9. Claude Code: settings.json hook registration ---
echo ""
echo "--- Claude Code: settings.json hook registration ---"
register_rtk_hook() {
    local settings="$CLAUDE_HOME/settings.json"
    local hook_path="$CLAUDE_HOME/hooks/rtk-rewrite.sh"

    if ! command -v jq &>/dev/null; then
        skip "jq not installed — skipping hook registration"
        return
    fi

    if [ ! -f "$settings" ]; then
        skip "settings.json not found ($settings)"
        return
    fi

    # Check if hook entry already exists
    local already
    already="$(jq -r '
        .hooks.PreToolUse[]?.hooks[]?
        | select(.type == "command" and .command == "'"$hook_path"'")
        | .command
    ' "$settings" 2>/dev/null)"

    if [ -n "$already" ]; then
        skip "rtk hook already registered in settings.json"
        return
    fi

    if $DRY_RUN; then
        dry "Register rtk hook in $settings (matcher: Bash, command: $hook_path)"
        return
    fi

    # Backup before modifying
    cp "$settings" "${settings}.backup.${TIMESTAMP}"

    # Check if .hooks.PreToolUse with Bash matcher exists
    local has_bash_matcher
    has_bash_matcher="$(jq '[.hooks.PreToolUse[]? | select(.matcher == "Bash")] | length > 0' "$settings" 2>/dev/null)"

    if [ "$has_bash_matcher" = "true" ]; then
        # Append to existing Bash matcher's hooks array
        jq --arg cmd "$hook_path" '
            .hooks.PreToolUse = [
                .hooks.PreToolUse[] |
                if .matcher == "Bash" then
                    .hooks += [{"type": "command", "command": $cmd}]
                else . end
            ]
        ' "$settings" > "${settings}.tmp" && mv "${settings}.tmp" "$settings"
    elif [ "$(jq 'has("hooks") and (.hooks | has("PreToolUse"))' "$settings" 2>/dev/null)" = "true" ]; then
        # PreToolUse exists but no Bash matcher — add one
        jq --arg cmd "$hook_path" '
            .hooks.PreToolUse += [
                {"matcher": "Bash", "hooks": [{"type": "command", "command": $cmd}]}
            ]
        ' "$settings" > "${settings}.tmp" && mv "${settings}.tmp" "$settings"
    else
        # Create hooks.PreToolUse from scratch
        jq --arg cmd "$hook_path" '
            .hooks.PreToolUse = [
                {"matcher": "Bash", "hooks": [{"type": "command", "command": $cmd}]}
            ]
        ' "$settings" > "${settings}.tmp" && mv "${settings}.tmp" "$settings"
    fi

    log "Registered rtk hook in settings.json"
}
register_rtk_hook

# --- 10. MCP servers: merge global definitions into ~/.claude.json ---
echo ""
echo "--- MCP servers: global definitions ---"
merge_global_mcp() {
    local mcp_def="$HARNESS_DIR/mcp/global.mcp.json"
    local claude_json="$HOME/.claude.json"

    if [ ! -f "$mcp_def" ]; then
        skip "mcp/global.mcp.json not found"
        return
    fi

    if [ ! -f "$claude_json" ]; then
        skip "~/.claude.json not found"
        return
    fi

    if ! command -v jq &>/dev/null; then
        skip "jq not installed — skipping MCP merge"
        return
    fi

    if $DRY_RUN; then
        local servers
        servers="$(jq -r 'keys[]' "$mcp_def" 2>/dev/null | tr '\n' ', ')"
        dry "Merge MCP servers into ~/.claude.json: ${servers%, }"
        return
    fi

    cp "$claude_json" "${claude_json}.backup.${TIMESTAMP}"

    # Merge: global.mcp.json entries into ~/.claude.json mcpServers (upsert)
    jq --slurpfile mcp "$mcp_def" '
        .mcpServers = ((.mcpServers // {}) * $mcp[0])
    ' "$claude_json" > "${claude_json}.tmp" && mv "${claude_json}.tmp" "$claude_json"

    log "Merged global MCP servers into ~/.claude.json"
}
merge_global_mcp

echo ""
echo "=== Setup complete ==="
if $DRY_RUN; then
    echo -e "${YELLOW}Re-run without --dry-run to apply changes.${NC}"
fi
