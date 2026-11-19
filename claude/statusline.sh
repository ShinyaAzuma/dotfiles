#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:$PATH"

input=$(cat)

# --- colors (dim-friendly ANSI) ---
CYAN='\033[36m'
MAGENTA='\033[35m'
GREEN='\033[32m'
RESET='\033[0m'

# --- account indicator ---
if [[ "$CLAUDE_CONFIG_DIR" == *"claude-rewire"* ]]; then
  account_color="$MAGENTA"
  account_label="Rewire"
else
  account_color="$CYAN"
  account_label="default"
fi

# --- model display name ---
model_name=$(echo "$input" | jq -r '.model.display_name // empty')

# --- current dir basename ---
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
dir_base=$(basename "$current_dir" 2>/dev/null)

# --- git branch (skip silently if not a repo) ---
branch=""
if [ -n "$current_dir" ]; then
  branch=$(git -C "$current_dir" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# --- assemble output ---
parts=("$(printf "${account_color}%s${RESET}" "$account_label")")
[ -n "$model_name" ] && parts+=("$model_name")
[ -n "$dir_base" ] && parts+=("$dir_base")
[ -n "$branch" ] && parts+=("$(printf "${GREEN}%s${RESET}" "$branch")")

out=""
for p in "${parts[@]}"; do
  if [ -z "$out" ]; then
    out="$p"
  else
    out="$out | $p"
  fi
done

printf "%b\n" "$out"
