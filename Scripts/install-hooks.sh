#!/bin/bash
set -e

CC_PET_DIR="$HOME/.cc-pet"
HOOK_JS="$CC_PET_DIR/hook.js"
SETTINGS="$HOME/.claude/settings.json"

mkdir -p "$CC_PET_DIR"

# Copy hook.js
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/hook.js" "$HOOK_JS"
chmod +x "$HOOK_JS"

echo "Hook script installed to $HOOK_JS"
echo "To register with Claude Code, use the 'Install Hook' button in cc-pet settings."
echo "Or manually add to $SETTINGS"
