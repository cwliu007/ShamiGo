@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem The stable personal folder is valid for both extracted and direct-ZIP installs.
set "TABLES=%LOCALAPPDATA%\ShamiGo\LicensedTables"
if not exist "%TABLES%" mkdir "%TABLES%"
if not exist "%TABLES%" (
 echo [ShamiGo] Could not create the dictionary folder.
 pause
 exit /b 2
)
start "" explorer.exe "%TABLES%"
exit /b 0
