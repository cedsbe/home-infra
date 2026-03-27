# Generalization script for Windows Server 2025 (ISO build)

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"  # Prevent warning stream from causing failures in Packer/WinRM sessions

Write-Host "=== Generalization script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
Write-Host "Host: $env:COMPUTERNAME | OS: $((Get-WmiObject Win32_OperatingSystem).Caption)"

# ---------------------------------------------------------------------------
# 1. Copy unattend.xml to C:\Deploy so sysprep can find it after ISO is ejected
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [1/9] Copying unattend.xml to C:\Deploy ---"
$unattendPath = "C:\Deploy\unattend.xml"
if (Test-Path -Path $unattendPath) {
    Write-Host "  Existing unattend found at $unattendPath - creating backup..."
    $backupPath = "C:\Deploy\unattend_backup.xml"
    if (Test-Path -Path $backupPath) {
        Remove-Item -Path $backupPath -Force -ErrorAction SilentlyContinue
    }
    Copy-Item -Path $unattendPath -Destination $backupPath -Force
    Write-Host "  Backup saved to $backupPath"
}

$sourceUnattendPath = $null
$mountedDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }

foreach ($drive in $mountedDrives) {
    $testPath = Join-Path -Path "$($drive.Name):\" -ChildPath "unattend.xml"
    Write-Host "  Checking: $testPath"
    if (Test-Path -Path $testPath) {
        $sourceUnattendPath = $testPath
        Write-Host "  Found unattend.xml at: $sourceUnattendPath"
        break
    }
}

if (-not $sourceUnattendPath) {
    Write-Host "  Not found on standard drives. Scanning CD/DVD drives..."
    $allDrives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -in @(2, 5) }
    foreach ($drive in $allDrives) {
        $testPath = Join-Path -Path "$($drive.DeviceID)\" -ChildPath "unattend.xml"
        Write-Host "  Checking removable/CD: $testPath"
        if (Test-Path -Path $testPath) {
            $sourceUnattendPath = $testPath
            Write-Host "  Found unattend.xml at: $sourceUnattendPath"
            break
        }
    }
}

if ($sourceUnattendPath -and (Test-Path -Path $sourceUnattendPath)) {
    Copy-Item -Path $sourceUnattendPath -Destination $unattendPath -Force
    Write-Host "  Copied $sourceUnattendPath -> $unattendPath ($((Get-Item $unattendPath).Length) bytes)"
}
else {
    Write-Host "  WARNING: unattend.xml not found on any drive. Sysprep will use an existing copy if present."
}

# ---------------------------------------------------------------------------
# 2. Stop services early to release file locks before cleanup
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [2/9] Stopping services ---"

function Stop-ServiceSafely {
    param ([string]$Name, [string]$Label = $Name)
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $svc) {
        Write-Host "  $Label - not found (skipping)"
    }
    elseif ($svc.Status -eq 'Stopped') {
        Write-Host "  $Label - already stopped"
    }
    else {
        Write-Host "  $Label - stopping (was: $($svc.Status))..."
        Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
        $svc.Refresh()
        Write-Host "  $Label - now: $($svc.Status)"
    }
}

Stop-ServiceSafely "wuauserv"     "Windows Update (wuauserv)"
Stop-ServiceSafely "bits"         "Background Intelligent Transfer (bits)"
Stop-ServiceSafely "cryptsvc"     "Cryptographic Services (cryptsvc)"
Stop-ServiceSafely "tiledatamodelsvc" "Tile Data Model (tiledatamodelsvc)"

# DISABLE (not just stop) Edge update services to prevent auto-restart during the
# long defrag/sdelete phase. Edge silently reinstalls companion packages (e.g. Edge.GameAssist)
# if its services recover, causing Remove-AppxPackage to appear to succeed but the package
# to reappear - even minutes later - and then block sysprep with 0x80073cf2.
Write-Host "  Disabling and stopping Microsoft Edge update services..."
foreach ($edgeSvcName in @("edgeupdate", "edgeupdatem", "MicrosoftEdgeElevationService")) {
    $edgeSvc = Get-Service -Name $edgeSvcName -ErrorAction SilentlyContinue
    if ($edgeSvc) {
        Write-Host "  Disabling: $edgeSvcName (was: $($edgeSvc.Status), StartType: $($edgeSvc.StartType))"
        Set-Service -Name $edgeSvcName -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $edgeSvcName -Force -ErrorAction SilentlyContinue
        Write-Host "  Disabled and stopped: $edgeSvcName"
    }
    else {
        Write-Host "  $edgeSvcName - not found (skipping)"
    }
}

$edgeProcs = Get-Process -Name msedge, MicrosoftEdge -ErrorAction SilentlyContinue
if ($edgeProcs) {
    $edgeProcs | ForEach-Object { Write-Host "  Killing Edge process: $($_.Name) (PID $($_.Id))" }
    $edgeProcs | Stop-Process -Force -ErrorAction SilentlyContinue
}
else {
    Write-Host "  No Edge processes running"
}

# Disable Edge scheduled tasks so they cannot relaunch Edge during cleanup
Write-Host "  Disabling Edge scheduled tasks..."
$edgeTasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.TaskPath -like "*Edge*" -or $_.TaskName -like "*Edge*"
}
if ($edgeTasks) {
    foreach ($task in $edgeTasks) {
        Write-Host "  Disabling task: $($task.TaskPath)$($task.TaskName)"
        Disable-ScheduledTask -TaskPath $task.TaskPath -TaskName $task.TaskName -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host "  Disabled $($edgeTasks.Count) Edge scheduled task(s)"
}
else {
    Write-Host "  No Edge scheduled tasks found"
}

# ---------------------------------------------------------------------------
# 3. Remove per-user AppX packages that are not provisioned system-wide
# ---------------------------------------------------------------------------
# Sysprep fails with 0x80073cf2 if any package was installed for a specific user
# but not provisioned for all users. Do this before temp cleanup since AppX
# removal generates temp files.
Write-Host ""
Write-Host "--- [3/9] AppX cleanup ---"

$provisionedDisplayNames = (Get-AppxProvisionedPackage -Online).DisplayName
Write-Host "  Provisioned packages in image: $($provisionedDisplayNames.Count)"

$packagesToRemove = Get-AppxPackage -AllUsers | Where-Object {
    -not $_.NonRemovable -and $provisionedDisplayNames -notcontains $_.Name
}
Write-Host "  Packages to remove (user-installed, not provisioned): $($packagesToRemove.Count)"

if ($packagesToRemove.Count -eq 0) {
    Write-Host "  Nothing to remove - skipping AppX cleanup."
}
else {
    $removed1 = 0
    $skipped1 = 0

    # First pass: frameworks throw COMException while dependents exist; they auto-remove later.
    Write-Host "  Pass 1: removing packages..."
    foreach ($pkg in $packagesToRemove) {
        Write-Host "    Removing: $($pkg.Name)"
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host "    Done: $($pkg.Name)" -ForegroundColor DarkGray
            $removed1++
        }
        catch {
            Write-Host "    Skipped (retry or auto-removed with dependents): $($pkg.Name) - $($_.Exception.Message)" -ForegroundColor DarkGray
            $skipped1++
        }
    }
    Write-Host "  Pass 1 complete: $removed1 removed, $skipped1 deferred"

    # Second pass: retry packages that failed due to dependency ordering
    $retried = 0
    $removedRetry = 0
    $failedRetry = 0
    Write-Host "  Pass 2: retrying deferred packages..."
    foreach ($pkg in $packagesToRemove) {
        if (Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -eq $pkg.PackageFullName }) {
            $retried++
            Write-Host "    Retrying: $($pkg.Name)"
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                Write-Host "    Done: $($pkg.Name)" -ForegroundColor DarkGray
                $removedRetry++
            }
            catch {
                Write-Host "    Could not remove: $($pkg.Name) - $($_.Exception.Message)" -ForegroundColor DarkGray
                $failedRetry++
            }
        }
    }
    if ($retried -eq 0) {
        Write-Host "  Pass 2: nothing left to retry (all removed or auto-removed with dependents)"
    }
    else {
        Write-Host "  Pass 2 complete: $retried retried, $removedRetry removed, $failedRetry failed"
    }
}
Write-Host "  AppX cleanup complete."

# ---------------------------------------------------------------------------
# 4. Clear Windows Update cache
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [4/9] Clearing Windows Update cache ---"
Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  Done: C:\Windows\SoftwareDistribution cleared"

# ---------------------------------------------------------------------------
# 5. Clear temporary files (after AppX so its temp output is also wiped)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [5/9] Clearing temporary files ---"
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -Exclude "packer*" -ErrorAction SilentlyContinue
Write-Host "  Done: C:\Windows\Temp cleared (excluding packer temp files)"
Remove-Item -Path "C:\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  Done: C:\Temp cleared"

# ---------------------------------------------------------------------------
# 6. Remove leftover user profiles
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [6/9] Cleaning up user profiles ---"
$profilesToRemove = Get-WmiObject -Class Win32_UserProfile | Where-Object {
    $_.Special -eq $false -and
    $_.LocalPath -notlike "*Administrator*" -and
    $_.LocalPath -notlike "*Default*"
}
if ($profilesToRemove) {
    foreach ($userProfile in $profilesToRemove) {
        Write-Host "  Removing profile: $($userProfile.LocalPath)"
        $userProfile | Remove-WmiObject -ErrorAction SilentlyContinue
    }
    Write-Host "  Removed $($profilesToRemove.Count) profile(s)"
}
else {
    Write-Host "  No extra profiles to remove"
}

# ---------------------------------------------------------------------------
# 7. BitLocker failsafe
# ---------------------------------------------------------------------------
# BitLocker should have been prevented by PreventDeviceEncryption set during the
# specialize pass in autounattend.xml. If the volume is still encrypted here,
# something went wrong upstream. Check before defrag/sdelete since decryption
# changes free space state.
Write-Host ""
Write-Host "--- [7/9] BitLocker check ---"
$bitlockerStatus = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
if ($null -eq $bitlockerStatus) {
    Write-Host "  BitLocker cmdlet returned nothing (BitLocker not available or not applicable)"
}
elseif ($bitlockerStatus.VolumeStatus -eq "FullyDecrypted") {
    Write-Host "  BitLocker OK: C: is fully decrypted (VolumeStatus=$($bitlockerStatus.VolumeStatus), ProtectionStatus=$($bitlockerStatus.ProtectionStatus))"
}
else {
    Write-Warning "  UNEXPECTED: BitLocker is active (VolumeStatus=$($bitlockerStatus.VolumeStatus), ProtectionStatus=$($bitlockerStatus.ProtectionStatus))."
    Write-Warning "  The PreventDeviceEncryption registry key set during specialize should have prevented this."
    Write-Warning "  Disabling BitLocker now as failsafe - investigate the autounattend specialize pass."
    Disable-BitLocker -MountPoint "C:" | Out-Null
    do {
        Start-Sleep -Seconds 10
        $bitlockerStatus = Get-BitLockerVolume -MountPoint "C:"
        Write-Host "  Decryption progress: $($bitlockerStatus.EncryptionPercentage)%"
    } while ($bitlockerStatus.VolumeStatus -ne "FullyDecrypted")
    Write-Host "  BitLocker fully decrypted on C:." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 8. Disk optimization
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [8/9] Disk optimization ---"
Write-Host "  Defragmenting C:..."
Optimize-Volume -DriveLetter C -Defrag -Verbose
Write-Host "  Zeroing free space (reduces template size after compression)..."
sdelete.exe -z C: -accepteula
Write-Host "  Disk optimization complete"

# ---------------------------------------------------------------------------
# 9. Clear event logs (last - captures log entries from this script too)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [9/9] Clearing event logs ---"
$logs = Get-EventLog -LogName * -ErrorAction SilentlyContinue
$logCount = ($logs | Measure-Object).Count
$logs | ForEach-Object {
    Write-Host "  Clearing: $($_.Log)"
    Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue
}
Write-Host "  Cleared $logCount event log(s)"

# ---------------------------------------------------------------------------
# Sysprep
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Pre-sysprep cleanup completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="

# Pre-flight: scan for packages installed per-user but not provisioned system-wide.
# Sysprep fails with 0x80073cf2 if any such package remains. This runs after all
# cleanup so anything listed here is a genuine blocker.
Write-Host ""
Write-Host "--- AppX pre-flight check ---"
$provisionedNames = (Get-AppxProvisionedPackage -Online).DisplayName
$sysprepBlockers = Get-AppxPackage -AllUsers | Where-Object {
    -not $_.NonRemovable -and $provisionedNames -notcontains $_.Name
}
if ($sysprepBlockers) {
    Write-Host "[WARNING] Found $($sysprepBlockers.Count) package(s) that would block sysprep (user-installed, not provisioned). Attempting final removal..."
    foreach ($pkg in $sysprepBlockers) {
        Write-Host "[WARNING] Blocker: $($pkg.Name) ($($pkg.PackageFullName))"
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host "  Removed in pre-flight: $($pkg.Name)" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "[WARNING] CRITICAL: Could not remove $($pkg.Name). Sysprep WILL fail with 0x80073cf2. Error: $($_.Exception.Message)"
        }
    }
    $stillBlocking = Get-AppxPackage -AllUsers | Where-Object {
        -not $_.NonRemovable -and $provisionedNames -notcontains $_.Name
    }
    if ($stillBlocking) {
        $names = ($stillBlocking | Select-Object -ExpandProperty Name) -join ", "
        Write-Error "Pre-flight FAILED: $($stillBlocking.Count) package(s) still blocking sysprep: $names"
        exit 1
    }
    Write-Host "  Pre-flight: all blockers resolved." -ForegroundColor Green
}
else {
    Write-Host "  Pre-flight passed: no packages would block sysprep." -ForegroundColor Green
}

# Verify unattend file before launching sysprep
Write-Host ""
Write-Host "--- Verifying unattend.xml ---"
if (-not (Test-Path "C:\Deploy\unattend.xml")) {
    Write-Error "Unattend file not found at C:\Deploy\unattend.xml. Cannot proceed with sysprep."
    exit 1
}
Write-Host "  Path : C:\Deploy\unattend.xml"
Write-Host "  Size : $((Get-Item 'C:\Deploy\unattend.xml').Length) bytes"
Write-Host "  Ready: OK" -ForegroundColor Green

Write-Host ""
Write-Host "--- Launching sysprep ---"
Write-Host "  Command: sysprep.exe /oobe /generalize /mode:vm /quit /unattend:C:\Deploy\unattend.xml"

try {
    # Final Edge kill right before sysprep to close the race window between the pre-flight
    # check and sysprep's own AppX validation. Edge may have respawned during event log
    # clearing or other late operations even with services disabled.
    Write-Host "  Final Edge sweep before sysprep..."
    Get-Process -Name msedge, MicrosoftEdge -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    $gameAssistFinal = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "Microsoft.Edge.GameAssist" }
    if ($gameAssistFinal) {
        Write-Host "[WARNING] Edge.GameAssist re-appeared after pre-flight - removing now (Edge respawned despite disabled services)..."
        foreach ($gaPkg in $gameAssistFinal) {
            try {
                Remove-AppxPackage -Package $gaPkg.PackageFullName -AllUsers -ErrorAction Stop
                Write-Host "  Final removal OK: $($gaPkg.PackageFullName)"
            }
            catch {
                Write-Host "[WARNING] Final removal of Edge.GameAssist failed: $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Host "  Edge.GameAssist not present - safe to proceed"
    }

    $sysrepStartTime = Get-Date
    Write-Host "  Started at: $($sysrepStartTime.ToString('yyyy-MM-dd HH:mm:ss'))"

    $sysprepArgs = @(
        "/oobe"
        "/generalize"
        "/mode:vm"
        "/quit"
        "/unattend:C:\Deploy\unattend.xml"
    )
    $process = Start-Process -FilePath "$($ENV:SystemRoot)\System32\Sysprep\sysprep.exe" -ArgumentList $sysprepArgs -Wait -PassThru -NoNewWindow

    $duration = (Get-Date) - $sysrepStartTime
    Write-Host "  Duration  : $($duration.TotalMinutes.ToString('F2')) minutes"
    Write-Host "  Exit code : $($process.ExitCode)"

    if ($process.ExitCode -eq 0) {
        Write-Host "  Sysprep completed successfully." -ForegroundColor Green

        Write-Host "  Clearing PowerShell history..."
        Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt" -Force -ErrorAction SilentlyContinue
        Write-Host "  Final temp file cleanup..."
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host ""
        Write-Host "=== Generalization completed successfully at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -ForegroundColor Green
        Write-Host "  Initiating shutdown..."
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
        Write-Host "Sysprep error log ($sysrepLog) - last 20 lines:" -ForegroundColor Yellow
        Get-Content $sysrepLog | Select-Object -Last 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    }
    else {
        Write-Host "  Sysprep error log not found at $sysrepLog"
    }

    exit 1
}
