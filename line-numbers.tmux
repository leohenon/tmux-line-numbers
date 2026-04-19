#!/usr/bin/env bash
# tmux-line-numbers - TPM plugin that shows relative line numbers in copy-mode-vi.
#
# When you enter copy-mode, a narrow pane appears on the left with relative line
# numbers (like vim's 'set relativenumber'). Numbers update as you move the cursor,
# so you can see exactly how many lines to jump with 5k, 12j, etc.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$CURRENT_DIR/scripts"

# Register the hook that fires when a pane enters or exits copy-mode.
tmux set-hook -g pane-mode-changed "run-shell '$SCRIPTS_DIR/pane-mode-changed.sh #{pane_id} #{pane_in_mode}'"
