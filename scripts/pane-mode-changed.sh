#!/usr/bin/env bash
set -euo pipefail

PANE_ID="${1:-}"
IN_MODE="${2:-}"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[ -n "$PANE_ID" ] || exit 1

if [ "$IN_MODE" = "1" ]; then
  PANE_MODE=$(tmux display -p -t "$PANE_ID" '#{pane_mode}' 2>/dev/null || true)
  if [ "$PANE_MODE" = "copy-mode" ]; then
    LN_PANE=$(tmux show-option -p -t "$PANE_ID" -v @line_numbers_pane 2>/dev/null || true)
    if [ -n "$LN_PANE" ]; then
      exit 0
    fi
  fi
fi

exec "$SCRIPTS_DIR/on-mode-changed.sh" "$PANE_ID" "$IN_MODE"
