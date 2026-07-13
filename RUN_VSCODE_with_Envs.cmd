
@echo off
setlocal enabledelayedexpansion

title Run VSCode in PortablePython4Windows

:: Forces CMD to use the UTF-8 code page to correctly interpret NON-Ascii chars in folder names
chcp 65001 >nul

:: 1. Finds the exact path where this script is running
set "BASE_DIR=%~dp0"

:: 2. Sets WORKON_HOME so VSCode can find the virtual environments
set "WORKON_HOME=%BASE_DIR%Envs"
::echo WORKON_HOME = %WORKON_HOME% 

:: Essential variable IN CASE WORKON_HOME has words with NON-Ascii chars...
:: This forces Python subprocesses to use UTF-8 natively. And magically
:: it fixed WORKON_HOME with NON-Ascii chars: it is now recognized by VSCode 
set "PYTHONUTF8=1"

:: 3. Checks if a project folder was dragged onto this script
set "PROJECT_PATH=%~1"

echo.
echo VSCode will be launched in a separate window.
echo To activate a specific virtual environment inside VSCode, use Ctrl+Shift+P
echo and in the menu that appears, search for "Python: select interpreter" and click on it.
echo.
echo HINT: You can drag and drop a source code folder onto this script and VSCode will open that folder.
echo.
echo.
set /p junk= Press ENTER to start VSCode
echo.
echo Opening VSCode...
if "%PROJECT_PATH%"=="" (
cmd /c code
) else (
cmd /c code "%PROJECT_PATH%"
)
echo.
exit /b

