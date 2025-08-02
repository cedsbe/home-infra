# Enhanced generalization script for Windows Server 2025

$ErrorActionPreference = "Stop"

Write-Host "Starting generalization process..."

# Stop Windows Update service to prevent conflicts during sysprep
Write-Host "Stopping Windows Update services..."
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
Stop-Service -Name cryptsvc -Force -ErrorAction SilentlyContinue

# Stop tile data model service
Write-Host "Stopping tiledatamodelsvc..."
Get-Service -Name tiledatamodelsvc -ErrorAction SilentlyContinue | Stop-Service -Force

# Clear Windows Update cache
Write-Host "Clearing Windows Update cache..."
Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear temporary files
Write-Host "Clearing temporary files..."
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear event logs (optional - comment out if you want to keep logs)
Write-Host "Clearing event logs..."
Get-EventLog -LogName * | ForEach-Object { Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue }

# Remove any leftover user profiles except default ones
Write-Host "Cleaning up user profiles..."
Get-WmiObject -Class Win32_UserProfile | Where-Object {
    $_.Special -eq $false -and
    $_.LocalPath -notlike "*Administrator*" -and
    $_.LocalPath -notlike "*Default*"
} | Remove-WmiObject -ErrorAction SilentlyContinue

# Defragment the disk (optional but recommended for template optimization)
# Write-Host "Optimizing disk..."
# Optimize-Volume -DriveLetter C -Defrag -Verbose

# Zero out free space (use with caution - this takes time but reduces template size)
# Uncomment the following lines if you want maximum compression:
# Write-Host "Zeroing free space (this may take a while)..."
# sdelete.exe -z C: -accepteula

Write-Host "Pre-sysprep cleanup completed successfully."
Write-Host "Starting Sysprep generalization..." -ForegroundColor Yellow

# Verify unattend file exists before running sysprep
if (-not (Test-Path "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\unattend.xml")) {
    Write-Error "Unattend file not found at C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\unattend.xml. Cannot proceed with sysprep."
    exit 1
}

Write-Host "Unattend file verified at: C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\unattend.xml" -ForegroundColor Green
Write-Host "File size: $((Get-Item 'C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\unattend.xml').Length) bytes" -ForegroundColor Cyan

# Run sysprep with proper error handling and monitoring
try {
    Write-Host "Executing sysprep command..." -ForegroundColor Yellow
    Write-Host "Command: sysprep.exe /oobe /generalize /mode:vm /quit `"/unattend:C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\unattend.xml`"" -ForegroundColor Gray

    $sysrepStartTime = Get-Date
    Write-Host "Sysprep started at: $($sysrepStartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan

    # Start sysprep process and wait for it to complete (using /quit instead of /shutdown)
    $unattendPath = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\unattend.xml"
    $process = Start-Process -FilePath "$($ENV:SystemRoot)\System32\Sysprep\sysprep.exe" `
        -ArgumentList "/oobe", "/generalize", "/mode:vm", "/quit", "`"/unattend:$unattendPath`"" `
        -Wait -PassThru -NoNewWindow

    $sysrepEndTime = Get-Date
    $duration = $sysrepEndTime - $sysrepStartTime

    Write-Host "Sysprep process completed." -ForegroundColor Green
    Write-Host "Duration: $($duration.TotalMinutes.ToString('F2')) minutes" -ForegroundColor Cyan
    Write-Host "Exit Code: $($process.ExitCode)" -ForegroundColor Cyan

    if ($process.ExitCode -eq 0) {
        Write-Host "✅ Sysprep completed successfully!" -ForegroundColor Green

        # Post-sysprep actions can be added here if needed
        Write-Host "Performing final cleanup..." -ForegroundColor Yellow

        # Final log cleanup (optional)
        Write-Host "Clearing PowerShell history..." -ForegroundColor Cyan
        Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt" -Force -ErrorAction SilentlyContinue

        # Clear any remaining temp files
        Write-Host "Final temp file cleanup..." -ForegroundColor Cyan
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "=== Generalization Process Completed Successfully ===" -ForegroundColor Green
        Write-Host "Script finished at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
        Write-Host "Initiating system shutdown..." -ForegroundColor Yellow

        # Give a brief pause to ensure all output is flushed
        Start-Sleep -Seconds 2

        # Shutdown the system
        Stop-Computer -Force
    }
    else {
        Write-Error "❌ Sysprep failed with exit code: $($process.ExitCode)"
        exit 1
    }
}
catch {
    Write-Error "❌ Sysprep execution failed: $($_.Exception.Message)"

    # Check if sysprep log exists for troubleshooting
    $sysrepLog = "C:\Windows\System32\Sysprep\Panther\setuperr.log"
    if (Test-Path $sysrepLog) {
        Write-Host "Sysprep error log found. Last 10 lines:" -ForegroundColor Yellow
        Get-Content $sysrepLog | Select-Object -Last 10 | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    }

    exit 1
}
