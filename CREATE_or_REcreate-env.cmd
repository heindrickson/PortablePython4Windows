
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
@REM Use SCRIPT_DIR throughout the code, instead of ~dp0, because if ~dp0 used AFTER a CD, then bad things happen 
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_NAME_WITH_PATH=%~f0"

set "RET_CODE=0"

@rem set GETCPCMD=powershell -NoProfile -Command "[Console]::OutputEncoding.CodePage"
@rem set ARGSFOR=tokens=*
set GETCPCMD=chcp
set ARGSFOR=tokens=2 delims=:
FOR /F "%ARGSFOR%" %%A IN ('%GETCPCMD%') DO SET OLD_CP=%%A
echo Original console encoding/codepage: %OLD_CP%
@rem Change to UTF-8 codepage:
chcp 65001
echo.

:: Trick to get the ESC character for ANSI escape codes
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

@rem Get the name of the virtual environment to create or use the name set in parameter 1
set "_ENV_="
:GETENV
if "%~1" EQU "" (
    set /P "_ENV_=Enter the name of the virtual environment to be created or 'X' to abort: "
) else (
    set "_ENV_=%~1"
)
if "%_ENV_%"=="" echo Invalid name & goto GETENV
if "%_ENV_:~,1%"==" " echo Invalid name & goto GETENV
if /I "%_ENV_:~,1%"=="X" echo Aborted... & SET "RET_CODE=888" & goto FIM

echo.
echo -------------------------------------
echo Environment name: "%_ENV_%"
echo -------------------------------------   
echo.

@REM Ensures it is running in the location where this script is located
cd %SCRIPT_DIR% 
echo Current working folder/directory: %CD%

set "THE_ENV_DIR=%SCRIPT_DIR%Envs\%_ENV_%"

set "PYTHON_FOLDER="
if "%~2" EQU "" (
    goto GETPYTHON
) else (
    set "PYTHON_FOLDER=%~2"
)
if "%PYTHON_FOLDER:~,1%"==" " (echo Invalid python folder & goto GETPYTHON) else (goto SEGUE1)

@REM Select one of the python folders that is located at the 'base' folder of our PORTABLE installation
@REM PS - those python folders are generated ONLY after running the 
:GETPYTHON
call Menu_subdirs.cmd "%SCRIPT_DIR%" "Select a python version to use in the new environment" "python*embed*amd*"
if "%MENU_SELECTED_SUBDIR%"=="" (
    @rem If empty, the user aborted the selection
    set "RET_CODE=1" & goto FIM
) else (
    set "PYTHON_FOLDER=%MENU_SELECTED_SUBDIR%"
)

:SEGUE1
@echo off
if  defined PYTHON_FOLDER if exist "%PYTHON_FOLDER%\python.exe" goto SEGUE2
echo ERROR - There is no python folder or python.exe was not found in it: %PYTHON_FOLDER%
SET "RET_CODE=888" & goto FIM

:SEGUE2
echo Found python.exe in: %PYTHON_FOLDER%
echo.

echo A virtual environment named %ESC%[30m%ESC%[103m '%_ENV_%' %ESC%[0m will be created (or recreated) and 
echo it will be associated to this python version: %ESC%[30m%ESC%[103m '%PYTHON_FOLDER%' %ESC%[0m. 
echo If a '%_ENV_%_requirements.txt' file exists, it will be used to install 
echo libraries into the new created environment.
echo.

:SEGUE3
set /P "confirm=Enter 'S' to start the creation of the '%_ENV_%' environment or 'X' to abort: "
if /I "%confirm%"=="" goto SEGUE3
if /I "%confirm:~,1%"==" " goto SEGUE3
if /I "%confirm:~,1%"=="X" (echo Aborted... & set "RET_CODE=1" & goto FIM)

@echo.
@echo Deleting previous version of the virtual environment, if it exists...
if exist "%THE_ENV_DIR%" rmdir /S /Q "%THE_ENV_DIR%"

@echo.
@echo Creating the virtual environment with name '%_ENV_%', please wait...
"%PYTHON_FOLDER%\python.exe" -m virtualenv "%THE_ENV_DIR%" > nul

@REM     ------ IMPORTANT -----
@REM We should ALWAYS copy the files 'env_startup.*' that are in the 'templates' folder 
@REM of base path of our portable installation to the environment's Lib\site-packages folder !
echo Executando o comando:  copy /Y "%SCRIPT_DIR%\templates\env_startup.*" "%THE_ENV_DIR%\Lib\site-packages" 
cmd.exe /C copy /Y "%SCRIPT_DIR%\templates\env_startup.*" "%THE_ENV_DIR%\Lib\site-packages"

@REM Tests if the newly created %_ENV_% environment is actually working
if not exist "%THE_ENV_DIR%\Scripts\python.exe" (
    @echo ERROR - python.exe was not found in %THE_ENV_DIR%\Scripts
    @echo The virtual environment '%_ENV_%' was NOT created correctly :(   Execution canceled!
    set "RET_CODE=888" & goto FIM
)
@REM Another test to check if the newly created %_ENV_% environment is working
@REM ('call' executes the called script and KEEPS all variables set there,
@REM  upon RETURNING to this console;  that is what we want):
call "%THE_ENV_DIR%\Scripts\activate.bat"
if "%VIRTUAL_ENV%" NEQ "%THE_ENV_DIR%" (
    @echo ERROR - When trying to activate the %_ENV_% environment with "%THE_ENV_DIR%\Scripts\activate.bat" 
    @echo The virtualenv '%_ENV_%' was NOT created correctly :[   Execution canceled!
    set "RET_CODE=888" & goto FIM
)

@REM When a virtual environment is activated, just typing 'python' will pick up the virtual-env's executable

@REM The call below runs sitecustomize.py and a title should appear in a DARK GREEN background:
python  -c "exit"   
@REM But the call below does NOT show the title, hence the line above :( sitecustomize.py does NOT run):
python --version   

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

@echo.
@echo Installing required libraries...
@REM Executes pip inside the %_ENV_% environment... 
@REM At this point the %_ENV_% environment IS STILL activated,  so typing 'python' ALWAYS targets the correct one 
if exist "%_ENV_%_requirements.txt"  (
    python -m pip install -r "%_ENV_%_requirements.txt" || (
        echo ERROR installing libraries from '%_ENV_%_requirements.txt' into '%_ENV_%'... Aborted! 
        set "RET_CODE=888" & goto FIM
    )
) 
@echo The %_ENV_% environment was (re)created and the libs in requirements.txt, if any, were installed.
@REM Calling 'python' after the virtual env is activated uses the python FROM that environment
python -m pip list

@REM Deactivates the %_ENV_% virtual environment 
@echo Deactivating the '%_ENV_%' environment
@echo.
@call "%THE_ENV_DIR%\Scripts\deactivate.bat"
@echo If a title with '*** PORTABLE Python ***' in white letters and dark GREEN background was shown, pointing
@echo to a path ending with '%_ENV_%\Scripts', then the '%_ENV_%' virtual environment was successfully created!
@echo.

:FIM
@echo Restoring the previous codepage...
@chcp %OLD_CP% >nul
@pause
exit /b %RET_CODE%
