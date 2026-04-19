#!/usr/bin/env bash
set -euo pipefail

TARGET_PANE="${1:-}"
shift || true

[ -n "$TARGET_PANE" ] || exit 1

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for _ in $(seq 1 120); do
  pane_mode=$(tmux display -p -t "$TARGET_PANE" '#{pane_mode}' 2>/dev/null || true)
  if [ "$pane_mode" = "copy-mode" ]; then
    exec "$SCRIPTS_DIR/render-loop.sh" "$TARGET_PANE" "$@"
  fi
  sleep 0.05
done
