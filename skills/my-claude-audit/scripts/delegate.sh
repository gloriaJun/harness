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
            local raw
            raw=$(timeout "$t" openai api chat.completions.create \
                -m gpt-4o -g user "$(cat "$file")" 2>/dev/null) || true
            if [ -n "$raw" ]; then
                echo "$raw" | python3 -c \
                    "import json,sys; d=json.load(sys.stdin); print(d['choices'][0]['message']['content'])" \
                    2>/dev/null
            fi
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
            echo "Error: Both stdin and --prompt methods failed for '$tool'" >&2
            return 1
            ;;
    esac
}

RESULT=$(invoke_tool "$CLI_TOOL" "$PROMPT_FILE" "$TIMEOUT") || true
if [ -n "$RESULT" ]; then
    echo "$RESULT"
    exit 0
fi

echo "Error: '$CLI_TOOL' returned empty output. Ensure the tool is installed and configured correctly." >&2
exit 1
