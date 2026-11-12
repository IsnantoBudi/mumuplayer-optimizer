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