# apply_admin_tweaks.ps1
# Must run as Administrator
$hvciKey = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
if (-not (Test-Path $hvciKey)) {
    New-Item -Path $hvciKey -Force | Out-Null
}
Set-ItemProperty -Path $hvciKey -Name "Enabled" -Value 0 -Type DWord -Force

$ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MuMuNxDevice.exe\PerfOptions"
if (-not (Test-Path $ifeoPath)) {
    New-Item -Path $ifeoPath -Force | Out-Null
}
Set-ItemProperty -Path $ifeoPath -Name "CpuPriorityClass" -Value 3 -Type DWord -Force

Write-Host "[SUCCESS] HVCI Disabled and IFEO CPU Priority set to High for MuMuNxDevice.exe!" -ForegroundColor Green
Start-Sleep -Seconds 2
