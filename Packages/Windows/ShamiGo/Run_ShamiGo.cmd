@echo off
setlocal EnableExtensions DisableDelayedExpansion
call "%~dp0..\..\..\Run_Windows.cmd"
exit /b %ERRORLEVEL%
