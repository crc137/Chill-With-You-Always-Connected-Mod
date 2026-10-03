@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Chill with You : Lo-Fi Story - Always Connected Uninstaller

set "MOD_DLL=AlwaysConnectedPlugin.dll"
set "CFG=crc137.chillwithyou.alwaysconnected.cfg"
set "APPID=3548580"
set "GAME_EXE=Chill With You.exe"

echo === Chill with You : Lo-Fi Story - Always Connected Uninstaller ===
echo.

set "GAME_DIR="
set "ROOTS=%TEMP%\cw_uroots_%RANDOM%.txt"
> "%ROOTS%" break

call :addroot "C:\Program Files (x86)\Steam"
call :addroot "C:\Program Files\Steam"
call :addroot "%ProgramFiles(x86)%\Steam"
call :addroot "%ProgramFiles%\Steam"
for %%D in (D E F G H I J K L M) do (
  call :addroot "%%D:\Steam"
  call :addroot "%%D:\SteamLibrary"
  call :addroot "%%D:\SteamGames"
)

for /f "usebackq delims=" %%R in ("%ROOTS%") do (
  if exist "%%~R\steamapps\appmanifest_%APPID%.acf" (
    for /f "usebackq tokens=2 delims=	" %%I in (`findstr /i "installdir" "%%~R\steamapps\appmanifest_%APPID%.acf" 2^>nul`) do (
      if exist "%%~R\steamapps\common\%%~I\%GAME_EXE%" set "GAME_DIR=%%~R\steamapps\common\%%~I"
    )
  )
  if "!GAME_DIR!"=="" (
    for /d %%D in ("%%~R\steamapps\common\*Chill with You*Lo-Fi*") do (
      if exist "%%~D\%GAME_EXE%" set "GAME_DIR=%%~D"
    )
  )
  if not "!GAME_DIR!"=="" goto :found
)

echo [ERROR] Could not automatically find the game.
set /p GAME_DIR="Please enter the game folder manually (or press Enter to cancel): "
if "!GAME_DIR!"=="" (
  echo [ERROR] Canceled by user.
  pause
  exit /b 1
)

:found
echo [OK] Game found at: %GAME_DIR%
del "%ROOTS%" 2>nul

if exist "%GAME_DIR%\BepInEx\plugins\%MOD_DLL%" (
  del "%GAME_DIR%\BepInEx\plugins\%MOD_DLL%"
  echo [OK] Removed %MOD_DLL%
) else (
  echo [WARNING] %MOD_DLL% was not present.
)

if exist "%GAME_DIR%\BepInEx\config\%CFG%" (
  del "%GAME_DIR%\BepInEx\config\%CFG%"
  echo [OK] Removed config
)

echo.
echo [SUCCESS] === Uninstalled ===
echo.
pause
exit /b 0

:addroot
if "%~1"=="" exit /b 0
if exist "%~1\steamapps" (
  findstr /b /c:"%~1" "%ROOTS%" >nul 2>&1 || >>"%ROOTS%" echo %~1
)
exit /b 0
