#ps1_sysnative

<#
.SYNOPSIS
    Set network connection profile to Private for Windows Server 2025

.DESCRIPTION
    This script is designed to run during Packer build to set the active network
    connection profile to Private. It includes comprehensive validation, error handling,
    and logging to ensure reliable deployment. The script identifies active network
    adapters and sets their connection profile to Private, which is required for
    certain firewall rules and network configurations.

.NOTES
    File Name      : set-network-private.ps1
    Author         : Home Infrastructure Team
    Prerequisite   : Windows Server 2025 with active network connection
    Version        : 1.0
    Exit Codes     : 0 = Success (don't run again - cloudbase-init)
                    1 = Error (retry on next boot)
                    2 = Fatal error (don't retry)
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Initialize logging
$LogFile = "C:\Windows\Temp\set-network-private.log"
$ScriptName = "Set-Network-Private"
$StartTime = Get-Date

# Logging function
function Write-Log {
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Message,
    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
    [string]$Level = "INFO"
  )

  $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $LogEntry = "[$Timestamp] [$Level] [$ScriptName] $Message"

  # Write to console
  switch ($Level) {
    "ERROR" { Write-Host $LogEntry -ForegroundColor Red }
    "WARN" { Write-Host $LogEntry -ForegroundColor Yellow }
    "SUCCESS" { Write-Host $LogEntry -ForegroundColor Green }
    "DEBUG" { Write-Host $LogEntry -ForegroundColor Cyan }
    default { Write-Host $LogEntry -ForegroundColor White }
  }

  # Write to log file
  try {
    Add-Content -Path $LogFile -Value $LogEntry -ErrorAction SilentlyContinue
  }
  catch {
    Write-Warning "Failed to write to log file: $_"
  }
}

# Function to test if running as administrator
function Test-Administrator {
  $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
  $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)
  return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to get network connection profiles
function Get-NetworkConnectionProfiles {
  Write-Log "Retrieving network connection profiles..." -Level "INFO"

  try {
    $NetworkProfiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue

    if (-not $NetworkProfiles) {
      Write-Log "No network connection profiles found" -Level "WARN"
      return @()
    }

    Write-Log "Found $(@($NetworkProfiles).Count) network connection profile(s)" -Level "INFO"

    foreach ($NetProfile in $NetworkProfiles) {
      Write-Log "Profile: $($NetProfile.Name) - Interface: $($NetProfile.InterfaceAlias) - Category: $($NetProfile.NetworkCategory)" -Level "INFO"
    }

    return @($NetworkProfiles)
  }
  catch {
    Write-Log "Failed to retrieve network connection profiles: $_" -Level "ERROR"
    return @()
  }
}

# Function to get active network adapters
function Get-ActiveNetworkAdapters {
  Write-Log "Retrieving active network adapters..." -Level "INFO"

  try {
    # Get adapters that are connected and operational
    $ActiveAdapters = Get-NetAdapter | Where-Object {
      $_.Status -eq "Up" -and
      $_.MediaConnectState -eq $true -and
      $_.Virtual -eq $false
    }

    if (-not $ActiveAdapters) {
      Write-Log "No active network adapters found" -Level "WARN"
      return @()
    }

    Write-Log "Found $(@($ActiveAdapters).Count) active network adapter(s)" -Level "INFO"

    foreach ($Adapter in $ActiveAdapters) {
      Write-Log "Adapter: $($Adapter.Name) - Interface: $($Adapter.InterfaceDescription) - Status: $($Adapter.Status)" -Level "INFO"
    }

    return @($ActiveAdapters)
  }
  catch {
    Write-Log "Failed to retrieve active network adapters: $_" -Level "ERROR"
    return @()
  }
}

# Function to set network profile to private
function Set-NetworkProfilePrivate {
  param(
    [Parameter(Mandatory = $true)]
    [object[]]$NetworkProfiles
  )

  Write-Log "Setting network connection profiles to Private..." -Level "INFO"

  $SuccessCount = 0
  $TotalCount = 0
  $ErrorsEncountered = @()

  foreach ($NetProfile in $NetworkProfiles) {
    $TotalCount++

    try {
      Write-Log "Processing profile: $($NetProfile.Name) (Interface: $($NetProfile.InterfaceAlias))" -Level "INFO"

      # Check current category
      if ($NetProfile.NetworkCategory -eq "Private") {
        Write-Log "Profile '$($NetProfile.Name)' is already set to Private" -Level "INFO"
        $SuccessCount++
        continue
      }

      Write-Log "Changing profile '$($NetProfile.Name)' from $($NetProfile.NetworkCategory) to Private" -Level "INFO"

      # Set the network category to Private
      Set-NetConnectionProfile -InterfaceAlias $NetProfile.InterfaceAlias -NetworkCategory Private -ErrorAction Stop
      Write-Log "Set-NetConnectionProfile command executed successfully" -Level "DEBUG"

      # Verify the change
      Start-Sleep -Seconds 2
      $UpdatedProfile = Get-NetConnectionProfile -InterfaceAlias $NetProfile.InterfaceAlias -ErrorAction Stop

      if ($UpdatedProfile.NetworkCategory -eq "Private") {
        Write-Log "Successfully set profile '$($NetProfile.Name)' to Private" -Level "SUCCESS"
        $SuccessCount++
      }
      else {
        $ErrorMsg = "Failed to verify profile change for '$($NetProfile.Name)' - Current: $($UpdatedProfile.NetworkCategory)"
        Write-Log $ErrorMsg -Level "ERROR"
        $ErrorsEncountered += $ErrorMsg
      }
    }
    catch {
      $ErrorMsg = "Failed to set profile '$($NetProfile.Name)' to Private: $_"
      Write-Log $ErrorMsg -Level "ERROR"
      $ErrorsEncountered += $ErrorMsg
    }
  }

  # Summary
  Write-Log "Network profile configuration summary: $SuccessCount/$TotalCount profiles successfully set to Private" -Level "INFO"

  if ($ErrorsEncountered.Count -gt 0) {
    Write-Log "Errors encountered during configuration:" -Level "WARN"
    foreach ($ErrorMsg in $ErrorsEncountered) {
      Write-Log "  - $ErrorMsg" -Level "WARN"
    }
  }

  return @{
    Success = $SuccessCount
    Total   = $TotalCount
    Errors  = $ErrorsEncountered
  }
}

# Function to validate network profile configuration
function Test-NetworkProfileConfiguration {
  Write-Log "Validating network profile configuration..." -Level "INFO"

  try {
    $NetworkProfiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue

    if (-not $NetworkProfiles) {
      Write-Log "No network profiles found during validation" -Level "WARN"
      return $false
    }

    $PrivateProfiles = $NetworkProfiles | Where-Object { $_.NetworkCategory -eq "Private" }
    $NonPrivateProfiles = $NetworkProfiles | Where-Object { $_.NetworkCategory -ne "Private" }

    Write-Log "Validation results:" -Level "INFO"
    Write-Log "  - Private profiles: $(@($PrivateProfiles).Count)" -Level "INFO"
    Write-Log "  - Non-private profiles: $(@($NonPrivateProfiles).Count)" -Level "INFO"

    if (@($NonPrivateProfiles).Count -gt 0) {
      Write-Log "Non-private profiles found:" -Level "WARN"
      foreach ($NetProfile in $NonPrivateProfiles) {
        Write-Log "  - $($NetProfile.Name) ($($NetProfile.InterfaceAlias)): $($NetProfile.NetworkCategory)" -Level "WARN"
      }
    }

    # Check if we have any active connections and they are all private
    $ActiveAdapters = Get-NetAdapter | Where-Object {
      $_.Status -eq "Up" -and
      $_.MediaConnectState -eq $true -and
      $_.Virtual -eq $false
    }

    # More robust matching - check Name, InterfaceDescription, and InterfaceAlias
    $ActiveAdapterNames = @($ActiveAdapters.Name) + @($ActiveAdapters.InterfaceDescription) + @($ActiveAdapters.InterfaceAlias)
    $ActivePrivateProfiles = $NetworkProfiles | Where-Object {
      $_.NetworkCategory -eq "Private" -and
      ($_.InterfaceAlias -in $ActiveAdapterNames -or $_.Name -in $ActiveAdapterNames)
    }

    # Also check if any network profile corresponds to an active adapter
    $ProfilesForActiveAdapters = @()
    foreach ($NetProfile in $NetworkProfiles) {
      foreach ($Adapter in $ActiveAdapters) {
        # Use precise matching only - avoid wildcard patterns that could cause false positives
        if ($NetProfile.InterfaceAlias -eq $Adapter.Name -or
          $NetProfile.InterfaceAlias -eq $Adapter.InterfaceDescription -or
          $NetProfile.InterfaceAlias -eq $Adapter.InterfaceAlias) {
          $ProfilesForActiveAdapters += $NetProfile
          Write-Log "Matched profile '$($NetProfile.Name)' to adapter '$($Adapter.Name)' via InterfaceAlias" -Level "DEBUG"
          break
        }
      }
    }

    $PrivateProfilesForActiveAdapters = $ProfilesForActiveAdapters | Where-Object { $_.NetworkCategory -eq "Private" }

    # Use the more comprehensive matching for validation
    $ValidProfileCount = [Math]::Max(@($ActivePrivateProfiles).Count, @($PrivateProfilesForActiveAdapters).Count)

    if (@($ActiveAdapters).Count -gt 0 -and $ValidProfileCount -ge @($ActiveAdapters).Count) {
      Write-Log "All active network connections are set to Private profile" -Level "SUCCESS"
      return $true
    }
    elseif (@($ActiveAdapters).Count -eq 0) {
      Write-Log "No active network adapters found during validation" -Level "WARN"
      return $false
    }
    else {
      Write-Log "Not all active network connections are set to Private profile (Found $ValidProfileCount private profiles for $(@($ActiveAdapters).Count) active adapters)" -Level "ERROR"
      return $false
    }
  }
  catch {
    Write-Log "Failed to validate network profile configuration: $_" -Level "ERROR"
    return $false
  }
}

# Function to perform comprehensive validation
function Test-NetworkDeployment {
  Write-Log "Performing comprehensive network profile validation..." -Level "INFO"

  $ValidationResults = @()

  # Test 1: Network adapters
  $ActiveAdapters = Get-ActiveNetworkAdapters
  if (@($ActiveAdapters).Count -gt 0) {
    $ValidationResults += "+ Found $(@($ActiveAdapters).Count) active network adapter(s)"
    Write-Log "+ Network adapter validation passed" -Level "SUCCESS"
  }
  else {
    $ValidationResults += "X No active network adapters found"
    Write-Log "X Network adapter validation failed" -Level "ERROR"
  }

  # Test 2: Network profiles
  $NetworkProfiles = Get-NetworkConnectionProfiles
  if (@($NetworkProfiles).Count -gt 0) {
    $ValidationResults += "+ Found $(@($NetworkProfiles).Count) network connection profile(s)"
    Write-Log "+ Network profile detection passed" -Level "SUCCESS"
  }
  else {
    $ValidationResults += "X No network connection profiles found"
    Write-Log "X Network profile detection failed" -Level "ERROR"
  }

  # Test 3: Private profile configuration
  if (Test-NetworkProfileConfiguration) {
    $ValidationResults += "+ All active connections are set to Private profile"
    Write-Log "+ Private profile validation passed" -Level "SUCCESS"
  }
  else {
    $ValidationResults += "X Private profile validation failed"
    Write-Log "X Private profile validation failed" -Level "ERROR"
  }

  # Display validation summary
  Write-Log "=== Network Profile Deployment Validation Summary ===" -Level "INFO"
  foreach ($Result in $ValidationResults) {
    Write-Log $Result -Level "INFO"
  }

  # Count failures
  $Failures = @($ValidationResults | Where-Object { $_ -match "X" })
  return $Failures.Count -eq 0
}

# Main execution block
try {
  Write-Log "=== Starting Network Profile Configuration ===" -Level "INFO"
  Write-Log "Script started at: $StartTime" -Level "INFO"
  Write-Log "Running on: $env:COMPUTERNAME" -Level "INFO"
  Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" -Level "INFO"

  # Check if running as administrator
  if (-not (Test-Administrator)) {
    Write-Log "Script must be run as Administrator" -Level "ERROR"
    exit 2
  }
  Write-Log "+ Running with administrator privileges" -Level "SUCCESS"

  # Step 1: Get active network adapters
  $ActiveAdapters = Get-ActiveNetworkAdapters
  if (@($ActiveAdapters).Count -eq 0) {
    Write-Log "No active network adapters found - this may be expected during early boot" -Level "WARN"
    Write-Log "Exiting with success code (no action needed)" -Level "INFO"
    exit 0
  }

  # Step 2: Get network connection profiles
  $NetworkProfiles = Get-NetworkConnectionProfiles
  if (@($NetworkProfiles).Count -eq 0) {
    Write-Log "No network connection profiles found" -Level "ERROR"
    exit 1
  }

  # Step 3: Set network profiles to private
  $Result = Set-NetworkProfilePrivate -NetworkProfiles $NetworkProfiles

  if ($Result.Errors.Count -gt 0 -and $Result.Success -eq 0) {
    Write-Log "Failed to set any network profiles to Private" -Level "ERROR"
    exit 1
  }
  elseif ($Result.Errors.Count -gt 0) {
    Write-Log "Partial success: $($Result.Success)/$($Result.Total) profiles set successfully" -Level "WARN"
  }

  # Step 4: Validate configuration
  if (-not (Test-NetworkDeployment)) {
    Write-Log "Network profile deployment validation failed" -Level "ERROR"
    exit 1
  }

  # Success!
  $EndTime = Get-Date
  $Duration = $EndTime - $StartTime
  Write-Log "=== Network Profile Configuration Completed Successfully ===" -Level "SUCCESS"
  Write-Log "Total execution time: $($Duration.TotalSeconds) seconds" -Level "INFO"
  Write-Log "All active network connections are now set to Private profile" -Level "SUCCESS"
  Write-Log "Exiting with code 0 (success, don't reboot, don't run again)" -Level "INFO"

  exit 0  # Success - tell cloudbase-init not to run this script again
}
catch {
  Write-Log "Critical error during network profile configuration: $_" -Level "ERROR"
  Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR"
  exit 1  # Error - allow cloudbase-init to retry on next boot
}
