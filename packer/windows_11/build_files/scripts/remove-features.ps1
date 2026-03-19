# Windows 11 - Remove Features

$ErrorActionPreference = "Stop"

# Remove PowerShell v2
Write-Host "Remove PowerShell v2"
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2 -NoRestart | Out-Null

# Remove XPS Viewer
Write-Host "Remove XPS Viewer"
Disable-WindowsOptionalFeature -Online -FeatureName Xps-Foundation-Xps-Viewer -NoRestart | Out-Null

# Remove Microsoft XPS Document Writer
Write-Host "Remove Microsoft XPS Document Writer"
Disable-WindowsOptionalFeature -Online -FeatureName Printing-XPSServices-Features -NoRestart | Out-Null

# Remove Windows Media Player (legacy)
Write-Host "Remove Windows Media Player (legacy)"
Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer -NoRestart | Out-Null

# Remove Windows Media Playback
Write-Host "Remove Windows Media Playback"
Disable-WindowsOptionalFeature -Online -FeatureName MediaPlayback -NoRestart | Out-Null

# Remove Microsoft Print to PDF
Write-Host "Remove Microsoft Print to PDF"
Disable-WindowsOptionalFeature -Online -FeatureName Printing-PrintToPDFServices-Features -NoRestart | Out-Null

# Remove Internet Explorer mode (optional, graceful)
Write-Host "Remove Internet Explorer optional component"
Disable-WindowsOptionalFeature -Online -FeatureName Internet-Explorer-Optional-amd64 -NoRestart | Out-Null
