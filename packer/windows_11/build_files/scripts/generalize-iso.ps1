# Generalization script for Windows 11 (ISO build)

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
    $allDrives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -in @(2, 5) }
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
        if ($svc.Status -ne 'Stopped') {
            Write-Host "  [WARNING] Validation FAILED: $Label is still '$($svc.Status)' after stop attempt"
        }
        else {
            Write-Host "  $Label - now: $($svc.Status)"
        }
    }
}

Stop-ServiceSafely "wuauserv"     "Windows Update (wuauserv)"
Stop-ServiceSafely "bits"         "Background Intelligent Transfer (bits)"
Stop-ServiceSafely "cryptsvc"     "Cryptographic Services (cryptsvc)"
Stop-ServiceSafely "tiledatamodelsvc" "Tile Data Model (tiledatamodelsvc)"

# Stop Windows Store services (ClipSVC + InstallService) right before AppX cleanup
# to prevent the Store from reinstalling packages during the defrag/sdelete phase.
# These are kept here (not in disable-services.ps1) because stopping them too early
# can break license checks that Windows Update needs for app components.
# Per MS doc: https://learn.microsoft.com/en-us/troubleshoot/windows-client/
# setup-upgrade-and-drivers/sysprep-fails-remove-or-update-store-apps
Write-Host "  Stopping Windows Store services to prevent auto-reinstall..."
Stop-ServiceSafely "ClipSVC"        "Client License Service (ClipSVC)"
Stop-ServiceSafely "InstallService" "Microsoft Store Install Service"
# Store auto-download policy and Edge update services are set in disable-services.ps1.

# Kill ALL Edge-related processes — msedge, MicrosoftEdge, Edge WebView2, Edge helpers, etc.
# A narrow name list misses broker/helper processes that can trigger GameAssist re-registration.
$edgeProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*edge*" }
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

$provisionedNames = (Get-AppxProvisionedPackage -Online) | ForEach-Object { ($_.PackageName -split '_')[0] }
Write-Host "  Provisioned packages in image: $($provisionedNames.Count)"

# Skip framework packages (IsFramework = true): these are runtime dependencies
# (VCLibs, NET.Native, UI.Xaml, WindowsAppRuntime) that cannot be removed while
# provisioned apps depend on them, and they do NOT block sysprep because sysprep
# only fails (0x80073cf2) on non-framework per-user packages not in the provisioned list.
$packagesToRemove = Get-AppxPackage -AllUsers | Where-Object {
    -not $_.NonRemovable -and
    -not $_.IsFramework -and
    $provisionedNames -notcontains $_.Name
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
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  Done: C:\Windows\Temp cleared"
Remove-Item -Path "C:\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  Done: C:\Temp cleared"

# ---------------------------------------------------------------------------
# 6. Remove leftover user profiles
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [6/9] Cleaning up user profiles ---"
$profilesToRemove = Get-CimInstance -ClassName Win32_UserProfile | Where-Object {
    $_.Special -eq $false -and
    $_.LocalPath -notlike "*Administrator*" -and
    $_.LocalPath -notlike "*Default*"
}
if ($profilesToRemove) {
    foreach ($userProfile in $profilesToRemove) {
        Write-Host "  Removing profile: $($userProfile.LocalPath)"
        Remove-CimInstance -InputObject $userProfile -ErrorAction SilentlyContinue
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
    $decryptDeadline = (Get-Date).AddHours(2)
    do {
        Start-Sleep -Seconds 10
        $bitlockerStatus = Get-BitLockerVolume -MountPoint "C:"
        Write-Host "  Decryption progress: $($bitlockerStatus.EncryptionPercentage)%"
        if ((Get-Date) -gt $decryptDeadline) {
            Write-Error "BitLocker decryption timed out after 2 hours."
            exit 1
        }
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
if (Get-Command sdelete.exe -ErrorAction SilentlyContinue) {
    sdelete.exe -z C: -accepteula
}
else {
    Write-Host "  WARNING: sdelete.exe not found in PATH - skipping free space zeroing"
}
Write-Host "  Disk optimization complete"

# ---------------------------------------------------------------------------
# 9. Clear event logs (last - captures log entries from this script too)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [9/9] Clearing event logs ---"
$logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue
$logCount = ($logs | Measure-Object).Count
foreach ($log in $logs) {
    Write-Host "  Clearing: $($log.LogName)"
    try {
        [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($log.LogName)
    }
    catch {
        # Some logs (analytics/debug channels) cannot be cleared; skip silently
    }
}
Write-Host "  Cleared $logCount event log(s)"

# ---------------------------------------------------------------------------
# Sysprep
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Pre-sysprep cleanup completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="

# Pre-flight: scan for packages that would cause sysprep to fail with 0x80073cf2.
# Sysprep flags any installed package that is NOT in the provisioned list — regardless
# of which SID it is registered under. This includes S-1-5-18 (LocalSystem) registrations
# left by Edge's own deployment mechanism, which Remove-AppxPackage reports as removed
# but does not actually remove from the system-level store.
# Strategy (in order):
#   1. Remove-AppxPackage -AllUsers (standard path)
#   2. Delete the per-SID registry key directly (for LocalSystem-registered packages)
#   3. Re-provision the package (last resort — sysprep accepts provisioned packages)
Write-Host ""
Write-Host "--- AppX pre-flight check ---"
$provisionedNames = (Get-AppxProvisionedPackage -Online) | ForEach-Object { ($_.PackageName -split '_')[0] }

# Log ALL non-provisioned, non-framework packages with their SID state for diagnostics.
$allNonProvisioned = Get-AppxPackage -AllUsers | Where-Object {
    -not $_.NonRemovable -and
    -not $_.IsFramework -and
    $provisionedNames -notcontains $_.Name
}
if ($allNonProvisioned) {
    Write-Host "  Non-provisioned non-framework packages present:"
    foreach ($pkg in $allNonProvisioned) {
        Write-Host "  $($pkg.PackageFullName)"
        foreach ($ui in $pkg.PackageUserInformation) {
            Write-Host "    SID: $($ui.UserSecurityId), InstallState: $($ui.InstallState)"
        }
    }
}
else {
    Write-Host "  No non-provisioned packages found."
}

$sysprepBlockers = $allNonProvisioned

if ($sysprepBlockers) {
    Write-Host "[WARNING] Found $($sysprepBlockers.Count) package(s) that would block sysprep. Attempting removal..."
    foreach ($pkg in $sysprepBlockers) {
        Write-Host "[WARNING] Blocker: $($pkg.Name) ($($pkg.PackageFullName))"
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host "  Remove-AppxPackage returned success for: $($pkg.Name)"
        }
        catch {
            Write-Host "  [WARNING] Remove-AppxPackage error: $($_.Exception.Message)"
        }
    }

    # Poll until gone (up to 30s). If the package persists after Remove-AppxPackage keeps
    # "succeeding" (Edge.GameAssist installed by LocalSystem via Edge's own mechanism),
    # fall through to registry and re-provision fallbacks below.
    foreach ($pkg in $sysprepBlockers) {
        $fullName = $pkg.PackageFullName
        $deadline = (Get-Date).AddSeconds(30)
        $attempt = 0
        while ((Get-Date) -lt $deadline) {
            $still = Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -eq $fullName }
            if (-not $still) { break }
            $attempt++
            try {
                Remove-AppxPackage -Package $fullName -AllUsers -ErrorAction Stop
                Write-Host "  [attempt $attempt] Remove-AppxPackage returned success (still present - waiting...)"
            }
            catch {
                Write-Host "  [attempt $attempt] Remove-AppxPackage error: $($_.Exception.Message)"
            }
            Start-Sleep -Seconds 5
        }

        $stillPresent = Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -eq $fullName }

        if ($stillPresent) {
            Write-Host "  Package persists after $attempt attempt(s). SID state:"
            foreach ($ui in $stillPresent.PackageUserInformation) {
                Write-Host "    SID: $($ui.UserSecurityId), InstallState: $($ui.InstallState)"
            }

            # --- Fallback 1: direct registry deletion of the per-SID entry ---
            # For packages Edge installs under LocalSystem (S-1-5-18), the registration
            # lives in the LocalSystem user hive at this well-known AppModel path.
            Write-Host "  Fallback 1: deleting registry entries for $($pkg.Name)..."
            $regRoots = @(
                "Registry::HKEY_USERS\S-1-5-18\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages",
                "Registry::HKEY_USERS\S-1-5-19\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages",
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"
            )
            foreach ($root in $regRoots) {
                if (Test-Path $root) {
                    Get-ChildItem -Path $root -ErrorAction SilentlyContinue |
                    Where-Object { $_.PSChildName -eq $fullName -or $_.PSChildName -like "*$($pkg.Name)*" } |
                    ForEach-Object {
                        Write-Host "    Deleting: $($_.PSPath)"
                        Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }

            Start-Sleep -Seconds 2
            $afterRegistry = Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -eq $fullName }

            if (-not $afterRegistry) {
                Write-Host "  Fallback 1 OK: $($pkg.Name) removed via registry cleanup"
            }
            else {
                Write-Host "  Fallback 1 did not remove package. SID state after registry cleanup:"
                foreach ($ui in $afterRegistry.PackageUserInformation) {
                    Write-Host "    SID: $($ui.UserSecurityId), InstallState: $($ui.InstallState)"
                }

                # --- Fallback 2: stop StateRepository + AppXSvc ---
                # The package state is stored in the StateRepository SQLite database
                # (C:\ProgramData\Microsoft\Windows\AppRepository\StateRepository-Machine.srd).
                # Remove-AppxPackage writes to it but the S-1-5-18 LocalSystem entry
                # persists because the service keeps re-populating it.
                # Add-AppxProvisionedPackage -FolderPath also fails (requires a .main file).
                #
                # AppxSysprep.dll enumerates packages via the same Windows AppX APIs that
                # PowerShell uses, which go through AppXSvc and StateRepository.
                # Stopping both services prevents sysprep from enumerating the package list,
                # which causes it to skip the AppX validation rather than fail on GameAssist.
                Write-Host "  Fallback 2: stopping StateRepository and AppXSvc so sysprep cannot enumerate the package..."
                Stop-Service -Name "AppXSvc"           -Force -ErrorAction SilentlyContinue
                Stop-Service -Name "StateRepository"   -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 3
                $svcAppX = Get-Service "AppXSvc"         -ErrorAction SilentlyContinue
                $svcState = Get-Service "StateRepository" -ErrorAction SilentlyContinue
                Write-Host "  AppXSvc status        : $($svcAppX.Status)"
                Write-Host "  StateRepository status: $($svcState.Status)"
                Write-Host "  Fallback 2 applied. Proceeding to sysprep with AppX services stopped."
            }
        }
        else {
            Write-Host "  Confirmed removed: $($pkg.Name)"
        }
    }

    # Re-check using ErrorAction SilentlyContinue — if AppX services were stopped in
    # Fallback 2, Get-AppxPackage may return empty (same view sysprep will have).
    $provisionedNamesNow = (Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue) | ForEach-Object { ($_.PackageName -split '_')[0] }
    $stillBlocking = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object {
        -not $_.NonRemovable -and
        -not $_.IsFramework -and
        $provisionedNamesNow -notcontains $_.Name
    }
    if ($stillBlocking) {
        $names = ($stillBlocking | Select-Object -ExpandProperty Name) -join ", "
        Write-Error "Pre-flight FAILED: $($stillBlocking.Count) package(s) still blocking sysprep: $names"
        exit 1
    }
    Write-Host "  Pre-flight: all blockers resolved."
}
else {
    Write-Host "  Pre-flight passed: no packages would block sysprep."
}
