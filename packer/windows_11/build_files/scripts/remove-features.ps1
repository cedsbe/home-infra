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
