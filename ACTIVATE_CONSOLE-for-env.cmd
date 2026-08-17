
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
set "PYWINCMD_SUBFOLDER=PyWinCMD-2.0.0"
setlocal enabledelayedexpansion
@REM Use SCRIPTDIR throughout the code, instead of ~dp0, because if ~dp0 used AFTER a CD, then bad things happen 
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_NAME_WITH_PATH=%~f0"

:: Trick to get the ESC character to be used with ANSI escape codes
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

@REM The call to powershell MUST be executed with de default CHCP active (before activating 65001/UTF-8)...
@REM otherwise the console fonts 'shrink' (if not using 'Windows Terminal') due to a weird Windows-CMD bug :(

@REM Update the *.cmd path and the icon path in the shortcut that launches PyWincmd, if it exists.
@REM This ensures the icon is displayed correctly if the PORTABLE installation folder has been moved.
if exist "%SCRIPT_DIR%\%PYWINCMD_SUBFOLDER%\images\PWC_128x128.ico" (
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ws = New-Object -ComObject WScript.Shell; " ^
    "$s = $ws.CreateShortcut((Join-Path $env:SCRIPT_DIR 'PyWinCMD - Activate_CONSOLE-for-env.lnk')); " ^
    "$s.Arguments = 'pWc'; " ^
    "$s.TargetPath = $env:SCRIPT_NAME_WITH_PATH; " ^
    "$s.WorkingDirectory = $env:SCRIPT_DIR; " ^
    "$icon_path = Join-Path $env:SCRIPT_DIR (Join-Path $env:PYWINCMD_SUBFOLDER 'images\PWC_128x128.ico'); " ^
    "$s.IconLocation = $icon_path + ',0'; " ^
    "$s.Save();"
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
cd /D "%SCRIPT_DIR%" 
echo Current working folder/directory: "%CD%"
echo.

for /D %%d in ("%SCRIPT_DIR%Envs\*") do goto CONTINUA0
echo %ESC%[31mERROR %ESC%[0m- No virtual environments found at "%SCRIPT_DIR%Envs"
echo Please, run 'CREATE_or_REcreate-env.cmd' before running this script.
pause
goto :FIM

:CONTINUA0
call Menu_subdirs.cmd "%SCRIPT_DIR%Envs" "Select a virtual environment"
if "%MENU_SELECTED_SUBDIR%"=="" (goto FIM) else (set "_ENV_=%MENU_SELECTED_SUBDIR%") 

set "THE_ENV_DIR=%SCRIPT_DIR%Envs\%_ENV_%"
echo A virtual environment named %_ENV_% will be activated (if it exists in "%SCRIPT_DIR%Envs" folder)

REM Check whether a virtual environment named %_ENV_% exists in the current location
if not exist "%THE_ENV_DIR%\Scripts\python.exe" (
    echo %ESC%[31mERROR %ESC%[0m- python.exe was not found in "%THE_ENV_DIR%\Scripts"
    echo Please run the CREATE_or_REcreate-env.cmd script, then run this script again.
    echo. & pause & goto FIM
)

REM Another test to verify that the virtual environment '%_ENV_%' is working
REM ('call' runs the specified script and KEEPS all variables it has set
REM  when RETURNING to this console, allowing this CMD script to CONTINUE executing):
call "%THE_ENV_DIR%\Scripts\activate.bat"
if "%VIRTUAL_ENV%" NEQ "%THE_ENV_DIR%" (
    @echo %ESC%[31mERROR %ESC%[0m- Failed to activate the '%_ENV_%' virtual environment using "%THE_ENV_DIR%\Scripts\activate.bat"
    @echo Please run the RECONFIGURE-env.cmd script, then run this script again.
    @echo [If it still does NOT work, then run the CREATE_or_REcreate-env.cmd script]
    @echo. & pause & goto FIM
)
call "%THE_ENV_DIR%\Scripts\deactivate.bat"

REM Read the file that was saved when this portable Python instalation was created
REM (UTF-8 code page 65001 MUST be active while reading it so that the
REM  test below works correctly, because last_path.txt is ALWAYS created/edited in UTF-8)
chcp 65001 >nul
set /p last_path=<last_path.txt

REM Note that last_path.txt content ALREADY comes with quotation marks (no need to add below)
if %last_path% EQU "%cd%" (
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

@REM Activate the '%_ENV_%' environment and REMAIN in the spawned 'cmd' prompt 

echo Check below if a title beginning with '*** PORTABLE Python ***' is displayed in white text on 
echo a dark GREEN background. If so, then everything is OK: the '%_ENV_%' environment is active!

@REM We must now end the local block, because we are going to spawn new 'cmd' process and STAY there,
@REM so the local variables like _ENV_ wil NOT be erased as it would if we went through the end of this script
@rem Ending the local block erases them all; only two Z_* variables will remain visible (they are harmless)
endlocal & set "Z_PARM1=%1" & set "Z_ENV_DIR=%THE_ENV_DIR%"

:: Adjust below just in case this folder has '&' as part of the name, because, 
:: when using CMD /C, strings inside quotation marks MUST have all the '&' replaced by escaped '^&'
:: (unfortunatelly, Windows allow the special char '&' in names, unlike others forbbiden special chars)
:: PS - Things are pretty confusing: Windows ALSO allows the special chars '(', ')' and '=', but these do NOT require an escape!
:: PS2- This fix has to be done ONLY when using 'cmd.exe'; no fix is necessary for 'call' or direct run.
::      Besides, it must NOT be applyed to strings that are NOT surrounded by quotation marks.
set "Z_ENV_DIR_ESCAPED=%Z_ENV_DIR:&=^&%"

:: We also MUST escape the '(' and ')' chars that are eventually part of the path,
:: whenever we use it inside CMD/C string  and inside blocks surrounded by these 2 chars !!
set "Z_ENV_DIR_ESCAPED=%Z_ENV_DIR_ESCAPED:)=^)%"
set "Z_ENV_DIR_ESCAPED=%Z_ENV_DIR_ESCAPED:(=^(%"
echo.

@REM Validate this CMD script's input parameter
@REM If it was launched by the 'PyWinCMD-ActivateXxxx' shortcut, it will receive 'PWC' as the first parameter
@if /I "%Z_PARM1%"=="PWC" (
    @cd %PYWINCMD_SUBFOLDER%
    @echo Current folder/directory is now: "%CD%"
    @REM Notice that we do NOT need to use the restricted cmd /k in the line below:
    cmd /c " "%Z_ENV_DIR_ESCAPED%\Scripts\activate.bat" & python ".\src\pywincmd.py" "
) else (
    @echo PS - If you get an error message saying that the command prompt is disabled, then run the 
    @echo      'PyWinCMD-Activate env.cmd' script instead [it always starts with an environment activated].
    cmd.exe /K " "%Z_ENV_DIR_ESCAPED%\Scripts\activate.bat" & python -c "exit" "
)

:FIM
@echo.
@echo Restoring the previous codepage...
@chcp %OLD_CP% >nul
@echo.
