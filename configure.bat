@echo off
rem
rem Checks that a bunch of crap is installed and available on Windows.
rem
echo Configuring C It Run on NT
echo.

rem
rem Need to 'setlocal' otherwise Path modifications get saved to the parent shell.
rem Extends to end of file so we have these modifications the entire time.
rem
setlocal
set Path=C:\Users\kyle\src\jam-2.6\bin.ntx86;%Path%
set Path=C:\LLVM\bin;%Path%

WHERE cl
if %ERRORLEVEL% NEQ 0 (
	echo cl.exe not found on the Path!
	echo(
	echo Please make sure Visual Studio is installed and that you're running this
	echo at a developer command prompt with the correct Path set.

	exit /B 1
)

WHERE jam
if %ERRORLEVEL% NEQ 0 (
	echo jam.exe not found on the Path!
	echo(
	echo Jam can be downloaded by this command:
)

WHERE llvm-config.exe 2>nul
if %ERRORLEVEL% NEQ 0 (
	echo llvm-config.exe not found on the Path!
	echo You need to have compiled the LLVM sources by hand to get this
	echo executable.
	echo(
	echo Download LLVM sources from http://llvm.org/.

	exit /B 1
)

WHERE perl

set CLANG_LIBS=clangAST.lib clangAnalysis.lib clangBasic.lib clangDriver.lib clangEdit.lib clangFrontend.lib clangFrontendTool.lib clangLex.lib clangParse.lib clangRewrite.lib clangRewriteFrontend.lib clangSema.lib clangSerialization.lib clangTooling.lib
set LLVM_LIBS=bitreader mcparser transformutils option

del Jamrules

echo C++FLAGS = /EHsc ; >>Jamrules
echo( >>Jamrules

echo FONT_PATH = "C:\Windows\Fonts\consola.ttf" ; >>Jamrules
echo CITRUN_SHARE = C:\Users\kyle\citrun\src ; >>Jamrules
echo( >>Jamrules

rem GL_CFLAGS = `pkg-config --cflags glfw3 glew freetype2` ;
rem GL_LIBS = ${GL_EXTRALIB-} `pkg-config --libs glfw3 glew freetype2` ;
rem GLTEST_LIBS  = `pkg-config --libs osmesa` ;

echo INST_CFLAGS = >>Jamrules
echo -IC:\\Clang\\include >>Jamrules
llvm-config.exe --cxxflags >>Jamrules
echo ; >>Jamrules
echo( >>Jamrules

echo INST_LDFLAGS = >>Jamrules
echo -LIBPATH:C:\\Clang\\lib >>Jamrules
llvm-config.exe --ldflags >>Jamrules
echo ; >>Jamrules
echo( >>Jamrules

echo INST_LIBS = >>Jamrules
echo %CLANG_LIBS% >>Jamrules
llvm-config.exe --libnames %LLVM_LIBS% >>Jamrules
llvm-config.exe --system-libs >>Jamrules
echo shlwapi.lib version.lib ; >>Jamrules
echo( >>Jamrules

copy /b Jamrules + Jamrules.tail Jamrules

endlocal
