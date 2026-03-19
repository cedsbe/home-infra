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
