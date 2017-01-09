@ECHO off
ECHO ░█▀▀░░░▀█▀░▀█▀░░░█▀▄░█░█░█▀█
ECHO ░█░░░░░░█░░░█░░░░█▀▄░█░█░█░█
ECHO ░▀▀▀░░░▀▀▀░░▀░░░░▀░▀░▀▀▀░▀░▀
ECHO Configuring...
ECHO.

::
:: Need to 'setlocal' otherwise Path modifications get saved to the parent shell.
:: Extends to end of file so we have these modifications the entire time.
::
SETLOCAL
SET Path=C:\LLVM\bin;%Path%

::
:: Check binaries needed for building are available.
::
WHERE cl
IF %ERRORLEVEL% NEQ 0 (
	ECHO cl.exe not found on the Path!
	ECHO Please make sure you run this script from a Developer Command Prompt.
	ECHO.
	PAUSE
	EXIT /B 1
)

WHERE jam
IF %ERRORLEVEL% NEQ 0 (
	ECHO jam.exe not found on the Path!
	PAUSE
	EXIT /B 1
)

WHERE llvm-config 2>nul
IF %ERRORLEVEL% NEQ 0 (
	ECHO llvm-config.exe not found on the Path!
	ECHO.
	ECHO I had to compile LLVM sources to get this  executable.
	ECHO.
	ECHO Download LLVM sources from http://llvm.org/.
	PAUSE
	EXIT /B 1
)

:: Silence warning about exceptions being disabled from xlocale.
>  Jamrules ECHO C++FLAGS = /D_HAS_EXCEPTIONS=0 ;
>> Jamrules ECHO.

>> Jamrules ECHO FONT_PATH = "C:\Windows\Fonts\consola.ttf" ;
>> Jamrules ECHO.

:: GL_CFLAGS = `pkg-config --cflags glfw3 glew freetype2` ;
:: GL_LIBS = ${GL_EXTRALIB-} `pkg-config --libs glfw3 glew freetype2` ;
:: GLTEST_LIBS  = `pkg-config --libs osmesa` ;

>  llvm-config.out llvm-config --cxxflags
SET /p inst_cflags=<llvm-config.out

>> Jamrules ECHO INST_CFLAGS = -IC:\\Clang\\include %inst_cflags:\=\\% ;
>> Jamrules ECHO.

>  llvm-config.out llvm-config --ldflags
SET /p inst_ldflags=<llvm-config.out

>> Jamrules ECHO INST_LDFLAGS = -LIBPATH:C:\\Clang\\lib %inst_ldflags:\=\\% ;
>> Jamrules ECHO.

>  llvm-config.out llvm-config --libnames bitreader mcparser transformutils option
>> llvm-config.out llvm-config --system-libs
SET /p inst_libs_llvm=<llvm-config.out

SET inst_libs_clang=clangAST.lib clangAnalysis.lib clangBasic.lib clangDriver.lib clangEdit.lib clangFrontend.lib clangFrontendTool.lib clangLex.lib clangParse.lib clangRewrite.lib clangRewriteFrontend.lib clangSema.lib clangSerialization.lib clangTooling.lib

>> Jamrules ECHO INST_LIBS = %inst_libs_clang% %inst_libs_llvm%
>> Jamrules ECHO shlwapi.lib version.lib ;

DEL llvm-config.out
ENDLOCAL
