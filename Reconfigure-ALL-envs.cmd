
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
@REM Use SCRIPTDIR throughout the code, instead of ~dp0, because if ~dp0 used AFTER a CD, then bad things happen 
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_NAME_WITH_PATH=%~f0"

@rem set GETCPCMD=powershell -NoProfile -Command "[Console]::OutputEncoding.CodePage"
@rem set ARGSFOR=tokens=*
set GETCPCMD=chcp
set ARGSFOR=tokens=2 delims=:
FOR /F "%ARGSFOR%" %%A IN ('%GETCPCMD%') DO SET OLD_CP=%%A
echo Original console encoding/codepage: %OLD_CP%
@rem Change to UTF-8 codepage:
chcp 65001
echo.

@REM Ensures it is running in the location where this script is located
cd %SCRIPT_DIR% 
echo Current working folder/directory: %CD%
echo.

set "ENVS_DIR=%SCRIPT_DIR%Envs"

rem Check if the ENVS_DIR folder exists
if not exist "%ENVS_DIR%" (
    echo.
    echo The folder "%ENVS_DIR%" was not found! Exiting...
    exit /b 1
)

rem Traverse each subfolder in ENVS_DIR
for /D %%D in ("%ENVS_DIR%\*") do (
    echo Executing RECONFIGURE-env.ps1 for %%~nxD...
    @REM Return to OLD_CP to avoid Windows bug that 'shrinks' font if codepage is 65001/utf-8 and powershell 
    @REM is called inside ( ) - We can do that because the %env variables% content are codepage 'agnostic'
    chcp %OLD_CP% >nul
    powershell -File "%SCRIPT_DIR%RECONFIGURE-env.PS1" "%%~nxD"
    @REM Back to 65001/UTF-8 
    chcp 65001 >nul
    @REM     ------ IMPORTANT -----
    @REM Ensure that the files 'env_startup.*' which are in the 'templates' folder of our
    @REM our portable installationthe 'base' folder exist in the Lib\site-packages of the virtual env !
    @echo Executing:   cmd.exe /C copy /Y "%SCRIPT_DIR%\templates\env_startup.*" "%ENVS_DIR%\%%~nxD\Lib\site-packages" 
    cmd.exe /C copy /Y "%SCRIPT_DIR%\templates\env_startup.*" "%ENVS_DIR%\%%~nxD\Lib\site-packages"
)

echo.

@REM Every virtual environment keeps in its configuration file the path where it was created.
@REM When such virtual environment folder is moved, it usually will NOT work anymore.
@REM Because of that, we must ensure that the 'base' folder of our PORTABLE installation is correct.
@REM Below, updates 'last_path.txt' with the path where this Python virtual environment is located;
@REM This will be used by the script 'Activate-CONSOLE-for-env.cmd' and other scripts to identify if 
@REM the 'base' folder has been moved to a different location.
@REM ... But first let's ensures output is ALWAYS in UTF-8/65001, for eventual non-ASCII characters 
@REM in the path, since this file can be edited by other scripts or manually in UTF-8 (and it will be)
chcp 65001 >nul
@echo Saving in 'last_path.txt' %CD% as the 'base' folder of this PORTABLE installation.
@echo %CD%>last_path.txt

:FIM
echo.
@echo Restoring the previous codepage...
echo.
@echo Done.  Please check the messages above to see if any command failed.
echo.
@chcp %OLD_CP% >nul
set /P lixo="Press ENTER to close this window "


