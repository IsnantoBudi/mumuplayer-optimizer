# run_debloat_vm.ps1
# Multi-instance Debloater & Ad-blocker for MuMu Player 12 Global (Android 15)
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateRange(0, 2147483647)]
    [int]$VmIndex = 14,

    [Parameter(Mandatory = $false)]
    [string]$MumuInstallDir = 'D:\Program Files\Netease\MuMuPlayerGlobal-12.0',

    [Parameter(Mandatory = $false)]
    [switch]$ShutdownAfter
)

$ErrorActionPreference = 'Stop'

try {
    Write-Host "=== MuMu Player 12 Optimization ===" -ForegroundColor Cyan
    Write-Host "Target VM Index : $VmIndex"
    Write-Host "MuMu Directory  : $MumuInstallDir"

    . (Join-Path $PSScriptRoot 'mumu_common.ps1')

    $cli = Join-Path $MumuInstallDir 'nx_main\mumu-cli.exe'
    $vmDir = Join-Path $MumuInstallDir "vms\MuMuPlayerGlobal-15.0-$VmIndex"
    if (-not (Test-Path -LiteralPath $vmDir -PathType Container)) {
        $vmDir = Join-Path $MumuInstallDir "vms\MuMuPlayer-15.0-$VmIndex"
    }
    if (-not (Test-Path -LiteralPath $vmDir -PathType Container)) {
        throw "VM directory not found for index $VmIndex ($vmDir)"
    }

    # Step 1: Temporarily Enable Root & Unlock System Disk via mumu-cli
    Write-Host "`n[1/6] Enabling Root and setting System Disk to Writable via mumu-cli..." -ForegroundColor Yellow
    Invoke-MumuNative $cli @('setting', '-v', [string]$VmIndex, '-k', 'root_permission', '-val', 'true', '-k', 'system_disk_readonly', '-val', 'false') | Out-Null

    try {
        # Step 2: Establish ADB Connection & Launch VM
        Write-Host "`n[2/6] Launching VM $VmIndex and establishing Root ADB connection..." -ForegroundColor Yellow
        $connection = New-MumuConnection -MumuInstallDir $MumuInstallDir -VmIndex $VmIndex -Launch -Root -StartupTimeoutSeconds 90
        Write-Host "Connected to $($connection.Device) as root." -ForegroundColor Green

        # Step 3: Install & Activate HeliBoard Keyboard
        Write-Host "`n[3/6] Setting up HeliBoard FOSS Keyboard..." -ForegroundColor Yellow
        $ime = 'helium314.keyboard/.latin.LatinIME'
        $installed = Invoke-MumuShell $connection 'ime list -a -s'
        if (($installed.StdOut -split '\s+') -notcontains $ime) {
            $apkPath = Join-Path $PSScriptRoot 'HeliBoard_4.2-release.apk'
            if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
                $apkPath = Join-Path $PSScriptRoot '..\HeliBoard_4.2-release.apk'
            }
            if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
                Write-Host "HeliBoard APK not found locally. Auto-downloading from GitHub release..." -ForegroundColor Cyan
                $downloadUrl = 'https://github.com/Helium314/HeliBoard/releases/download/v4.2/HeliBoard_4.2-release.apk'
                $apkPath = Join-Path $PSScriptRoot 'HeliBoard_4.2-release.apk'
                Invoke-WebRequest -Uri $downloadUrl -OutFile $apkPath -UseBasicParsing
                Write-Host "HeliBoard APK downloaded successfully." -ForegroundColor Green
            }
            Write-Host "Installing HeliBoard APK..."
            $installResult = Invoke-MumuNative $connection.AdbPath @('-s', $connection.Device, 'install', '-r', '-d', '-g', $apkPath) -TimeoutSeconds 180
            if (($installResult.StdOut -split '\r?\n') -notcontains 'Success') {
                throw "Failed to install HeliBoard APK: $($installResult.Output)"
            }
            Write-Host "HeliBoard APK installed." -ForegroundColor Green
        }
        Enable-MumuHeliBoard $connection
        Write-Host "HeliBoard set as active default keyboard." -ForegroundColor Green

        # Step 3b: Set Lawnchair as Default Launcher (Stops host CefViewWing advertising processes)
        $installedPackages = Invoke-MumuShell $connection 'pm list packages'
        if ($installedPackages.StdOut -match 'app.lawnchair') {
            Invoke-MumuShell $connection 'cmd role add-role-holder --user 0 android.app.role.HOME app.lawnchair' | Out-Null
            Write-Host "Pre-installed Lawnchair activated as default HOME launcher." -ForegroundColor Green
        }

        # Step 4: Disable NetEase Bloatware & Adware (Preserving Cloner)
        Write-Host "`n[4/6] Disabling NetEase Bloatware & Adware packages..." -ForegroundColor Yellow
        $googleInstaller = 'com.nemu.googleinstaller'
        if (Test-MumuPackage $connection $googleInstaller) {
            Invoke-MumuShell $connection "pm uninstall -k --user 0 $googleInstaller" | Out-Null
        }

        $packagesToDisable = @(
            'com.mumu.store',
            'com.mumu.shared.sdk',
            'com.mumu.acc',
            'com.nemu.oaidmanager',
            'com.nemu.nlp',
            'com.sohu.inputmethod.sogou.chuizi',
            'com.android.chromium',
            'com.android.camera2'
        )

        foreach ($package in $packagesToDisable) {
            if (-not (Test-MumuPackage $connection $package) -or (Test-MumuPackage $connection $package -Disabled)) {
                Write-Host "  [-] $($package): Already inactive/disabled." -ForegroundColor Gray
                continue
            }
            Invoke-MumuShell $connection "am force-stop $package" | Out-Null
            Invoke-MumuShell $connection "pm disable-user --user 0 $package" | Out-Null
            if (-not (Test-MumuPackage $connection $package -Disabled)) {
                throw "Could not verify that $package is disabled."
            }
            Write-Host "  [x] $($package): Disabled." -ForegroundColor Green
        }

        if (Test-MumuPackage $connection 'com.netease.mumu.cloner') {
            Write-Host "  [i] com.netease.mumu.cloner: Protected and active." -ForegroundColor Cyan
        }

        # Step 5: In-Guest DNS Sinkhole (/system/etc/hosts)
        Write-Host "`n[5/6] Deploying In-Guest DNS Sinkhole (/system/etc/hosts)..." -ForegroundColor Yellow
        $tmpHosts = [IO.Path]::GetTempFileName()
        $remoteHosts = '/data/local/tmp/mumu_hosts_' + [guid]::NewGuid().ToString('N')
        try {
            $hostsSource = Join-Path $PSScriptRoot '..\configs\hosts'
            if (-not (Test-Path $hostsSource)) { $hostsSource = Join-Path $PSScriptRoot 'hosts' }
            $hostsText = (Get-Content -LiteralPath $hostsSource -Raw) -replace "`r`n", "`n"
            [IO.File]::WriteAllText($tmpHosts, $hostsText, (New-Object Text.UTF8Encoding($false)))
            Send-MumuVerifiedFile $connection $tmpHosts $remoteHosts
            Invoke-MumuShell $connection "cp '$remoteHosts' /system/etc/hosts" | Out-Null
            Invoke-MumuShell $connection 'chmod 644 /system/etc/hosts' | Out-Null
            $hostsHash = Invoke-MumuShell $connection 'sha256sum /system/etc/hosts'
            $expectedHash = (Get-FileHash -LiteralPath $tmpHosts -Algorithm SHA256).Hash
            if (($hostsHash.StdOut -split '\s+')[0] -ne $expectedHash) {
                throw 'Could not verify the installed hosts blocklist checksum.'
            }
            Write-Host "DNS Sinkhole deployed successfully (SHA256 verified)." -ForegroundColor Green
        } finally {
            Remove-Item -LiteralPath $tmpHosts -Force -ErrorAction SilentlyContinue
            Invoke-MumuShell $connection "rm -f '$remoteHosts'" -AllowFailure | Out-Null
        }

        # Flush guest buffers
        Invoke-MumuShell $connection 'sync' | Out-Null
    } finally {
        # Step 6: Revoke Root and lock System Disk to Read-Only unconditionally
        Write-Host "`n[6/6] Restoring Root permission to 'false' and locking System Disk to Read-Only..." -ForegroundColor Yellow
        Invoke-MumuNative $cli @('setting', '-v', [string]$VmIndex, '-k', 'root_permission', '-val', 'false', '-k', 'system_disk_readonly', '-val', 'true') -AllowFailure | Out-Null
        Write-Host "Root setting restored to 'false' and system_disk_readonly locked to 'true'." -ForegroundColor Green

        if ($ShutdownAfter) {
            Write-Host "`nShutting down VM $VmIndex..." -ForegroundColor Yellow
            Invoke-MumuNative $cli @('control', '-v', [string]$VmIndex, 'shutdown') -AllowFailure | Out-Null
            Start-Sleep -Seconds 3
            Write-Host "VM $VmIndex shutdown signal sent." -ForegroundColor Green
        }
    }

    Write-Host "`n=== OPTIMIZATION FOR VM $VmIndex COMPLETED! ===" -ForegroundColor Green
    exit 0
} catch {
    [Console]::Error.WriteLine("Optimization failed for VM $($VmIndex): $($_.Exception.Message)")
    exit 1
}
