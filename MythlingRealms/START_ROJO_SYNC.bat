@echo off
setlocal
title Mythling Realms - Rojo Sync
cd /d "%~dp0"

where rojo >nul 2>nul
if errorlevel 1 (
  echo.
  echo [ERROR] Rojo CLI was not found in PATH.
  echo Official guide: https://create.roblox.com/docs/projects/external-tools
  echo.
  pause
  exit /b 1
)

echo.
echo Starting Rojo for the Mythling Realms project...
echo Leave this window open while syncing.
echo In Roblox Studio: open your place, open the Rojo plugin, and connect to the server.
echo.
rojo serve "default.project.json"
pause
endlocal
