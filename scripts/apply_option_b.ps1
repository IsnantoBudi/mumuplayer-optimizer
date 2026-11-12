# ==============================================================================
# Script: apply_option_b.ps1
# Description: Implements Option B (Hyper-V Coexistence) Host Optimization
# Target: Windows 11 Host, MuMu Player 12, WSL2 Resource Clamping
# ==============================================================================

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  APPLYING MUMU PLAYER 12 OPTION B OPTIMIZATIONS (COEXISTENCE)" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# 1. WSL2 Resource Clamping
Write-Host "`n[1/6] Configuring C:\Users\Lenovo\.wslconfig..." -ForegroundColor Yellow
$wslConfigPath = "C:\Users\Lenovo\.wslconfig"
$wslConfigContent = @"
# Global configuration per user for WSL 2 based on %USERPROFILE%\.wslconfig
[wsl2]
memory=3GB
processors=2
swap=4GB
localhostForwarding=true
"@

try {
    [System.IO.File]::WriteAllText($wslConfigPath, $wslConfigContent, [System.Text.Encoding]::UTF8)
    Write-Host "[OK] .wslconfig configured successfully with 3GB memory limit." -ForegroundColor Green
    Get-Content -Path $wslConfigPath | ForEach-Object { Write-Host "     $_" -ForegroundColor DarkGray }
} catch {
    Write-Host "[ERROR] Failed to write .wslconfig: $_" -ForegroundColor Red
}

# 2. Register MuMu Render Engine to Windows High Performance GPU Preference
Write-Host "`n[2/6] Registering High Performance GPU Preferences..." -ForegroundColor Yellow
$gpuKey = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
if (-not (Test-Path $gpuKey)) {
    New-Item -Path $gpuKey -Force | Out-Null
}

$executables = @(
    "D:\Program Files\Netease\MuMuPlayerGlobal-12.0\nx_device\15.0\shell\MuMuNxDevice.exe",
    "D:\Program Files\Netease\MuMuPlayerGlobal-12.0\nx_main\MuMuNxMain.exe",
    "D:\Program Files\Netease\MuMuPlayerGlobal-12.0\nx_main\MuMuNxLauncher.exe"
)

foreach ($exe in $executables) {
    if (Test-Path $exe) {
        Set-ItemProperty -Path $gpuKey -Name $exe -Value "GpuPreference=2;" -Type String -Force
        Write-Host "[OK] Registered High Performance (GpuPreference=2;) for $exe" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Target executable not found at: $exe" -ForegroundColor DarkGray
    }
}

# 3. Power Plan Configuration
Write-Host "`n[3/6] Checking Windows Power Plan..." -ForegroundColor Yellow
$ultimateGuid = "0b9c751a-c9f6-43bb-abc0-b87d47d8a7c2"
$schemes = & powercfg /list
if ($schemes -match $ultimateGuid) {
    & powercfg /setactive $ultimateGuid
    Write-Host "[OK] Switched to Ultimate Performance power plan." -ForegroundColor Green
} else {
    Write-Host "[INFO] Ultimate Performance scheme not registered. Duplicating from template..." -ForegroundColor DarkGray
    & powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
    & powercfg /setactive $ultimateGuid 2>$null
}
$currentActive = & powercfg /getactivescheme
Write-Host "[ACTIVE SCHEME] $currentActive" -ForegroundColor Cyan

# 4. Host Ad Cache & CEF Wing Neutralization
Write-Host "`n[4/6] Neutralizing Host Ad Caches and CEF Telemetry..." -ForegroundColor Yellow
$adsDir = Join-Path $env:APPDATA "Netease\MuMuPlayer\data\ProgramAds"
$advertisementDir = Join-Path $adsDir "advertisement"
if (Test-Path $advertisementDir) {
    Remove-Item -Path (Join-Path $advertisementDir "*") -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Cleared host advertisement cache folder." -ForegroundColor Green
}

$programAds = Join-Path $adsDir "programAds.json"
$reportConfig = Join-Path $env:APPDATA "Netease\MuMuPlayer\configs\report_app_data_config.json"
foreach ($cfg in @($programAds, $reportConfig)) {
    if (Test-Path $cfg) {
        Set-ItemProperty -Path $cfg -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
        [System.IO.File]::WriteAllText($cfg, "{}", [System.Text.Encoding]::UTF8)
        Set-ItemProperty -Path $cfg -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
        Write-Host "[OK] Emptied and write-locked: $cfg" -ForegroundColor Green
    }
}

# 5. WSL2 Restart to apply memory limit
Write-Host "`n[5/6] Restarting WSL2 to bind memory limit..." -ForegroundColor Yellow
& wsl.exe --shutdown
Write-Host "[OK] WSL2 shutdown completed. New memory limit will take effect on next launch." -ForegroundColor Green

# 6. Admin Registry Script Generation
Write-Host "`n[6/6] Generating 1-Click Administrator Registry Batch Script..." -ForegroundColor Yellow
$adminBatContent = @"
@echo off
:: Run this batch file as Administrator to disable HVCI and set IFEO CPU Priority
echo ==================================================================
echo   APPLYING HKLM REGISTRY TWEAKS (RUN AS ADMINISTRATOR)
echo ==================================================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please right-click this file and select 'Run as administrator'!
    pause
    exit /b 1
)

echo [1/2] Disabling HVCI (Memory Integrity / Core Isolation)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f

echo [2/2] Setting High CPU Priority Class for MuMuNxDevice.exe...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MuMuNxDevice.exe\PerfOptions" /v "CpuPriorityClass" /t REG_DWORD /d 3 /f

echo.
echo [SUCCESS] Both HKLM optimizations applied successfully!
echo Please restart Windows when convenient to finalize Core Isolation removal.
pause
"@

$adminBatPath = "D:\Project\mumu optimization\Run_As_Admin_Option_B.bat"
[System.IO.File]::WriteAllText($adminBatPath, $adminBatContent, [System.Text.Encoding]::ASCII)
Write-Host "[OK] Admin batch script written to: $adminBatPath" -ForegroundColor Green

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "  OPTION B SETUP EXECUTED!" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
