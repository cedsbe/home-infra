# Windows Server 2025 - Remove Features

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
    }
}

# Determine if Core or Desktop Experience
$osVersion = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name InstallationType

# Common Features

# Remove PowerShell v2
Write-Host "Remove PowerShell v2"
Disable-FeatureSafely -FeatureName "MicrosoftWindowsPowerShellV2Root"
Disable-FeatureSafely -FeatureName "MicrosoftWindowsPowerShellV2"

# If Desktop Experience is installed disable these features, otherwise Exit cleanly

if ( $osVersion -eq "Server" )
{
    # Remove XPS Viewer
    Write-Host "Remove XPS Viewer"
    Uninstall-WindowsFeature -Name XPS-Viewer | Out-Null

    # Remove Microsoft XPS Document Writer
    Write-Host "Remove Microsoft XPS Document Writer"
    Disable-FeatureSafely -FeatureName "Printing-XPSServices-Features"

    # Remove Windows Media Player
    Write-Host "Remove Windows Media Player"
    Disable-FeatureSafely -FeatureName "WindowsMediaPlayer"

    # Remove Windows Media Playback
    Write-Host "Remove Windows Media Playback"
    Disable-FeatureSafely -FeatureName "MediaPlayback"

    # Remove Microsoft Print to PDF
    Write-Host "Remove Microsoft Print to PDF"
    Disable-FeatureSafely -FeatureName "Printing-PrintToPDFServices-Features"

    # Deprovision bloatware AppX packages from the image (Desktop Experience only).
    # Using Remove-AppxProvisionedPackage so packages are removed from the provisioned
    # image list and will NOT be re-installed by sysprep when the template is cloned.
    # Must run before Windows Update to prevent re-installation.
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
            Write-Host "[WARNING] Failed to deprovision $DisplayName`: $($_.Exception.Message)"
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
}
else
{
    exit 0
}
