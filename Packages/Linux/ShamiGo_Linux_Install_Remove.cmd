@echo off
setlocal EnableExtensions DisableDelayedExpansion
call "%~dp0..\..\Install_Linux_VM_from_Windows.cmd"
exit /b %ERRORLEVEL%
