# Generalization script for Windows 11 (clone build)
# System-level cleanup: unattend copy, service stops, cache/temp/profile removal.
# AppX cleanup and disk optimization are handled by separate scripts.

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"  # Prevent warning stream from causing failures in Packer/WinRM sessions

Write-Host "=== Generalization script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
Write-Host "Host: $env:COMPUTERNAME | OS: $((Get-WmiObject Win32_OperatingSystem).Caption)"

# ---------------------------------------------------------------------------
# 1. Stop services early to release file locks before cleanup
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [1/5] Stopping services ---"

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

# Stop sshd before touching key files to avoid file locks
Stop-ServiceSafely "sshd" "OpenSSH Server (sshd)"

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
Write-Host "--- [2/5] Clearing Windows Update cache ---"
Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  Done: C:\Windows\SoftwareDistribution cleared"

# ---------------------------------------------------------------------------
# 4. Clear temporary files (after AppX so its temp output is also wiped)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [3/5] Clearing temporary files ---"
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -Exclude "packer*" -ErrorAction SilentlyContinue
Write-Host "  Done: C:\Windows\Temp cleared (excluding packer temp files)"
Remove-Item -Path "C:\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  Done: C:\Temp cleared"

# ---------------------------------------------------------------------------
# 5. Remove leftover user profiles
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [4/5] Cleaning up user profiles ---"
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
# 5. SSH key cleanup
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [5/5] SSH key cleanup ---"

# Remove OpenSSH host keys so each cloned VM regenerates unique fingerprints on first boot
Write-Host "  Removing OpenSSH host keys from C:\ProgramData\ssh..."
$sshHostKeyPath = "C:\ProgramData\ssh"
if (Test-Path $sshHostKeyPath) {
    $hostKeys = Get-ChildItem -Path $sshHostKeyPath -Filter 'ssh_host_*' -File -ErrorAction SilentlyContinue
    if ($hostKeys) {
        foreach ($key in $hostKeys) {
            try {
                Remove-Item -Path $key.FullName -Force -ErrorAction Stop
                Write-Host "  Removed host key: $($key.Name)"
            }
            catch {
                Write-Warning "  Failed to remove host key $($key.FullName): $($_.Exception.Message)"
            }
        }
        Write-Host "  Removed $($hostKeys.Count) host key file(s)"
    }
    else {
        Write-Host "  No ssh_host_* files found in $sshHostKeyPath"
    }
}
else {
    Write-Host "  OpenSSH directory not found ($sshHostKeyPath) - skipping"
}

# Scrub user private SSH keys from all user profiles (keep authorized_keys)
Write-Host "  Scrubbing user private SSH keys from C:\Users\..."
$usersWithSsh = 0
$keysRemoved = 0
Get-ChildItem -Path 'C:\Users' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $userSsh = Join-Path $_.FullName '.ssh'
    if (Test-Path $userSsh) {
        $usersWithSsh++
        $privateKeys = Get-ChildItem $userSsh -ErrorAction SilentlyContinue | Where-Object {
            ($_.Name -like 'id_*' -or $_.Extension -in '.pem', '.ppk') -and -not $_.PSIsContainer
        }
        foreach ($key in $privateKeys) {
            try {
                Remove-Item -Path $key.FullName -Force -ErrorAction Stop
                Write-Host "  Removed private key: $($key.FullName)"
                $keysRemoved++
            }
            catch {
                Write-Warning "  Failed to remove private key $($key.FullName): $($_.Exception.Message)"
            }
        }
    }
}
Write-Host "  SSH key scrub complete: $keysRemoved private key file(s) removed across $usersWithSsh user(s) with .ssh directories"

Write-Host ""
Write-Host "=== Generalization cleanup completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
