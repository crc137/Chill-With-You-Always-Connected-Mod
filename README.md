<div align="center">
  <a href="https://github.com/coonlink">
    <img width="90px" src="logo.png" alt="Logo" />
  </a>
  <h1>Chill with You : Lo-Fi Story — Mod «Always Connected»</h1>

  [![English](https://img.shields.io/badge/lang-English%20🇺🇸-white)](README.md)
  [![Русский](https://img.shields.io/badge/язык-Русский%20🇷🇺-white)](README.ru.md)

  <img alt="last-commit" src="https://img.shields.io/github/last-commit/crc137/Chill-With-You-Always-Connected-Mod?style=flat&amp;logo=git&amp;logoColor=white&amp;color=0080ff" style="margin: 0px 2px;">
  <img alt="repo-top-language" src="https://img.shields.io/github/languages/top/crc137/Chill-With-You-Always-Connected-Mod?style=flat&amp;color=0080ff" style="margin: 0px 2px;">
  <img alt="repo-language-count" src="https://img.shields.io/github/languages/count/crc137/Chill-With-You-Always-Connected-Mod?style=flat&amp;color=0080ff" style="margin: 0px 2px;">
  <img alt="version" src="https://img.shields.io/badge/version-26.1.0-blue" style="margin: 0px 2px;">
  <!-- img alt="status" src="https://img.shields.io/badge/status-STABLE-green" style="margin: 0px 2px;" -->
</div>

<br />

<div align="center">
  <p>Removes the <b>scripted connection-loss event</b> at episode 32, so the heroine stays reachable and you can keep talking to her.</p>
</div>

## Requirements

1. **Chill with You : Lo-Fi Story** (Steam), launched at least once.
2. **BepInEx 5.x** in the game folder
   → `.../Chill with You Lo-Fi Story/BepInEx/`
   (the installer puts it there automatically if it is missing — for example after
   reinstalling the game).
3. The plugin file `AlwaysConnectedPlugin.dll` (this mod).

No other files are needed. The mod patches game code in memory and does not
modify a single game file.

## Download

The ready-to-run zip is published in **GitHub Releases** only:

👉 [github.com/crc137/Chill-With-You-Always-Connected-Mod/releases](https://github.com/crc137/Chill-With-You-Always-Connected-Mod/releases)

Take `ChillWithYou-AlwaysConnected-v26.1.0-Linux-Windows.zip`. The repository
itself holds sources, installers and documentation, no binaries.

## Install

**Option A — one-click installer (recommended)**

Unpack the zip and run the installer for your OS:

- **Windows:** double-click `install.bat`
- **Linux / Steam Deck:** `./install.sh`

The installer finds the game in **any Steam library** (including non-standard
paths and external drives), installs BepInEx if it is missing, and copies the
plugin into `BepInEx/plugins`. If the game is not found, it asks for the path.

**Option B — manually**

1. Install the game via Steam and **launch it once** so the folders exist.
2. Put **BepInEx 5.x** into the game folder:
   - Windows: `Chill with You Lo-Fi Story/BepInEx/`
   - Steam Deck / Linux (flatpak):
     `~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Chill with You Lo-Fi Story/BepInEx/`
3. Copy the plugin into the **plugins** folder:
   ```
   BepInEx/plugins/AlwaysConnectedPlugin.dll     ← the mod
   ```

Remove it again with `uninstall.sh` / `uninstall.bat`.

## Turning the mod off without uninstalling

The disconnect is a scripted event, so you may want to watch the original once,
or record it. You do not have to move files — flip the config switch:

- **Linux / Steam Deck:** `./mod.sh on` · `./mod.sh off` · `./mod.sh status`
- **Windows:** edit the config by hand, see below

Close the game before switching, otherwise it rewrites the config on exit.

## Config

`BepInEx/config/crc137.chillwithyou.alwaysconnected.cfg`

| Setting | Default | Meaning |
| --- | --- | --- |
| `SkipConnectionLost` | `true` | Master switch. `false` restores the original behaviour without uninstalling. |
| `VerboseState` | `false` | Log the heroine's connection state every 10 s to `BepInEx/LogOutput.log`. Only for troubleshooting. |

## Seeing the original event again

The disconnect only fires while `NextEpisodeNumber == 32`. Once you have read
episode 32 it can never trigger again, so for recording or screenshots you have
to rewind the save:

```
python3 tools/reset-episode.py --status   # show current progress
python3 tools/reset-episode.py            # set episode 32 again
```

It writes a timestamped `.before-reset-*` backup next to the save file. Close
the game first, otherwise it overwrites your change on exit.

## If it does not work

- **The disconnect still happens** → check that `SkipConnectionLost = true` in
  `BepInEx/config/crc137.chillwithyou.alwaysconnected.cfg`, and that you
  actually launched the game *after* installing the mod.
- **Nothing happens at all, no mod** → BepInEx is probably not loaded. The game
  folder must contain `BepInEx/core`. If you just reinstalled the game, run
  `install.sh` / `install.bat` again — it restores BepInEx and the mod.
- **Need proof it is active** → set `VerboseState = true` and watch
  `BepInEx/LogOutput.log`: you should see `[AlwaysConnected] patched: ...` lines
  at startup.
- **No BepInEx console** → enable `[Logging.Console] Enabled = true` in
  `BepInEx/config/BepInEx.cfg`.

## What the event actually is

It is not a bug and it is not random. The game schedules a deliberate
disconnect after episode 31:

- `GamePlayingDefectDirection.CheckNeedUseDefectDirection()` returns
  `ConnectionLost` when `NextEpisodeNumber == 32`. In `DirectionService.cs` the
  field is labelled `31話読了後用切断演出` — "disconnect direction after finishing
  episode 31".
- `UseConnectionLost()` raises the overlay, fires a glitch effect and drops the
  audio low-pass filters.
- `HeroineService.Setup()` subscribes to that state and freezes her:
  `_animator.speed = 0f` and `_heroineAI.SetIsUse(false)`.
- Talking is then blocked in several places, for example
  `PlayerStatusReactionTalkController` and `RoomGameManager`.

There is a second gate on top of that one. At episode 32,
`ScenarioProgressData.IsPossibleTalkNextMainEpisode()` only returns true once
`CanShowConnectionLostNextEpisode` is set, and that requires **50 minutes** of
accumulated pomodoro work (`TimerCoreService.UpdateLastStoryUnlockFlg`).
Reconnecting is gated on reaching level 33 (`MyDefine.IsPossibleReconnectLevel`).

## What the mod changes

Three Harmony patches:

| Target | Effect |
| --- | --- |
| `GamePlayingDefectDirection.CheckNeedUseDefectDirection` | rewrites `ConnectionLost` to `None`, so the disconnect never starts |
| `GamePlayingDefectDirection.PlayDefectDirection` | if a disconnect is applied anyway, replays it as `None`, which runs the game's own `Init()` and clears the overlay, audio and reactive flag |
| `ScenarioProgressData.IsPossibleTalkNextMainEpisode` | returns true at episode 32, skipping the 50 minute wait |

A `ConnectionWatchdog` additionally re-checks the heroine's state every 2 s, so
a disconnect that still slipped through gets cleared instead of leaving her
frozen.

The separate episode-31 `AlwaysNoise` effect is deliberately left untouched.

Only `Assembly-CSharp` is patched. No game file is modified.

## Build from source

Needs the .NET SDK and `build.sh`, which builds, copies the plugin next to the
game and packs the release zip:

```bash
./build.sh
```

Tested against game build 9/10/2026, Unity 2022.3.62, BepInEx 5.4.23.5,
Mono 6.14 (Steam Deck / Proton).
