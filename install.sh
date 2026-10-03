#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC} $*"; }

MOD_DLL_NAME="AlwaysConnectedPlugin.dll"
MOD_DLL=""
for cand in "$MOD_DLL_NAME" "bin/Release/net472/$MOD_DLL_NAME" "dist/$MOD_DLL_NAME"; do
  if [ -f "$cand" ]; then MOD_DLL="$cand"; break; fi
done

STEAM_APPID=3548580
GAME_EXE="Chill With You.exe"
BEPINEX_VER="5.4.23.5"
BEPINEX_URL="https://github.com/BepInEx/BepInEx/releases/download/v${BEPINEX_VER}/BepInEx_linux_x64_${BEPINEX_VER}.zip"

if [ -z "$MOD_DLL" ]; then
  err "File $MOD_DLL_NAME not found next to the script (or in bin/Release/net472/)."
  err "Please download the release or build it: ./build.sh"
  exit 1
fi

echo "=== Chill with You : Lo-Fi Story — Always Connected Installer ==="
echo ""

declare -a ROOTS=()

add_root() {
  local r="${1%/}"
  [ -z "$r" ] && return 0
  [ -d "$r" ] || return 0
  for x in "${ROOTS[@]:-}"; do
    [ "$x" = "$r" ] && return 0
  done
  ROOTS+=("$r")
}

add_root "$HOME/.steam/steam"
add_root "$HOME/.local/share/Steam"
add_root "$HOME/.steam/debian-installation"
add_root "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"

for _round in 1 2 3 4; do
  changed=0
  for root in "${ROOTS[@]:-}"; do
    vdf="$root/steamapps/libraryfolders.vdf"
    [ -f "$vdf" ] || continue
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      before=${#ROOTS[@]}
      add_root "$p"
      if [ "${#ROOTS[@]}" -gt "$before" ]; then changed=1; fi
    done < <(sed -nE 's/^[[:space:]]*"path"[[:space:]]+"([^"]+)".*/\1/p' "$vdf" 2>/dev/null)
  done
  [ "$changed" -eq 0 ] && break
done

for base in /run/media /media /mnt; do
  [ -d "$base" ] || continue
  while IFS= read -r f; do
    root="$(dirname "$(dirname "$f")")"
    add_root "$root"
  done < <(find "$base" -maxdepth 8 -type f -name "appmanifest_${STEAM_APPID}.acf" 2>/dev/null)
done

is_real_game_dir() {
  local d="$1"
  [ -d "$d" ] || return 1
  if [ -f "$d/$GAME_EXE" ] || [ -d "$d/Chill With You_Data" ] || ls "$d"/*_Data >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

find_game_dir() {
  local root inst cand
  for root in "${ROOTS[@]:-}"; do
    inst=""
    if [ -f "$root/steamapps/appmanifest_${STEAM_APPID}.acf" ]; then
      if grep -q '"StateFlags"[[:space:]]*"4"' "$root/steamapps/appmanifest_${STEAM_APPID}.acf" 2>/dev/null; then
        inst=$(sed -nE 's/^[[:space:]]*"installdir"[[:space:]]+"([^"]+)".*/\1/p' "$root/steamapps/appmanifest_${STEAM_APPID}.acf" | head -1)
      fi
      if [ -n "$inst" ] && is_real_game_dir "$root/steamapps/common/$inst"; then
        echo "$root/steamapps/common/$inst"
        return 0
      fi
    fi
    while IFS= read -r cand; do
      if is_real_game_dir "$cand"; then
        echo "$cand"
        return 0
      fi
    done < <(find "$root/steamapps/common" -maxdepth 1 -type d -iname "*Chill with You*Lo-Fi*" 2>/dev/null)
  done
  return 1
}

GAME_DIR="${GAME_DIR:-}"
if [ -z "$GAME_DIR" ]; then
  GAME_DIR="$(find_game_dir || true)"
fi

if [ -z "$GAME_DIR" ]; then
  err "Game not found automatically."
  echo ""
  echo "If you installed the game to a non-standard location, enter the path manually:"
  read -r -p "Path to game folder (Enter — cancel): " GAME_DIR || true
  GAME_DIR="${GAME_DIR//\~/$HOME}"
  if [ -z "$GAME_DIR" ]; then
    err "No path provided. Aborted."
    exit 1
  fi
  if ! is_real_game_dir "$GAME_DIR"; then
    err "Could not find game files ($GAME_EXE) in $GAME_DIR. Please check the path."
    exit 1
  fi
fi

ok "Game found: $GAME_DIR"

if [ ! -d "$GAME_DIR/BepInEx/core" ]; then
  warn "BepInEx not found (this usually happens after reinstalling the game). Downloading BepInEx $BEPINEX_VER and installing..."
  tmp="$(mktemp -d)"
  zip="$tmp/bepinex.zip"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$zip" "$BEPINEX_URL" || true
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$zip" "$BEPINEX_URL" || true
  fi
  if [ ! -s "$zip" ]; then
    err "Failed to download BepInEx."
    echo ""
    echo "Please install it manually:"
    echo "  1. Download: $BEPINEX_URL"
    echo "  2. Unzip the archive contents to: $GAME_DIR/"
    echo "  3. Run this script again."
    rm -rf "$tmp"
    exit 1
  fi
  if command -v unzip >/dev/null 2>&1; then
    unzip -o -q "$zip" -d "$GAME_DIR"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -m zipfile -e "$zip" "$GAME_DIR"
  elif command -v bsdtar >/dev/null 2>&1; then
    bsdtar -xf "$zip" -C "$GAME_DIR"
  else
    err "Cannot unzip file (no unzip/python3/bsdtar available)."
    echo "Unzip $BEPINEX_URL manually into: $GAME_DIR/"
    rm -rf "$tmp"
    exit 1
  fi
  rm -rf "$tmp"
  if [ ! -d "$GAME_DIR/BepInEx/core" ]; then
    err "Something went wrong: BepInEx/core was not created. Please install BepInEx manually to: $GAME_DIR/"
    exit 1
  fi
  ok "BepInEx installed to game folder."
  warn "On first game launch, BepInEx will create the config (you may need to relaunch the game)."
else
  ok "BepInEx found"
fi

PLUGINS="$GAME_DIR/BepInEx/plugins"
mkdir -p "$PLUGINS"

cp -f "$MOD_DLL" "$PLUGINS/"
ok "Installed: $MOD_DLL -> $PLUGINS/"

if [ -f "$GAME_DIR/BepInEx/config/crc137.chillwithyou.alwaysconnected.cfg" ]; then
  ok "Existing config kept (SkipConnectionLost / VerboseState can be changed there)"
fi

echo ""
echo -e "${GREEN}=== Installation complete! ===${NC}"
echo "Launch the game. The scripted connection-loss event is disabled, so the heroine"
echo "stays reachable and you can keep talking to her."
echo "Config: $GAME_DIR/BepInEx/config/crc137.chillwithyou.alwaysconnected.cfg"
echo "Uninstall with: $PWD/uninstall.sh"
