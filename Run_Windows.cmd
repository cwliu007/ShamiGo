@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "ROOT=%~dp0Windows"
if not exist "%ROOT%\ShamiGo_v0.10.394.exe" (
    echo ERROR: Extract the entire ZIP before running this launcher.
    pause
    exit /b 2
)
if not exist "%ROOT%\LicensedTables\liu-uni.tab" (
    echo NOTE: Copy your own properly licensed liu-uni.tab into
    echo       Windows\LicensedTables first, or run the protected installer
    echo       after adding the file there. ShamiGo cannot type without it.
    pause
    exit /b 3
)
start "" /D "%ROOT%" "%ROOT%\ShamiGo_v0.10.394.exe"
exit /b %ERRORLEVEL%
