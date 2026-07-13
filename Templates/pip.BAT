
@echo off
REM Ensures that the 'pip' command, when executed from the folder where our "base" Python 
REM is located, always invokes the pip.exe via the python.exe located in THAT same folder.
REM Otherwise, the 'pip' command will execute the HOST computer's pip.exe, if one exists.
REM (this is just an extra precaution to avoid using the wrong pip version,
REM  if the user forgets that they need '.\' to reference the local folder: .\python -m pip)
REM PS --> All of this is irrelevant IF we always use ACTIVATE-CONSOLE-myenv.cmd BEFORE calling
REM        programs like python or pip, so... DO IT THIS WAY!
"%~dp0\python" -m pip %*