
@REM *********** IMPORTANT **********************************************************************
@REM This script is saved in UTF-8 encoding, so we need to force
@REM the console to use codepage 65001 below, via 'chcp'.  And WHY use UTF-8??
@REM a) to maintain a single unique encoding standard for all scripts, avoiding eventual
@REM    generation/modification in different encodings, causing problems (items b and c);
@REM b) to ensure that scripts created/edited in Notepad++ and VSCode in UTF-8
@REM    correctly display any non-ASCII characters printed via 'echo';  
@REM c) to guarantee uniform and correct read/write of the 'last_path' file used ahead 
@REM    as well as its reading in python (prevents MISINTERPRETING non-ASCII paths/file names). 
@REM ********************************************************************************************
@REM NOTE: Notice that the 'codepage' ONLY affects the encoding of I/O done in the app CONSOLE,
@REM       it does NOT affect the encoding of FILES read/written by python.exe, because Python's 
@REM       file I/O follows the 'locale' mechanism (it is independent of the CONSOLE 'codepage').
@REM ********************************************************************************************

@echo off
setlocal enabledelayedexpansion

:: Trick to get the ESC character to be used with ANSI escape codes
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

@REM Use SCRIPTDIR throughout the code, instead of ~dp0, because if ~dp0 used AFTER a CD, then bad things happen 
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_NAME_WITH_PATH=%~f0"

:: Checks if the absolute path of this folder contains the Powershell escape char or brackets: '`', '[' or ']'
:: We can NOT allow that, because we use a powershell script ('RECONFIGURE-env.PS1') as the actual 
:: engine to reconfigure the virtual environments, and that framework treats brackets as wildcards. 
:: And using the escape char '`' to escape the '`' symbol would add more complexity.
:: No simple solution was found to ensure correct escape of those 3 symbols in the .ps1 script.
:: PS - We tested to escape the symbols with "`" and -LiteralPath in .ps1,  works for SOME cases, not for others.
::      So, the use of  '['  or  ']'  and  '`'  in the path of the 'base' folder is now forbidden in PortablePython4Windows.
echo "%SCRIPT_DIR%" | findstr /r "[\[\`\]]" >nul
if %errorlevel% EQU 0 (
    echo %ESC%[31m--- CRITICAL ERROR --- %ESC%[0m
    echo The 'base' folder of this portable installation has symbol '`' or '[' or ']', which causes errors in PowerShell.
    echo Please rename or move the folder to a directory that does NOT use these characters in the path name and try again.
    goto FIM
)

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
cd "%SCRIPT_DIR%" 
echo Current working folder/directory: "%CD%"
echo.

call Menu_subdirs.cmd "%SCRIPT_DIR%Envs" "Select a virtual environment"

if [%MENU_SELECTED_SUBDIR%]==[] (goto FIM) else (set "_ENV_=%MENU_SELECTED_SUBDIR%") 

set "THE_ENV_DIR=%SCRIPT_DIR%Envs\%_ENV_%"

@echo Executing:   powershell -File RECONFIGURE-env.ps1 "%_ENV_%"
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File RECONFIGURE-env.ps1 "%_ENV_%"
if %errorlevel% NEQ 0 (echo ======    ERROR executing 'RECONFIGURE-env.ps1' & goto FIM) 

@REM     ------ IMPORTANT -----
@REM We should ALWAYS copy the files 'env_startup.*' that are in the 'templates' folder 
@REM of base path of our portable installation to the environment's Lib\site-packages folder !
@echo Executing:  copy /Y "%SCRIPT_DIR%\templates\env_startup.*" "%THE_ENV_DIR%\Lib\site-packages" 
copy /Y "%SCRIPT_DIR%\templates\env_startup.*" "%THE_ENV_DIR%\Lib\site-packages"

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
@echo "%CD%">last_path.txt


:FIM
@echo Restoring the previous codepage...
@chcp %OLD_CP% >nul
@echo Press ENTER to close this window
set /P lixo=""
