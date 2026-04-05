#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
DRY_RUN=false
UNINSTALL=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)   DRY_RUN=true;  shift ;;
    --uninstall) UNINSTALL=true; shift ;;
    --target)    CLAUDE_DIR="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CMD_SRC="$SCRIPT_DIR/commands/promote-memory.md"
CMD_DST="$CLAUDE_DIR/commands/promote-memory.md"
AGENT_SRC="$SCRIPT_DIR/agents/memory-promoter.md"
AGENT_DST="$CLAUDE_DIR/agents/memory-promoter.md"

if [[ "$UNINSTALL" == true ]]; then
  echo "Uninstalling promote-memory..."
  [[ "$DRY_RUN" == true ]] && echo "[DRY RUN]"

  for file in "$CMD_DST" "$AGENT_DST"; do
    if [[ -f "$file" ]]; then
      [[ "$DRY_RUN" == false ]] && rm "$file"
      echo "  Removed: $file"
    else
      echo "  Not found (skipped): $file"
    fi
  done

  echo "Uninstall complete."
  exit 0
fi

echo "Installing promote-memory to $CLAUDE_DIR..."
[[ "$DRY_RUN" == true ]] && echo "[DRY RUN]"

if [[ "$DRY_RUN" == false ]]; then
  mkdir -p "$CLAUDE_DIR/commands" "$CLAUDE_DIR/agents"

  # Idempotent install — skip if identical
  if [[ -f "$CMD_DST" ]] && diff -q "$CMD_SRC" "$CMD_DST" &>/dev/null; then
    echo "  Up to date: $CMD_DST"
  else
    cp "$CMD_SRC" "$CMD_DST"
    echo "  Installed: $CMD_DST"
  fi

  if [[ -f "$AGENT_DST" ]] && diff -q "$AGENT_SRC" "$AGENT_DST" &>/dev/null; then
    echo "  Up to date: $AGENT_DST"
  else
    cp "$AGENT_SRC" "$AGENT_DST"
    echo "  Installed: $AGENT_DST"
  fi
else
  echo "  Would install: $CMD_DST"
  echo "  Would install: $AGENT_DST"
fi

echo ""
echo "Installation complete. Restart Claude Code, then run: /promote-memory"
