@ECHO off

SETLOCAL

:: CITRUN_PATH is used in citrun_inst to find the runtime library and compilers.
:: Hook the PATH with our directory that conveniently has a cl.exe in it.
SET CITRUN_PATH=%~dp0
SET Path=%CITRUN_PATH%compilers;%Path%

CALL %*
EXIT /B %ERRORLEVEL%

ENDLOCAL
