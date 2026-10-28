@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "ROOT=%~dp0"
set "CFG=%ROOT%Windows\Tools\Configure_ShamiGo_AutoStart.ps1"
if not exist "%ROOT%Windows\ShamiGo_v0.10.394.exe" goto missing
if not exist "%ROOT%Windows\ShamiGo_AdminSetup.exe" goto missing
if not exist "%ROOT%Windows\LicensedTables\README.txt" goto missing
if not exist "%ROOT%Windows\ShamiGo_Help.html" goto missing
if not exist "%CFG%" goto missing
if not exist "%ROOT%Windows\liu.box" (
    >"%ROOT%Windows\liu.box" echo ; ShamiGo optional local dictionary (not distributed).
    if errorlevel 1 (
        echo ERROR: Cannot create Windows\liu.box. Extract ZIP into a writable folder.
        pause
        exit /b 2
    )
)
if not exist "%ROOT%Windows\LicensedTables\liu-uni.tab" (
    echo NOTE: No local liu-uni.tab supplied. A fresh installation cannot type
    echo       until you supply your own properly licensed dictionary.
)
set "MODE=Install"
if /I "%~1"=="/remove" set "MODE=Disable"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%CFG%" -Mode %MODE%
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" pause
exit /b %RC%
:missing
echo ERROR: Required Windows installer components are missing.
echo Please extract the ENTIRE ZIP before running Install_Windows.cmd.
pause
exit /b 2
