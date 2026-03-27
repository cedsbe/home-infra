# Disk optimization for Windows 11 (ISO build)
# BitLocker failsafe, defrag, free-space zeroing, and event log clearing.
# Run this after all cleanup scripts and before sysprep.

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"  # Prevent warning stream from causing failures in Packer/WinRM sessions

Write-Host "=== Disk optimization started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="

# ---------------------------------------------------------------------------
# 1. BitLocker failsafe
# ---------------------------------------------------------------------------
# BitLocker should have been prevented by PreventDeviceEncryption set during the
# specialize pass in autounattend.xml. If the volume is still encrypted here,
# something went wrong upstream. Check before defrag/sdelete since decryption
# changes free space state.
Write-Host ""
Write-Host "--- [1/3] BitLocker check ---"
$bitlockerStatus = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
if ($null -eq $bitlockerStatus) {
    Write-Host "  BitLocker cmdlet returned nothing (BitLocker not available or not applicable)"
}
elseif ($bitlockerStatus.VolumeStatus -eq "FullyDecrypted") {
    Write-Host "  BitLocker OK: C: is fully decrypted (VolumeStatus=$($bitlockerStatus.VolumeStatus), ProtectionStatus=$($bitlockerStatus.ProtectionStatus))"
}
else {
    Write-Warning "  UNEXPECTED: BitLocker is active (VolumeStatus=$($bitlockerStatus.VolumeStatus), ProtectionStatus=$($bitlockerStatus.ProtectionStatus))."
    Write-Warning "  The PreventDeviceEncryption registry key set during specialize should have prevented this."
    Write-Warning "  Disabling BitLocker now as failsafe - investigate the autounattend specialize pass."
    Disable-BitLocker -MountPoint "C:" | Out-Null
    $decryptDeadline = (Get-Date).AddHours(2)
    do {
        Start-Sleep -Seconds 10
        $bitlockerStatus = Get-BitLockerVolume -MountPoint "C:"
        Write-Host "  Decryption progress: $($bitlockerStatus.EncryptionPercentage)%"
        if ((Get-Date) -gt $decryptDeadline) {
            Write-Error "BitLocker decryption timed out after 2 hours."
            exit 1
        }
    } while ($bitlockerStatus.VolumeStatus -ne "FullyDecrypted")
    Write-Host "  BitLocker fully decrypted on C:." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 2. Disk optimization
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [2/3] Disk optimization ---"
Write-Host "  Defragmenting C:..."
Optimize-Volume -DriveLetter C -Defrag -Verbose
Write-Host "  Zeroing free space (reduces template size after compression)..."
if (Get-Command sdelete.exe -ErrorAction SilentlyContinue) {
    sdelete.exe -z C: -accepteula
}
else {
    Write-Host "  WARNING: sdelete.exe not found in PATH - skipping free space zeroing"
}
Write-Host "  Disk optimization complete"

# ---------------------------------------------------------------------------
# 3. Clear event logs (last - captures log entries from all prior scripts)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- [3/3] Clearing event logs ---"
$logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue
$logCount = ($logs | Measure-Object).Count
foreach ($log in $logs) {
    Write-Host "  Clearing: $($log.LogName)"
    try {
        [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($log.LogName)
    }
    catch {
        # Some logs (analytics/debug channels) cannot be cleared; skip silently
    }
}
Write-Host "  Cleared $logCount event log(s)"

Write-Host ""
Write-Host "=== Disk optimization completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
