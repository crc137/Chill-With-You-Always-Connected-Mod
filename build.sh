#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")"

VERSION="${VERSION:-26.1.0}"
NAME="ChillWithYou-AlwaysConnected-v${VERSION}-Linux-Windows"

echo "=== building AlwaysConnectedPlugin ==="

if [ ! -d "${TERMINFO:-}" ] && [ -d /usr/share/terminfo ]; then
  export TERMINFO=/usr/share/terminfo
fi
dotnet build -c Release -v q -nologo 2>&1 | cat

DLL="bin/Release/net472/AlwaysConnectedPlugin.dll"
[ -f "$DLL" ] || { echo "build output missing: $DLL" >&2; exit 1; }

rm -rf dist
mkdir -p dist

cp "$DLL" dist/
cp install.sh dist/
cp uninstall.sh dist/
cp install.bat dist/
cp uninstall.bat dist/
chmod +x dist/install.sh dist/uninstall.sh

( cd dist && zip -q -r "../${NAME}.zip" \
    AlwaysConnectedPlugin.dll \
    install.sh install.bat \
    uninstall.sh uninstall.bat )

echo
echo "packed: $(pwd)/${NAME}.zip"
python3 - "$NAME.zip" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    for i in z.infolist():
        print(f"  {i.filename}  {i.file_size}")
PY