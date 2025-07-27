# Enhanced generalization script for Windows Server 2025

$ErrorActionPreference = "Stop"

Write-Host "Starting enhanced generalization process..."

# Stop Windows Update service to prevent conflicts during sysprep
Write-Host "Stopping Windows Update services..."
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
Stop-Service -Name cryptsvc -Force -ErrorAction SilentlyContinue

# Stop tile data model service
Write-Host "Stopping tiledatamodelsvc..."
Get-Service -Name tiledatamodelsvc -ErrorAction SilentlyContinue | Stop-Service -Force

# Clear Windows Update cache
Write-Host "Clearing Windows Update cache..."
Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear temporary files
Write-Host "Clearing temporary files..."
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear event logs (optional - comment out if you want to keep logs)
Write-Host "Clearing event logs..."
Get-EventLog -LogName * | ForEach-Object { Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue }

# Remove any leftover user profiles except default ones
Write-Host "Cleaning up user profiles..."
Get-WmiObject -Class Win32_UserProfile | Where-Object {
    $_.Special -eq $false -and
    $_.LocalPath -notlike "*Administrator*" -and
    $_.LocalPath -notlike "*Default*"
} | Remove-WmiObject -ErrorAction SilentlyContinue

# Defragment the disk (optional but recommended for template optimization)
Write-Host "Optimizing disk..."
Optimize-Volume -DriveLetter C -Defrag -Verbose

# Zero out free space (use with caution - this takes time but reduces template size)
# Uncomment the following lines if you want maximum compression:
# Write-Host "Zeroing free space (this may take a while)..."
# sdelete.exe -z C: -accepteula

Write-Host "Pre-sysprep cleanup completed successfully."
Write-Host "Starting Sysprep generalization..."

# Run sysprep with proper error handling
try {
    & "$($ENV:SystemRoot)\System32\Sysprep\sysprep.exe" /oobe /generalize /mode:vm /shutdown
    Write-Host "Sysprep initiated successfully. VM will shutdown automatically."
} catch {
    Write-Error "Sysprep failed: $($_.Exception.Message)"
    exit 1
}
