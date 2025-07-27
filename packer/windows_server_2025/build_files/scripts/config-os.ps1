# Windows 2025 - Customize OS

$ErrorActionPreference = "Stop"

#Disable Windows Admin Center Pop-up in Server Manager
Write-Host "Disable Windows Admin Center Pop-up in Server Manager"
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -Name "DoNotPopWACConsoleAtSMLaunch" -Value 1 -PropertyType DWord | Out-Null

# Enable RDP Connections
Write-Host "Enable RDP Connections"
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Type DWord -Value 0 | Out-Null
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" | Out-Null

# Create C:\Temp
Write-Host "Create C:\Temp"
New-Item -Path C:\Temp -ItemType Directory | Out-Null

# Create C:\Deploy
Write-Host "Create C:\Deploy"
New-Item -Path C:\Deploy -ItemType Directory | Out-Null

# Enable Firewall
Write-Host "Enable Windows Firewall"
netsh Advfirewall set allprofiles state on

# Clear Event Logs
Write-Host "Clear Event Logs"
Get-EventLog -LogName * | ForEach-Object { Clear-EventLog -LogName $_.Log } -Verbose | Out-Null
