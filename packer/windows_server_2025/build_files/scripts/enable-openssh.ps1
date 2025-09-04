#ps1_sysnative

<#
.SYNOPSIS
    Enable and configure OpenSSH Server for Windows Server 2025

.DESCRIPTION
    This script is designed to run during cloudbase-init to enable and configure
    the OpenSSH Server service. It includes comprehensive validation, error handling,
    and logging to ensure reliable deployment.

.NOTES
    File Name      : enable-openssh.ps1
    Author         : Home Infrastructure Team
    Prerequisite   : Windows Server 2025 with OpenSSH feature available
    Version        : 2.0
    Exit Codes     : 0 = Success (don't run again - cloudbase-init)
                    1 = Error (retry on next boot)
                    2 = Fatal error (don't retry)
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Initialize logging
$LogFile = "C:\Windows\Temp\enable-openssh.log"
$ScriptName = "Enable-OpenSSH"
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

# Function to validate OpenSSH installation
function Test-OpenSSHInstallation {
  Write-Log "Validating OpenSSH Server installation..." -Level "INFO"

  # Check if OpenSSH Server feature is available
  $OpenSSHFeature = Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH.Server*"
  if (-not $OpenSSHFeature) {
    Write-Log "OpenSSH Server feature not found on this system" -Level "ERROR"
    return $false
  }

  Write-Log "OpenSSH Server feature found: $($OpenSSHFeature.Name) - State: $($OpenSSHFeature.State)" -Level "INFO"

  # Install OpenSSH Server if not already installed
  if ($OpenSSHFeature.State -ne "Installed") {
    Write-Log "Installing OpenSSH Server feature..." -Level "INFO"
    try {
      Add-WindowsCapability -Online -Name $OpenSSHFeature.Name | Out-Null
      Write-Log "OpenSSH Server feature installed successfully" -Level "SUCCESS"
    }
    catch {
      Write-Log "Failed to install OpenSSH Server feature: $_" -Level "ERROR"
      return $false
    }
  }

  # Verify service exists
  $SSHDService = Get-Service -Name "sshd" -ErrorAction SilentlyContinue
  if (-not $SSHDService) {
    Write-Log "SSHD service not found after installation" -Level "ERROR"
    return $false
  }

  Write-Log "OpenSSH Server validation completed successfully" -Level "SUCCESS"
  return $true
}

# Function to configure and start OpenSSH service
function Start-OpenSSHService {
  Write-Log "Configuring and starting OpenSSH service..." -Level "INFO"

  try {
    # Get the service
    $SSHDService = Get-Service -Name "sshd"
    Write-Log "Current SSHD service status: $($SSHDService.Status)" -Level "INFO"

    # Set startup type to Automatic
    Write-Log "Setting SSHD service startup type to Automatic..." -Level "INFO"
    Set-Service -Name "sshd" -StartupType "Automatic"

    # Verify startup type was set
    $SSHDService = Get-Service -Name "sshd"
    Write-Log "SSHD service startup type set to: $($SSHDService.StartType)" -Level "INFO"

    # Start the service if not running
    if ($SSHDService.Status -ne "Running") {
      Write-Log "Starting SSHD service..." -Level "INFO"
      Start-Service -Name "sshd"

      # Wait for service to start and verify
      $Timeout = 30
      $Timer = 0
      do {
        Start-Sleep -Seconds 1
        $Timer++
        $SSHDService = Get-Service -Name "sshd"
      } while ($SSHDService.Status -ne "Running" -and $Timer -lt $Timeout)

      if ($SSHDService.Status -eq "Running") {
        Write-Log "SSHD service started successfully" -Level "SUCCESS"
      }
      else {
        Write-Log "SSHD service failed to start within $Timeout seconds. Status: $($SSHDService.Status)" -Level "ERROR"
        return $false
      }
    }
    else {
      Write-Log "SSHD service is already running" -Level "INFO"
    }

    # Also configure and start ssh-agent
    Write-Log "Configuring SSH Agent service..." -Level "INFO"
    $SSHAgentService = Get-Service -Name "ssh-agent" -ErrorAction SilentlyContinue
    if ($SSHAgentService) {
      Set-Service -Name "ssh-agent" -StartupType "Automatic"
      if ($SSHAgentService.Status -ne "Running") {
        Start-Service -Name "ssh-agent"
        Write-Log "SSH Agent service started" -Level "SUCCESS"
      }
    }

    return $true
  }
  catch {
    Write-Log "Failed to configure OpenSSH service: $_" -Level "ERROR"
    return $false
  }
}

# Function to configure firewall rules
function Set-OpenSSHFirewallRules {
  Write-Log "Configuring Windows Firewall rules for OpenSSH..." -Level "INFO"

  try {
    # Define expected firewall rule properties
    $ExpectedProperties = @{
      Enabled   = $true
      Direction = "Inbound"
      Action    = "Allow"
      Protocol  = "TCP"
      LocalPort = "22"
      Profile   = "Any"
    }

    # Check if default OpenSSH rule exists
    $ExistingRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue

    if ($ExistingRule) {
      Write-Log "Existing firewall rule found: $($ExistingRule.DisplayName) - Enabled: $($ExistingRule.Enabled)" -Level "INFO"

      # Get detailed rule properties for validation
      $RulePort = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $ExistingRule

      $RuleValid = $true
      $ValidationMessages = @()

      # Check each property
      if ($ExistingRule.Enabled -ne $ExpectedProperties.Enabled) {
        $RuleValid = $false
        $ValidationMessages += "Rule not enabled (Expected: $($ExpectedProperties.Enabled), Found: $($ExistingRule.Enabled))"
      }

      if ($ExistingRule.Direction -ne $ExpectedProperties.Direction) {
        $RuleValid = $false
        $ValidationMessages += "Wrong direction (Expected: $($ExpectedProperties.Direction), Found: $($ExistingRule.Direction))"
      }

      if ($ExistingRule.Action -ne $ExpectedProperties.Action) {
        $RuleValid = $false
        $ValidationMessages += "Wrong action (Expected: $($ExpectedProperties.Action), Found: $($ExistingRule.Action))"
      }

      if ($RulePort.Protocol -ne $ExpectedProperties.Protocol) {
        $RuleValid = $false
        $ValidationMessages += "Wrong protocol (Expected: $($ExpectedProperties.Protocol), Found: $($RulePort.Protocol))"
      }

      if ($RulePort.LocalPort -ne $ExpectedProperties.LocalPort) {
        $RuleValid = $false
        $ValidationMessages += "Wrong port (Expected: $($ExpectedProperties.LocalPort), Found: $($RulePort.LocalPort))"
      }

      if ($ExistingRule.Profile -ne $ExpectedProperties.Profile) {
        $RuleValid = $false
        $ValidationMessages += "Wrong profile (Expected: $($ExpectedProperties.Profile), Found: $($ExistingRule.Profile))"
      }

      if (-not $RuleValid) {
        Write-Log "Existing firewall rule does not meet requirements:" -Level "WARN"
        foreach ($Message in $ValidationMessages) {
          Write-Log "  - $Message" -Level "WARN"
        }
        Write-Log "Updating existing rule to meet requirements..." -Level "INFO"

        # Fix each property individually
        if ($ExistingRule.Enabled -ne $ExpectedProperties.Enabled) {
          Write-Log "Updating rule enabled state to: $($ExpectedProperties.Enabled)" -Level "INFO"
          if ($ExpectedProperties.Enabled -eq $true) {
            Enable-NetFirewallRule -Name "OpenSSH-Server-In-TCP"
          }
          else {
            Disable-NetFirewallRule -Name "OpenSSH-Server-In-TCP"
          }
        }

        if ($ExistingRule.Direction -ne $ExpectedProperties.Direction) {
          Write-Log "Updating rule direction to: $($ExpectedProperties.Direction)" -Level "INFO"
          Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Direction $ExpectedProperties.Direction
        }

        if ($ExistingRule.Action -ne $ExpectedProperties.Action) {
          Write-Log "Updating rule action to: $($ExpectedProperties.Action)" -Level "INFO"
          Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Action $ExpectedProperties.Action
        }

        if ($RulePort.Protocol -ne $ExpectedProperties.Protocol -or $RulePort.LocalPort -ne $ExpectedProperties.LocalPort) {
          Write-Log "Updating rule protocol to: $($ExpectedProperties.Protocol) and port to: $($ExpectedProperties.LocalPort)" -Level "INFO"
          Set-NetFirewallPortFilter -AssociatedNetFirewallRule $ExistingRule -Protocol $ExpectedProperties.Protocol -LocalPort $ExpectedProperties.LocalPort
        }

        if ($ExistingRule.Profile -ne $ExpectedProperties.Profile) {
          Write-Log "Updating rule profile to: $($ExpectedProperties.Profile)" -Level "INFO"
          Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Profile $ExpectedProperties.Profile
        }

        Write-Log "OpenSSH firewall rule updated successfully" -Level "SUCCESS"
      }
      else {
        Write-Log "Existing firewall rule configuration is correct" -Level "SUCCESS"
        # Ensure it's enabled if it wasn't
        if ($ExistingRule.Enabled -eq $false) {
          Write-Log "Enabling existing OpenSSH firewall rule..." -Level "INFO"
          Enable-NetFirewallRule -Name "OpenSSH-Server-In-TCP"
          Write-Log "OpenSSH firewall rule enabled" -Level "SUCCESS"
        }
      }
    }
    else {
      Write-Log "Creating new OpenSSH firewall rule..." -Level "INFO"
      New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
        -DisplayName "OpenSSH Server (sshd)" `
        -Description "Allow inbound SSH connections on port 22" `
        -Enabled $ExpectedProperties.Enabled `
        -Direction $ExpectedProperties.Direction `
        -Protocol $ExpectedProperties.Protocol `
        -Action $ExpectedProperties.Action `
        -LocalPort $ExpectedProperties.LocalPort `
        -Profile $ExpectedProperties.Profile | Out-Null
      Write-Log "OpenSSH firewall rule created successfully" -Level "SUCCESS"
    }

    # Verify the rule is properly configured
    $FinalRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP"
    $RulePort = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $FinalRule

    Write-Log "Firewall rule validation - Name: $($FinalRule.DisplayName), Enabled: $($FinalRule.Enabled), Port: $($RulePort.LocalPort)" -Level "INFO"

    if ($FinalRule.Enabled -eq $true -and $RulePort.LocalPort -eq "22") {
      Write-Log "Firewall configuration completed successfully" -Level "SUCCESS"
      return $true
    }
    else {
      Write-Log "Firewall rule validation failed" -Level "ERROR"
      return $false
    }
  }
  catch {
    Write-Log "Failed to configure firewall rules: $_" -Level "ERROR"
    return $false
  }
}

# Function to test SSH connectivity
function Test-SSHConnectivity {
  Write-Log "Testing SSH connectivity..." -Level "INFO"

  try {
    # Test if SSH port is listening
    $SSHPort = Get-NetTCPConnection -LocalPort 22 -State Listen -ErrorAction SilentlyContinue
    if ($SSHPort) {
      Write-Log "SSH service is listening on port 22" -Level "SUCCESS"
      Write-Log "SSH server process ID: $($SSHPort.OwningProcess)" -Level "INFO"
      return $true
    }
    else {
      Write-Log "SSH service is not listening on port 22" -Level "ERROR"
      return $false
    }
  }
  catch {
    Write-Log "Failed to test SSH connectivity: $_" -Level "ERROR"
    return $false
  }
}

# Function to configure SSH server settings
function Set-SSHConfiguration {
  Write-Log "Configuring SSH server settings..." -Level "INFO"

  try {
    $SSHDConfigPath = "$env:ProgramData\ssh\sshd_config"

    if (Test-Path $SSHDConfigPath) {
      Write-Log "SSH configuration file found at: $SSHDConfigPath" -Level "INFO"

      # Read current configuration
      $ConfigContent = Get-Content $SSHDConfigPath

      # Ensure key settings are configured for security
      # Empty for now, but can be extended as needed
      $RequiredSettings = @{}

      $Modified = $false
      foreach ($Setting in $RequiredSettings.GetEnumerator()) {
        $SettingLine = $ConfigContent | Where-Object { $_ -match "^\s*$($Setting.Key)" }
        $CommentedLine = $ConfigContent | Where-Object { $_ -match "^\s*#\s*$($Setting.Key)" }

        if (-not $SettingLine -and -not $CommentedLine) {
          # Setting doesn't exist at all, add it
          Write-Log "Adding SSH configuration: $($Setting.Key) $($Setting.Value)" -Level "INFO"
          $ConfigContent += "$($Setting.Key) $($Setting.Value)"
          $Modified = $true
        }
        elseif ($CommentedLine -and -not $SettingLine) {
          # Setting exists but is commented out, uncomment and set value
          Write-Log "Enabling SSH configuration: $($Setting.Key) $($Setting.Value)" -Level "INFO"
          $ConfigContent += "$($Setting.Key) $($Setting.Value)"
          $Modified = $true
        }
        elseif ($SettingLine -and $SettingLine -notmatch "\s+$($Setting.Value)(\s|$)") {
          # Setting exists but has wrong value, update it
          Write-Log "Updating SSH configuration: $($Setting.Key) from current value to $($Setting.Value)" -Level "INFO"
          $ConfigContent = $ConfigContent | ForEach-Object {
            if ($_ -match "^\s*$($Setting.Key)") {
              "$($Setting.Key) $($Setting.Value)"
            }
            else {
              $_
            }
          }
          $Modified = $true
        }
      }

      if ($Modified) {
        Set-Content -Path $SSHDConfigPath -Value $ConfigContent
        Write-Log "SSH configuration updated" -Level "SUCCESS"

        # Restart service to apply changes
        Write-Log "Restarting SSHD service to apply configuration changes..." -Level "INFO"
        Restart-Service -Name "sshd"
        Start-Sleep -Seconds 3
      }
    }
    else {
      Write-Log "SSH configuration file not found, using defaults" -Level "WARN"
    }

    return $true
  }
  catch {
    Write-Log "Failed to configure SSH settings: $_" -Level "ERROR"
    return $false
  }
}

# Function to set default shell for OpenSSH (idempotent, prefers pwsh if present)
function Set-DefaultShell {
  Write-Log "Configuring default shell for OpenSSH..." -Level "INFO"

  try {
    $RegPath = 'HKLM:\SOFTWARE\OpenSSH'

    # Prefer PowerShell Core (pwsh) if available, otherwise use Windows PowerShell
    $pwshCmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($pwshCmd) {
      $PreferredShell = $pwshCmd.Source
      Write-Log "Detected pwsh at: $PreferredShell" -Level "DEBUG"
    }
    else {
      $PreferredShell = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
      Write-Log "Falling back to Windows PowerShell: $PreferredShell" -Level "DEBUG"
    }

    # Ensure the OpenSSH registry key exists
    if (-not (Test-Path $RegPath)) {
      Write-Log "Registry path $RegPath not found, creating..." -Level "INFO"
      New-Item -Path 'HKLM:\SOFTWARE' -Name 'OpenSSH' -Force | Out-Null
    }

    # Check current DefaultShell value (safely handle non-existent property)
    $CurrentProperty = Get-ItemProperty -Path $RegPath -Name 'DefaultShell' -ErrorAction SilentlyContinue
    $Current = if ($CurrentProperty) { $CurrentProperty.DefaultShell } else { $null }

    if ($Current) {
      Write-Log "Current DefaultShell setting: $Current" -Level "DEBUG"
      if ($Current -ieq $PreferredShell) {
        Write-Log "DefaultShell already set to preferred shell: $Current" -Level "INFO"
        return $true
      }
      else {
        Write-Log "DefaultShell needs to be updated from '$Current' to '$PreferredShell'" -Level "INFO"
      }
    }
    else {
      Write-Log "No existing DefaultShell setting found, will create new one" -Level "DEBUG"
    }

    Write-Log "Setting DefaultShell to: $PreferredShell" -Level "INFO"
    New-ItemProperty -Path $RegPath -Name 'DefaultShell' -Value $PreferredShell -PropertyType 'String' -Force | Out-Null

    # Verify the setting was applied correctly
    $VerifyProperty = Get-ItemProperty -Path $RegPath -Name 'DefaultShell' -ErrorAction SilentlyContinue
    if ($VerifyProperty -and $VerifyProperty.DefaultShell -eq $PreferredShell) {
      Write-Log "DefaultShell registry value verified: $($VerifyProperty.DefaultShell)" -Level "SUCCESS"
    }
    else {
      Write-Log "Failed to verify DefaultShell registry setting" -Level "WARN"
    }

    # Restart sshd so new shell is picked up for new sessions
    try {
      Write-Log "Restarting sshd service to apply DefaultShell change..." -Level "INFO"
      Restart-Service -Name 'sshd' -Force -ErrorAction Stop
      Start-Sleep -Seconds 2
      Write-Log "sshd restarted" -Level "SUCCESS"
    }
    catch {
      Write-Log "Failed to restart sshd: $_" -Level "WARN"
      # not fatal; the change will apply on next sshd restart
    }

    return $true
  }
  catch {
    Write-Log "Failed to set DefaultShell: $_" -Level "ERROR"
    return $false
  }
}

# Function to perform comprehensive validation
function Test-OpenSSHDeployment {
  Write-Log "Performing comprehensive OpenSSH deployment validation..." -Level "INFO"

  $ValidationResults = @()

  # Test 1: Service status
  $SSHDService = Get-Service -Name "sshd" -ErrorAction SilentlyContinue
  if ($SSHDService -and $SSHDService.Status -eq "Running" -and $SSHDService.StartType -eq "Automatic") {
    $ValidationResults += "+ SSHD service is running and set to automatic startup"
    Write-Log "+ Service validation passed" -Level "SUCCESS"
  }
  else {
    $ValidationResults += "X SSHD service validation failed"
    Write-Log "X Service validation failed" -Level "ERROR"
  }

  # Test 2: Firewall rule
  $FirewallRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
  if ($FirewallRule -and $FirewallRule.Enabled -eq $true) {
    $ValidationResults += "+ Firewall rule is configured and enabled"
    Write-Log "+ Firewall validation passed" -Level "SUCCESS"
  }
  else {
    $ValidationResults += "X Firewall rule validation failed"
    Write-Log "X Firewall validation failed" -Level "ERROR"
  }

  # Test 3: Port listening
  $PortTest = Get-NetTCPConnection -LocalPort 22 -State Listen -ErrorAction SilentlyContinue
  if ($PortTest) {
    $ValidationResults += "+ SSH service is listening on port 22"
    Write-Log "+ Port listening validation passed" -Level "SUCCESS"
  }
  else {
    $ValidationResults += "X SSH service is not listening on port 22"
    Write-Log "X Port listening validation failed" -Level "ERROR"
  }

  # Test 4: SSH Agent (optional but recommended)
  $SSHAgentService = Get-Service -Name "ssh-agent" -ErrorAction SilentlyContinue
  if ($SSHAgentService -and $SSHAgentService.Status -eq "Running") {
    $ValidationResults += "+ SSH Agent service is running"
    Write-Log "+ SSH Agent validation passed" -Level "SUCCESS"
  }
  else {
    $ValidationResults += "! SSH Agent service is not running (optional)"
    Write-Log "! SSH Agent validation warning" -Level "WARN"
  }

  # Display validation summary
  Write-Log "=== OpenSSH Deployment Validation Summary ===" -Level "INFO"
  foreach ($Result in $ValidationResults) {
    Write-Log $Result -Level "INFO"
  }

  # Count failures - ensure we always have an array to count
  $Failures = @($ValidationResults | Where-Object { $_ -match "X" })
  return $Failures.Count -eq 0
}

# Main execution block
try {
  Write-Log "=== Starting OpenSSH Server Configuration ===" -Level "INFO"
  Write-Log "Script started at: $StartTime" -Level "INFO"
  Write-Log "Running on: $env:COMPUTERNAME" -Level "INFO"
  Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" -Level "INFO"

  # Check if running as administrator
  if (-not (Test-Administrator)) {
    Write-Log "Script must be run as Administrator" -Level "ERROR"
    exit 2
  }
  Write-Log "+ Running with administrator privileges" -Level "SUCCESS"

  # Step 1: Validate OpenSSH installation
  if (-not (Test-OpenSSHInstallation)) {
    Write-Log "OpenSSH installation validation failed" -Level "ERROR"
    exit 1
  }

  # Step 2: Configure SSH server settings
  if (-not (Set-SSHConfiguration)) {
    Write-Log "SSH configuration failed" -Level "ERROR"
    exit 1
  }

  # Step 3: Start and configure OpenSSH service
  if (-not (Start-OpenSSHService)) {
    Write-Log "OpenSSH service configuration failed" -Level "ERROR"
    exit 1
  }

  # Step 4: Configure firewall rules
  if (-not (Set-OpenSSHFirewallRules)) {
    Write-Log "Firewall configuration failed" -Level "ERROR"
    exit 1
  }

  # Step 4a: Configure default shell for SSH sessions
  if (-not (Set-DefaultShell)) {
    Write-Log "Setting DefaultShell for OpenSSH failed" -Level "WARN"
    # not fatal; continue to allow validation to report issues
  }

  # Step 5: Test SSH connectivity
  if (-not (Test-SSHConnectivity)) {
    Write-Log "SSH connectivity test failed" -Level "ERROR"
    exit 1
  }

  # Step 6: Comprehensive validation
  if (-not (Test-OpenSSHDeployment)) {
    Write-Log "OpenSSH deployment validation failed" -Level "ERROR"
    exit 1
  }

  # Success!
  $EndTime = Get-Date
  $Duration = $EndTime - $StartTime
  Write-Log "=== OpenSSH Server Configuration Completed Successfully ===" -Level "SUCCESS"
  Write-Log "Total execution time: $($Duration.TotalSeconds) seconds" -Level "INFO"
  Write-Log "SSH Server is now ready for connections" -Level "SUCCESS"
  Write-Log "Exiting with code 0 (success, don't reboot, don't run again)" -Level "INFO"

  exit 0  # Success - tell cloudbase-init not to run this script again
}
catch {
  Write-Log "Critical error during OpenSSH configuration: $_" -Level "ERROR"
  Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR"
  exit 1  # Error - allow cloudbase-init to retry on next boot
}
