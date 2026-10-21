@echo off
setlocal
title Mythling Realms - Build Roblox Place
cd /d "%~dp0"

where rojo >nul 2>nul
if errorlevel 1 (
  echo.
  echo [ERROR] Rojo CLI was not found in PATH.
  echo.
  echo Install Rojo first, then reopen this file.
  echo Official guide: https://create.roblox.com/docs/projects/external-tools
  echo If you use VS Code, the Rojo extension can help install the tool and plugin.
  echo.
  pause
  exit /b 1
)

echo.
echo ============================================
echo   MYTHLING REALMS - BUILD PLACE FILE
echo ============================================
echo.
echo Building all project scripts and mapped assets from default.project.json...
echo.

rojo build "default.project.json" -o "MythlingRealms.rbxlx"
if errorlevel 1 (
  echo.
  echo [ERROR] Rojo could not build the place. Review the messages above.
  pause
  exit /b 1
)

echo.
echo [SUCCESS] Built:
echo %~dp0MythlingRealms.rbxlx
echo.
echo Open MythlingRealms.rbxlx in Roblox Studio.
echo This build packages the mapped scripts and instances; it does not publish the game.
echo.
pause
endlocal
