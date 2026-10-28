@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "CFG=%~dp0Windows\Tools\Configure_ShamiGo_AutoStart.ps1"
if not exist "%CFG%" (
    echo ERROR: Extract the whole ZIP first. Installer script is missing.
    pause
    exit /b 2
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%CFG%" -Mode Uninstall
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" pause
exit /b %RC%
