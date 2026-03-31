# Generalization script for Windows 11 (ISO build)
# System-level cleanup: unattend copy, service stops, cache/temp/profile removal.
# AppX cleanup and disk optimization are handled by separate scripts.

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"  # Prevent warning stream from causing failures in Packer/WinRM sessions

Write-Host "=== Generalization script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
Write-Host "Host: $env:COMPUTERNAME | OS: $((Get-WmiObject Win32_OperatingSystem).Caption)"

# ---------------------------------------------------------------------------
# 1. Copy unattend.xml to C:\Deploy so sysprep can find it after ISO is ejected
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [1/6] Copying unattend.xml to C:\Deploy ---"
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
Write-Host "--- [2/6] Stopping services ---"

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

# Kill ALL Edge-related processes - msedge, MicrosoftEdge, Edge WebView2, Edge helpers, etc.
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
# 3. Clear Windows Update cache
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [3/6] Clearing Windows Update cache ---"
Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  Done: C:\Windows\SoftwareDistribution cleared"

# ---------------------------------------------------------------------------
# 4. Clear temporary files (after AppX so its temp output is also wiped)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [4/6] Clearing temporary files ---"
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -Exclude "packer*" -ErrorAction SilentlyContinue
Write-Host "  Done: C:\Windows\Temp cleared (excluding packer temp files)"
Remove-Item -Path "C:\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  Done: C:\Temp cleared"

# ---------------------------------------------------------------------------
# 5. Remove leftover user profiles
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [5/6] Cleaning up user profiles ---"
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

Write-Host ""
Write-Host "=== Generalization cleanup completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
