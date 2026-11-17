@echo off
setlocal EnableExtensions DisableDelayedExpansion
if exist "%~dp0..\..\Packages\Linux\ShamiGo_VM_Manager.ps1" goto extracted
echo ERROR: Extract the entire ShamiGo ZIP first.
pause
exit /b 2
:extracted
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\Packages\Linux\ShamiGo_VM_Manager.ps1" -Action menu
exit /b %ERRORLEVEL%
