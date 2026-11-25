#!/usr/bin/env bash
set -euo pipefail

MOD_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$MOD_DIR/../.." && pwd)"
GODOT="$REPO_ROOT/.agent/mod-dev/tools/Godot.app/Contents/MacOS/Godot"

if [ ! -x "$GODOT" ]; then
  echo "ERROR: macOS Godot 4.5.2 binary not found at $GODOT" >&2
  exit 1
fi

if [ -z "${MP_PCK_PATH:-}" ] && [ -r "$HOME/Downloads/Machine Party.pck" ]; then
  export MP_PCK_PATH="$HOME/Downloads/Machine Party.pck"
fi
if [ ! -r "${MP_PCK_PATH:-}" ]; then
  echo "Preview uses fallback assets. Set MP_PCK_PATH to a readable Machine Party.pck for the original visuals." >&2
fi

MODE="${1:-play}"
case "$MODE" in
  --self-test)
    exec "$GODOT" --headless --path "$MOD_DIR" -- --self-test
    ;;
  --smoke-test)
    exec "$GODOT" --headless --path "$MOD_DIR" -- --smoke-test
    ;;
  --screenshot)
    OUT="${2:-$REPO_ROOT/.agent/mod-dev/dist/bomb_cart_preview.png}"
    exec "$GODOT" --path "$MOD_DIR" --windowed --resolution 1280x720 -- "--capture-screenshot=$OUT"
    ;;
  play|"")
    exec "$GODOT" --path "$MOD_DIR"
    ;;
  *)
    echo "Usage: $0 [play | --self-test | --smoke-test | --screenshot <output.png>]" >&2
    exit 2
    ;;
esac
