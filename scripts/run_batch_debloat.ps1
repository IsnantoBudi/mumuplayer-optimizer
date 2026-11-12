# run_batch_debloat.ps1
# Batch Orchestrator for MuMu Player 12 Global (Android 15) VMs
param(
    [Parameter(Mandatory = $false)]
    [int[]]$VmIndices = @(15..23),

    [Parameter(Mandatory = $false)]
    [string]$MumuInstallDir = 'D:\Program Files\Netease\MuMuPlayerGlobal-12.0'
)

$ErrorActionPreference = 'Continue'
$total = $VmIndices.Count
$results = [System.Collections.Generic.List[PSCustomObject]]::new()
$startTime = [Diagnostics.Stopwatch]::StartNew()

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   BATCH OPTIMIZATION FOR MUMU PLAYER 12 (ANDROID 15)" -ForegroundColor Cyan
Write-Host "   Total Target VMs : $total ($($VmIndices -join ', '))" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$scriptPath = Join-Path $PSScriptRoot 'run_debloat_vm.ps1'
$cliPath = Join-Path $MumuInstallDir 'nx_main\mumu-cli.exe'

$current = 0
foreach ($index in $VmIndices) {
    $current++
    $vmWatch = [Diagnostics.Stopwatch]::StartNew()

    $vmName = "VM-$index"
    try {
        $infoRaw = & $cliPath info -v $index
        $infoJson = $infoRaw | ConvertFrom-Json
        if ($infoJson.name) { $vmName = $infoJson.name }
    } catch {}

    Write-Host "`n>>> [$current/$total] Starting Optimization for VM $index ($vmName)..." -ForegroundColor Magenta

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath -VmIndex $index -MumuInstallDir $MumuInstallDir -ShutdownAfter
    $exitCode = $LASTEXITCODE
    $vmWatch.Stop()

    $durationStr = "{0:mm\:ss}" -f $vmWatch.Elapsed
    if ($exitCode -eq 0) {
        Write-Host ">>> [$current/$total] VM $index ($vmName) SUCCEEDED in $durationStr" -ForegroundColor Green
        $results.Add([PSCustomObject]@{
            Index    = $index
            Name     = $vmName
            Status   = 'SUCCESS'
            Duration = $durationStr
        })
    } else {
        Write-Host ">>> [$current/$total] VM $index ($vmName) FAILED (Exit Code $exitCode) in $durationStr" -ForegroundColor Red
        $results.Add([PSCustomObject]@{
            Index    = $index
            Name     = $vmName
            Status   = 'FAILED'
            Duration = $durationStr
        })
    }

    Start-Sleep -Seconds 3
}

$startTime.Stop()

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "                 BATCH EXECUTION SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
$results | Format-Table -AutoSize

$successCount = ($results | Where-Object { $_.Status -eq 'SUCCESS' }).Count
$failCount = ($results | Where-Object { $_.Status -eq 'FAILED' }).Count
$totalDuration = "{0:mm\:ss}" -f $startTime.Elapsed

Write-Host "Total Processed : $total" -ForegroundColor Cyan
Write-Host "Succeeded       : $successCount" -ForegroundColor Green
Write-Host "Failed          : $failCount" -ForegroundColor $(if ($failCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "Total Time      : $totalDuration" -ForegroundColor Cyan

if ($failCount -gt 0) {
    exit 1
} else {
    exit 0
}
