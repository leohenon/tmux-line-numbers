#!/usr/bin/env bash
# Called by the pane-mode-changed hook.

PANE_ID="$1"
# This value is `1` if tmux is in a mode, `0` if not.
IN_MODE="$2"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Marker used to find the line-number pane.
MARKER="TMUX_LINE_NUMBERS_FOR"

if [ "$IN_MODE" = "1" ]; then
    # Check this pane is actually in copy-mode (not command mode, etc.).
    PANE_MODE=$(tmux display -p -t "$PANE_ID" '#{pane_mode}' 2>/dev/null)
    if [ "$PANE_MODE" != "copy-mode" ]; then
        exit 0
    fi

    # Don't create a second line-number pane if one already exists.
    EXISTING=$(tmux list-panes -F '#{pane_id} #{pane_start_command}' 2>/dev/null | grep "$MARKER=$PANE_ID" | awk '{print $1}')
    if [ -n "$EXISTING" ]; then
        exit 0
    fi

    # Calculate width based on the largest possible line number (history + visible).
    MAX_LINE=$(tmux display -p -t "$PANE_ID" '#{e|+:#{history_size},#{pane_height}}')
    # Number of digits needed, with a minimum of 3.
    DIGITS=${#MAX_LINE}
    if [ "$DIGITS" -lt 3 ]; then
        DIGITS=3
    fi
    # Add 1 column of padding.
    LN_WIDTH=$((DIGITS + 1))

    # Split a narrow pane to the left of the current pane. The line-number pane
    # runs the render script in a loop.
    LN_PANE=$(tmux split-window -t "$PANE_ID" -hbdl "$LN_WIDTH" -PF '#{pane_id}' \
        -e "$MARKER=$PANE_ID" \
        "$SCRIPTS_DIR/render-loop.sh $PANE_ID $DIGITS")

    if [ -z "$LN_PANE" ]; then
        exit 1
    fi

    # Store the line-number pane ID so we can clean it up later.
    tmux set-option -p -t "$PANE_ID" @line_numbers_pane "$LN_PANE"

    # Disable borders/status for the line-number pane and make it non-interactive.
    tmux set-option -p -t "$LN_PANE" remain-on-exit on
    # Prevent focus from going to the line-number pane.
    tmux select-pane -t "$PANE_ID"
else
    # Kill the line-number pane if it exists when exiting copy-mode.
    LN_PANE=$(tmux show-options -p -t "$PANE_ID" -v @line_numbers_pane 2>/dev/null)
    if [ -n "$LN_PANE" ]; then
        tmux kill-pane -t "$LN_PANE" 2>/dev/null
        tmux set-option -pu -t "$PANE_ID" @line_numbers_pane 2>/dev/null
    fi
fi
