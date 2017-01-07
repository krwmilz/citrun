@ECHO off
REM
REM Checks that a bunch of crap is installed and available on Windows.
REM

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



DEL Jamrules 2>nul

:: Silence warning about exceptions being disabled from xlocale.
>> Jamrules ECHO C++FLAGS = /D_HAS_EXCEPTIONS=0 ;
>> Jamrules ECHO.

>> Jamrules ECHO FONT_PATH = "C:\Windows\Fonts\consola.ttf" ;
>> Jamrules ECHO CITRUN_COMPILERS = %CD:\=/%/compilers ;
>> Jamrules ECHO CITRUN_LIB = %CD:\=/%/libcitrun.lib ;
>> Jamrules ECHO.

REM GL_CFLAGS = `pkg-config --cflags glfw3 glew freetype2` ;
REM GL_LIBS = ${GL_EXTRALIB-} `pkg-config --libs glfw3 glew freetype2` ;
REM GLTEST_LIBS  = `pkg-config --libs osmesa` ;

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
>> Jamrules ECHO.
>> Jamrules ECHO include Jamrules.tail ;

DEL llvm-config.out
ENDLOCAL

ECHO !! C It Run Windows configuration script finished.
PAUSE
