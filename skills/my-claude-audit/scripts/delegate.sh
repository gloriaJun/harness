#!/bin/bash
# Delegates prompt to external CLI tool with per-tool invocation
# Usage: delegate.sh <cli-tool-name> <prompt-file> [timeout]
# Returns: stdout text, exit 0 on success, exit 1 on failure

set -euo pipefail

CLI_TOOL="$1"
PROMPT_FILE="$2"
TIMEOUT="${3:-120}"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: Prompt file not found: $PROMPT_FILE" >&2
    exit 1
fi

if ! command -v "$CLI_TOOL" &>/dev/null; then
    echo "Error: $CLI_TOOL not found in PATH" >&2
    exit 1
fi

invoke_tool() {
    local tool="$1"
    local file="$2"
    local t="$3"

    case "$tool" in
        gemini)
            timeout "$t" gemini < "$file" 2>/dev/null
            ;;
        openai)
            timeout "$t" openai api chat.completions.create \
                -m gpt-4o -M "$(cat "$file")" 2>/dev/null
            ;;
        codex)
            timeout "$t" codex "$(cat "$file")" 2>/dev/null
            ;;
        *)
            local result
            result=$(timeout "$t" "$tool" < "$file" 2>/dev/null) || true
            if [ -n "$result" ]; then
                echo "$result"
                return 0
            fi
            result=$(timeout "$t" "$tool" --prompt "$file" 2>/dev/null) || true
            if [ -n "$result" ]; then
                echo "$result"
                return 0
            fi
            return 1
            ;;
    esac
}

RESULT=$(invoke_tool "$CLI_TOOL" "$PROMPT_FILE" "$TIMEOUT") || true
if [ -n "$RESULT" ]; then
    echo "$RESULT"
    exit 0
fi

exit 1
