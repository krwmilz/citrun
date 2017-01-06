@ECHO off
REM
REM Checks that a bunch of crap is installed and available on Windows.
REM
ECHO.
ECHO !! Windows configuration script running.
ECHO.

REM
REM Need to 'setlocal' otherwise Path modifications get saved to the parent shell.
REM Extends to end of file so we have these modifications the entire time.
REM
SETLOCAL
SET Path=C:\LLVM\bin;%Path%

REM
REM Check binaries needed for building are available.
REM

WHERE cl >nul
IF %ERRORLEVEL% NEQ 0 (
	ECHO cl.exe not found on the Path!
	ECHO.
	ECHO Please make sure Visual Studio is installed and that you're running this
	ECHO at a developer command prompt with the correct Path set.
	EXIT /B 1
)

WHERE jam >nul
IF %ERRORLEVEL% NEQ 0 (
	ECHO jam.exe not found on the Path!
	EXIT /B 1
)

WHERE llvm-config >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
	ECHO llvm-config.exe not found on the Path!
	ECHO.
	ECHO I had to compile LLVM sources to get this  executable.
	ECHO.
	ECHO Download LLVM sources from http://llvm.org/.
	EXIT /B 1
)

WHERE perl >nul
IF %ERRORLEVEL% NEQ 0 (
	ECHO Perl not found.
	ECHO
	ECHO Consider installing Strawberry Perl from
	ECHO http://strawberryperl.com
	EXIT /B 1
)


SET CLANG_LIBS=clangAST.lib clangAnalysis.lib clangBasic.lib clangDriver.lib clangEdit.lib clangFrontend.lib clangFrontendTool.lib clangLex.lib clangParse.lib clangRewrite.lib clangRewriteFrontend.lib clangSema.lib clangSerialization.lib clangTooling.lib
SET LLVM_LIBS=bitreader mcparser transformutils option

DEL Jamrules 2>nul

>> Jamrules ECHO C++FLAGS = ;
>> Jamrules ECHO.

>> Jamrules ECHO FONT_PATH = "C:\Windows\Fonts\consola.ttf" ;
>> Jamrules ECHO CITRUN_COMPILERS = %CD:\=\\%\\compilers ;
>> Jamrules ECHO CITRUN_LIB = %CD:\=\\%\\libcitrun.lib ;
>> Jamrules ECHO.

REM GL_CFLAGS = `pkg-config --cflags glfw3 glew freetype2` ;
REM GL_LIBS = ${GL_EXTRALIB-} `pkg-config --libs glfw3 glew freetype2` ;
REM GLTEST_LIBS  = `pkg-config --libs osmesa` ;

>> Jamrules ECHO INST_CFLAGS =
>> Jamrules ECHO -IC:\\Clang\\include
>> Jamrules llvm-config --cxxflags
>> Jamrules ECHO ;
>> Jamrules ECHO.

>> Jamrules ECHO INST_LDFLAGS =
>> Jamrules ECHO -LIBPATH:C:\\Clang\\lib
>> Jamrules llvm-config --ldflags
>> Jamrules ECHO ;
>> Jamrules ECHO.

>> Jamrules ECHO INST_LIBS =
>> Jamrules ECHO %CLANG_LIBS%
>> Jamrules llvm-config --libnames %LLVM_LIBS%
>> Jamrules llvm-config --system-libs
>> Jamrules ECHO shlwapi.lib version.lib ;
>> Jamrules ECHO.

REM Append Jamrules.tail to generated Jamrules.
COPY /b Jamrules + Jamrules.tail Jamrules >nul

ENDLOCAL
ECHO !! Jamrules written, configuration is complete.
PAUSE
