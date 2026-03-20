# Windows Server 2025 - Remove Features

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
}
else
{
    exit 0
}
