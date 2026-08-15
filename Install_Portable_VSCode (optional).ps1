# ==============================================================================
# Script to download and configure Portable VSCode
# ==============================================================================

# 1. Get the current directory where the script is running
$scriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($scriptDir)) { $scriptDir = (Get-Location).Path }

$zipFile = Join-Path $scriptDir "vscode_x64.zip"
$extractFolder = Join-Path $scriptDir "VSCode-Portable"

# 2. Official and stable URL for the Windows x64 ZIP version
$downloadUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-archive"

try {
    $shouldDownload = $true

    # Check if the ZIP file already exists
    if (Test-Path -Path $zipFile) {
        Write-Host "The file 'vscode_x64.zip' already exists in this folder." -ForegroundColor Yellow
        Write-Host "You can install Portable VSCode using this existing file, OR download a new ZIP and install from it." -ForegroundColor Yellow
        $userChoice = Read-Host "Do you want to download a new ZIP file? (Y/N)"
        
        if ($userChoice -notmatch '^[Yy]') {
            $shouldDownload = $false
            Write-Host "Using the existing ZIP file for installation." -ForegroundColor Cyan
        }
    }

    if ($shouldDownload) {
        # 3. Download the ZIP file
        Write-Host "Downloading VSCode (x64 ZIP)... This might take a few minutes." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile
    }

    # 4. Extract the archive into the 'VSCode-Portable' folder
    Write-Host "Extracting the archive... Please wait." -ForegroundColor Cyan
    try {
        Expand-Archive -Path $zipFile -DestinationPath $extractFolder -Force -ErrorAction Stop
    } catch {
        # Throws a custom, clearer error message if the extraction fails (e.g., corrupted ZIP)
        throw "Failed to extract the ZIP file. The file might be corrupted or incomplete from an interrupted download. Please run the script again and choose to download a new ZIP."
    }
    
    # 5. Create or Manage the 'data' subfolder to enable portable mode
    Write-Host "Checking for the 'data' folder..." -ForegroundColor Cyan
    $dataFolder = Join-Path $extractFolder "data"
    
    if (-Not (Test-Path -Path $dataFolder)) {
        New-Item -ItemType Directory -Path $dataFolder | Out-Null
        Write-Host "'data' folder created successfully!" -ForegroundColor Green
    } else {
        Write-Host "Warning: The ${dataFolder} folder already exists." -ForegroundColor Yellow
        Write-Host "This folder contains your previous extensions and settings." -ForegroundColor Yellow
        $overwriteChoice = Read-Host "Do you want to overwrite it (delete all previous data and start fresh)? (Y/N)"
        
        if ($overwriteChoice -match '^[Yy]') {
            Write-Host "Deleting existing 'data' folder..." -ForegroundColor Cyan
            Remove-Item -Path $dataFolder -Recurse -Force
            New-Item -ItemType Directory -Path $dataFolder | Out-Null
            Write-Host "The 'data' folder was recreated successfully!" -ForegroundColor Green
        } else {
            Write-Host "Keeping the existing 'data' folder (settings and extensions preserved)." -ForegroundColor Cyan
        }
    }

    # 6. Install the Python Extension
    Write-Host "Installing the Python extension (ms-python.python)..." -ForegroundColor Cyan
    $codeCli = Join-Path $extractFolder "bin\code.cmd"
    
    if (Test-Path -Path $codeCli) {
        # Running the CLI to install the extension
        & $codeCli --install-extension ms-python.python --force
        Write-Host "Python extension installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Warning: Could not find VSCode CLI to install extensions." -ForegroundColor Yellow
    }


    # Ask the user if they want to delete the ZIP file
    $deleteChoice = Read-Host "Extraction complete. Do you want to delete the downloaded ZIP file? (Y/N)"
    if ($deleteChoice -match '^[Yy]') {
        Write-Host "Removing the ZIP file..." -ForegroundColor Cyan
        Remove-Item -Path $zipFile -Force
    } else {
        Write-Host "Keeping the ZIP file." -ForegroundColor Cyan
    }

    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "Done! Portable VSCode is ready to use." -ForegroundColor Green
    Write-Host "You can start it by running: $(Join-Path $extractFolder 'Code.exe')" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green

    # Keep the console window open so the user can read the final message
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

} catch {
    Write-Host "An error occurred during script execution: $_" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

