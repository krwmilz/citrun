@ECHO off
REM
REM Checks that a bunch of crap is installed and available on Windows.
REM
ECHO Configuring C It Run for Windows
ECHO.

REM
REM Need to 'setlocal' otherwise Path modifications get saved to the parent shell.
REM Extends to end of file so we have these modifications the entire time.
REM
SETLOCAL
SET Path=C:\LLVM\bin;%Path%

WHERE cl
IF %ERRORLEVEL% NEQ 0 (
	ECHO cl.exe not found on the Path!
	ECHO(
	ECHO Please make sure Visual Studio is installed and that you're running this
	ECHO at a developer command prompt with the correct Path set.

	EXIT /B 1
)

WHERE jam
IF %ERRORLEVEL% NEQ 0 (
	ECHO jam.exe not found on the Path!
	ECHO(
	ECHO Jam can be downloaded by this command:
)

WHERE llvm-config.exe 2>nul
IF %ERRORLEVEL% NEQ 0 (
	ECHO llvm-config.exe not found on the Path!
	ECHO You need to have compiled the LLVM sources by hand to get this
	ECHO executable.
	ECHO(
	ECHO Download LLVM sources from http://llvm.org/.

	EXIT /B 1
)

SET CLANG_LIBS=clangAST.lib clangAnalysis.lib clangBasic.lib clangDriver.lib clangEdit.lib clangFrontend.lib clangFrontendTool.lib clangLex.lib clangParse.lib clangRewrite.lib clangRewriteFrontend.lib clangSema.lib clangSerialization.lib clangTooling.lib
SET LLVM_LIBS=bitreader mcparser transformutils option

DEL Jamrules

ECHO C++FLAGS = ; >>Jamrules
ECHO( >>Jamrules

ECHO FONT_PATH = "C:\Windows\Fonts\consola.ttf" ; >>Jamrules
ECHO CITRUN_COMPILERS = %CD:\=\\\\%\\\\compilers ; >> Jamrules
ECHO CITRUN_LIB = %CD:\=\\\\%\\\\libcitrun.lib ; >>Jamrules
ECHO( >>Jamrules

REM GL_CFLAGS = `pkg-config --cflags glfw3 glew freetype2` ;
REM GL_LIBS = ${GL_EXTRALIB-} `pkg-config --libs glfw3 glew freetype2` ;
REM GLTEST_LIBS  = `pkg-config --libs osmesa` ;

ECHO INST_CFLAGS = >>Jamrules
ECHO -IC:\\Clang\\include >>Jamrules
llvm-config.exe --cxxflags >>Jamrules
ECHO ; >>Jamrules
ECHO( >>Jamrules

ECHO INST_LDFLAGS = >>Jamrules
ECHO -LIBPATH:C:\\Clang\\lib >>Jamrules
llvm-config.exe --ldflags >>Jamrules
ECHO ; >>Jamrules
ECHO( >>Jamrules

ECHO INST_LIBS = >>Jamrules
ECHO %CLANG_LIBS% >>Jamrules
llvm-config.exe --libnames %LLVM_LIBS% >>Jamrules
llvm-config.exe --system-libs >>Jamrules
ECHO shlwapi.lib version.lib ; >>Jamrules
ECHO( >>Jamrules

COPY /b Jamrules + Jamrules.tail Jamrules

ENDLOCAL
PAUSE
