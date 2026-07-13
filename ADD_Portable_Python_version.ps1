
#USAGE EXAMPLE:
#.\ADD_Portable_Python_version.ps1 -version 3.14.6 -base_dir "C:\SomeDir\PortablePython\"

#You can find the list of Python's Binary packages for Windows here: 
# https://www.python.org/downloads/windows/ 


#*********************************************************************************
#* This file MUST be edited and saved as UTF-8 BOM, so that Powershell           *
#* correctly displays eventual non-ASCII messages/contents on the screen!        *
#* Note that saving this script just as UTF is NOT enough, it must be UTF-8 BOM. *  <<==========
#* Suggestion: Use Notepad++ to edit scripts (see the 'Encoding' menu there).    *
#* See: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding 
#* *******************************************************************************
#  PS - Furthermore, folders and files NAMES with NON-ASCII characters will be   *
#       READ by this script; also files CONTENT with NON-ASCII characters will   *
#       be READ and WRITTEN by THIS script. To ensure that all names and content *
#       encodings are correctly handled, we'll stick with the UTF-8 standard.    * 
#  PS2- One alternative could be to save this script in 'ANSI' or 'Windows-1252' *
#       encoding, but some scripts of this 'tool' MUST be saved in UTF-8, so it  *
#       seems better to save EVERY script in ONE commom encoding: UTF-8, which   *  
#       is the Notepad++ and VSCode default.                                     *
#*********************************************************************************


param ($version, $base_dir)

# Any unhandled error will stop the execution of this script and return errorlevel <> 0
$ErrorActionPreference = "Stop"  

$source=''

if (!$version) {
    # If no version was provided, we will use the one below:
    $version='3.14.6'
}

# IMPORTANT: we must ALWAYS use the 'embed' version as the installation base and NOT the 'normal' version,
# because the latter does NOT guarantee isolation from the 'host' computer, in addition to making
# (undesired) changes to the host Registry even when we just unzip that package with MSIEXEC
$source = "https://www.python.org/ftp/python/$version/python-$version-embed-amd64.zip"
Write-Host $source

if (!$base_dir) {
    # Get the full path of the current directory  
    $base_dir =  (Get-Location).Path
}

# Fixes an error if the user doesn't put a backslash at the end of the base folder
if( !$base_dir.EndsWith('\') ) {
   $base_dir += "\"
}

$python_subdir = Split-Path $source -leaf
$python_subdir = $python_subdir.TrimEnd('.zip')
$python_subdir = $python_subdir.TrimEnd('.ZIP')
$expand_dir = $base_dir + $python_subdir + '\'


#IMPORTANT -- we will perform the creation positioned in the 'base' FOLDER, i.e., 
#             the root of the folder where our portable installation will be placed
Set-Location $base_dir  #<<-- same as: CD $base_dir

$ShortVersion  = ($version -split "\.")[0..1] -join ""   #<-- e.g., "314"

Write-Host "Installing Python$($version) into  $($base_dir)" -ForegroundColor Cyan

# Set package = path+filename, to save the downloaded file
$filename = Split-Path $source -leaf
$package = "$($base_dir)$($filename)"
Write-Host $package


# Check to see if this zip has ALREADY been downloaded, if so, it won't download again
if(!(Test-Path -Path $package)) {
  #Download the package file
  "Downloading package from $($source)"
  Invoke-WebRequest -Uri $source -OutFile $package
}

#Finished downloading, the package should exist now
if(!(Test-Path -Path $package)) {
    throw [System.IO.FileNotFoundException] "$package not found after downloading it"
}

Write-Host "Deleting the target folder of the downloaded python package extraction, if it exists..."
cmd.exe /C rmdir /S /Q "$expand_dir"

# Unzip the Python Embed ZIP package that was downloaded
Expand-Archive -Force -Path $package -DestinationPath $expand_dir

# Ensures that our PORTABLE python will be truly ISOLATED from the HOST computer platform
# (both the python in the 'base' folder and in the created virtual environments)
"Now copying sitecustomize.py and some .Bat files to $($expand_dir):"
cmd.exe /C copy /Y "$base_dir\templates\sitecustomize.py"  "$expand_dir"

# Creates a py.BAT, a python.BAT and a pip.BAT in the 'base' python folder to assist
cmd.exe /C copy /Y  "$base_dir\templates\*.BAT"  "$expand_dir"

# Saves the 'base' path where this PORTABLE Python installation was created
# This will be used by the script running the APP to check that the environment was NOT moved
# since each virtual environment keeps the path where it was created in its configuration
# and when such virtual environment is moved it usually will NOT work anymore
#... but first ensures the use of UTF-8 with chcp (for non-ASCII characters in the Path)
cmd.exe /C "chcp 65001 >nul `&` echo %CD%>last_path.txt"

#Unfortunatelly, the Tcl/Tk libraries are no included in the 'embeded' python package. So, let's
#download, extract and inject these components in the python folder located at the 'base' directory: 
Write-Host "Installing TclTk (tkinter...)"
$TclMsiUrl     = "https://www.python.org/ftp/python/$version/amd64/tcltk.msi"
$TclMsiPath    = Join-Path $base_dir "tcltk-$($version).msi"
$TclExtractDir = Join-Path $base_dir "tcl_extracted"

try {
    if (!(Test-Path $TclMsiPath)) {  # If file already exists, do not download
        #Download and Extract the Production Tcl/Tk Components
        Write-Host "[-] Fetching Production Tcl/Tk MSI Component..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $TclMsiUrl -OutFile $TclMsiPath -UseBasicParsing
    }
    # Download finished, now the package should exist
    if (!(Test-Path $TclMsiPath)) {
        # Causes an exit from this try block
        throw [System.IO.FileNotFoundException] "File not found after downloading: $($TclMsiPath)"
    }

    # Remove tcltk temporary extraction folder
    Remove-Item $TclExtractDir -Recurse -Force -ErrorAction Ignore | Out-Null  #<-- 'Ignore' required if the folder does not exist

    # Now ensure the target directory exists
    New-Item -ItemType Directory -Path $TclExtractDir -Force | Out-Null 
    
    Write-Host "[-] Unpacking TclTk files from the downloaded MSI..." -ForegroundColor Cyan
    # Use msiexec to perform a pseudo-administrative install (extraction)
    # /a = Administrative install (just extracts files)
    # /qb = Basic UI (shows a small progress bar but requires no clicking)
    # TARGETDIR = Where to dump the extracted files 
    $ArgumentList = "/a `"$TclMsiPath`" /qb TARGETDIR=`"$TclExtractDir`" /qn"    

    "Executing... Start-Process -FilePath `"msiexec.exe`" -ArgumentList $ArgumentList -Wait -PassThru"

    $Process = Start-Process -FilePath "msiexec.exe" -ArgumentList $ArgumentList -Wait -PassThru

    # Check if the extraction was successful
    if ($Process.ExitCode -eq 0) {
        Write-Host "[-] TclTk Extraction completed"
    } else {
        # Causes an exit from this try block
        throw [System.IO.FileNotFoundException] "Failed to extract the TclTk MSI. Exit code: $($Process.ExitCode)"
    }

    # Merge Tcl/Tk into the Python directory located at the 'base' folder 
    Write-Host "Merging the TclTk components into Target Structure..." -ForegroundColor Cyan
    
    # Copy the main tcl internal standard library directory
    if (Test-Path (Join-Path $TclExtractDir "tcl")) {
        Copy-Item -Path (Join-Path $TclExtractDir "tcl") -Destination $expand_dir -Recurse -Force
    }

    if (Test-Path (Join-Path $TclExtractDir "Lib")) {
        Copy-Item -Path (Join-Path $TclExtractDir "Lib") -Destination $expand_dir -Recurse -Force
    }

    if (Test-Path (Join-Path $TclExtractDir "DLLs")) {
        Copy-Item -Path (Join-Path $TclExtractDir "DLLs") -Destination $expand_dir -Recurse -Force
    }
    Write-Host "[+] The TclTk components were injected in the embed python folder: $expand_dir" -ForegroundColor Green
} catch {
    Write-Host "An error occurred while installing TclTk/Tkinter: $_"  -ForegroundColor Yellow
    Write-Host "Proceeding anyway, because it is not a core component." -ForegroundColor Yellow   
} finally {
    # Cleanup temporary workspace
    if (Test-Path $TclExtractDir) { Remove-Item $TclExtractDir -Recurse -Force | Out-Null }    
}

#Create the file ($ShortVersion)._pth (to make things visible to Python)
$pth_file = "$($expand_dir)python$ShortVersion._pth" 
Write-Host "Writing $pth_file"

$pth_content= @"
# This file is required inside the 'python-N.N.nn-embed-amd64' folder of each Python
# version added to the 'base' folder of this portable installation. 
# It sets 'sys.path' BEFORE the 'sitecustomize.py' script is executed.

# The 4 paths below are the bare minimum required for PORTABLE python to work:
.\python$ShortVersion.zip
.
.\Lib
.\DLLs

# The below line is NOT required; apparently the 'import site' forces searching this folder:
#.\Scripts

# The line below activates TCL/TK, if the 'tcl' folder extracted from tcltk.msi was incorporated 
# into the Python folder at the 'base' directory (and it was).
# This is enough for the 'base' python.exe, BUT, in a virtual-environment, this is NOT enough...
# it is also necessary to filter and include paths in sys.path (done via 'sitecustomize.py'). 
.\tcl

# Line below is unnecessary, adding .\Lib already covers it (it was added above).
#Lib/tkinter

# ALWAYS UNcomment the line below, otherwise NONE of the sets above will be applied!
# It also activates searching in .\Lib\site-packages, including within a virtual-environment.
import site 
"@

# Write to the actual _pth file:
$Utf8NoBom   = New-Object System.Text.UTF8Encoding $false # For .bat, .cfg, .xsh, etc.
# $pth_content | Out-File -FilePath $pth_file -encoding utf8  #<<--- this did NOT work, saves UTF-8-BOM file under Powershell 5.1
[System.IO.File]::WriteAllText($pth_file, $pth_content, $Utf8NoBom)

# PIP Installation
Write-Host "Installing PIP... Please wait......" -ForegroundColor Cyan
Invoke-WebRequest -OutFile "$($expand_dir)get-pip.py" "https://bootstrap.pypa.io/get-pip.py"
$PythonExe = Join-Path $expand_dir "python.exe"
$argsList = Join-Path $expand_dir "get-pip.py"
& $PythonExe $argsList --no-warn-script-location
# Check if pip installation was successful
if ($LastExitCode -eq $null -or $LastExitCode -ne 0) {
    throw("Error during pip installation") # Terminates due to ErrorActionPreference 'stop'
}

# We install the virtualenv package, because the native venv module is NOT included in the Embed Version :(
Write-Host "Installing the 'virtualenv' module... "  -ForegroundColor Cyan
& $PythonExe -m pip install virtualenv --no-warn-script-location
if ($LastExitCode -eq $null -or $LastExitCode -ne 0) {
    throw("Error during virtualenv installation") # Terminates due to ErrorActionPreference 'stop'
}


# ---------------------------------------------------------------------
# Basic verification of the Python installation at the 'base' folder
# ---------------------------------------------------------------------

Write-Host ""
Write-Host "Testing installation..."  -ForegroundColor Cyan
Write-Host ""
$PythonExe = Join-Path $expand_dir "python.exe"
& $PythonExe  -c "exit"   #<<--- this makes sitecustomize run and a title appears in DARK PURPLE
& $PythonExe --version      #<<--- THIS does NOT show the title, hence the line above :(
Write-Host ""
Write-Host "Testing pip..."
& $PythonExe -m pip --version

Write-Host ""
Write-Host "Testing virtualenv..."
& $PythonExe -m virtualenv --version

Write-Host ""
Write-Host "Testing tkinter..."
& $PythonExe -c "import tkinter; print('tkinter OK')"

# ---------------------------------------------------------------------
# Create a default virtual environment
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "Creating a virtual environment (optional)"  -ForegroundColor Cyan
# The idea is always to use a virtual environment, , via calling its 'activate.bat' script,
# in order to automatically adjust the PATH and other things, when using this PORTABLE 'tool'. 
# This will ensure that everything will be done INSIDE the 'base' folder of our PORTABLE installation; 
# it helps guarantee that our environment is ISOLATED from the HOST computer and other environments...
# ps - BUT that alone is NOT enough, IT WAS NECESSARY also to set things inside the 'sitecustomize.py' 
#      script to really GUARANTEE the desired isolation!

# Let's CREATE a virtual environment associated to THIS python version 
# we are now adding to our PORTABLE installation:
cmd /c " .\Create_or_REcreate-env.cmd `"`" `"$python_subdir`" "

if ($LastExitCode -eq $null -or $LastExitCode -ne 0) {
    Write-Host "Error during the creation of the virtual environment "  -ForegroundColor Yellow
    Write-Host "Try to create it later using the 'Create_or_REcreate-env.cmd' " -ForegroundColor Yellow    
}

#-------------------------------------
# Wrap-up
#-------------------------------------
$esc = [char]27
$FG_WHITE  =  "${esc}[38;2;255;255;255m"  
$FG_YELLOW =  "${esc}[38;2;255;255;0m"
$BG_DGREEN = "${esc}[48;2;0;105;0m"
$BG_DPURPLE = "${esc}[48;2;105;0;105m"
$RST_CLR    = "${esc}[0m"

Write-Host ""
# Text inside @" and "@ is printed as a RAW string and $vars are expanded... like print(r"xxxxxx") in python 
Write-Host  @"
To use any virtual environment you created from inside this PORTABLE installation, 
run the script 'Activate_CONSOLE-env.cmd' !
You should run the 'python' and 'pip' commands only from inside an activated virtual 
environment, when the console shows a title starting with $FG_WHITE$($BG_DGREEN)*** PORTABLE Python ***.$RST_CLR"
Inside that console/prompt, you can install libraries via: 
     python -m pip install `<<SOME_LIB>>`
And you can also run any python program via: 
     python <<SOMESCRIPT>>.py
Note:
- Creation of a NEW virtual environments does NOT work if you try to do that 
  from INSIDE the PROMPT of an activated virtual environment.
  To perform such task, you MUST run the 'CREATE_or_REcreate-env.cmd' script.
  Note: A title starting with 
"@ -NoNewline
Write-Host "$FG_WHITE$($BG_DPURPLE)*** PORTABLE Python ***$RST_CLR should appear "
Write-Host "  in a dark PURPLE background, when running that script."

Write-Host ""
# Text inside @" and "@ is printed as a RAW string and $vars are expanded... like print(r"xxxxxx") in python 
Write-Host @"
Finished! READ all messages above!
If no error occurred during the execution of this script, you can now (optionally) 
delete the ZIP and MSI files that were downloaded to perform the installation.

IMPORTANT:
$($FG_YELLOW)You MUST ALWAYS execute 'python' and 'pip' when INSIDE a virtual environment 
of this PORTABLE installation, as explained above (via 'ACTIVATE_CONSOLE-env.cmd')$RST_CLR, 
otherwise you might be (incorrectly) executing the python eventually ALREADY   
installed on the 'host' computer, which will lead to unwanted side effects.
As explained, it is easy to confirm that you are running the 'python' command from a 
virtual environment that belongs to this PORTABLE installation, since it always shows 
a title starting with 
"@ -NoNewline
Write-Host "$FG_WHITE$($BG_DGREEN)*** PORTABLE Python ***$RST_CLR in a dark GREEN background!"  

#Optional REMOVAL of downloaded files used to perform the INSTALLATION
Write-Host ""
"Cleaning up temporary files"
Remove-Item -Path $package -Confirm:$true -Force -ErrorAction Ignore
Remove-Item -Path $TclMsiPath -Confirm:$true -Force -ErrorAction Ignore
#Remove-Item -Path "$($expand_dir)get-pip.py" -Confirm:$false -Force -ErrorAction Ignore 
Write-Host "-----   END   -----"

# The line below prevents this Powershell session from closing, in case the  
# user executed it from a Right_click + "Run with Powershell".
# So, it is still possible to read the messages generated on the screen :)
cmd /c pause
