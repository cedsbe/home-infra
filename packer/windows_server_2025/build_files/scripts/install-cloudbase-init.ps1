# Download and install Cloudbase-Init for Windows Server 2025 template
# Enhanced with logging and error handling

$ErrorActionPreference = "Stop"

Write-Host "=== Cloudbase-Init Installation Script ===" -ForegroundColor Green
Write-Host "Starting at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Configuration
$cloudbaseInitUrl = "https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi"
$cloudbaseInitInstaller = "$env:TEMP\CloudbaseInitSetup.msi"
$logFile = "$env:TEMP\CloudbaseInit_Install.log"

try {
    # Check if Cloudbase-Init is already installed
    Write-Host "Checking for existing Cloudbase-Init installation..." -ForegroundColor Yellow

    # Use registry check for faster detection instead of slow WMI query
    $uninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $existingInstall = $null
    foreach ($keyPath in $uninstallKeys) {
        $apps = Get-ItemProperty -Path $keyPath -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Cloudbase-Init*" }
        if ($apps) {
            $existingInstall = $apps | Select-Object -First 1
            break
        }
    }

    if ($existingInstall) {
        Write-Host "Cloudbase-Init is already installed:" -ForegroundColor Yellow
        Write-Host "  Name: $($existingInstall.DisplayName)" -ForegroundColor Cyan
        Write-Host "  Version: $($existingInstall.DisplayVersion)" -ForegroundColor Cyan
        if ($existingInstall.InstallDate) {
            Write-Host "  Install Date: $($existingInstall.InstallDate)" -ForegroundColor Cyan
        }
        Write-Host "Skipping installation." -ForegroundColor Yellow
        exit 0
    }

    # Download Cloudbase-Init installer
    Write-Host "Downloading Cloudbase-Init from: $cloudbaseInitUrl" -ForegroundColor Yellow
    Write-Host "Destination: $cloudbaseInitInstaller" -ForegroundColor Cyan

    $downloadStart = Get-Date
    Invoke-WebRequest -Uri $cloudbaseInitUrl -OutFile $cloudbaseInitInstaller
    $downloadEnd = Get-Date
    $downloadDuration = $downloadEnd - $downloadStart

    # Verify download
    if (Test-Path $cloudbaseInitInstaller) {
        $fileSize = (Get-Item $cloudbaseInitInstaller).Length
        Write-Host "Download completed successfully!" -ForegroundColor Green
        Write-Host "  File size: $([math]::Round($fileSize / 1MB, 2)) MB" -ForegroundColor Cyan
        Write-Host "  Download time: $($downloadDuration.TotalSeconds) seconds" -ForegroundColor Cyan
    }
    else {
        throw "Download failed - installer file not found at $cloudbaseInitInstaller"
    }

    # Install Cloudbase-Init
    Write-Host "Installing Cloudbase-Init..." -ForegroundColor Yellow
    Write-Host "Installation parameters:" -ForegroundColor Cyan
    Write-Host "  - Silent installation (/qn)" -ForegroundColor Cyan
    Write-Host "  - No restart (/norestart)" -ForegroundColor Cyan
    Write-Host "  - Run as LOCAL SYSTEM (RUN_SERVICE_AS_LOCAL_SYSTEM=1)" -ForegroundColor Cyan
    Write-Host "  - Log file: $logFile" -ForegroundColor Cyan

    $installStart = Get-Date
    $installArgs = @(
        "/i", "`"$cloudbaseInitInstaller`"",
        "/qn",
        "/norestart",
        "/l*v", "`"$logFile`"",
        "RUN_SERVICE_AS_LOCAL_SYSTEM=1"
    )

    Write-Host "Executing: msiexec.exe $($installArgs -join ' ')" -ForegroundColor Gray

    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
    $installEnd = Get-Date
    $installDuration = $installEnd - $installStart

    # Check installation result
    Write-Host "Installation completed with exit code: $($process.ExitCode)" -ForegroundColor $(if ($process.ExitCode -eq 0) { "Green" } else { "Red" })
    Write-Host "Installation time: $($installDuration.TotalSeconds) seconds" -ForegroundColor Cyan

    if ($process.ExitCode -eq 0) {
        Write-Host "Cloudbase-Init installed successfully!" -ForegroundColor Green

        # Verify installation
        Write-Host "Verifying installation..." -ForegroundColor Yellow

        # Use same fast registry method for verification
        $installedProduct = $null
        foreach ($keyPath in $uninstallKeys) {
            $apps = Get-ItemProperty -Path $keyPath -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Cloudbase-Init*" }
            if ($apps) {
                $installedProduct = $apps | Select-Object -First 1
                break
            }
        }

        if ($installedProduct) {
            Write-Host "Verification successful!" -ForegroundColor Green
            Write-Host "Installed product details:" -ForegroundColor Cyan
            Write-Host "  Name: $($installedProduct.DisplayName)" -ForegroundColor Cyan
            Write-Host "  Version: $($installedProduct.DisplayVersion)" -ForegroundColor Cyan
            Write-Host "  Publisher: $($installedProduct.Publisher)" -ForegroundColor Cyan
            if ($installedProduct.InstallLocation) {
                Write-Host "  Install Location: $($installedProduct.InstallLocation)" -ForegroundColor Cyan
            }
        }
        else {
            Write-Warning "Installation completed but product not found in registry"
        }

        # Check service status
        Write-Host "Checking Cloudbase-Init service..." -ForegroundColor Yellow
        $service = Get-Service -Name "cloudbase-init" -ErrorAction SilentlyContinue

        if ($service) {
            Write-Host "Service status:" -ForegroundColor Cyan
            Write-Host "  Name: $($service.Name)" -ForegroundColor Cyan
            Write-Host "  Display Name: $($service.DisplayName)" -ForegroundColor Cyan
            Write-Host "  Status: $($service.Status)" -ForegroundColor Cyan
            Write-Host "  Start Type: $($service.StartType)" -ForegroundColor Cyan
        }
        else {
            Write-Warning "Cloudbase-Init service not found"
        }

    }
    else {
        throw "Installation failed with exit code: $($process.ExitCode)"
    }

}
catch {
    Write-Host "Error occurred during Cloudbase-Init installation!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red

    # Display installation log if it exists
    if (Test-Path $logFile) {
        Write-Host "Installation log contents:" -ForegroundColor Yellow
        Write-Host "=========================" -ForegroundColor Yellow
        Get-Content $logFile | Select-Object -Last 20 | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
        Write-Host "=========================" -ForegroundColor Yellow
        Write-Host "Full log available at: $logFile" -ForegroundColor Cyan
    }

    throw
}
finally {
    # Cleanup
    if (Test-Path $cloudbaseInitInstaller) {
        Write-Host "Cleaning up installer file..." -ForegroundColor Yellow
        Remove-Item $cloudbaseInitInstaller -Force -ErrorAction SilentlyContinue
        Write-Host "Installer file removed: $cloudbaseInitInstaller" -ForegroundColor Cyan
    }

    Write-Host "Script completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Green
}
