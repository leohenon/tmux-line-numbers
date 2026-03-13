#!/usr/bin/env bash
# Continuously renders relative line numbers for a pane in copy-mode.

# Stores the pane in copy-mode.
TARGET_PANE="$1"
# Number of digits to use for formatting (calculated at split time).
DIGITS="${2:-3}"
FMT="%${DIGITS}d"
POLL_INTERVAL=0.1

# Hide the cursor in this pane.
printf '\e[?25l'

LAST_SCREEN_Y=""
LAST_HEIGHT=""
LAST_ABS=""

render() {
    local screen_y=$1
    local pane_height=$2
    local abs_line=$3
    local last_line=$((pane_height - 1))
    local line rel

    # Move to top left.
    printf '\e[H'

    for ((line = 0; line < pane_height; line++)); do
        rel=$((line - screen_y))
        if [ $rel -lt 0 ]; then
            rel=$((-rel))
        fi

        if [ $rel -eq 0 ]; then
            # Current line: bold yellow absolute line number.
            printf "\e[1;33m${FMT}\e[0m\e[K" "$abs_line"
        else
            # Other lines: gray relative number.
            printf "\e[38;5;243m${FMT}\e[0m\e[K" "$rel"
        fi

        # No newline on last line to prevent scrolling.
        if [ $line -lt $last_line ]; then
            printf '\n'
        fi
    done
}

while true; do
    # Single tmux call to get all values. This is much faster than separate calls.
    state=$(tmux display -p -t "$TARGET_PANE" \
        '#{pane_mode} #{copy_cursor_y} #{history_size} #{scroll_position} #{pane_height}' \
        2>/dev/null) || break

    # Parse space-separated values.
    read -r pane_mode screen_y hist_size scroll_pos pane_height <<< "$state"

    if [ "$pane_mode" != "copy-mode" ]; then
        break
    fi

    if [ -z "$screen_y" ] || [ -z "$pane_height" ]; then
        break
    fi

    # Absolute line number: distance from top of scrollback to cursor.
    # +1 to make it 1-indexed (line 1 = first line of output).
    abs_line=$((hist_size - scroll_pos + screen_y + 1))

    # Only re-render if position or height has changed.
    if [ "$screen_y" = "$LAST_SCREEN_Y" ] && [ "$pane_height" = "$LAST_HEIGHT" ] && [ "$abs_line" = "$LAST_ABS" ]; then
        sleep "$POLL_INTERVAL"
        continue
    fi
    LAST_SCREEN_Y="$screen_y"
    LAST_HEIGHT="$pane_height"
    LAST_ABS="$abs_line"

    render "$screen_y" "$pane_height" "$abs_line"

    sleep "$POLL_INTERVAL"
done
