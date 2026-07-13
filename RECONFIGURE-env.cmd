
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

call Menu_subdirs.cmd "%SCRIPT_DIR%Envs" "Select a virtual environment"

if [%MENU_SELECTED_SUBDIR%]==[] (goto FIM) else (set "_ENV_=%MENU_SELECTED_SUBDIR%") 

set "THE_ENV_DIR=%SCRIPT_DIR%Envs\%_ENV_%"

@echo Executing:   powershell -File RECONFIGURE-env.ps1 "%_ENV_%"
powershell -File RECONFIGURE-env.ps1 "%_ENV_%"
if %errorlevel% NEQ 0 (echo ======    ERROR executing 'RECONFIGURE-env.ps1' & goto FIM) 

@REM     ------ IMPORTANT -----
@REM We should ALWAYS copy the files 'env_startup.*' that are in the 'templates' folder 
@REM of base path of our portable installation to the environment's Lib\site-packages folder !
@echo Executing:   cmd.exe /C copy /Y "%SCRIPT_DIR%\templates\env_startup.*" "%THE_ENV_DIR%\Lib\site-packages" 
cmd.exe /C copy /Y "%SCRIPT_DIR%\templates\env_startup.*" "%THE_ENV_DIR%\Lib\site-packages"

@REM Each virtual environment keeps in its configuration file the path where it was created.
@REM When such virtual environment folder is moved, it usually will NOT work anymore.
@REM Because of that, we must ensure that the 'base' folder of our PORTABLE installation is correct.
@REM Below, updates 'last_path.txt' with the path where this Python virtual environment is located;
@REM This will be used by the script 'Activate-CONSOLE-for-env.cmd' and other scripts to identify if 
@REM the 'base' folder has been moved to a different location.
@REM ... But first let's ensures output is ALWAYS in UTF-8/65001, for eventual non-ASCII characters 
@REM in the path, since this file can be edited by other scripts or manually in UTF-8 (and it will be)
chcp 65001 >nul
@echo Saving in 'last_path.txt' the current path of this PORTABLE installation.
@echo %CD%>last_path.txt


:FIM
@echo Restoring the previous codepage...
@chcp %OLD_CP% >nul
@echo Press ENTER to close this window
set /P lixo=""
