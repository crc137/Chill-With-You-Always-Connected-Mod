#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC} $*"; }

MOD_DLL="AlwaysConnectedPlugin.dll"
STEAM_APPID=3548580
GAME_EXE="Chill With You.exe"

is_real_game_dir() {
  local d="$1"
  [ -d "$d" ] || return 1
  [ -f "$d/$GAME_EXE" ] || [ -d "$d/Chill With You_Data" ]
}

find_game_dir() {
  local root inst cand base
  local -a roots=(
    "$HOME/.steam/steam"
    "$HOME/.local/share/Steam"
    "$HOME/.steam/debian-installation"
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"
  )
  for root in "${roots[@]}"; do
    [ -f "$root/steamapps/appmanifest_${STEAM_APPID}.acf" ] || continue
    inst=$(sed -nE 's/^[[:space:]]*"installdir"[[:space:]]+"([^"]+)".*/\1/p' "$root/steamapps/appmanifest_${STEAM_APPID}.acf" | head -1)
    if [ -n "$inst" ] && is_real_game_dir "$root/steamapps/common/$inst"; then
      echo "$root/steamapps/common/$inst"; return 0
    fi
  done
  for base in /run/media /media /mnt; do
    [ -d "$base" ] || continue
    while IFS= read -r cand; do
      if is_real_game_dir "$cand"; then echo "$cand"; return 0; fi
    done < <(find "$base" -maxdepth 8 -type d -iname "*Chill with You*Lo-Fi*" 2>/dev/null)
  done
  return 1
}

GAME_DIR="${GAME_DIR:-$(find_game_dir || true)}"
if [ -z "$GAME_DIR" ]; then
  err "Game not found. Set GAME_DIR=/path/to/'Chill with You Lo-Fi Story' and rerun."
  exit 1
fi
ok "Game found: $GAME_DIR"

PLUGINS="$GAME_DIR/BepInEx/plugins"
if [ -f "$PLUGINS/$MOD_DLL" ]; then
  rm -f "$PLUGINS/$MOD_DLL"
  ok "Removed $MOD_DLL"
else
  warn "$MOD_DLL not present"
fi

CFG="$GAME_DIR/BepInEx/config/crc137.chillwithyou.alwaysconnected.cfg"
if [ -f "$CFG" ]; then
  rm -f "$CFG"
  ok "Removed config"
fi

echo ""
echo -e "${GREEN}=== Uninstalled ===${NC}"
