
#*********************************************************************************
#* This file MUST be edited and saved as UTF-8 BOM, so that Powershell           *
#* correctly displays eventual non-ASCII messages/contents on the screen!        *
#* Note that saving this script just as UTF is NOT enough, it must be UTF-8 BOM. *  <<==========
#* Suggestion: Use Notepad++ to edit scripts (see the 'Encoding' menu there).    *
#* See: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding 
#* *******************************************************************************
#  PS - Furthermore, folders and files NAMES with NON-ASCII characters could be  *
#       READ from this script; also files CONTENT with NON-ASCII characters could*
#       be READ and WRITTEN by THIS script. To ensure that all names and content *
#       encodings are correctly handled, let's stick with the UTF-8 standard.    * 
#  PS2- One alternative could be to save this script in 'ANSI' or 'Windows-1252' *
#       encoding, but it seems to be better to save EVERY script of this 'tool'  *
#       in just ONE commom encoding: UTF-8, which is the Notepad++ default.      *
#*********************************************************************************

param ($EnvName)

$ErrorActionPreference = "Stop"

# ----------------------------------------------------------------------------------
# 1. DEFINE PATHS AND PARAMETERS
# ----------------------------------------------------------------------------------
if ( ! $EnvName) {
    # If no virtual environment name was provided, abort
    Write-Host "Error - no virtual environment name was provided! "
    Exit 333
}
$BasePathDir    = Split-Path -Parent $MyInvocation.MyCommand.Definition  # Or $PSScriptRoot
$VenvPath       = Join-Path (Join-Path $BasePathDir "Envs") $EnvName
$CfgFile        = Join-Path $VenvPath "pyvenv.cfg"
$ScriptsPath    = Join-Path $VenvPath "Scripts"

# ----------------------------------------------------------------------------------
# 2. PROCESS AND UPDATE THE FILES
# ----------------------------------------------------------------------------------
try {
    Write-Host "============================================================"
    Write-Host " Starting path update..."
    Write-Host " Target Virtual Environment: $VenvPath"
    Write-Host " Current root ('base') folder of the portable installation: $BasePathDir"
    Write-Host " Virtual environment configuration file: $CfgFile"
    Write-Host "============================================================"

    if (-not (Test-Path $CfgFile)) {
        Write-Host "
    ERROR: File not found: $CfgFile
           Check the virtual environment name and try again." -ForegroundColor Red
        exit 333
    }

    # Read the file as UTF-8
    $originalContent = Get-Content -Path $CfgFile -Raw -Encoding UTF8

    # Extract the 'home' line
    $homeLine = $originalContent -split "`r?`n" | 
                Where-Object { $_ -match '^\s*home\s*=' } | 
                Select-Object -First 1

    if (-not $homeLine) {
        Write-Error "'home' key not found in pyvenv.cfg"
        exit 333
    }

    $fullHome = ($homeLine -split '=', 2)[1].Trim() -replace '\s*#.*$', ''

    if ($fullHome -notmatch '^(.*?)\\python-') {
        Write-Error "Substring '\python-' not found in the 'home' value."
        exit 333
    }

    # Prepare the variables for the standard replacement (single backslash)
    $old = $Matches[1]
    $new = $BasePathDir
    $escapedOld = [regex]::Escape($old)

    # Prepare the variables for the escaped replacement (double backslashes, used in .xsh)
    $oldDouble = $old.Replace('\', '\\')
    $newDouble = $new.Replace('\', '\\')
    $escapedOldDouble = [regex]::Escape($oldDouble)

    # Define the Encoding objects correctly
    $Utf8NoBom   = New-Object System.Text.UTF8Encoding $false # For .bat, .cfg, .xsh, etc.
    $Utf8WithBom = New-Object System.Text.UTF8Encoding $true  # EXCLUSIVELY for .ps1

    # --- STEP A: Update pyvenv.cfg ---
    $newContent = $originalContent -ireplace $escapedOld, $new
    $contentChanged = ($newContent -ne $originalContent)

    if ($contentChanged) {
        [System.IO.File]::WriteAllText($CfgFile, $newContent, $Utf8NoBom)
    }

    # --- STEP B: Update Activate.* files in the Scripts folder ---
    $activateChangedCount = 0
    if (Test-Path $ScriptsPath) {
        Write-Host "`nUpdating activation files in $ScriptsPath..."
        
        # Filter all files that start with 'activate.*'
        $activateFiles = Get-ChildItem -Path $ScriptsPath -Filter "activate.*" -File

        foreach ($file in $activateFiles) {
            $filePath = $file.FullName
            $actContent = Get-Content -Path $filePath -Raw -Encoding UTF8
            
            # 1st: Try replacing the version with double backslashes (e.g. activate.xsh)
            $newActContent = $actContent -ireplace $escapedOldDouble, $newDouble
            
            # 2nd: Try replacing the version with single backslashes (e.g. activate.bat, Activate.ps1)
            $newActContent = $newActContent -ireplace $escapedOld, $new

            if ($newActContent -ne $actContent) {
                # Set the target encoding depending on the file extension
                $targetEncoding = $Utf8NoBom
                $hasBomMsg = "UTF-8 Without BOM"
                
                if ($file.Extension -ieq '.ps1') {
                    $targetEncoding = $Utf8WithBom
                    $hasBomMsg = "UTF-8 with BOM"
                }

                [System.IO.File]::WriteAllText($filePath, $newActContent, $targetEncoding)
                $activateChangedCount++
                Write-Host "   -> Updated: $($file.Name) ($hasBomMsg)" -ForegroundColor Cyan
            }
        }
    } else {
        Write-Warning "Scripts folder not found at: $ScriptsPath. The activation scripts were not updated."
    }

    # ----------------------------------------------------------------------------------
    # 3. FINAL MESSAGE
    # ----------------------------------------------------------------------------------
    Write-Host ""
    if ($contentChanged -or $activateChangedCount -gt 0) {
        Write-Host "Success! The environment has been reconfigured for the new path:" -ForegroundColor Green
        Write-Host "   $new" -ForegroundColor Green
        
        if ($contentChanged) { 
            Write-Host "   - pyvenv.cfg updated." -ForegroundColor Green 
        }
        if ($activateChangedCount -gt 0) { 
            Write-Host "   - $activateChangedCount activation file(s) updated." -ForegroundColor Green 
        }
    }
    else {
        Write-Host "No changes were necessary (the paths are already synchronized)." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Error while updating the environment: $($_.Exception.Message)"
}
finally {
    Write-Host ""
#    Read-Host "Press Enter to exit..."
}
