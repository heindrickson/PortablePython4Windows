
@REM *********** IMPORTANT **********************************************************************
@REM This script is saved in UTF-8 encoding, so we need to force
@REM the console to use codepage 65001 below, via 'chcp'.  And WHY use UTF-8??
@REM a) to maintain a single unique encoding standard for all scripts, avoiding eventual
@REM    generation/modification in different encodings, causing problems (items b and c);
@REM b) to guarantee that scripts created/edited in Notepad++ and VSCode in UTF-8
@REM    correctly display any non-ASCII characters shown via 'echo';  
@REM c) to guarantee uniform and correct read/write of the 'last_path' file used ahead 
@REM    as well as its reading in python (prevents MISINTERPRETING non-ASCII paths/file names). 
@REM ********************************************************************************************
@REM NOTE: Notice that the 'codepage' ONLY affects the encoding of I/O done in the app CONSOLE,
@REM       it does NOT affect the encoding of FILES read/written by python.exe, because Python's 
@REM       file I/O follows the 'locale' mechanism (it is independent of the CONSOLE 'codepage').
@REM ********************************************************************************************

@echo off
setlocal enabledelayedexpansion

@rem set GETCPCMD=powershell -NoProfile -Command "[Console]::OutputEncoding.CodePage"
@rem set ARGSFOR=tokens=*
set GETCPCMD=chcp
set ARGSFOR=tokens=2 delims=:
FOR /F "%ARGSFOR%" %%A IN ('%GETCPCMD%') DO SET OLD_CP=%%A
echo Original console encoding/codepage: %OLD_CP%
@rem Change to UTF-8 codepage:
chcp 65001
echo.


:GET_VRS
echo Check the available Python versions at: https://www.python.org/downloads/windows/
set /p "PYT_VRS=Please enter the Python version to install in this PORTABLE folder (e.g.: 3.13.14): "
if "%PYT_VRS%"=="" goto GET_VRS


REM Ensures it is running in the location where this script is located
cd "%~dp0" 
echo.
echo Current working folder/directory: %CD%

echo.
echo ATTENTION - The chosen Python version is: %PYT_VRS%
echo             If that version exists, the installer will be downloaded and Python will be 
echo             installed in '%CD%' 
echo             This will overwrite any same version Python already installed in such folder.
echo. 
set /p "TECLA=Enter 'S' to start the installation or ANY OTHER key to abort: "
if /I "%TECLA:~,1%" equ "S" (
    goto INSTALA
)
echo Exiting without installing anything...
goto FIM

:INSTALA
@REM Return to OLD_CP to avoid Windows bug that 'shrinks' font if codepage is 65001/utf-8 and powershell 
@REM is called inside ( ) - We can do that because the %env variables% content are codepage 'agnostic'
chcp %OLD_CP% >nul
powershell -File ADD_Portable_Python_version.ps1 -version %PYT_VRS%
if %ERRORLEVEL% equ 0 goto FIM

pause

:FIM 
@echo Restoring the previous codepage...
@chcp %OLD_CP%
exit /b
