# Windows 2025 Datacenter and Standard - Disable Services
# https://docs.microsoft.com/en-us/windows-server/security/windows-services/security-guidelines-for-disabling-system-services-in-windows-server

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


# Determine if Core or Desktop Experience
$osVersion = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name InstallationType

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

# If Desktop Experience is installed disable these services, otherwise Exit cleanly

if ( $osVersion -eq "Server" )
{
    Write-Host "Disable ActiveX Installer (AxInstSV)"
    Disable-Service -ServiceName "AxInstSV"

    Write-Host "Disable Bluetooth Support Service"
    Disable-Service -ServiceName "bthserv"

    Write-Host "Disable Contact Data"
    Disable-Service -ServiceName "PimIndexMaintenanceSvc"

    Write-Host "Disable WAP Push Message Routing Service"
    Disable-Service -ServiceName "dmwappushservice"

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

    Write-Host "Disable Quality Windows Audio Video Experience"
    Disable-Service -ServiceName "QWAVE"

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

    Write-Host "Disable Still Image Acquisition Events"
    Disable-Service -ServiceName "WiaRpc"

    Write-Host "Disable Touch Keyboard and Handwriting Panel Service"
    Disable-Service -ServiceName "TabletInputService"

    Write-Host "Disable UPnP Device Host"
    Disable-Service -ServiceName "upnphost"

    Write-Host "Disable User Data Access"
    Disable-Service -ServiceName "UserDataSvc"

    Write-Host "Disable User Data Storage"
    Disable-Service -ServiceName "UnistoreSvc"

    Write-Host "Disable WalletService"
    Disable-Service -ServiceName "WalletService"

    Write-Host "Disable Windows Audio"
    Disable-Service -ServiceName "Audiosrv"

    Write-Host "Disable Windows Audio Endpoint Builder"
    Disable-Service -ServiceName "AudioEndpointBuilder"

    Write-Host "Disable Windows Camera Frame Server"
    Disable-Service -ServiceName "FrameServer"

    Write-Host "Disable Windows Image Acquisition (WIA)"
    Disable-Service -ServiceName "stisvc"

    Write-Host "Disable Windows Push Notifications System Service"
    Disable-Service -ServiceName "WpnService"

    Write-Host "Disable Windows Push Notifications User Service"
    Disable-Service -ServiceName "WpnUserService"
}
else
{
    exit 0
}
