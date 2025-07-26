# Remove Azure Arc and Azure-related components
# This script removes Azure Arc agents and related services that might appear in the system tray

$ErrorActionPreference = "Stop"

Write-Host "Removing Azure Arc and Azure-related components..."

# Function to safely stop and disable services
function Stop-DisableService {
    param (
        [string]$ServiceName
    )
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            Write-Host "Stopping and disabling service: $ServiceName"
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Host "Service $ServiceName not found or already disabled"
    }
}

# Function to remove scheduled tasks
function Remove-ScheduledTaskSafe {
    param (
        [string]$TaskName,
        [string]$TaskPath = "\"
    )
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
        if ($task) {
            Write-Host "Removing scheduled task: $TaskName"
            Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
        }
    }
    catch {
        Write-Host "Scheduled task $TaskName not found"
    }
}

# Stop and disable Azure Arc services
Write-Host "Disabling Azure Arc services..."
Stop-DisableService -ServiceName "himds"          # Azure Instance Metadata Service
Stop-DisableService -ServiceName "GCArcService"   # Guest Configuration Arc Service
Stop-DisableService -ServiceName "ExtensionService" # Extension Service
Stop-DisableService -ServiceName "AzureConnectedMachineAgent" # Connected Machine Agent

# Remove Azure Arc scheduled tasks
Write-Host "Removing Azure Arc scheduled tasks..."
Remove-ScheduledTaskSafe -TaskName "AzureConnectedMachineAgent" -TaskPath "\Microsoft\Azure\"
Remove-ScheduledTaskSafe -TaskName "GCWorker" -TaskPath "\Microsoft\Azure\"

# Remove Azure-related registry entries for system tray notifications
Write-Host "Removing Azure Arc system tray entries..."
try {
    $azureRegPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )
    
    foreach ($regPath in $azureRegPaths) {
        if (Test-Path $regPath) {
            $entries = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            if ($entries) {
                $entries.PSObject.Properties | Where-Object { 
                    $_.Name -like "*Azure*" -or $_.Name -like "*Arc*" -or $_.Value -like "*Azure*" 
                } | ForEach-Object {
                    Write-Host "Removing registry entry: $($_.Name)"
                    Remove-ItemProperty -Path $regPath -Name $_.Name -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
catch {
    Write-Host "Error removing registry entries: $($_.Exception.Message)"
}

# Uninstall Azure Arc agent if present
Write-Host "Checking for Azure Arc agent installation..."
try {
    $arcAgent = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Azure Connected Machine Agent*" }
    if ($arcAgent) {
        Write-Host "Uninstalling Azure Connected Machine Agent..."
        $arcAgent.Uninstall()
    }
    
    # Also check for other Azure-related software
    $azureSoftware = Get-WmiObject -Class Win32_Product | Where-Object { 
        $_.Name -like "*Azure*" -and $_.Name -notlike "*Visual Studio*" 
    }
    
    foreach ($software in $azureSoftware) {
        Write-Host "Found Azure software: $($software.Name)"
        # Uncomment the next line if you want to remove all Azure software
        # $software.Uninstall()
    }
}
catch {
    Write-Host "Error checking/removing Azure software: $($_.Exception.Message)"
}

# Remove Azure Arc directories if they exist
Write-Host "Removing Azure Arc directories..."
$azureDirectories = @(
    "$env:ProgramFiles\AzureConnectedMachineAgent",
    "$env:ProgramData\AzureConnectedMachineAgent",
    "$env:ProgramFiles(x86)\Microsoft\Azure",
    "$env:ProgramData\Microsoft\Azure"
)

foreach ($dir in $azureDirectories) {
    if (Test-Path $dir) {
        try {
            Write-Host "Removing directory: $dir"
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host "Could not remove directory: $dir"
        }
    }
}

# Disable Windows Update delivery optimization for Azure updates
Write-Host "Disabling Azure-related Windows Update settings..."
try {
    $updateRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (-not (Test-Path $updateRegPath)) {
        New-Item -Path $updateRegPath -Force | Out-Null
    }
    
    # Disable automatic Azure integration
    Set-ItemProperty -Path $updateRegPath -Name "DisableAzureADJoin" -Value 1 -Type DWord -ErrorAction SilentlyContinue
}
catch {
    Write-Host "Error setting Windows Update policies: $($_.Exception.Message)"
}

Write-Host "Azure Arc cleanup completed"
