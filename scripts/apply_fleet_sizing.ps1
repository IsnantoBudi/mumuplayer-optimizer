# ==============================================================================
# Script: apply_fleet_sizing.ps1
# Description: Configures MuMu Player 12 Multi-Instance Fleet (VM 14 to 23)
# Settings: 2 vCPU, 3 GB RAM, Vulkan, 540p (960x540), 30/15 FPS, Read-only system disk
# ==============================================================================

$MumuInstallDir = 'D:\Program Files\Netease\MuMuPlayerGlobal-12.0'
$cli = Join-Path $MumuInstallDir 'nx_main\mumu-cli.exe'
$targetVms = 14..23

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  CONFIGURING MULTI-INSTANCE FLEET HARDWARE SIZING" -ForegroundColor Cyan
Write-Host "  Targets: VM 14 through 23 (10 Instances)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

foreach ($vm in $targetVms) {
    Write-Host "Setting VM $vm..." -NoNewline -ForegroundColor Yellow
    $argsList = @(
        'setting',
        '-v', [string]$vm,
        '-k', 'performance_mode', '-val', 'custom',
        '-k', 'performance_cpu.custom', '-val', '2',
        '-k', 'performance_mem.custom', '-val', '3.000000',
        '-k', 'renderer_mode', '-val', 'vk',
        '-k', 'max_frame_rate', '-val', '30',
        '-k', 'dynamic_adjust_frame_rate', '-val', 'true',
        '-k', 'dynamic_low_frame_rate_limit', '-val', '15',
        '-k', 'resolution_mode', '-val', 'custom',
        '-k', 'resolution_width.custom', '-val', '960.000000',
        '-k', 'resolution_height.custom', '-val', '540.000000',
        '-k', 'resolution_dpi.custom', '-val', '220.000000',
        '-k', 'system_disk_readonly', '-val', 'true',
        '-k', 'root_permission', '-val', 'false'
    )
    
    $proc = Start-Process -FilePath $cli -ArgumentList $argsList -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -eq 0) {
        Write-Host " [OK]" -ForegroundColor Green
    } else {
        Write-Host " [FAILED: ExitCode $($proc.ExitCode)]" -ForegroundColor Red
    }
}

Write-Host "`nVerifying VM 14 configuration..." -ForegroundColor Cyan
& $cli setting -v 14 -aw

Write-Host "`nFleet sizing completed successfully!" -ForegroundColor Green
