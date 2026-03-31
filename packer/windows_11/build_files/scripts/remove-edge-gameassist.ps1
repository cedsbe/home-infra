# ---------------------------------------------------------------------------
# Nuclear removal of Edge GameAssist (version-agnostic)
# ---------------------------------------------------------------------------
# Edge can silently install GameAssist under LocalSystem (S-1-5-18) via its
# sidebar / games-hub feature. Remove-AppxPackage -AllUsers claims success
# but leaves the registration in the StateRepository SQLite database, which
# causes AppxSysprep.dll to fail sysprep with 0x80073cf2.
#
# The standard AppX APIs cannot remove the S-1-5-18 entry completely, so we:
#   1. Stop StateRepository + AppXSvc (they own the package database)
#   2. Delete the AppRepository XML metadata file
#   3. Delete the Deprovisioned registry entry
#   4. Take ownership and delete the package folder from WindowsApps
#   5. Restart services so Remove-AppxPackage -User can reach the DB
#   6. Remove the S-1-5-18 user registration via Remove-AppxPackage -User
#   7. Remove the AppX-Sysprep block from Generalize.xml (AppxSysprep.dll
#      reads the StateRepository directly - even a "pending removal" ghost
#      entry will make it fail; all AppX cleanup is already done upstream)
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "--- Edge GameAssist nuclear removal ---"

# Kill all Edge processes to prevent re-registration during cleanup
$edgeProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*edge*" }
if ($edgeProcs) {
  $edgeProcs | ForEach-Object { Write-Host "  Killing Edge process: $($_.Name) (PID $($_.Id))" }
  $edgeProcs | Stop-Process -Force -ErrorAction SilentlyContinue
}
else {
  Write-Host "  No Edge processes running"
}

$gameAssist = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
Where-Object { $_.Name -eq "Microsoft.Edge.GameAssist" }

if (-not $gameAssist) {
  Write-Host "  Edge.GameAssist not present - no action needed"
}
else {
  foreach ($pkg in $gameAssist) {
    $fullName = $pkg.PackageFullName
    $familyName = $pkg.PackageFamilyName
    $installPath = $pkg.InstallLocation

    Write-Host "  Package : $fullName"
    Write-Host "  Family  : $familyName"
    Write-Host "  Location: $installPath"
    foreach ($ui in $pkg.PackageUserInformation) {
      Write-Host "  SID: $($ui.UserSecurityId)  State: $($ui.InstallState)"
    }

    # Step 1 - Stop services that own the StateRepository
    Write-Host "  [1/7] Stopping StateRepository and AppXSvc..."
    Stop-Service -Name "StateRepository" -Force -ErrorAction SilentlyContinue
    Stop-Service -Name "AppXSvc" -Force -ErrorAction SilentlyContinue
    Get-Service StateRepository, AppXSvc -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Host "    $($_.Name): $($_.Status)" }

    # Step 2 - Delete AppRepository XML metadata
    Write-Host "  [2/7] Deleting AppRepository XML metadata..."
    $xmlPath = "C:\ProgramData\Microsoft\Windows\AppRepository\$fullName.xml"
    if (Test-Path $xmlPath) {
      Remove-Item $xmlPath -Force -ErrorAction SilentlyContinue
      Write-Host "    Deleted: $xmlPath"
    }
    else {
      Write-Host "    Not found: $xmlPath (already removed or different path)"
    }

    # Step 3 - Delete the Deprovisioned registry entry
    Write-Host "  [3/7] Deleting Deprovisioned registry entry..."
    $deprovPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\$familyName"
    if (Test-Path $deprovPath) {
      Remove-Item $deprovPath -Recurse -Force -ErrorAction SilentlyContinue
      Write-Host "    Deleted: $deprovPath"
    }
    else {
      Write-Host "    Not found: $deprovPath (already removed)"
    }

    # Step 4 - Take ownership and delete the package folder
    Write-Host "  [4/7] Deleting package folder..."
    if ($installPath -and (Test-Path $installPath)) {
      $null = takeown /f $installPath /r /d y 2>&1
      $null = icacls $installPath /grant Administrators:F /t 2>&1
      Remove-Item $installPath -Recurse -Force -ErrorAction SilentlyContinue
      if (Test-Path $installPath) {
        Write-Host "    [WARNING] Could not fully delete: $installPath"
      }
      else {
        Write-Host "    Deleted: $installPath"
      }
    }
    else {
      Write-Host "    InstallLocation empty or path not found - skipping"
    }

    # Step 5 - Restart services so Remove-AppxPackage -User can reach the DB
    Write-Host "  [5/7] Restarting StateRepository and AppXSvc..."
    Start-Service -Name "StateRepository" -ErrorAction SilentlyContinue
    Start-Service -Name "AppXSvc" -ErrorAction SilentlyContinue
    Get-Service StateRepository, AppXSvc -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Host "    $($_.Name): $($_.Status)" }

    # Step 6 - Remove the S-1-5-18 (LocalSystem) user registration
    Write-Host "  [6/7] Removing S-1-5-18 (LocalSystem) registration..."
    Remove-AppxPackage -Package $fullName -User "S-1-5-18" -ErrorAction SilentlyContinue
    $afterRemoval = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
    Where-Object { $_.PackageFullName -eq $fullName }
    if ($afterRemoval) {
      Write-Host "    Package still registered (Status: $($afterRemoval.Status))"
      foreach ($ui in $afterRemoval.PackageUserInformation) {
        Write-Host "    SID: $($ui.UserSecurityId)  State: $($ui.InstallState)"
      }
    }
    else {
      Write-Host "    Package fully removed from AppX database"
    }
  }

  # Step 7 - Remove AppxSysprep.dll from Generalize.xml
  # AppxSysprep.dll reads the StateRepository SQLite database directly (not
  # via AppXSvc). Even a ghost "pending removal" entry causes 0x80073cf2.
  # All AppX cleanup was already performed by generalize-iso.ps1.
  Write-Host "  [7/7] Removing AppX-Sysprep block from Generalize.xml..."
  $genXml = "$env:SystemRoot\System32\Sysprep\ActionFiles\Generalize.xml"
  $null = takeown /f $genXml 2>&1
  $null = icacls $genXml /grant Administrators:F 2>&1
  $xmlContent = Get-Content $genXml -Raw
  $lengthBefore = $xmlContent.Length
  $xmlContent = [regex]::Replace($xmlContent,
    '(?s)<imaging exclude=""><assemblyIdentity name="Microsoft-Windows-AppX-Sysprep".*?</imaging>', '')
  $lengthAfter = $xmlContent.Length
  $charsRemoved = $lengthBefore - $lengthAfter
  if ($charsRemoved -gt 0) {
    Set-Content $genXml -Value $xmlContent -NoNewline
    Write-Host "    Removed AppX-Sysprep block ($charsRemoved chars) from Generalize.xml"
  }
  else {
    Write-Host "    [WARNING] AppX-Sysprep block not found in Generalize.xml (already removed or unexpected format)"
  }
}

# Defensive: ensure MountedDevices key exists - a previous partial sysprep
# run deletes it, and MountPointManager fails with error=2 if it is missing.
if (-not (Test-Path "HKLM:\SYSTEM\MountedDevices")) {
  New-Item "HKLM:\SYSTEM\MountedDevices" -Force | Out-Null
  Write-Host "  Recreated missing HKLM:\SYSTEM\MountedDevices key"
}

# Defensive: reset sysprep state in case a prior attempt left it dirty
Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\Status\SysprepStatus" -Name "GeneralizationState" -Value 7 -Type DWord
Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\Status\SysprepStatus" -Name "CleanupState" -Value 2 -Type DWord

Write-Host "--- Edge GameAssist nuclear removal complete ---"
