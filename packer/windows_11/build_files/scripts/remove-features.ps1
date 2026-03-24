# Windows 11 - Remove Features

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"  # Prevent warning stream from causing failures in Packer/WinRM sessions

# Gracefully disable an optional feature - skip if not present or already disabled
function Disable-FeatureSafely {
    param ([string]$FeatureName)
    $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction SilentlyContinue
    if ($null -eq $feature) {
        Write-Host "$FeatureName not found - skipping"
    } elseif ($feature.State -eq "Disabled") {
        Write-Host "$FeatureName already disabled - skipping"
    } else {
        Write-Host "Disabling $FeatureName"
        Disable-WindowsOptionalFeature -Online -FeatureName $FeatureName -NoRestart | Out-Null
        $after = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction SilentlyContinue
        if ($after -and $after.State -ne "Disabled") {
            Write-Host "  [WARNING] Validation FAILED: $FeatureName state is '$($after.State)' after disable attempt"
        } else {
            Write-Host "  Validation OK: $FeatureName is disabled"
        }
    }
}

# Remove PowerShell v2 (not present in all Windows 11 builds)
Write-Host "Remove PowerShell v2"
Disable-FeatureSafely -FeatureName "MicrosoftWindowsPowerShellV2Root"
Disable-FeatureSafely -FeatureName "MicrosoftWindowsPowerShellV2"

# Remove XPS Viewer
Write-Host "Remove XPS Viewer"
Disable-FeatureSafely -FeatureName "Xps-Foundation-Xps-Viewer"

# Remove Microsoft XPS Document Writer
Write-Host "Remove Microsoft XPS Document Writer"
Disable-FeatureSafely -FeatureName "Printing-XPSServices-Features"

# Remove Windows Media Player (legacy - removed in some Win11 builds)
Write-Host "Remove Windows Media Player (legacy)"
Disable-FeatureSafely -FeatureName "WindowsMediaPlayer"

# Remove Windows Media Playback
Write-Host "Remove Windows Media Playback"
Disable-FeatureSafely -FeatureName "MediaPlayback"

# Remove Microsoft Print to PDF
Write-Host "Remove Microsoft Print to PDF"
Disable-FeatureSafely -FeatureName "Printing-PrintToPDFServices-Features"

# Remove Internet Explorer mode (removed from Windows 11)
Write-Host "Remove Internet Explorer optional component"
Disable-FeatureSafely -FeatureName "Internet-Explorer-Optional-amd64"

# Deprovision bloatware AppX packages from the image.
# Using Remove-AppxProvisionedPackage (not Remove-AppxPackage) so the packages are
# removed from the provisioned image list and will NOT be re-installed by sysprep
# when the template is cloned. Must run before Windows Update to prevent re-installation.
Write-Host "Deprovisioning bloatware AppX packages from the image..."

function Remove-ProvisionedAppSafely {
    param ([string]$DisplayName)

    Write-Host "  Processing: $DisplayName"

    # Step 1: Remove from the provisioning list so the package is not reinstalled for
    # new users after sysprep. Remove-AppxProvisionedPackage alone is not enough —
    # it does NOT remove the package from users that already have it installed.
    # Per MS: https://learn.microsoft.com/en-us/troubleshoot/windows-client/
    # setup-upgrade-and-drivers/sysprep-fails-remove-or-update-store-apps
    Write-Host "  Step 1: Deprovision $DisplayName"
    try {
        $provPkg = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $DisplayName }
        if ($null -eq $provPkg) {
            Write-Host "    $DisplayName not provisioned - skipping deprovision"
        } else {
            Write-Host "    Deprovisioning: $DisplayName ($($provPkg.PackageName))"
            Remove-AppxProvisionedPackage -Online -PackageName $provPkg.PackageName -ErrorAction Stop | Out-Null
            Write-Host "    Removed: $DisplayName"
        }
    }
    catch {
        Write-Host "    [WARNING] Failed to deprovision ${DisplayName}: $($_.Exception.Message)"
    }

    # Validate step 1: confirm the package is no longer in the provisioned list.
    $stillProvisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $DisplayName }
    if ($stillProvisioned) {
        Write-Host "    [WARNING] Validation FAILED: $DisplayName is still provisioned after removal attempt"
    } else {
        Write-Host "    Validation OK: $DisplayName is not provisioned"
    }

    # Step 2: Remove all currently-installed instances for all users, including
    # architecture-specific variants (e.g. _x64__ packages installed alongside the
    # neutral bundle). These survive Remove-AppxProvisionedPackage and cause sysprep
    # to fail with 0x80073cf2 if left behind.
    Write-Host "  Step 2: Remove installed instances of $DisplayName for all users"
    $installedPkgs = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $DisplayName }
    if ($installedPkgs.Count -eq 0) {
        Write-Host "    No installed instances found"
    }
    foreach ($pkg in $installedPkgs) {
        try {
            Write-Host "    Removing: $($pkg.PackageFullName)"
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host "    Removed: $($pkg.PackageFullName)"
        }
        catch {
            Write-Host "    [WARNING] Could not remove $($pkg.PackageFullName): $($_.Exception.Message)"
        }
    }

    # Validate step 2: confirm no installed instances remain.
    $stillInstalled = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $DisplayName }
    if ($stillInstalled) {
        $names = ($stillInstalled | Select-Object -ExpandProperty PackageFullName) -join ", "
        Write-Host "    [WARNING] Validation FAILED: $($stillInstalled.Count) instance(s) still installed: $names"
    } else {
        Write-Host "    Validation OK: no installed instances of $DisplayName remain"
    }
}

# Consumer / entertainment
Remove-ProvisionedAppSafely "Clipchamp.Clipchamp"
Remove-ProvisionedAppSafely "Microsoft.BingNews"
Remove-ProvisionedAppSafely "Microsoft.BingSearch"
Remove-ProvisionedAppSafely "Microsoft.BingWeather"
Remove-ProvisionedAppSafely "Microsoft.GamingApp"
Remove-ProvisionedAppSafely "Microsoft.MicrosoftOfficeHub"
Remove-ProvisionedAppSafely "Microsoft.MicrosoftSolitaireCollection"
Remove-ProvisionedAppSafely "Microsoft.MicrosoftStickyNotes"
Remove-ProvisionedAppSafely "Microsoft.OutlookForWindows"
Remove-ProvisionedAppSafely "Microsoft.PowerAutomateDesktop"
Remove-ProvisionedAppSafely "Microsoft.Todos"
Remove-ProvisionedAppSafely "Microsoft.WindowsAlarms"
Remove-ProvisionedAppSafely "Microsoft.WindowsCamera"
Remove-ProvisionedAppSafely "Microsoft.WindowsFeedbackHub"
Remove-ProvisionedAppSafely "Microsoft.WindowsSoundRecorder"
Remove-ProvisionedAppSafely "Microsoft.YourPhone"
Remove-ProvisionedAppSafely "Microsoft.ZuneMusic"
Remove-ProvisionedAppSafely "Microsoft.Windows.DevHome"

# Xbox / gaming
Remove-ProvisionedAppSafely "Microsoft.Xbox.TCUI"
Remove-ProvisionedAppSafely "Microsoft.XboxGamingOverlay"
Remove-ProvisionedAppSafely "Microsoft.XboxIdentityProvider"
Remove-ProvisionedAppSafely "Microsoft.XboxSpeechToTextOverlay"
Remove-ProvisionedAppSafely "Microsoft.Edge.GameAssist"

# Widgets / cross-device
Remove-ProvisionedAppSafely "MicrosoftWindows.Client.WebExperience"
Remove-ProvisionedAppSafely "MicrosoftWindows.CrossDevice"
Remove-ProvisionedAppSafely "Microsoft.WidgetsPlatformRuntime"

# Communication
Remove-ProvisionedAppSafely "MSTeams"
Remove-ProvisionedAppSafely "MicrosoftCorporationII.QuickAssist"

Write-Host "AppX deprovisioning complete."

Write-Host "Here are the remaining Microsoft-provisioned AppX packages (should be empty or close to it):"

# 8wekyb3d8bbwe is the package family name for Microsoft-provisioned apps. Filter out framework packages (e.g. .NET) since those are dependencies and not user-facing apps.
$appX = Get-AppxPackage -AllUsers | Where {$_.PackageFullName -like "*8wekyb3d8bbwe*" -and -not $_.IsFramework};
foreach ($pkg in $appX) {
    Write-Host "  $($pkg.PackageFullName)"
}

Write-Host "Feature removal complete."
