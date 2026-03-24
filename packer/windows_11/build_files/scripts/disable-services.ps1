# Windows 11 - Disable Services
# https://docs.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services

$ErrorActionPreference = "Stop"

# Create a function to disable services. If the service is not installed, ignore the error.
function Disable-Service {
    param (
        [string]$ServiceName
    )

    try {
        Get-Service -Name $ServiceName | Set-Service -StartupType Disabled | Out-Null
    }
    catch {
        Write-Host "Service $ServiceName not installed"
    }
}

# Common Services

Write-Host "Disable Internet Connection Sharing (ICS)"
Disable-Service -ServiceName "SharedAccess"

Write-Host "Disable Link-Layer Topology Discovery Mapper"
Disable-Service -ServiceName "lltdsvc"

Write-Host "Disable Smart Card Device Enumeration Service"
Disable-Service -ServiceName "ScDeviceEnum"

Write-Host "Disable Windows Insider Service"
Disable-Service -ServiceName "wisvc"

Write-Host "Disable Azure Arc Instance Metadata Service"
Disable-Service -ServiceName "himds"

Write-Host "Disable Azure Guest Configuration Arc Service"
Disable-Service -ServiceName "GCArcService"

Write-Host "Disable Azure Connected Machine Agent"
Disable-Service -ServiceName "AzureConnectedMachineAgent"

Write-Host "Disable Azure Extension Service"
Disable-Service -ServiceName "ExtensionService"

# Windows 11 consumer services

Write-Host "Disable Bluetooth Support Service"
Disable-Service -ServiceName "bthserv"

Write-Host "Disable Contact Data"
Disable-Service -ServiceName "PimIndexMaintenanceSvc"

Write-Host "Disable Diagnostics Tracking Service"
Disable-Service -ServiceName "DiagTrack"

Write-Host "Disable Downloaded Maps Manager"
Disable-Service -ServiceName "MapsBroker"

Write-Host "Disable Geolocation Service"
Disable-Service -ServiceName "lfsvc"

Write-Host "Disable Microsoft Account Sign-in Assistant"
Disable-Service -ServiceName "wlidsvc"

Write-Host "Disable Network Connection Broker"
Disable-Service -ServiceName "NcbService"

Write-Host "Disable Print Spooler"
Disable-Service -ServiceName "Spooler"

Write-Host "Disable Printer Extensions and Notifications"
Disable-Service -ServiceName "PrintNotify"

Write-Host "Disable Program Compatibility Assistant Service"
Disable-Service -ServiceName "PcaSvc"

Write-Host "Disable Radio Management Service"
Disable-Service -ServiceName "RmSvc"

Write-Host "Disable Sensor Data Service"
Disable-Service -ServiceName "SensorDataService"

Write-Host "Disable Sensor Monitoring Service"
Disable-Service -ServiceName "SensrSvc"

Write-Host "Disable Sensor Service"
Disable-Service -ServiceName "SensorService"

Write-Host "Disable Shell Hardware Detection"
Disable-Service -ServiceName "ShellHWDetection"

Write-Host "Disable SSDP Discovery"
Disable-Service -ServiceName "SSDPSRV"

Write-Host "Disable UPnP Device Host"
Disable-Service -ServiceName "upnphost"

Write-Host "Disable User Data Access"
Disable-Service -ServiceName "UserDataSvc"

Write-Host "Disable User Data Storage"
Disable-Service -ServiceName "UnistoreSvc"

Write-Host "Disable WalletService"
Disable-Service -ServiceName "WalletService"

Write-Host "Disable WAP Push Message Routing Service"
Disable-Service -ServiceName "dmwappushservice"

Write-Host "Disable Windows Camera Frame Server"
Disable-Service -ServiceName "FrameServer"

Write-Host "Disable Windows Push Notifications System Service"
Disable-Service -ServiceName "WpnService"

Write-Host "Disable Windows Push Notifications User Service"
Disable-Service -ServiceName "WpnUserService"

Write-Host "Disable Xbox Live Auth Manager"
Disable-Service -ServiceName "XblAuthManager"

Write-Host "Disable Xbox Live Game Save"
Disable-Service -ServiceName "XblGameSave"

Write-Host "Disable Xbox Live Networking Service"
Disable-Service -ServiceName "XboxNetApiSvc"

Write-Host "Disable Xbox Accessory Management Service"
Disable-Service -ServiceName "XboxGipSvc"

# Disable Edge's sidebar/games hub via policy so Edge cannot re-register
# GameAssist (or other companion packages) at any point during the build —
# including during Windows Update and the defrag/sdelete phase.
# This key persists across reboots so it remains effective in generalize-iso.ps1.
Write-Host "Disable Edge sidebar (prevents GameAssist re-registration)"
$edgePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
if (-not (Test-Path $edgePolicy)) { New-Item -Path $edgePolicy -Force | Out-Null }
Set-ItemProperty -Path $edgePolicy -Name "HubsSidebarEnabled" -Value 0 -Type DWord -Force

# Disable Edge update services early so Edge cannot update itself (and silently
# reinstall companion packages like GameAssist) during the Windows Update phase.
Write-Host "Disable Edge update services"
Disable-Service -ServiceName "edgeupdate"
Disable-Service -ServiceName "edgeupdatem"
Disable-Service -ServiceName "MicrosoftEdgeElevationService"

# List all the services containing "edge" and their startup types for validation/debugging purposes.
Write-Host "Current services containing 'edge' in their name and their startup types:"
Get-Service -Name "*edge*" | ForEach-Object {
    Write-Host "  $($_.Name): $($_.StartType)"
}

# List all the services and their startup types for validation/debugging purposes.
Write-Host "Current services and their startup types:"
Get-Service | ForEach-Object {
    Write-Host "  $($_.Name): $($_.StartType)"
}

# Disable Store auto-download policy early so the Store does not download or
# update app packages during Windows Update. Persists across reboots.
Write-Host "Disable Windows Store auto-download"
$storePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
if (-not (Test-Path $storePolicy)) { New-Item -Path $storePolicy -Force | Out-Null }
Set-ItemProperty -Path $storePolicy -Name "AutoDownload" -Value 2 -Type DWord -Force

# Disable Edge scheduled tasks (first pass — prevents them from firing during
# Windows Update; generalize-iso.ps1 runs a second pass to catch any re-added
# by Edge's own Windows Update).
Write-Host "Disable Edge scheduled tasks"
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.TaskPath -like "*Edge*" -or $_.TaskName -like "*Edge*"
} | ForEach-Object {
    Disable-ScheduledTask -TaskPath $_.TaskPath -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  Disabled task: $($_.TaskPath)$($_.TaskName)"
}

# List all the scheduled tasks and their states for validation/debugging purposes.
Write-Host "Current scheduled tasks and their states:"
Get-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  $($_.TaskPath)$($_.TaskName): $($_.State)"
}
