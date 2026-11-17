@echo off
setlocal EnableExtensions DisableDelayedExpansion
call "%~dp0..\..\..\Uninstall_Windows.cmd"
exit /b %ERRORLEVEL%
