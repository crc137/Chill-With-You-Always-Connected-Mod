#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CFG_NAME="crc137.chillwithyou.alwaysconnected.cfg"
GAME_EXE="Chill With You.exe"

game_running() {
  pgrep -f "Chill With You Lo-Fi Story/Chill With You.exe" >/dev/null 2>&1 \ || pgrep -f "Chill with You Lo-Fi Story.exe" >/dev/null 2>&1 }

find_game_dir() {
  if [ -n "${GAME_DIR:-}" ]; then echo "$GAME_DIR"; return 0; fi
  local base d
  for base in "$HOME/.steam/steam" "$HOME/.local/share/Steam" /run/media /media /mnt; do
    [ -d "$base" ] || continue
    while IFS= read -r d; do
      if [ -f "$d/$GAME_EXE" ] || [ -d "$d/Chill With You_Data" ]; then
        echo "$d"; return 0
      fi
    done < <(find "$base" -maxdepth 6 -type d -iname "*Chill with You*Lo-Fi*" 2>/dev/null)
  done
  return 1
}

GAME="$(find_game_dir || true)"
if [ -z "$GAME" ]; then
  echo -e "${RED}[ERR]${NC} Game not found. Specify the path: GAME_DIR=\"/path/to/game\" ./mod.sh on" >&2
  exit 1
fi

CFG="$GAME/BepInEx/config/$CFG_NAME"

set_key() {
  local key="$1" val="$2"
  if grep -qE "^$key = " "$CFG" 2>/dev/null; then
    if grep -qE "^$key = .*\r$" "$CFG"; then
      sed -i "s|^$key = .*\r$|$key = $val\r|" "$CFG"
    else
      sed -i "s|^$key = .*$|$key = $val|" "$CFG"
    fi
  else
    printf '%s = %s\n' "$key" "$val" >> "$CFG"
  fi
}

read_key() { grep -E "^$1 = " "$CFG" 2>/dev/null | head -1 | sed -E "s/^$1 = //; s/\r$//" || true }

case "${1:-status}" in
  on|off)
    if game_running; then
      echo -e "${RED}[ERR]${NC} Game is running. Close it first, then try again — otherwise it may overwrite the config." >&2
      exit 1
    fi
    mkdir -p "$(dirname "$CFG")"
    [ -f "$CFG" ] || printf '#Always Connected\n' > "$CFG"
    if [ "$1" = "on" ]; then
      set_key SkipConnectionLost true
      echo -e "${GREEN}[OK]${NC} Mod ENABLED — connection loss will be skipped, you can talk."
    else
      set_key SkipConnectionLost false
      echo -e "${YELLOW}[OK]${NC} Mod DISABLED — original game event will play."
    fi
    echo "    $CFG"
    ;;
  status)
    if [ ! -f "$CFG" ]; then
      echo -e "${YELLOW}[!]${NC} Config not found: $CFG"
      exit 0
    fi
    val="$(read_key SkipConnectionLost)"
    case "$val" in
      true)  echo "SkipConnectionLost = true   (mod enabled, connection loss is skipped)" ;;
      false) echo "SkipConnectionLost = false  (mod disabled, original event will play)" ;;
      *)     echo "SkipConnectionLost = ${val:-<none>}  (mod will default to enabled)" ;;
    esac
    ;;
  *)
    echo "Usage: ./mod.sh on | off | status" >&2
    exit 1
    ;;
esac