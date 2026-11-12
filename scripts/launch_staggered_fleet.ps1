# ==============================================================================
# Script: launch_staggered_fleet.ps1
# Description: Launches 10 MuMu Player 12 instances with a 12s stagger to prevent boot-storms
# ==============================================================================

param(
    [int[]]$VmIndices = @(14..23),
    [int]$StaggerIntervalSeconds = 12,
    [string]$MumuInstallDir = 'D:\Program Files\Netease\MuMuPlayerGlobal-12.0'
)

$cli = Join-Path $MumuInstallDir 'nx_main\mumu-cli.exe'
$adb = Join-Path $MumuInstallDir 'nx_device\15.0\shell\adb.exe'

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  LAUNCHING MULTI-INSTANCE FLEET (STAGGERED: ${StaggerIntervalSeconds}s)" -ForegroundColor Cyan
Write-Host "  Total Target VMs : $($VmIndices.Count) ($($VmIndices -join ', '))" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

foreach ($index in $VmIndices) {
    $port = 16384 + ($index * 32)
    $endpoint = "127.0.0.1:$port"
    Write-Host "`nLaunching VM $index (Target ADB: $endpoint)..." -ForegroundColor Yellow

    & $cli control -v $index launch | Out-Null
    Start-Sleep -Seconds $StaggerIntervalSeconds

    # Test TCP Port Readiness
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $iar = $tcp.BeginConnect('127.0.0.1', $port, $null, $null)
        if ($iar.AsyncWaitHandle.WaitOne(3000, $false) -and $tcp.Connected) {
            Write-Host "  [OK] VM $index ADB port $port listening!" -ForegroundColor Green
            & $adb connect $endpoint | Out-Null
        } else {
            Write-Host "  [!] VM $index ADB port $port initializing in background..." -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [!] Probe pending for VM $index" -ForegroundColor Gray
    } finally {
        $tcp.Close(); $tcp.Dispose()
    }
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  ALL INSTANCES DISPATCHED SUCCESSFULLY!" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
