# ==============================================================================
# Script: mumu_tool.ps1
# Description: All-in-One MuMu Player 12 & Host Windows Optimization Utility
# Style: Inspired by Chris Titus Tech (CTT) Windows Utility
# ==============================================================================

param(
    [string]$MumuInstallDir = 'D:\Program Files\Netease\MuMuPlayerGlobal-12.0'
)

$cli = Join-Path $MumuInstallDir 'nx_main\mumu-cli.exe'
$vboxImg = "C:\Program Files\MuMuNxVbox\Hypervisor\vbox-img.exe"
$targetVms = 14..23

function Get-SystemStatus {
    $plan = (& powercfg /getactivescheme) -replace '.*\(|\).*', ''
    $wslLimited = Test-Path "C:\Users\Lenovo\.wslconfig"
    $runningVMs = (Get-Process -Name 'MuMuNxDevice' -ErrorAction SilentlyContinue).Count

    $vm14Cpu = "N/A"
    $vm14Ram = "N/A"
    $vm14Audio = "N/A"

    if (Test-Path $cli) {
        try {
            $raw = & $cli setting -v 14 -aw | ConvertFrom-Json
            $vm14Cpu = $raw.'performance_cpu.custom' + " vCPU"
            $vm14Ram = $raw.'performance_mem.custom' + " GB"
            $isMuted = ($raw.'system_volume_close' -eq 'true')
            $vm14Audio = if ($isMuted) { "Muted" } else { "Active (On)" }
        } catch {}
    }

    return [PSCustomObject]@{
        PowerPlan  = $plan
        WslConfig  = if ($wslLimited) { "Active (3GB Limit)" } else { "Default" }
        RunningVMs = "$runningVMs Instance(s)"
        VM14Config = "$vm14Cpu / $vm14Ram / Audio: $vm14Audio"
    }
}

function Show-Header {
    Clear-Host
    $status = Get-SystemStatus

    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "          MUMU PLAYER 12 ALL-IN-ONE OPTIMIZATION TOOL (CTT-STYLE)                " -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "  Host OS       : Windows 11 (AMD Ryzen 7 5825U · 40GB RAM · Vega 8 iGPU)" -ForegroundColor DarkGray
    Write-Host "  Power Plan    : $($status.PowerPlan) | WSL2 Budget: $($status.WslConfig)" -ForegroundColor DarkGray
    Write-Host "  Active Fleet  : $($status.RunningVMs) running | Current Spec: $($status.VM14Config)" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan
}

function Invoke-SetHardware {
    param([int]$Cpu, [double]$RamGB, [string]$Audio = 'on')
    $script = Join-Path $PSScriptRoot 'set_cpu.ps1'
    if (Test-Path $script) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -Cpu $Cpu -RamGB $RamGB -Audio $Audio -VmIndices $targetVms
    } else {
        Write-Host "[ERROR] set_cpu.ps1 not found." -ForegroundColor Red
    }
}

while ($true) {
    Show-Header

    Write-Host "`n  [ HARDWARE SIZING PRESETS ]" -ForegroundColor Yellow
    Write-Host "    [1] Preset Responsif (3 vCPU / 4 GB RAM / Suara Aktif)  -> Optimal 3-4 Instans"
    Write-Host "    [2] Preset 10x Fleet (2 vCPU / 3 GB RAM / 30-15 FPS)    -> Skala Penuh 10 Instans"
    Write-Host "    [3] Preset Solo Peak Gaming (4 vCPU / 6 GB RAM / 120 FPS)-> Main Game Berat 1 VM"
    Write-Host "    [4] Kustomisasi Bebas (Input vCPU & RAM manual)"

    Write-Host "`n  [ AUDIO & MULTIMEDIA ]" -ForegroundColor Yellow
    Write-Host "    [5] Aktifkan Suara di Seluruh Instans (Unmute All)"
    Write-Host "    [6] Bisukan Suara di Seluruh Instans (Mute All)"

    Write-Host "`n  [ HOST & SYSTEM TWEAKS ]" -ForegroundColor Yellow
    Write-Host "    [7] Terapkan Optimasi Host (WSL2 3GB Limit, GPU High Pref, Ultimate Power)"
    Write-Host "    [8] Buka Administrator Tweaks (Matikan HVCI & Set IFEO High Priority)"
    Write-Host "    [9] Bersihkan Cache Iklan Host MuMu (ProgramAds Wipe & Lock)"

    Write-Host "`n  [ ANDROID MAINTENANCE & STORAGE ]" -ForegroundColor Yellow
    Write-Host "    [10] Jalankan Batch Debloat Android 15 (HeliBoard, Lawnchair, Sinkhole DNS)"
    Write-Host "    [11] Kompaksi Virtual Disk VDI (Bebaskan 20-40 GB Ruang SSD)"

    Write-Host "`n  [ FLEET LIFECYCLE MANAGEMENT ]" -ForegroundColor Yellow
    Write-Host "    [12] Luncurkan 10 Instans Bertahap (Jeda 12 detik aman boot-storm)"
    Write-Host "    [13] Matikan Bersih Seluruh Instans yang Sedang Berjalan"

    Write-Host "`n  [0] Keluar" -ForegroundColor Gray
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

    $choice = Read-Host "  Pilih nomor menu [0-13]"

    switch ($choice) {
        "1" {
            Write-Host "`nMenerapkan Preset Responsif (3 vCPU / 4 GB RAM / Suara ON)..." -ForegroundColor Cyan
            Invoke-SetHardware -Cpu 3 -RamGB 4 -Audio 'on'
        }
        "2" {
            Write-Host "`nMenerapkan Preset 10x Fleet (2 vCPU / 3 GB RAM / Suara ON)..." -ForegroundColor Cyan
            Invoke-SetHardware -Cpu 2 -RamGB 3 -Audio 'on'
        }
        "3" {
            Write-Host "`nMenerapkan Preset Solo Peak Gaming (4 vCPU / 6 GB RAM / Suara ON)..." -ForegroundColor Cyan
            Invoke-SetHardware -Cpu 4 -RamGB 6 -Audio 'on'
        }
        "4" {
            $inputCpu = Read-Host "  Masukkan jumlah vCPU [1-8]"
            $inputRam = Read-Host "  Masukkan jumlah RAM dalam GB (misal: 3 atau 4)"
            if ($inputCpu -match '^\d+$' -and $inputRam -match '^\d+(\.\d+)?$') {
                Invoke-SetHardware -Cpu ([int]$inputCpu) -RamGB ([double]$inputRam) -Audio 'on'
            } else {
                Write-Host "[ERROR] Input tidak valid." -ForegroundColor Red
            }
        }
        "5" {
            Write-Host "`nMengaktifkan suara pada seluruh instans..." -ForegroundColor Cyan
            Invoke-SetHardware -Cpu 3 -RamGB 0 -Audio 'on'
        }
        "6" {
            Write-Host "`nMembisukan suara pada seluruh instans..." -ForegroundColor Cyan
            Invoke-SetHardware -Cpu 3 -RamGB 0 -Audio 'off'
        }
        "7" {
            Write-Host "`nMenerapkan optimasi host..." -ForegroundColor Cyan
            $applyHost = Join-Path $PSScriptRoot 'apply_option_b.ps1'
            if (Test-Path $applyHost) {
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $applyHost
            }
        }
        "8" {
            Write-Host "`nMembuka skrip Administrator untuk HVCI & IFEO..." -ForegroundColor Cyan
            $adminBat = Join-Path $PSScriptRoot 'Run_As_Admin_Option_B.bat'
            if (Test-Path $adminBat) {
                Start-Process -FilePath 'cmd.exe' -ArgumentList "/c `"$adminBat`"" -Verb RunAs
                Write-Host "[INFO] Silakan konfirmasi 'Yes' pada jendela UAC administrator yang muncul." -ForegroundColor Yellow
            }
        }
        "9" {
            Write-Host "`nMembersihkan dan mengunci cache iklan..." -ForegroundColor Cyan
            $adsDir = Join-Path $env:APPDATA "Netease\MuMuPlayer\data\ProgramAds"
            $advertisementDir = Join-Path $adsDir "advertisement"
            if (Test-Path $advertisementDir) {
                Remove-Item -Path (Join-Path $advertisementDir "*") -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "[OK] Folder iklan dibersihkan." -ForegroundColor Green
            }
            $programAds = Join-Path $adsDir "programAds.json"
            $reportConfig = Join-Path $env:APPDATA "Netease\MuMuPlayer\configs\report_app_data_config.json"
            foreach ($cfg in @($programAds, $reportConfig)) {
                if (Test-Path $cfg) {
                    Set-ItemProperty -Path $cfg -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
                    [System.IO.File]::WriteAllText($cfg, "{}", [System.Text.Encoding]::UTF8)
                    Set-ItemProperty -Path $cfg -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
                    Write-Host "[OK] Dikunci read-only: $cfg" -ForegroundColor Green
                }
            }
        }
        "10" {
            Write-Host "`nMenjalankan Batch Debloat pada VM 14-23..." -ForegroundColor Cyan
            $batchDebloat = Join-Path $PSScriptRoot 'run_batch_debloat.ps1'
            if (Test-Path $batchDebloat) {
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $batchDebloat
            }
        }
        "11" {
            Write-Host "`nMenjalankan Kompaksi Virtual Disk (VDI)..." -ForegroundColor Cyan
            if (-not (Test-Path $vboxImg)) {
                Write-Host "[ERROR] vbox-img.exe tidak ditemukan di $vboxImg" -ForegroundColor Red
            } else {
                foreach ($vm in $targetVms) {
                    $vdi = Join-Path $MumuInstallDir "vms\MuMuPlayerGlobal-15.0-$vm\data.vdi"
                    if (Test-Path $vdi) {
                        $before = [math]::Round(((Get-Item $vdi).Length / 1GB), 2)
                        Write-Host "Kompaksi VM $vm data.vdi (Ukuran: $before GB)..." -ForegroundColor Yellow
                        & $vboxImg compact --filename $vdi
                        $after = [math]::Round(((Get-Item $vdi).Length / 1GB), 2)
                        Write-Host "  [OK] VM $vm selesai. Ukuran baru: $after GB (Hemat: $([math]::Round($before - $after, 2)) GB)" -ForegroundColor Green
                    }
                }
            }
        }
        "12" {
            Write-Host "`nMeluncurkan 10 instans secara bertahap (jeda 12 detik)..." -ForegroundColor Cyan
            $launchScript = Join-Path $PSScriptRoot 'launch_staggered_fleet.ps1'
            if (Test-Path $launchScript) {
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $launchScript
            }
        }
        "13" {
            Write-Host "`nMematikan bersih seluruh instans yang aktif..." -ForegroundColor Cyan
            foreach ($vm in $targetVms) {
                Write-Host "Mengirim sinyal shutdown ke VM $vm..." -NoNewline -ForegroundColor Gray
                & $cli control -v $vm shutdown | Out-Null
                Write-Host " [OK]" -ForegroundColor Green
            }
            Write-Host "`n[SUCCESS] Sinyal shutdown terkirim ke seluruh instans." -ForegroundColor Green
        }
        "0" {
            Write-Host "`nTerima kasih! Menutup MuMu Optimization Tool.`n" -ForegroundColor Green
            break
        }
        default {
            Write-Host "`n[Peringatan] Pilihan tidak valid, silakan pilih nomor 0 sampai 13." -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "Tekan [Enter] untuk kembali ke menu utama..." -ForegroundColor DarkGray
    $null = Read-Host
}
