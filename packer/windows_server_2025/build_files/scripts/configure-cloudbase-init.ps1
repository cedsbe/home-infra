# Configure Cloudbase-Init Script for Windows Server 2025
# This script searches for Cloudbase-Init configuration files and replaces the default ones

$ErrorActionPreference = "Stop"

Write-Host "=== Cloudbase-Init Configuration Script ===" -ForegroundColor Green
Write-Host "Starting at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

# Configuration paths
$cloudbaseConfigPath = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf"
$configFiles = @(
    "cloudbase-init.conf",
    "cloudbase-init-unattend.conf"
)

try {
    # Verify Cloudbase-Init is installed
    Write-Host "Verifying Cloudbase-Init installation..." -ForegroundColor Yellow
    if (-not (Test-Path $cloudbaseConfigPath)) {
        Write-Error "Cloudbase-Init configuration directory not found at: $cloudbaseConfigPath"
        Write-Host "Please ensure Cloudbase-Init is installed before running this script." -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Cloudbase-Init installation verified" -ForegroundColor Green
    Write-Host "Configuration directory: $cloudbaseConfigPath" -ForegroundColor Cyan

    # Create backup directory
    $backupDir = Join-Path -Path $cloudbaseConfigPath -ChildPath "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Host "Creating backup directory..." -ForegroundColor Yellow
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    Write-Host "Backup directory created: $backupDir" -ForegroundColor Cyan

    # Process each configuration file
    foreach ($configFile in $configFiles) {
        Write-Host "Processing configuration file: $configFile" -ForegroundColor Yellow
        
        # Search for source configuration file
        Write-Host "Searching for $configFile at the root of all drives..." -ForegroundColor Cyan
        
        $sourceConfigPath = $null
        $usedDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }

        foreach ($drive in $usedDrives) {
            $testPath = Join-Path -Path "$($drive.Name):\" -ChildPath $configFile
            Write-Host "  Checking: $testPath" -ForegroundColor Gray
            
            if (Test-Path -Path $testPath) {
                $sourceConfigPath = $testPath
                Write-Host "  ✅ Found $configFile at: $sourceConfigPath" -ForegroundColor Green
                break
            }
        }

        if (-not $sourceConfigPath) {
            Write-Host "  $configFile not found at the root of any fixed drive. Checking CD/DVD drives..." -ForegroundColor Yellow
            
            # Also check removable drives and CD/DVD drives
            $allDrives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -in @(2, 5) } # 2=Removable, 5=CD-ROM
            
            foreach ($drive in $allDrives) {
                $testPath = Join-Path -Path "$($drive.DeviceID)\" -ChildPath $configFile
                Write-Host "  Checking removable/CD drive: $testPath" -ForegroundColor Gray
                
                if (Test-Path -Path $testPath) {
                    $sourceConfigPath = $testPath
                    Write-Host "  ✅ Found $configFile at: $sourceConfigPath" -ForegroundColor Green
                    break
                }
            }
        }

        # Process the configuration file if found
        if ($sourceConfigPath -and (Test-Path -Path $sourceConfigPath)) {
            $targetConfigPath = Join-Path -Path $cloudbaseConfigPath -ChildPath $configFile
            
            # Backup existing configuration file if it exists
            if (Test-Path -Path $targetConfigPath) {
                $backupPath = Join-Path -Path $backupDir -ChildPath $configFile
                Write-Host "  Backing up existing $configFile..." -ForegroundColor Yellow
                Copy-Item -Path $targetConfigPath -Destination $backupPath -Force
                Write-Host "  ✅ Backup created: $backupPath" -ForegroundColor Green
                
                # Show file comparison info
                $originalSize = (Get-Item $targetConfigPath).Length
                $newSize = (Get-Item $sourceConfigPath).Length
                Write-Host "  File size comparison:" -ForegroundColor Cyan
                Write-Host "    Original: $originalSize bytes" -ForegroundColor Gray
                Write-Host "    New:      $newSize bytes" -ForegroundColor Gray
            }
            else {
                Write-Host "  No existing $configFile found to backup" -ForegroundColor Yellow
            }
            
            # Copy new configuration file
            Write-Host "  Copying new $configFile..." -ForegroundColor Yellow
            Copy-Item -Path $sourceConfigPath -Destination $targetConfigPath -Force
            Write-Host "  ✅ Configuration file copied successfully" -ForegroundColor Green
            Write-Host "    From: $sourceConfigPath" -ForegroundColor Cyan
            Write-Host "    To:   $targetConfigPath" -ForegroundColor Cyan
            
            # Verify the copy
            if (Test-Path -Path $targetConfigPath) {
                $copiedFileInfo = Get-Item $targetConfigPath
                Write-Host "  ✅ Copy verification successful" -ForegroundColor Green
                Write-Host "    Size: $($copiedFileInfo.Length) bytes" -ForegroundColor Gray
                Write-Host "    Modified: $($copiedFileInfo.LastWriteTime)" -ForegroundColor Gray
            }
            else {
                Write-Error "Copy verification failed - file not found at target location"
            }
        }
        else {
            Write-Host "  ⚠️ Source $configFile not found at the root of any drive. Skipping..." -ForegroundColor Yellow
        }
        
        Write-Host "" # Empty line for readability
    }

    # Summary of configuration changes
    Write-Host "=== Configuration Summary ===" -ForegroundColor Green
    Write-Host "Cloudbase-Init configuration directory: $cloudbaseConfigPath" -ForegroundColor Cyan
    Write-Host "Backup directory: $backupDir" -ForegroundColor Cyan
    
    Write-Host "Current configuration files:" -ForegroundColor Yellow
    Get-ChildItem -Path $cloudbaseConfigPath -Filter "*.conf" | ForEach-Object {
        Write-Host "  $($_.Name) - $($_.Length) bytes - Modified: $($_.LastWriteTime)" -ForegroundColor Gray
    }
    
    # Check if any configuration files were updated
    $updatedFiles = @()
    foreach ($configFile in $configFiles) {
        $targetPath = Join-Path -Path $cloudbaseConfigPath -ChildPath $configFile
        if (Test-Path -Path $targetPath) {
            $updatedFiles += $configFile
        }
    }
    
    if ($updatedFiles.Count -gt 0) {
        Write-Host "✅ Successfully configured $($updatedFiles.Count) Cloudbase-Init configuration file(s):" -ForegroundColor Green
        $updatedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
        
        Write-Host "Note: Cloudbase-Init service may need to be restarted to apply new configuration." -ForegroundColor Yellow
        
        # Optional: Restart Cloudbase-Init service if it's running
        $cloudbaseService = Get-Service -Name "cloudbase-init" -ErrorAction SilentlyContinue
        if ($cloudbaseService -and $cloudbaseService.Status -eq "Running") {
            Write-Host "Cloudbase-Init service is currently running. Consider restarting it to apply new configuration." -ForegroundColor Yellow
            Write-Host "Command to restart: Restart-Service -Name 'cloudbase-init'" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "⚠️ No configuration files were updated" -ForegroundColor Yellow
    }

}
catch {
    Write-Host "Error occurred during Cloudbase-Init configuration!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    # Attempt to restore from backup if error occurred
    if ((Test-Path $backupDir) -and (Get-ChildItem $backupDir -ErrorAction SilentlyContinue)) {
        Write-Host "Attempting to restore from backup..." -ForegroundColor Yellow
        try {
            Get-ChildItem -Path $backupDir -Filter "*.conf" | ForEach-Object {
                $restorePath = Join-Path -Path $cloudbaseConfigPath -ChildPath $_.Name
                Copy-Item -Path $_.FullName -Destination $restorePath -Force
                Write-Host "Restored: $($_.Name)" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Failed to restore from backup: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    throw
}
finally {
    Write-Host "=== Cloudbase-Init Configuration Script Completed ===" -ForegroundColor Green
    Write-Host "Finished at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Green
}
