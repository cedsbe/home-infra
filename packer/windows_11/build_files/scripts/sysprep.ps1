# Verify unattend file before launching sysprep
Write-Host ""
Write-Host "--- Verifying unattend.xml ---"
if (-not (Test-Path "C:\Deploy\unattend.xml")) {
  Write-Error "Unattend file not found at C:\Deploy\unattend.xml. Cannot proceed with sysprep."
  exit 1
}
Write-Host "  Path : C:\Deploy\unattend.xml"
Write-Host "  Size : $((Get-Item 'C:\Deploy\unattend.xml').Length) bytes"
Write-Host "  Ready: OK" -ForegroundColor Green

Write-Host ""
Write-Host "--- Launching sysprep ---"
Write-Host "  Command: sysprep.exe /oobe /generalize /mode:vm /quit /unattend:C:\Deploy\unattend.xml"

try {
  # Final Edge kill right before sysprep to close the race window between the pre-flight
  # check and sysprep's own AppX validation. Edge may have respawned during event log
  # clearing or other late operations even with services disabled.
  Write-Host "  Final Edge sweep before sysprep..."
  Get-Process | Where-Object { $_.Name -like "*edge*" } | Stop-Process -Force -ErrorAction SilentlyContinue
  $gameAssistFinal = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "Microsoft.Edge.GameAssist" }
  if ($gameAssistFinal) {
    Write-Host "[WARNING] Edge.GameAssist re-appeared after pre-flight - removing now (Edge respawned despite disabled services)..."
    foreach ($gaPkg in $gameAssistFinal) {
      try {
        Remove-AppxPackage -Package $gaPkg.PackageFullName -AllUsers -ErrorAction Stop
        Write-Host "  Final removal OK: $($gaPkg.PackageFullName)"
      }
      catch {
        Write-Host "[WARNING] Final removal of Edge.GameAssist failed: $($_.Exception.Message)"
      }
    }
  }
  else {
    Write-Host "  Edge.GameAssist not present - safe to proceed"
  }

  $sysrepStartTime = Get-Date
  Write-Host "  Started at: $($sysrepStartTime.ToString('yyyy-MM-dd HH:mm:ss'))"

  $sysprepArgs = @(
    "/oobe"
    "/generalize"
    "/mode:vm"
    "/quit"
    "/unattend:C:\Deploy\unattend.xml"
  )
  $process = Start-Process -FilePath "$($ENV:SystemRoot)\System32\Sysprep\sysprep.exe" -ArgumentList $sysprepArgs -Wait -PassThru -NoNewWindow

  $duration = (Get-Date) - $sysrepStartTime
  Write-Host "  Duration  : $($duration.TotalMinutes.ToString('F2')) minutes"
  Write-Host "  Exit code : $($process.ExitCode)"

  if ($process.ExitCode -eq 0) {
    Write-Host "  Sysprep completed successfully." -ForegroundColor Green

    Write-Host "  Clearing PowerShell history..."
    Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt" -Force -ErrorAction SilentlyContinue
    Write-Host "  Final temp file cleanup..."
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "=== Generalization completed successfully at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -ForegroundColor Green
    Write-Host "  Initiating shutdown..."
    Start-Sleep -Seconds 2
    Stop-Computer -Force
  }
  else {
    Write-Error "Sysprep failed with exit code: $($process.ExitCode)"
    exit 1
  }
}
catch {
  Write-Error "Sysprep execution failed: $($_.Exception.Message)"

  $sysrepLog = "C:\Windows\System32\Sysprep\Panther\setuperr.log"
  if (Test-Path $sysrepLog) {
    Write-Host "Sysprep error log ($sysrepLog) - last 20 lines:" -ForegroundColor Yellow
    Get-Content $sysrepLog | Select-Object -Last 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
  }
  else {
    Write-Host "  Sysprep error log not found at $sysrepLog"
  }

  exit 1
}
