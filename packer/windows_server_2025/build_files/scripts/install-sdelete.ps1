# Install SDelete utility for secure disk cleanup
# Enhanced with logging and error handling

$ErrorActionPreference = "Stop"

Write-Host "=== SDelete Installation Script ===" -ForegroundColor Green
Write-Host "Starting at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

# Configuration
$sdeleteUrl = "https://download.sysinternals.com/files/SDelete.zip"
$sdeleteZip = "$env:TEMP\SDelete.zip"
$sdeleteExtractPath = "$env:TEMP\SDelete"
$sdeleteDestination = "C:\Windows\System32"
$sdeleteTargetPath = Join-Path -Path $sdeleteDestination -ChildPath "sdelete.exe"

try {
    # Check if SDelete is already installed
    Write-Host "Checking for existing SDelete installation..." -ForegroundColor Yellow
    $existingSDelete = Get-Command "sdelete.exe" -ErrorAction SilentlyContinue

    if ($existingSDelete) {
        $sdeleteInfo = Get-ItemProperty -Path $existingSDelete.Source
        Write-Host "SDelete is already installed:" -ForegroundColor Yellow
        Write-Host "  File: $($existingSDelete.Source)" -ForegroundColor Cyan
        Write-Host "  Size: $([math]::Round($sdeleteInfo.Length / 1KB, 2)) KB" -ForegroundColor Cyan
        Write-Host "  Version: $($sdeleteInfo.VersionInfo.FileVersion)" -ForegroundColor Cyan
        Write-Host "  Last Modified: $($sdeleteInfo.LastWriteTime)" -ForegroundColor Cyan
        Write-Host "Skipping installation." -ForegroundColor Yellow
        exit 0
    }

    # Download SDelete
    Write-Host "Downloading SDelete from: $sdeleteUrl" -ForegroundColor Yellow
    Write-Host "Destination: $sdeleteZip" -ForegroundColor Cyan

    $downloadStart = Get-Date
    Invoke-WebRequest -Uri $sdeleteUrl -OutFile $sdeleteZip -UseBasicParsing
    $downloadEnd = Get-Date
    $downloadDuration = $downloadEnd - $downloadStart

    # Verify download
    if (Test-Path $sdeleteZip) {
        $fileSize = (Get-Item $sdeleteZip).Length
        Write-Host "Download completed successfully!" -ForegroundColor Green
        Write-Host "  File size: $([math]::Round($fileSize / 1KB, 2)) KB" -ForegroundColor Cyan
        Write-Host "  Download time: $($downloadDuration.TotalSeconds) seconds" -ForegroundColor Cyan
    }
    else {
        throw "Download failed - ZIP file not found at $sdeleteZip"
    }

    # Create extraction directory
    Write-Host "Creating extraction directory..." -ForegroundColor Yellow
    if (Test-Path $sdeleteExtractPath) {
        Remove-Item -Path $sdeleteExtractPath -Recurse -Force
    }
    New-Item -Path $sdeleteExtractPath -ItemType Directory -Force | Out-Null
    Write-Host "Extraction directory created: $sdeleteExtractPath" -ForegroundColor Cyan

    # Extract SDelete
    Write-Host "Extracting SDelete archive..." -ForegroundColor Yellow
    try {
        Expand-Archive -Path $sdeleteZip -DestinationPath $sdeleteExtractPath -Force
        Write-Host "Archive extracted successfully" -ForegroundColor Green
    }
    catch {
        throw "Failed to extract SDelete archive: $($_.Exception.Message)"
    }

    # Verify extraction
    $sdeleteExe = Get-ChildItem -Path $sdeleteExtractPath -Name "sdelete*.exe" | Select-Object -First 1
    if (-not $sdeleteExe) {
        throw "SDelete executable not found in extracted files"
    }

    $sdeleteSourcePath = Join-Path -Path $sdeleteExtractPath -ChildPath $sdeleteExe
    Write-Host "Found SDelete executable: $sdeleteSourcePath" -ForegroundColor Green

    # Install SDelete to System32
    Write-Host "Installing SDelete to System32..." -ForegroundColor Yellow

    try {
        Copy-Item -Path $sdeleteSourcePath -Destination $sdeleteTargetPath -Force
        Write-Host "✅ SDelete installed successfully to: $sdeleteTargetPath" -ForegroundColor Green
    }
    catch {
        throw "Failed to copy SDelete to System32: $($_.Exception.Message)"
    }

    # Verify installation
    Write-Host "Verifying SDelete installation..." -ForegroundColor Yellow
    if (Test-Path $sdeleteTargetPath) {
        $sdeleteInfo = Get-ItemProperty -Path $sdeleteTargetPath
        Write-Host "Installation verification successful!" -ForegroundColor Green
        Write-Host "  File: $sdeleteTargetPath" -ForegroundColor Cyan
        Write-Host "  Size: $([math]::Round($sdeleteInfo.Length / 1KB, 2)) KB" -ForegroundColor Cyan
        Write-Host "  Version: $($sdeleteInfo.VersionInfo.FileVersion)" -ForegroundColor Cyan
        Write-Host "  Last Modified: $($sdeleteInfo.LastWriteTime)" -ForegroundColor Cyan
    }
    else {
        throw "Installation verification failed - SDelete not found at target location"
    }

    Write-Host "=== SDelete Installation Completed Successfully ===" -ForegroundColor Green

}
catch {
    Write-Host "Error occurred during SDelete installation!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
finally {
    # Cleanup
    Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow

    if (Test-Path $sdeleteZip) {
        Remove-Item $sdeleteZip -Force -ErrorAction SilentlyContinue
        Write-Host "Cleaned up: $sdeleteZip" -ForegroundColor Cyan
    }

    if (Test-Path $sdeleteExtractPath) {
        Remove-Item $sdeleteExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleaned up: $sdeleteExtractPath" -ForegroundColor Cyan
    }

    Write-Host "Script completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Green
}

exit 0
