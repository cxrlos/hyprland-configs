#!/usr/bin/env bash
# Run the ratatoist TUI in its own floating Alacritty (Super+Shift+T).
set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

if ! command -v ratatoist >/dev/null 2>&1; then
    echo "ratatoist not found in PATH" >&2
    read -r -p "Press Enter to close..."
    exit 1
fi

exec ratatoist
