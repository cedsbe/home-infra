# Generalization script for Windows 11 (ISO build)

$ErrorActionPreference = "Stop"

Write-Host "Starting generalization process..."

# Copy the unattend.xml from the CD to C:\Deploy so sysprep can find it after the ISO is ejected
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
    $allDrives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -in @(2, 5) }
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

# Stop services early to avoid file locks during cleanup
Write-Host "Stopping Windows Update services..."
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
Stop-Service -Name cryptsvc -Force -ErrorAction SilentlyContinue

Write-Host "Stopping tiledatamodelsvc..."
Get-Service -Name tiledatamodelsvc -ErrorAction SilentlyContinue | Stop-Service -Force

# Remove per-user AppX packages that are not provisioned system-wide.
# Sysprep fails with 0x80073cf2 if any package was installed for a specific user
# but not provisioned for all users (e.g. MicrosoftOfficeHub installed during OOBE).
# Do this before temp cleanup since AppX removal generates temp files.
Write-Host "Removing per-user AppX packages not provisioned for all users..."
$provisionedDisplayNames = (Get-AppxProvisionedPackage -Online).DisplayName
$packagesToRemove = Get-AppxPackage -AllUsers | Where-Object {
    -not $_.NonRemovable -and $provisionedDisplayNames -notcontains $_.Name
}
# First pass: remove non-framework packages. Framework packages (e.g. WindowsAppRuntime)
# throw a COMException if dependents are still present, but auto-remove once they are gone.
foreach ($pkg in $packagesToRemove) {
    Write-Host "  Removing: $($pkg.Name)"
    try {
        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
    }
    catch {
        Write-Host "  Skipped (will retry or auto-removed with dependents): $($pkg.Name) - $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}
# Second pass: retry any that failed due to dependency ordering
foreach ($pkg in $packagesToRemove) {
    if (Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -eq $pkg.PackageFullName }) {
        Write-Host "  Retrying: $($pkg.Name)"
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
        }
        catch {
            Write-Host "  Could not remove $($pkg.Name): $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }
}
Write-Host "AppX cleanup complete."

# Clear Windows Update cache
Write-Host "Clearing Windows Update cache..."
Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear temporary files (after AppX removal so its temp output is also wiped)
Write-Host "Clearing temporary files..."
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Remove any leftover user profiles except default ones
Write-Host "Cleaning up user profiles..."
Get-WmiObject -Class Win32_UserProfile | Where-Object {
    $_.Special -eq $false -and
    $_.LocalPath -notlike "*Administrator*" -and
    $_.LocalPath -notlike "*Default*"
} | Remove-WmiObject -ErrorAction SilentlyContinue

# Failsafe: BitLocker should have been prevented by the PreventDeviceEncryption registry key
# set during the specialize pass in autounattend.xml. If the volume is still encrypted here,
# something went wrong upstream and this block should not have been reached.
# Check before defrag/sdelete since decryption changes free space state.
$bitlockerStatus = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
if ($bitlockerStatus -and $bitlockerStatus.VolumeStatus -ne "FullyDecrypted") {
    Write-Warning "UNEXPECTED: BitLocker is active (VolumeStatus=$($bitlockerStatus.VolumeStatus)). The PreventDeviceEncryption registry key set during specialize should have prevented this. Disabling BitLocker now as a failsafe - investigate the autounattend specialize pass."
    Disable-BitLocker -MountPoint "C:" | Out-Null
    do {
        Start-Sleep -Seconds 10
        $bitlockerStatus = Get-BitLockerVolume -MountPoint "C:"
        Write-Host "Decryption progress: $($bitlockerStatus.EncryptionPercentage)%"
    } while ($bitlockerStatus.VolumeStatus -ne "FullyDecrypted")
    Write-Host "BitLocker fully decrypted on C:." -ForegroundColor Green
}

# Defragment the disk (optional but recommended for template optimization)
Write-Host "Optimizing disk..."
Optimize-Volume -DriveLetter C -Defrag -Verbose

# Zero out free space (use with caution - this takes time but reduces template size)
# Comment the following lines if you don't want maximum compression:
Write-Host "Zeroing free space (this may take a while)..."
sdelete.exe -z C: -accepteula

# Clear event logs last so log entries generated by this script are also wiped
Write-Host "Clearing event logs..."
Get-EventLog -LogName * | ForEach-Object { Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue }

Write-Host "Pre-sysprep cleanup completed successfully."
Write-Host "Starting Sysprep generalization..." -ForegroundColor Yellow

# Verify unattend file exists before running sysprep
if (-not (Test-Path "C:\Deploy\unattend.xml")) {
    Write-Error "Unattend file not found at C:\Deploy\unattend.xml. Cannot proceed with sysprep."
    exit 1
}

Write-Host "Unattend file verified at: C:\Deploy\unattend.xml" -ForegroundColor Green
Write-Host "File size: $((Get-Item 'C:\Deploy\unattend.xml').Length) bytes" -ForegroundColor Cyan

try {
    Write-Host "Executing sysprep command..." -ForegroundColor Yellow
    Write-Host "Command: sysprep.exe /oobe /generalize /mode:vm /quit /unattend:C:\Deploy\unattend.xml" -ForegroundColor Gray

    $sysrepStartTime = Get-Date
    Write-Host "Sysprep started at: $($sysrepStartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan

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
        Write-Host "Sysprep completed successfully!" -ForegroundColor Green

        Write-Host "Clearing PowerShell history..." -ForegroundColor Cyan
        Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt" -Force -ErrorAction SilentlyContinue

        Write-Host "Final temp file cleanup..." -ForegroundColor Cyan
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "=== Generalization Process Completed Successfully ===" -ForegroundColor Green
        Write-Host "Script finished at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
        Write-Host "Initiating system shutdown..." -ForegroundColor Yellow

        Start-Sleep -Seconds 2
        Stop-Computer -Force
    }
    else {
        Write-Error "Sysprep failed with exit code: $($process.ExitCode)"
        exit 1
    }
}
catch {
    Write-Error "Sysprep execution failed: $($_.Exception.Message)"

    $sysrepLog = "C:\Windows\System32\Sysprep\Panther\setuperr.log"
    if (Test-Path $sysrepLog) {
        Write-Host "Sysprep error log found. Last 10 lines:" -ForegroundColor Yellow
        Get-Content $sysrepLog | Select-Object -Last 10 | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    }

    exit 1
}
