#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="/home/vscode/.claude"
BASHRC="/home/vscode/.bashrc"

mkdir -p "$CLAUDE_DIR"
mkdir -p "$REPO_ROOT/workspace"

if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
  cp "$REPO_ROOT/.devcontainer/claude-user-settings.json" "$CLAUDE_DIR/settings.json"
fi

chmod +x "$REPO_ROOT/scripts/claude-bypass" "$REPO_ROOT/scripts/claude-auto"

if command -v sudo >/dev/null; then
  sudo ln -sf "$REPO_ROOT/scripts/claude-bypass" /usr/local/bin/claude-bypass
  sudo ln -sf "$REPO_ROOT/scripts/claude-auto" /usr/local/bin/claude-auto
fi

touch "$BASHRC"
echo "source $REPO_ROOT/scripts/bash_preference.bash" >> "$BASHRC"

npm install -D @playwright/test
npx playwright install --with-deps chromium

echo "Claude Code devcontainer post-create setup complete."
echo "Open a terminal in workspace/ and run: claude"
echo "For bypass mode inside the container, run: claude-bypass"
