@echo off
setlocal EnableExtensions DisableDelayedExpansion
call "%~dp0..\..\..\Install_Windows.cmd"
exit /b %ERRORLEVEL%
