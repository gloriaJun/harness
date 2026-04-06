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

# --- generate_agents_md: concatenate claude/*.md into AGENTS.md ---
generate_agents_md() {
    local output="$CODEX_HOME/AGENTS.md"

    if $DRY_RUN; then
        dry "Generate $output from PRINCIPLES.md + RULES.md + FLAGS.md"
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

    for f in PRINCIPLES.md RULES.md FLAGS.md; do
        if [ -f "$HARNESS_DIR/claude/$f" ]; then
            echo "---" >> "$output"
            echo "" >> "$output"
            cat "$HARNESS_DIR/claude/$f" >> "$output"
            echo "" >> "$output"
        fi
    done

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

# --- 1. Claude Code: custom instruction files (non-SuperClaude) ---
echo "--- Claude Code: custom instruction files ---"
for f in "$HARNESS_DIR"/claude/*.md; do
    [ -e "$f" ] || continue
    fname="$(basename "$f")"
    safe_link "$f" "$CLAUDE_HOME/$fname"
done

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

# --- 4. Codex CLI: rules ---
echo ""
echo "--- Codex CLI: rules ---"
if [ -d "$CODEX_HOME" ]; then
    mkdir -p "$CODEX_HOME/rules" 2>/dev/null || true
    safe_link "$HARNESS_DIR/codex/rules/default.rules" "$CODEX_HOME/rules/default.rules"
else
    skip "Codex home not found ($CODEX_HOME)"
fi

# --- 5. Codex CLI: generate AGENTS.md ---
echo ""
echo "--- Codex CLI: AGENTS.md ---"
if [ -d "$CODEX_HOME" ]; then
    generate_agents_md
else
    skip "Codex home not found ($CODEX_HOME)"
fi

# --- 6. Plugin info ---
show_plugin_info

echo ""
echo "=== Setup complete ==="
if $DRY_RUN; then
    echo -e "${YELLOW}Re-run without --dry-run to apply changes.${NC}"
fi
