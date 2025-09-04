<#
    install-powershell-core.ps1

    <#
    install-powershell-core.ps1

    Idempotent installer for PowerShell (pwsh) on Windows Server 2025.

    Strategy:
      1. If pwsh is already installed and satisfies requested version, do nothing.
      2. If winget is available, try to install via winget (non-interactive).
      3. Otherwise download the MSI from the official PowerShell GitHub releases and install silently.

    Usage examples:
      .\install-powershell-core.ps1
      .\install-powershell-core.ps1 -Version 7.4.6
      .\install-powershell-core.ps1 -UseWinget

    Notes:
      - This script runs under Windows PowerShell (built-in) to bootstrap pwsh.
      - It attempts to use TLS1.2 for web calls.
      - It does not hardcode credentials and is safe for public repositories.
    #>

param(
  [Parameter(Position = 0)]
  [ValidateNotNullOrEmpty()]
  [string]
  $Version = 'latest',

  [Parameter()]
  [switch]
  $UseWinget
)

# Logging initialization (match style used by enable-openssh.ps1)
$LogFile = "C:\Windows\Temp\install-powershell-core.log"
$ScriptName = "Install-PowerShell-Core"
$StartTime = Get-Date

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

  # Write to console with simple coloring
  switch ($Level) {
    "ERROR" { Write-Host $LogEntry -ForegroundColor Red }
    "WARN" { Write-Host $LogEntry -ForegroundColor Yellow }
    "SUCCESS" { Write-Host $LogEntry -ForegroundColor Green }
    "DEBUG" { Write-Host $LogEntry -ForegroundColor Cyan }
    default { Write-Host $LogEntry -ForegroundColor White }
  }

  # Append to log file if possible
  try {
    Add-Content -Path $LogFile -Value $LogEntry -ErrorAction SilentlyContinue
  }
  catch {
    Write-Warning "Failed to write to log file: $_"
  }
}

function Get-InstalledPwshVersion {
  # Refresh process PATH from Machine and User environment variables so newly-installed pwsh
  # (which updates system PATH) becomes visible to this script without restarting.
  try {
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if ($machinePath -and $userPath) { $env:Path = "$machinePath;$userPath" }
    elseif ($machinePath) { $env:Path = $machinePath }
    Write-Log "Refreshed PATH from registry. Machine length: $($machinePath.Length) User length: $($userPath.Length)" "DEBUG"
  }
  catch {
    Write-Log "Failed to refresh PATH from registry: $_" "DEBUG"
  }

  # Try to find pwsh on PATH first
  $cmd = Get-Command -Name pwsh -CommandType Application -ErrorAction SilentlyContinue
  if ($cmd) { Write-Log "Get-Command found pwsh at: $($cmd.Source)" "DEBUG" } else { Write-Log "Get-Command did not find pwsh on PATH" "DEBUG" }

  # If not found on PATH, probe common install locations under Program Files\PowerShell
  $pwshExePath = $null
  if (-not $cmd) {
    $pf = $env:ProgramFiles
    Write-Log "ProgramFiles path: $pf" "DEBUG"
    if ($pf) {
      $candidateRoot = Join-Path $pf 'PowerShell'
      Write-Log "Looking for candidates under: $candidateRoot" "DEBUG"
      if (Test-Path $candidateRoot) {
        $candidates = Get-ChildItem -Path $candidateRoot -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName 'pwsh.exe' } |
        Where-Object { Test-Path $_ } |
        Sort-Object -Descending
        if ($candidates -and $candidates.Count -gt 0) {
          Write-Log "Found pwsh candidates: $($candidates -join ', ')" "DEBUG"
          $pwshExePath = $candidates[0]
        }
      }
    }
  }
  else {
    $pwshExePath = $cmd.Source
  }
  if (-not $pwshExePath) {
    Write-Log "No pwsh executable path found after probing" "DEBUG"
    return $null
  }

  Write-Log "Querying pwsh executable at path: $pwshExePath" "DEBUG"
  try {
    # Capture stdout and stderr by redirecting to temporary files (Start-Process requires file paths)
    $outTemp = [IO.Path]::GetTempFileName() + '.out'
    $errTemp = [IO.Path]::GetTempFileName() + '.err'
    $startInfo = @{ FilePath = $pwshExePath; ArgumentList = @('-NoProfile', '-Command', '[PSCustomObject]@{Version = $PSVersionTable.PSVersion.ToString()} | ConvertTo-Json'); Wait = $true; RedirectStandardOutput = $outTemp; RedirectStandardError = $errTemp }
    Start-Process @startInfo | Out-Null

    # Read redirected output files (may be empty)
    $stdout = ''
    $stderr = ''
    try {
      if (Test-Path $outTemp) { $stdout = Get-Content -Path $outTemp -Raw -ErrorAction SilentlyContinue }
      if (Test-Path $errTemp) { $stderr = Get-Content -Path $errTemp -Raw -ErrorAction SilentlyContinue }
    }
    finally {
      Remove-Item -Path $outTemp, $errTemp -ErrorAction SilentlyContinue
    }
    if ($stdout) { Write-Log "pwsh stdout: $stdout" "DEBUG" }
    if ($stderr) { Write-Log "pwsh stderr: $stderr" "DEBUG" }

    if ($stdout) {
      $obj = $stdout | ConvertFrom-Json -ErrorAction Stop
      if ($obj -and $obj.Version) { return [version]$obj.Version }
      else { Write-Log "pwsh returned JSON but 'Version' property missing" "DEBUG" }
    }
    else {
      Write-Log "pwsh invocation returned no stdout" "DEBUG"
    }
  }
  catch {
    Write-Log "Failed to query pwsh version: $_" "DEBUG"
    return $null
  }
  return $null
}

function Compare-Versions {
  param([Version]$a, [Version]$b)
  if ($a -eq $b) { return 0 }
  if ($a -gt $b) { return 1 }
  return -1
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Log "Starting PowerShell Core installer (requested version: $Version)"

$installed = Get-InstalledPwshVersion
if ($installed) {
  Write-Log "Found installed pwsh version: $installed"
  if ($Version -ne 'latest') {
    try {
      $req = [version]$Version
      if (Compare-Versions -a $installed -b $req -eq 1 -or $installed -eq $req) {
        Write-Log "Installed version $installed satisfies requested version $Version. Nothing to do."
        exit 0
      }
    }
    catch { Write-Log "Requested version string could not be parsed as version. Will proceed with install." "WARN" }
  }
  else { Write-Log "Requested 'latest' and pwsh is present; will still attempt to ensure latest if installation path requires it." }
}

function Install-PwshWithWinget {
  if (-not (Get-Command -Name winget -ErrorAction SilentlyContinue)) {
    Write-Log "winget not found, skipping winget install" "DEBUG"
    return $false
  }

  Write-Log "Attempting install with winget"
  # Force the official "winget" source to avoid msstore source agreements prompting the user.
  $wingetArgs = @('install', '--id', 'Microsoft.PowerShell', '-e', '--source', 'winget')
  $wingetArgs += @('--accept-source-agreements', '--accept-package-agreements')
  if ($Version -ne 'latest') { $wingetArgs += @('--version', $Version) }

  $startInfo = @{ FilePath = 'winget'; ArgumentList = $wingetArgs; Wait = $true; PassThru = $true }
  $proc = Start-Process @startInfo
  if ($proc.ExitCode -eq 0) { Write-Log 'winget install succeeded'; return $true }
  Write-Log "winget install failed with exit code $($proc.ExitCode)" "WARN"
  return $false
}

function Install-PwshFromMsi {
  param([Parameter(Mandatory = $true)][string]$downloadUrl)

  Write-Log "Downloading MSI from $downloadUrl"
  $tmp = [IO.Path]::GetTempFileName()
  Remove-Item $tmp -Force
  $msiPath = "$tmp.msi"

  try { Invoke-WebRequest -Uri $downloadUrl -OutFile $msiPath -ErrorAction Stop }
  catch { Write-Log "Failed to download MSI: $_" "ERROR"; return $false }

  Write-Log "Running msiexec to install $msiPath"
  $msiArgs = "/i `"$msiPath`" /qn /norestart"
  $startInfo = @{ FilePath = 'msiexec.exe'; ArgumentList = $msiArgs; Wait = $true; PassThru = $true }
  $proc = Start-Process @startInfo
  if ($proc.ExitCode -ne 0) { Write-Log "msiexec failed with exit code $($proc.ExitCode)" "ERROR"; return $false }

  Write-Log "Installation finished; removing $msiPath"
  try { Remove-Item $msiPath -Force -ErrorAction SilentlyContinue } catch {}
  return $true
}


Write-Log "=== Starting PowerShell Core Installation ===" -Level "INFO"
Write-Log "Script started at: $StartTime" -Level "INFO"
Write-Log "Running on: $env:COMPUTERNAME" -Level "INFO"
Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" -Level "INFO"

$installedAfter = $null

if ($UseWinget) { Write-Log "User requested winget via -UseWinget" }

$didInstall = $false
if ($UseWinget -or (Get-Command -Name winget -ErrorAction SilentlyContinue)) {
  if (Install-PwshWithWinget) { $didInstall = $true }
}

if (-not $didInstall) {
  if ($Version -eq 'latest') {
    Write-Log "Resolving latest release from GitHub"
    try {
      $api = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
      $headers = @{ 'User-Agent' = 'PowerShell-Install-Script' }
      $rel = Invoke-RestMethod -Uri $api -Headers $headers -ErrorAction Stop
      $asset = $rel.assets | Where-Object { $_.name -match 'win-x64.*\.msi$' } | Select-Object -First 1
      if (-not $asset) { throw 'no matching MSI asset found in release' }
      $downloadUrl = $asset.browser_download_url
    }
    catch { Write-Log "Failed to resolve latest release: $_" "ERROR"; exit 2 }
  }
  else {
    $ver = $Version
    if ($ver -notmatch '^v') { $ver = "v$ver" }
    $downloadUrl = "https://github.com/PowerShell/PowerShell/releases/download/$ver/PowerShell-$($ver.TrimStart('v'))-win-x64.msi"
    Write-Log "Constructed download URL: $downloadUrl" "DEBUG"
  }

  if (-not (Install-PwshFromMsi -downloadUrl $downloadUrl)) { Write-Log "MSI installation failed" "ERROR"; exit 3 }
  $didInstall = $true
}

Start-Sleep -Seconds 2
$installedAfter = Get-InstalledPwshVersion
if ($installedAfter) { Write-Log "pwsh now installed at version: $installedAfter"; exit 0 }
else { Write-Log "pwsh not found after installation attempts" "ERROR"; exit 4 }
