#!/usr/bin/env bash
set -euo pipefail

PANE_ID="${1:-}"
shift || true

[ -n "$PANE_ID" ] || exit 1

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKER="TMUX_LINE_NUMBERS_FOR"

open_gutter() {
  local existing max_line digits ln_width cur_bg cur_bold cur_fg ln_bg ln_fg min_width poll_interval position relative pane_width split_flags ln_pane

  existing=$(tmux list-panes -F '#{pane_id} #{pane_start_command}' 2>/dev/null | grep -F "$MARKER=$PANE_ID" | awk '{print $1}' || true)
  if [ -n "$existing" ]; then
    if [ "$(tmux display -p -t "$existing" '#{pane_dead}' 2>/dev/null || true)" = "1" ]; then
      tmux kill-pane -t "$existing" 2>/dev/null || true
    else
      tmux set-option -p -t "$PANE_ID" @line_numbers_pane "$existing" 2>/dev/null || true
      return 0
    fi
  fi

  max_line=$(tmux display -p -t "$PANE_ID" '#{e|+:#{history_size},#{pane_height}}')
  digits=${#max_line}
  if [ "$digits" -lt 3 ]; then
    digits=3
  fi
  ln_width=$((digits + 1))

  cur_bg=$(tmux show-option -gqv @line-numbers-current-line-bg 2>/dev/null)
  cur_bold=$(tmux show-option -gqv @line-numbers-current-line-bold 2>/dev/null)
  if [ "$cur_bold" != "off" ]; then
    cur_bold="on"
  fi
  cur_fg=$(tmux show-option -gqv @line-numbers-current-line-fg 2>/dev/null)
  ln_bg=$(tmux show-option -gqv @line-numbers-bg 2>/dev/null)
  ln_fg=$(tmux show-option -gqv @line-numbers-fg 2>/dev/null)

  min_width=$(tmux show-option -gqv @line-numbers-min-pane-width 2>/dev/null)
  min_width="${min_width:-40}"
  poll_interval=$(tmux show-option -gqv @line-numbers-poll-interval 2>/dev/null)
  position=$(tmux show-option -gqv @line-numbers-position 2>/dev/null)
  if [ "$position" != "right" ]; then
    position="left"
  fi
  relative=$(tmux show-option -gqv @line-numbers-relative 2>/dev/null)
  if [ "$relative" != "off" ]; then
    relative="on"
  fi

  pane_width=$(tmux display -p -t "$PANE_ID" '#{pane_width}')
  if [ "$pane_width" -lt "$min_width" ]; then
    return 0
  fi

  split_flags="-hdl $ln_width"
  if [ "$position" = "left" ]; then
    split_flags="-hbdl $ln_width"
  fi

  ln_pane=$(tmux split-window -t "$PANE_ID" $split_flags -PF '#{pane_id}' \
    -e "$MARKER=$PANE_ID" \
    "'$SCRIPTS_DIR/render-loop-wait.sh' '$PANE_ID' '$cur_bg' '$cur_bold' '$cur_fg' '$digits' '$ln_bg' '$ln_fg' '$poll_interval' '$relative'")

  [ -n "$ln_pane" ] || return 1

  tmux set-option -p -t "$PANE_ID" @line_numbers_pane "$ln_pane"
  tmux set-option -p -t "$ln_pane" remain-on-exit on
  tmux select-pane -t "$PANE_ID"
}

wait_for_settle() {
  local prev curr unchanged i

  sleep 0.2
  prev=$(tmux capture-pane -p -t "$PANE_ID" 2>/dev/null || true)
  unchanged=0

  for i in $(seq 1 20); do
    sleep 0.05
    curr=$(tmux capture-pane -p -t "$PANE_ID" 2>/dev/null || true)
    if [ "$curr" = "$prev" ]; then
      unchanged=$((unchanged + 1))
      if [ "$unchanged" -ge 2 ]; then
        return 0
      fi
    else
      unchanged=0
    fi
    prev="$curr"
  done
}

open_gutter || true
wait_for_settle || true

if [ "$#" -gt 0 ]; then
  tmux copy-mode "$@" -t "$PANE_ID"
else
  tmux copy-mode -t "$PANE_ID"
fi
