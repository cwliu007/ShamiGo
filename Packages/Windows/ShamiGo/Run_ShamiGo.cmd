@echo off
setlocal EnableExtensions DisableDelayedExpansion
if exist "%~dp0..\..\..\Packages\Windows\ShamiGo\ShamiGo.exe" goto extracted
echo ERROR: Extract the entire ShamiGo ZIP first.
pause
exit /b 2
:extracted
if exist "%~dp0..\..\..\Tools\Prepare_Windows_Data.ps1" (
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\..\Tools\Prepare_Windows_Data.ps1" -ReleaseRoot "%~dp0..\..\..\."
  if errorlevel 1 (echo ERROR: Personal data preparation failed. & pause & exit /b 1)
)
if exist "%~dp0..\..\..\Data\EnglishECDICT.tar.xz" if exist "%~dp0..\..\..\Data\EnglishUsage.tar.xz" if exist "%~dp0..\..\..\Data\EnglishChineseReverse.tar.xz" (
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\..\Packages\Windows\ShamiGo\Tools\Prepare_ECDICT.ps1" -Archive "%~dp0..\..\..\Data\EnglishECDICT.tar.xz" -UsageArchive "%~dp0..\..\..\Data\EnglishUsage.tar.xz" -ReverseArchive "%~dp0..\..\..\Data\EnglishChineseReverse.tar.xz"
  if errorlevel 1 (echo ERROR: ECDICT preparation failed. & pause & exit /b 21)
)
start "" /D "%~dp0..\..\..\Packages\Windows\ShamiGo" "%~dp0..\..\..\Packages\Windows\ShamiGo\ShamiGo.exe"
exit /b %ERRORLEVEL%
