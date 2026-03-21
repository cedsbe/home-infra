# Windows 11 - Remove Features

$ErrorActionPreference = "Stop"

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
    try {
        $pkg = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $DisplayName }
        if ($null -eq $pkg) {
            Write-Host "  $DisplayName not provisioned - skipping"
        } else {
            Write-Host "  Deprovisioning: $DisplayName ($($pkg.PackageName))"
            Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction Stop | Out-Null
            Write-Host "  Done: $DisplayName" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "  Failed to deprovision $DisplayName`: $($_.Exception.Message)"
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
