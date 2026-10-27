#!/usr/bin/env bash
# Link the skill into every Claude Code config dir found on this machine.
set -eu
src="$(cd "$(dirname "$0")" && pwd)/skill"

if ! command -v zenity >/dev/null && ! command -v yad >/dev/null && ! command -v kdialog >/dev/null; then
  echo "No dialog program found. Install one: sudo apt install zenity" >&2
fi

linked=0
seen=" "
for dir in "$HOME/.claude" "$HOME"/.claude-*/ ${CLAUDE_CONFIG_DIR:+"$CLAUDE_CONFIG_DIR"}; do
  dir="${dir%/}"
  [ -d "$dir" ] || continue
  case "$seen" in *" $dir "*) continue ;; esac
  seen="$seen$dir "
  mkdir -p "$dir/skills"
  target="$dir/skills/askpass-prompt"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "skip $target (exists and is not a symlink)" >&2
    continue
  fi
  ln -sfn "$src" "$target"
  echo "linked $target -> $src"
  linked=1
done
[ "$linked" = 1 ] || echo "No Claude Code config dir found (~/.claude)." >&2
