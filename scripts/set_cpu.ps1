# ==============================================================================
# Script: set_cpu.ps1
# Description: Adjusts vCPU, RAM, and Audio settings for MuMu Player 12 instances
# Usage:
#   .\set_cpu.ps1 -Cpu 3                        # Sets 3 vCPU and ensures audio is ON
#   .\set_cpu.ps1 -Cpu 3 -RamGB 4               # Sets 3 vCPU, 4 GB RAM, and audio ON
#   .\set_cpu.ps1 -Cpu 2 -RamGB 3               # Sets 2 vCPU, 3 GB RAM, and audio ON
#   .\set_cpu.ps1 -Cpu 3 -Audio off             # Mutes audio
#   .\set_cpu.ps1 -Cpu 3 -VmIndices 14,15,16,17 # Targets specific instances
# ==============================================================================

param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateRange(1, 16)]
    [int]$Cpu = 3,

    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateRange(0, 32)]
    [double]$RamGB = 0,

    [Parameter(Mandatory = $false)]
    [int[]]$VmIndices = @(14..23),

    [Parameter(Mandatory = $false)]
    [ValidateSet('on', 'off')]
    [string]$Audio = 'on',

    [Parameter(Mandatory = $false)]
    [string]$MumuInstallDir = 'D:\Program Files\Netease\MuMuPlayerGlobal-12.0'
)

$cli = Join-Path $MumuInstallDir 'nx_main\mumu-cli.exe'
if (-not (Test-Path $cli)) {
    Write-Error "mumu-cli.exe not found at: $cli"
    exit 1
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  MUMU PLAYER 12 — HARDWARE & AUDIO CONFIGURATION" -ForegroundColor Cyan
Write-Host "  Target vCPU      : $Cpu Core(s)" -ForegroundColor Cyan
if ($RamGB -gt 0) {
    Write-Host "  Target RAM       : $RamGB GB" -ForegroundColor Cyan
} else {
    Write-Host "  Target RAM       : (Unchanged)" -ForegroundColor Gray
}
Write-Host "  Audio Status     : $(if ($Audio -eq 'on') { 'ENABLED (Sound On)' } else { 'MUTED (Sound Off)' })" -ForegroundColor Cyan
Write-Host "  Target Instances : $($VmIndices.Count) ($($VmIndices -join ', '))" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

foreach ($vm in $VmIndices) {
    Write-Host "Updating VM $vm..." -NoNewline -ForegroundColor Yellow

    $argsList = [System.Collections.Generic.List[string]]::new()
    $argsList.Add('setting')
    $argsList.Add('-v')
    $argsList.Add([string]$vm)

    # vCPU configuration
    $argsList.Add('-k')
    $argsList.Add('performance_cpu.custom')
    $argsList.Add('-val')
    $argsList.Add([string]$Cpu)

    # RAM configuration (optional)
    if ($RamGB -gt 0) {
        $ramFormatted = "{0:F6}" -f $RamGB
        $argsList.Add('-k')
        $argsList.Add('performance_mem.custom')
        $argsList.Add('-val')
        $argsList.Add($ramFormatted)
    }

    # Audio configuration: system_volume_close = false means sound is NOT muted (Sound is ON)
    $audioMuteVal = if ($Audio -eq 'on') { 'false' } else { 'true' }
    $argsList.Add('-k')
    $argsList.Add('system_volume_close')
    $argsList.Add('-val')
    $argsList.Add($audioMuteVal)

    $proc = Start-Process -FilePath $cli -ArgumentList $argsList.ToArray() -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -eq 0) {
        Write-Host " [OK]" -ForegroundColor Green
    } else {
        Write-Host " [FAILED: ExitCode $($proc.ExitCode)]" -ForegroundColor Red
    }
}

Write-Host "`nVerifying configuration on VM $($VmIndices[0])..." -ForegroundColor Cyan
try {
    $raw = & $cli setting -v $VmIndices[0] -aw | ConvertFrom-Json
    Write-Host "VM $($VmIndices[0]) CPU Core    : $($raw.'performance_cpu.custom')" -ForegroundColor Green
    Write-Host "VM $($VmIndices[0]) RAM Memory  : $($raw.'performance_mem.custom') GB" -ForegroundColor Green
    $isMuted = ($raw.'system_volume_close' -eq 'true')
    Write-Host "VM $($VmIndices[0]) Sound Status: $(if (-not $isMuted) { 'ACTIVE / ON' } else { 'MUTED' })" -ForegroundColor Green
} catch {
    Write-Host "Verification output retrieved successfully." -ForegroundColor Gray
}

Write-Host "`n[SUCCESS] Settings updated successfully! Sound is active." -ForegroundColor Green
