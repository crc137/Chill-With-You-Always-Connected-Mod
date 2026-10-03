@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Chill with You : Lo-Fi Story - Always Connected Installer

set "MOD_DLL=AlwaysConnectedPlugin.dll"
set "APPID=3548580"
set "GAME_EXE=Chill With You.exe"
set "BEPINEX_VER=5.4.23.5"
set "BEPINEX_URL=https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.5/BepInEx_win_x64_5.4.23.5.zip"

if not exist "%MOD_DLL%" (
  echo [ERROR] File "%MOD_DLL%" was not found next to this installer.
  echo [ERROR] Please download a release or build it first.
  pause
  exit /b 1
)

echo === Chill with You : Lo-Fi Story - Always Connected Installer ===
echo.

set "ROOTS=%TEMP%\cw_roots_%RANDOM%.txt"
> "%ROOTS%" break

call :addroot "C:\Program Files (x86)\Steam"
call :addroot "C:\Program Files\Steam"
call :addroot "%ProgramFiles(x86)%\Steam"
call :addroot "%ProgramFiles%\Steam"
for %%D in (D E F G H I J K L M) do (
  call :addroot "%%D:\Steam"
  call :addroot "%%D:\SteamLibrary"
  call :addroot "%%D:\SteamGames"
  call :addroot "%%D:\Program Files (x86)\Steam"
)

:expand
set "EXPANDED=0"
for /f "usebackq delims=" %%R in ("%ROOTS%") do (
  if exist "%%~R\steamapps\libraryfolders.vdf" (
    for /f "usebackq tokens=2 delims=	" %%L in ("%%~R\steamapps\libraryfolders.vdf") do (
      set "LIB=%%~L"
      if not "!LIB!"=="" (
        findstr /b /c:"!LIB!" "%ROOTS%" >nul 2>&1
        if errorlevel 1 (
          if exist "!LIB!\steamapps" (
            >>"%ROOTS%" echo !LIB!
            set "EXPANDED=1"
          )
        )
      )
    )
  )
)
if "%EXPANDED%"=="1" goto :expand

set "GAME_DIR="
set "INST="
for /f "usebackq delims=" %%R in ("%ROOTS%") do (
  if exist "%%~R\steamapps\appmanifest_%APPID%.acf" (
    set "INST="
    for /f "usebackq tokens=2 delims=	" %%I in (`findstr /i "installdir" "%%~R\steamapps\appmanifest_%APPID%.acf" 2^>nul`) do set "INST=%%~I"
    if not "!INST!"=="" (
      if exist "%%~R\steamapps\common\!INST!\%GAME_EXE%" set "GAME_DIR=%%~R\steamapps\common\!INST!"
    )
  )
  if "!GAME_DIR!"=="" (
    for /d %%D in ("%%~R\steamapps\common\*Chill with You*Lo-Fi*") do (
      if exist "%%~D\%GAME_EXE%" set "GAME_DIR=%%~D"
    )
  )
  if not "!GAME_DIR!"=="" goto :found
)

echo [ERROR] Could not automatically find the game. Make sure it is installed on Steam and run at least once.
echo.
set /p GAME_DIR="Please enter the game folder manually (or press Enter to cancel): "
if "!GAME_DIR!"=="" (
  echo [ERROR] No folder selected. Canceled by user.
  pause
  exit /b 1
)
if not exist "!GAME_DIR!\%GAME_EXE%" (
  echo [ERROR] "%GAME_DIR%" does not look like the game folder (no %GAME_EXE% found).
  pause
  exit /b 1
)

:found
echo [OK] Game found at: %GAME_DIR%

if not exist "%GAME_DIR%\BepInEx\core" (
  echo [INFO] BepInEx not found in game directory. Installing automatically...
  set "ZIP=!TEMP!\bepinex_%RANDOM%.zip"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%BEPINEX_URL%' -OutFile '!ZIP!' } catch { exit 1 }" >nul 2>&1
  if errorlevel 1 (
    echo [ERROR] Could not download BepInEx. Please download and install manually:
    echo        %BEPINEX_URL%
    echo        Extract the contents to: %GAME_DIR%
    pause
    exit /b 1
  )
  tar -xf "!ZIP!" -C "%GAME_DIR%" >nul 2>&1
  if not exist "%GAME_DIR%\BepInEx\core" (
    powershell -NoProfile -Command "Expand-Archive -Path '!ZIP!' -DestinationPath '%GAME_DIR%' -Force" >nul 2>&1
  )
  del "!ZIP!" 2>nul
  if not exist "%GAME_DIR%\BepInEx\core" (
    echo [ERROR] Failed to extract BepInEx. Please install it manually:
    echo        %BEPINEX_URL%
    pause
    exit /b 1
  )
  echo [OK] BepInEx has been installed.
  echo [INFO] Please launch the game once so BepInEx can create its config, then close it and run this installer again if needed.
) else (
  echo [OK] BepInEx detected in the game directory.
)

set "PLUGINS=%GAME_DIR%\BepInEx\plugins"
if not exist "%PLUGINS%" mkdir "%PLUGINS%"

copy /y "%MOD_DLL%" "%PLUGINS%\" >nul
echo [OK] %MOD_DLL% installed to %PLUGINS%

del "%ROOTS%" 2>nul

echo.
echo [SUCCESS] === Installation complete! ===
echo Start the game. The scripted connection-loss event is disabled, so the heroine stays reachable.
echo Config: "%GAME_DIR%\BepInEx\config\crc137.chillwithyou.alwaysconnected.cfg"
echo.
pause

:addroot
if "%~1"=="" exit /b 0
if exist "%~1\steamapps" (
  findstr /b /c:"%~1" "%ROOTS%" >nul 2>&1 || >>"%ROOTS%" echo %~1
)
exit /b 0
