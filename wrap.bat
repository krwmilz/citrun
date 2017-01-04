@ECHO off

SETLOCAL
SET Path=C:\Users\kyle\citrun\compilers;%Path%
CALL %*
exit /B %ERRORLEVEL%
ENDLOCAL
