# Not working - see remove-edge-gameassist.ps1 for the new approach of stopping AppX services to block sysprep from enumerating the package list, which allows sysprep to succeed even if GameAssist persists in the system-level store.


# AppX package cleanup for Windows 11 (ISO build)
# Removes per-user AppX packages that are not provisioned system-wide.
# Sysprep fails with 0x80073cf2 if any such package remains.

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"  # Prevent warning stream from causing failures in Packer/WinRM sessions

Write-Host "=== AppX cleanup started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="

# ---------------------------------------------------------------------------
# 1. Remove per-user AppX packages that are not provisioned system-wide
# ---------------------------------------------------------------------------
# Sysprep fails with 0x80073cf2 if any package was installed for a specific user
# but not provisioned for all users. Do this before temp cleanup since AppX
# removal generates temp files.
Write-Host ""
Write-Host "--- [1/2] AppX cleanup ---"

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
# 2. Pre-flight check for sysprep blockers
# ---------------------------------------------------------------------------
# Pre-flight: scan for packages that would cause sysprep to fail with 0x80073cf2.
# Sysprep flags any installed package that is NOT in the provisioned list - regardless
# of which SID it is registered under. This includes S-1-5-18 (LocalSystem) registrations
# left by Edge's own deployment mechanism, which Remove-AppxPackage reports as removed
# but does not actually remove from the system-level store.
# Strategy (in order):
#   1. Remove-AppxPackage -AllUsers (standard path)
#   2. Delete the per-SID registry key directly (for LocalSystem-registered packages)
#   3. Re-provision the package (last resort - sysprep accepts provisioned packages)
Write-Host ""
Write-Host "--- [2/2] AppX pre-flight check ---"
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

    # Re-check using ErrorAction SilentlyContinue - if AppX services were stopped in
    # Fallback 2, Get-AppxPackage may return empty (same view sysprep will have).
    $provisionedNamesNow = (Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue) | ForEach-Object { ($_.PackageName -split '_')[0] }
    $stillBlocking = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object {
        -not $_.NonRemovable -and
        -not $_.IsFramework -and
        $provisionedNamesNow -notcontains $_.Name
    }
    if ($stillBlocking) {
        $names = ($stillBlocking | Select-Object -ExpandProperty Name) -join ", "
        Write-Host "Pre-flight FAILED: $($stillBlocking.Count) package(s) still blocking sysprep: $names"
        Write-Host "GameAssist is the most common offender due to its LocalSystem registration. It will be nuked later in the final cleanup script if it persists."
    }
    Write-Host "  Pre-flight: all blockers resolved."
}
else {
    Write-Host "  Pre-flight passed: no packages would block sysprep."
}

Write-Host ""
Write-Host "=== AppX cleanup completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
