
@REM *********** IMPORTANT **********************************************************************
@REM This script is saved in UTF-8 encoding, so we need to force
@REM the console to use codepage 65001 below, via 'chcp'.  And WHY use UTF-8??
@REM a) to maintain a single unique encoding standard for all scripts, avoiding eventual
@REM    generation/modification in different encodings, causing problems (items b and c);
@REM b) to guarantee that scripts created/edited in Notepad++ and VSCode in UTF-8
@REM    correctly display any non-ASCII characters shown via 'echo';  
@REM c) to guarantee uniform and correct read/write of files and folder NAMES in the script
@REM    as well as inside python (prevents MISINTERPRETING non-ASCII paths/file names). 
@REM ********************************************************************************************
@REM NOTE: Notice that the 'codepage' ONLY affects the encoding of I/O done in the app CONSOLE,
@REM       it does NOT affect the encoding of FILES read/written by python.exe, because Python's 
@REM       file I/O follows the 'locale' mechanism (it is independent of the CONSOLE 'codepage').
@REM ********************************************************************************************

@echo off
:: Enables delayed variable expansion (essential for creating arrays/lists in CMD)
setlocal enabledelayedexpansion

@REM Use SCRIPTDIR throughout the code, instead of ~dp0, because if ~dp0 used AFTER a CD, then bad things happen 
set "SCRIPT_DIR=%~dp0"
@rem set GETCPCMD=powershell -NoProfile -Command "[Console]::OutputEncoding.CodePage"
@rem set ARGSFOR=tokens=*

set GETCPCMD=chcp
set ARGSFOR=tokens=2 delims=:
FOR /F "%ARGSFOR%" %%A IN ('%GETCPCMD%') DO SET OLD_CP=%%A
@REM echo Original console encoding/codepage: %OLD_CP%
@rem Change to UTF-8 codepage:
chcp 65001 >nul
@rem echo.

@REM Ensures it is running in the location where this script is located
cd /D "%SCRIPT_DIR%" 
::echo Current working folder/directory: %CD%
::echo.

:: Resets this variable (starts empty/undefined at the beginning of this script):
set "MENU_SELECTED_SUBDIR="

:: Uses the received parameter as the target folder, or uses the folder where this script is located
:: PS ==>   %1 includes the received surrounding quotes;    %~1 removes the surrounding quotes.
if "%~1"=="" (
    set "TARGET_FOLDER=%SCRIPT_DIR%"
) else (
    set "TARGET_FOLDER=%~1"
)

if "%~2"=="" (
    set "OPTION_STR=an option"
) else (
    set "OPTION_STR=%~2"
)

if "%~3"=="" (
    set "FILTER=*"
) else (
    set "FILTER=%~3"
)

set /a counter=0

echo ==============================================================
echo MENU FOR %TARGET_FOLDER% (filter: %FILTER%)
echo ==============================================================
:: The 'for /d' command iterates through SUBdirectories only.
:: %%~nxF gets the Name and eXtension of the subfolder (ignoring the full path)
for /d %%F in ("%TARGET_FOLDER%\%FILTER%") do (
    set /a counter+= 1
    :: Stores the subdir name in a dynamic variable (e.g.: subdir_1, subdir_2...)
    set "subdir_!counter!=%%~nxF"
   :: Displays the option on the screen
   echo !counter! - %%~nxF
)
echo X - Abort the selection

:: Checks whether any subdir was found
if %counter%==0 (
    echo.
    echo No subdirectory matched the filter in "%TARGET_FOLDER%".
    pause
    exit /b
)

echo =====================================
echo.
:SELECT
:: Prompts the user to make a selection
set /p "option=%OPTION_STR% - Enter the corresponding number (1 to %counter%): "
:: Basic validation: checks whether the user entered something and whether it is within the valid range
if "%option%"=="" echo Invalid option & goto SELECT
if "%option:~,1%"==" " echo Invalid option & goto SELECT
if /I "%option%"=="X" echo Selection aborted... & goto FIM
if %option% LSS 1 echo Invalid option & goto SELECT
if %option% GTR %counter% echo Invalid option & goto SELECT

:: Retrieves the folder name based on the entered number
set "selected_subdir=!subdir_%option%!"

echo.
echo -------------------------------------
echo You selected: %selected_subdir%
echo -------------------------------------   
goto FIM

:FIM
:: The ampersand below makes the local 'selected_subdir' variable visible to the calling script
:: PS - remember that it may be returned empty/undefined if the selected option was invalid
endlocal & set "MENU_SELECTED_SUBDIR=%selected_subdir%"
:: echo Content of the visible MENU_SELECTED_SUBDIR variable: %MENU_SELECTED_SUBDIR%
@chcp %OLD_CP% >nul
@echo.
exit /b
