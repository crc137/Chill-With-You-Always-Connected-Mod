#!/usr/bin/env python3

import argparse
import glob
import gzip
import os
import re
import shutil
import sys
import time

SEARCH_ROOT = os.path.expanduser("~")
DEFAULT_HINT = ("*/steam/steamapps/compatdata/*/pfx/drive_c/users/*/AppData/LocalLow/" "nestopi/Chill With You/SaveData/Release/v2/*")

def find_save_dir():
    matches = sorted(glob.glob(os.path.join(os.getcwd(), DEFAULT_HINT))+ glob.glob(os.path.join(SEARCH_ROOT, DEFAULT_HINT)))
    if not matches:
        matches = sorted(glob.glob("/run/media/*/*/steam/steamapps/compatdata/*/pfx/drive_c/users/*/" "AppData/LocalLow/nestopi/Chill With You/SaveData/Release/v2/*"))
    if not matches:
        sys.exit("Save directory not found. Make sure the game was launched at least once.")
    return matches[-1]

def locate(save_dir):
    for path in sorted(glob.glob(os.path.join(save_dir, "*.es3"))):
        try:
            data = gzip.decompress(open(path, "rb").read())
        except Exception:
            continue
        if b"Bulbul.ScenarioProgressData" in data:
            return path, data
    sys.exit("ScenarioProgressData file not found in " + save_dir)

def read_state(text):
    state = {}
    for key in ("FinishReadMainEpisodeNumber", "NextEpisodeNumber", "NextEpisodeUnlockLevel", "CanShowConnectionLostNextEpisode"):
        m = re.search(r'"%s"\s*:\s*([^,\r\n]+)' % key, text)
        state[key] = m.group(1).strip() if m else "?"
    return state

def show(state):
    print("FinishReadMainEpisodeNumber : %s" % state["FinishReadMainEpisodeNumber"])
    print("NextEpisodeNumber : %s" % state["NextEpisodeNumber"])
    print("NextEpisodeUnlockLevel : %s" % state["NextEpisodeUnlockLevel"])
    print("CanShowConnectionLostNextEpisode : %s" % state["CanShowConnectionLostNextEpisode"])

def write_gzip(path, data):
    with open(path, "wb") as fh:
        with gzip.GzipFile(filename="", mode="wb", fileobj=fh, mtime=0, compresslevel=9) as gz:
            gz.write(data)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--status", action="store_true", help="only show save status")
    args = ap.parse_args()

    save_dir = find_save_dir()
    path, data = locate(save_dir)
    text = data.decode("utf-8")
    state = read_state(text)

    print("Save file: %s" % path)
    show(state)

    if args.status:
        return

    if state["NextEpisodeNumber"] == "32":
        print("\nAlready at episode 32 — nothing to reset.")
        return

    stamp = time.strftime("%Y%m%d-%H%M%S")
    backup = path + ".before-reset-" + stamp
    shutil.copy2(path, backup)
    print("\nBackup created: %s" % os.path.basename(backup))

    patched = re.sub(r'("FinishReadMainEpisodeNumber"\s*:\s*)32', r'\g<1>31', text)
    patched = re.sub(r'("NextEpisodeNumber"\s*:\s*)33', r'\g<1>32', patched)

    write_gzip(path, patched.encode("utf-8"))

    check = gzip.decompress(open(path, "rb").read()).decode("utf-8")
    print("After reset:")
    show(read_state(check))
    print("\nDone. Launch the game WITHOUT the mod — connection lost event should appear.")

if __name__ == "__main__":
    main()