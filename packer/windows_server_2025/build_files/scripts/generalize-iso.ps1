# Enhanced generalization script for Windows Server 2025

$ErrorActionPreference = "Stop"

Write-Host "Starting enhanced generalization process..."

# Copy the unattend file to the C:\Deploy directory
Write-Host "Copying unattend.xml to C:\Deploy..."
$unattendPath = "C:\Deploy\unattend.xml"
if (Test-Path -Path $unattendPath) {
    Write-Host "Unattend file already exists at $unattendPath. Creating a backup..."
    $backupPath = "C:\Deploy\unattend_backup.xml"
    if (Test-Path -Path $backupPath) {
        Remove-Item -Path $backupPath -Force -ErrorAction SilentlyContinue
    }
    Copy-Item -Path $unattendPath -Destination $backupPath -Force
    Write-Host "Backup created at $backupPath."
}

# Find the source unattend.xml file located at the root of a drive.
# To avoid hardcoding, we will search for it in every drive.
Write-Host "Searching for unattend.xml at the root of all drives..."

$sourceUnattendPath = $null
$mountedDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }

foreach ($drive in $mountedDrives) {
    $testPath = Join-Path -Path "$($drive.Name):\" -ChildPath "unattend.xml"
    Write-Host "Checking: $testPath"
    
    if (Test-Path -Path $testPath) {
        $sourceUnattendPath = $testPath
        Write-Host "Found unattend.xml at: $sourceUnattendPath"
        break
    }
}

if (-not $sourceUnattendPath) {
    Write-Host "unattend.xml not found at the root of any drive. Checking CD/DVD drives..."
    
    # Also check removable drives and CD/DVD drives
    $allDrives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -in @(2, 5) } # 2=Removable, 5=CD-ROM
    
    foreach ($drive in $allDrives) {
        $testPath = Join-Path -Path "$($drive.DeviceID)\" -ChildPath "unattend.xml"
        Write-Host "Checking removable/CD drive: $testPath"
        
        if (Test-Path -Path $testPath) {
            $sourceUnattendPath = $testPath
            Write-Host "Found unattend.xml at: $sourceUnattendPath"
            break
        }
    }
}

if ($sourceUnattendPath -and (Test-Path -Path $sourceUnattendPath)) {
    Copy-Item -Path $sourceUnattendPath -Destination $unattendPath -Force
    Write-Host "Unattend file copied successfully from $sourceUnattendPath to $unattendPath"
}
else {
    Write-Host "Source unattend.xml not found at the root of any drive. Nothing to copy."
}

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
Write-Host "Optimizing disk..."
Optimize-Volume -DriveLetter C -Defrag -Verbose

# Zero out free space (use with caution - this takes time but reduces template size)
# Uncomment the following lines if you want maximum compression:
# Write-Host "Zeroing free space (this may take a while)..."
# sdelete.exe -z C: -accepteula

Write-Host "Pre-sysprep cleanup completed successfully."
Write-Host "Starting Sysprep generalization..." -ForegroundColor Yellow

# Verify unattend file exists before running sysprep
if (-not (Test-Path "C:\Deploy\unattend.xml")) {
    Write-Error "Unattend file not found at C:\Deploy\unattend.xml. Cannot proceed with sysprep."
    exit 1
}

Write-Host "Unattend file verified at: C:\Deploy\unattend.xml" -ForegroundColor Green
Write-Host "File size: $((Get-Item 'C:\Deploy\unattend.xml').Length) bytes" -ForegroundColor Cyan

# Run sysprep with proper error handling and monitoring
try {
    Write-Host "Executing sysprep command..." -ForegroundColor Yellow
    Write-Host "Command: sysprep.exe /oobe /generalize /mode:vm /quit /unattend:C:\Deploy\unattend.xml" -ForegroundColor Gray
    
    $sysrepStartTime = Get-Date
    Write-Host "Sysprep started at: $($sysrepStartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
    
    # Construct sysprep argument list for clarity and maintainability
    $sysprepArgs = @(
        "/oobe"
        "/generalize"
        "/mode:vm"
        "/quit"
        "/unattend:C:\Deploy\unattend.xml"
    )
    $process = Start-Process -FilePath "$($ENV:SystemRoot)\System32\Sysprep\sysprep.exe" -ArgumentList $sysprepArgs -Wait -PassThru -NoNewWindow
    
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
