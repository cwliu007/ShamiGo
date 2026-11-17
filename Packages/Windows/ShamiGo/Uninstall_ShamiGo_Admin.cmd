@echo off
setlocal EnableExtensions DisableDelayedExpansion
if exist "%~dp0..\..\..\Packages\Windows\ShamiGo\Tools\Configure_ShamiGo_AutoStart.ps1" goto extracted
echo ERROR: Extract the entire ShamiGo ZIP first.
pause
exit /b 2
:extracted
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\..\Packages\Windows\ShamiGo\Tools\Configure_ShamiGo_AutoStart.ps1" -Mode Uninstall
exit /b %ERRORLEVEL%
