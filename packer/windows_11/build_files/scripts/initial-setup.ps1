param(
    [switch]$SkipFirewallDisable
)

$ErrorActionPreference = "Stop"

Write-Host "=== Windows Server 2025 Initial Setup Script ===" -ForegroundColor Green
Write-Host "Starting at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
if ($SkipFirewallDisable) {
    Write-Host "Running with: -SkipFirewallDisable parameter" -ForegroundColor Yellow
}

# Switch network connection to private mode
# Required for WinRM firewall rules
Write-Host "Configuring network profile..." -ForegroundColor Yellow
$networkProfile = Get-NetConnectionProfile
Write-Host "Current network profile: '$($networkProfile.Name)' (Category: $($networkProfile.NetworkCategory))" -ForegroundColor Cyan

While ($networkProfile.Name -eq "Identifying...") {
    Write-Host "Network still identifying... waiting 10 seconds" -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    $networkProfile = Get-NetConnectionProfile
    Write-Host "Current network profile: '$($networkProfile.Name)'" -ForegroundColor Cyan
}

Write-Host "Setting network profile '$($networkProfile.Name)' to Private..." -ForegroundColor Yellow
Set-NetConnectionProfile -Name $networkProfile.Name -NetworkCategory Private
Write-Host "✅ Network profile set to Private successfully" -ForegroundColor Green

# Drop the firewall while building and re-enable as a standalone provisioner in the Packer file if needs be
if (-not $SkipFirewallDisable) {
    Write-Host "Disabling Windows Firewall for all profiles..." -ForegroundColor Yellow
    Write-Host "Command: netsh Advfirewall set allprofiles state off" -ForegroundColor Gray
    netsh Advfirewall set allprofiles state off
    Write-Host "✅ Windows Firewall disabled successfully" -ForegroundColor Green
}
else {
    Write-Host "⏭️ Skipping firewall disable (parameter specified)" -ForegroundColor Yellow
}

# Enable WinRM service
Write-Host "Configuring WinRM service..." -ForegroundColor Yellow
Write-Host "Running WinRM quickconfig..." -ForegroundColor Cyan
winrm quickconfig -quiet
Write-Host "✅ WinRM quickconfig completed" -ForegroundColor Green

Write-Host "Enabling unencrypted connections..." -ForegroundColor Cyan
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
Write-Host "✅ Unencrypted connections enabled" -ForegroundColor Green

Write-Host "Enabling basic authentication..." -ForegroundColor Cyan
winrm set winrm/config/service/auth '@{Basic="true"}'
Write-Host "✅ Basic authentication enabled" -ForegroundColor Green

# Reset auto logon count
# https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon-logoncount#logoncount-known-issue
Write-Host "Resetting auto logon count..." -ForegroundColor Yellow
Write-Host "Setting AutoLogonCount to 0 in registry..." -ForegroundColor Cyan
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value 0
Write-Host "✅ Auto logon count reset successfully" -ForegroundColor Green

Write-Host "=== Initial Setup Script Completed Successfully ===" -ForegroundColor Green
Write-Host "Finished at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
