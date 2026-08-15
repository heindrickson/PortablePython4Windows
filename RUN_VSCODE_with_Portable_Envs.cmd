
@echo off
setlocal enabledelayedexpansion

title Run VSCode that can 'see' portable environments

:: Forces CMD to use the UTF-8 code page to correctly interpret NON-Ascii chars in folder names
chcp 65001 >nul

:: 1. Finds the exact path where this script is running
set "BASE_DIR=%~dp0"

:: 2. Sets WORKON_HOME so VSCode can find our PORTABLE virtual environments (this is the 'MAGIC' :)
set "WORKON_HOME=%BASE_DIR%Envs"
::echo WORKON_HOME = %WORKON_HOME% 

:: Essential variable IN CASE WORKON_HOME has words with NON-Ascii chars...
:: This forces Python subprocesses to use UTF-8 natively and magically
:: it fixed WORKON_HOME with NON-Ascii chars: they are now recognized by VSCode 
set "PYTHONUTF8=1"

:: 3. Checks if a project folder was dragged onto this script
set "PROJECT_PATH=%~1"

rem ============================================================
rem Find all available VSCode installations (Portable + PATH)
rem ============================================================

set "COUNT=0"

rem First, check for a Portable VSCode installation in the script's directory
set "PORTABLE_VSCODE=%BASE_DIR%VSCode-Portable\Code.exe"
if exist "!PORTABLE_VSCODE!" (
    set /a COUNT+=1
    set "CODE[!COUNT!]=!PORTABLE_VSCODE!"
)

rem Next, find Code.exe natively if it was added directly to the PATH
for /f "delims=" %%C in ('where.exe code.exe 2^>nul') do (
    set /a COUNT+=1
    set "CODE[!COUNT!]=%%C"
)

rem Finally, look for 'code.cmd' (the default PATH entry) and resolve its true 'Code.exe'
for /f "delims=" %%C in ('where.exe code.cmd 2^>nul') do (
    rem Goes up one directory from the \bin\ folder to find the real EXE
    for %%A in ("%%~dpC..") do set "VSCODE_DIR=%%~fA"
    set "EXE_PATH=!VSCODE_DIR!\Code.exe"
    
    if exist "!EXE_PATH!" (
        rem Avoid duplicates if both code.cmd and code.exe pointed to the same place
        set "DUPLICATE=0"
        for /L %%N in (1,1,!COUNT!) do (
            if /I "!CODE[%%N]!"=="!EXE_PATH!" set "DUPLICATE=1"
        )
        if "!DUPLICATE!"=="0" (
            set /a COUNT+=1
            set "CODE[!COUNT!]=!EXE_PATH!"
        )
    )
)

rem ============================================================
rem No code executable found
rem ============================================================

if %COUNT%==0 (
    echo.
    echo ERROR: No VSCode installation was found in the portable folder or in PATH.
    echo.
    pause
    exit /b 1
)

rem ============================================================
rem Only one code executable -- use it automatically
rem ============================================================

if %COUNT%==1 (
    set "CODE=!CODE[1]!"
    goto :Launch
)

rem ============================================================
rem More than one VSCode found -- ask the user
rem ============================================================

echo.
echo Multiple VS Code installations were found:
echo.

for /L %%N in (1,1,%COUNT%) do (
    echo   %%N^) !CODE[%%N]!
)

echo.
echo   Q^) Quit
echo.

:Choose
set "CHOICE="
set /p "CHOICE=Select the VS Code installation [1-%COUNT%]: "

if /i "%CHOICE%"=="Q" (
    echo.
    echo Cancelled.
    exit /b 0
)

rem Validate numeric selection
set "CODE="

for /L %%N in (1,1,%COUNT%) do (
    if "%CHOICE%"=="%%N" set "CODE=!CODE[%%N]!"
)

if not defined CODE (
    echo.
    echo Invalid selection. Please try again.
    echo.
    goto :Choose
)

rem ============================================================
rem Launch selected VS Code
rem ============================================================

:Launch
echo.
echo VSCode will be launched in a separate window.
echo Inside VSCode, follow these steps to activate and use a PORTABLE virtual environment:
echo - press Ctrl+Shift+P
echo - in the menu that appears, search for "Python: select interpreter" and select that option
echo - wait a few seconds, until a list of virtual environments is displayed
echo - locate your PORTABLE virtual environment in that list and select it  
echo - confirm that the name of the selected environment appears at the bottom right of the VS Code window.  

echo.
if "%PROJECT_PATH%"=="" (
  echo HINT: You can drag and drop a source code folder onto this script and VSCode will open that folder.
) else (
  echo You dragged a project - it will be opened by VSCode: "%PROJECT_PATH%"
)
echo.
set /p junk= Press ENTER to start VSCode
echo.
echo Opening VSCode...

rem Using start "" to completely detach the VSCode GUI process from this CMD window
if "%PROJECT_PATH%"=="" (
  start "" "%CODE%" 
) else (
  start "" "%CODE%" "%PROJECT_PATH%"
)

echo.
endlocal
exit



