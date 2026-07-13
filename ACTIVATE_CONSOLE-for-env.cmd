
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

@REM Update the *.cmd path and the icon path in the shortcut that launches PyWincmd, if it exists.
@REM This ensures the icon is displayed correctly if the PORTABLE installation folder has been moved.
if exist "%SCRIPT_DIR%\PyWinCMD\images\PWC_128x128.ico" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$ws = New-Object -ComObject WScript.Shell; " ^
        "$s = $ws.CreateShortcut('%SCRIPT_DIR%\PyWinCMD - Activate_CONSOLE-for-env.lnk'); " ^
        "$s.Arguments = 'pWc'; " ^
        "$s.TargetPath = '%SCRIPT_NAME_WITH_PATH%'; " ^
        "$s.WorkingDirectory = '%SCRIPT_DIR%'; " ^
        "$s.IconLocation = '%SCRIPT_DIR%\PyWinCMD\images\PWC_128x128.ico'; " ^
        "$s.Save();"
)

@REM Ensures it is running in the location where this script is located
cd /D "%SCRIPT_DIR%" 
echo Current working folder/directory: %CD%
echo.

call Menu_subdirs.cmd "%SCRIPT_DIR%Envs" "Select a virtual environment"
if [%MENU_SELECTED_SUBDIR%]==[] (goto FIM) else (set "_ENV_=%MENU_SELECTED_SUBDIR%") 

set "THE_ENV_DIR=%SCRIPT_DIR%Envs\%_ENV_%"
echo A virtual environment named %_ENV_% will be activated (if it exists in %SCRIPT_DIR%Envs folder)

REM Check whether a virtual environment named %_ENV_% exists in the current location
if not exist "%THE_ENV_DIR%\Scripts\python.exe" (
    echo ERROR - python.exe was not found in %THE_ENV_DIR%\Scripts
    echo Please run the CREATE_or_REcreate-env.cmd script, then run this script again.
    echo. & pause & goto FIM
)

REM Another test to verify that the newly created '%_ENV_%' environment is working
REM ('call' runs the specified script and KEEPS all variables it sets,
REM  when RETURNING to this console, allowing this CMD script to CONTINUE executing):
call "%THE_ENV_DIR%\Scripts\activate.bat"

if "%VIRTUAL_ENV%" NEQ "%THE_ENV_DIR%" (
    @echo ERROR - Failed to activate the '%_ENV_%' virtual environment using "%THE_ENV_DIR%\Scripts\activate.bat"
    @echo Please run the RECONFIGURE-env.cmd script, then run this script again.
    @echo [If it still does NOT work, then run the CREATE_or_REcreate-env.cmd script.]
    @echo. & pause & goto FIM
)

call "%THE_ENV_DIR%\Scripts\deactivate.bat"

REM Read the file that was saved when this portable Python instalation was created
REM (UTF-8 code page 65001 MUST be active while reading it so that the
REM  test below works correctly, because last_path.txt is ALWAYS created/edited in UTF-8)
chcp 65001 >nul
set /p last_path=<last_path.txt
if "%last_path%" EQU "%cd%" (
    goto CONTINUA1
)
echo This script is running from a different folder than the one where this PORTABLE
echo installation was originally created... this situation would cause errors.
echo Please run the RECONFIGURE-env.cmd script, then run this script again.
echo [If it still does NOT work, then run the CREATE_or_REcreate-env.cmd script.]
echo.
goto FIM

:CONTINUA1
@echo off
@REM Restore the console's previous codepage now that we are about to run the Activate script;
@REM this is not mandatory, but under NORMAL conditions Python uses that codepage after 'Activate'.
@echo Restoring the previous codepage...
@chcp %OLD_CP% >nul
@echo.

@REM Activate the '%_ENV_%' environment and REMAIN in the new 'cmd' prompt spawned

echo Check below if a title beginning with '*** PORTABLE Python ***' is displayed in white text on 
echo a dark GREEN background. If so, then everything is OK: the '%_ENV_%' environment is active!

@REM We must now end the local block, because we are going to spawn new 'cmd' process and STAY there,
@REM so the local variables like _ENV_ wil NOT be erased as it would if we went through the end of this script
@rem Ending the local block erases them all; only two Z_* variables will remain visible (they are harmless)
endlocal & set "Z_PARM1=%1" & set "Z_ENV_DIR=%THE_ENV_DIR%"

@REM Validate this CMD script's input parameter
@REM If it was launched by the 'PyWinCMD-ActivateXxxx' shortcut, it will receive 'PWC' as the first parameter
@if /I "%Z_PARM1%"=="PWC" (
    @cd ".\PyWinCMD"
    @echo Current folder/directory now is: %CD%
    @REM Notice that we do NOT need to use the restricted cmd /k in the line below:
    cmd /c " "%Z_ENV_DIR%\Scripts\activate.bat" & python ".\src\pywincmd.py" "
) else (
    @echo.
    @echo PS - If you get an error message saying that the command prompt is disabled, then run the 
    @echo      'PyWinCMD-Activate env.cmd' script instead [it always starts with an environment activated].
    cmd.exe /K " "%Z_ENV_DIR%\Scripts\activate.bat" & python -c "exit" "
)

:FIM
@echo Restoring the previous codepage...
@chcp %OLD_CP% >nul
@echo.
