# MuMu Player 12 Optimizer & Multi-Instance Fleet Manager

[![Platform](https://img.shields.io/badge/Platform-Windows%2011%20%7C%2010-blue.svg)](https://microsoft.com/windows)
[![Emulator](https://img.shields.io/badge/Emulator-MuMu%20Player%2012%20Global-orange.svg)](https://www.mumuplayer.com/)
[![Guest OS](https://img.shields.io/badge/Android-15.0%20(VanillaIceCream)-green.svg)](https://developer.android.com)
[![Architecture](https://img.shields.io/badge/Architecture-x86__64%20%7C%20ARM64%20Trans-purple.svg)]()
[![Shell](https://img.shields.io/badge/Shell-PowerShell%205.1%2B%20%7C%20Batch-blue.svg)]()
[![License](https://img.shields.io/badge/License-MIT-emerald.svg)](LICENSE)

Tool otomasi, debloater, dan pengatur sumber daya holistik untuk **NetEase MuMu Player 12 (Android 15)** pada sistem Windows 11. Dilengkapi antarmuka konsol interaktif bergaya **CTT Tool (Chris Titus Tech Windows Utility)** untuk mengatur profil perangkat keras, koeksistensi Hyper-V & WSL2, pembersihan bloatware, proteksi storage disk, hingga peluncuran armada multi-instance bertahap.

---

## 📌 Masalah Utama yang Diselesaikan

Pada konfigurasi bawaan pabrik, menjalankan banyak instans MuMu Player 12 sering kali memicu bottleneck sistem yang parah:

1. **Hypervisor Trap ("NEM: Snail Execution Mode")**:
   Windows 11 *Virtualization-Based Security (VBS)* dan *Memory Integrity (HVCI)* memblokir akses langsung kernel driver MuMu ke hardware AMD-V (SVM), memaksa emulasi berjalan via *Native Execution Manager (NEM)*. Latensi VM-exit membengkak dari **~500 siklus menjadi >5.000 siklus** dengan clock drift jam hingga puluhan menit.
2. **Over-Alokasi RAM & vCPU (Pagefile Swap Thrashing)**:
   Alokasi default 6–8 vCPU dan 12 GB RAM per VM pada 10 instans menuntut komitmen virtual 120 GB RAM dan 68 vCPU (memicu *spinlock convoys* dan swap gila-gilaan ke SSD).
3. **Throttling GPU AMD Radeon / iGPU**:
   Proses rendering sesungguhnya (`MuMuNxDevice.exe`) tidak terdaftar di Windows Graphics Preferences, menyebabkan driver AMD PowerPlay menurunkan clock GPU ke level terendah (**400 MHz**).
4. **Bloatware & Iklan Host**:
   Launcher bawaan memicu proses web host `CefViewWing.exe` (~150 MB RAM host per instans) dan aplikasi internal rakus memori seperti Sogou Chinese IME dan alarm Google Play Services liar.
5. **Duplikasi Storage SSD (Bug `system_disk_readonly`)**:
   Status disk sistem yang tidak terkunci (*writable*) memaksa tiap instans menduplikasi puluhan gigabyte *Copy-On-Write* disk yang mubazir.

---

## 🚀 Fitur Unggulan

- **🖥️ All-in-One Interactive CLI (`mumu_tool.bat`)**: Antarmuka menu konsol tunggal untuk mengendalikan semua fungsi optimasi secara terpadu.
- **⚡ Presets Hardware Fleksibel**:
  - **Preset Responsif (3–4 Instans)**: 3 vCPU · 4 GB RAM · Vulkan · 30 FPS · Suara Aktif.
  - **Preset Skala Penuh (10 Instans)**: 2 vCPU · 3 GB RAM · Vulkan · Cap 30/15 FPS · Zero Swap Thrashing.
  - **Preset Solo Peak Gaming**: 4 vCPU · 6 GB RAM · Vulkan · 120 FPS.
- **🛡️ Koeksistensi Aman Hyper-V & WSL2 (Opsi B)**:
  - Mematikan overhead inspeksi HVCI (*Memory Integrity*) tanpa merusak instalasi WSL2/Docker.
  - Mengunci konsumsi memori WSL2 maksimal **3 GB** (`.wslconfig`) agar tidak saling berebut RAM fisik.
- **🧹 Debloat Tamu Android 15 & Sinkhole DNS**:
  - Mengaktifkan keyboard FOSS **HeliBoard** (otomatis unduh dari rilis resmi jika belum ada).
  - Mengaktifkan **Lawnchair** sebagai launcher default via Android Role Manager (menghentikan proses iklan host `CefViewWing.exe`).
  - Memasang DNS Sinkhole (`/system/etc/hosts`) untuk memblokir 22 domain analitik & iklan NetEase.
  - **100% Aman untuk Google Sign-In**: Komponen autentikasi Google Play Services & Play Store tetap aktif dan aman untuk login akun Google (misal: aplikasi REALITY).
- **💾 Shared Master Base Disk & Kompaksi VDI**:
  - Mengunci `system_disk_readonly = true` sehingga 10 instans berbagi 1 base image `system.vdi` (menghemat 40–50 GB SSD).
  - Skrip kompaksi VDI (`vbox-img.exe compact`) untuk membersihkan sisa blok data tak terpakai.
- **⏱️ Staggered Fleet Launch (Anti Boot-Storm)**:
  - Menyalakan 10 VM dengan jeda berkala 12 detik antar instans agar APU laptop 15W tidak tercekik *thermal throttling*.

---

## 📁 Struktur Repositori

```text
mumuplayer-optimizer/
│
├── mumu_tool.bat               # Launcher Utama All-in-One 1-Klik
├── README.md                   # Dokumentasi Utama
├── LICENSE                     # Lisensi Open Source MIT
├── .gitignore                  # Filter Kebersihan Git
│
├── configs/                    # Berkas Konfigurasi & Blocklist
│   ├── hosts                   # DNS Sinkhole Telemetri & Ad Blocklist
│   └── .wslconfig.example      # Template Batas Memori WSL2 (3 GB)
│
├── scripts/                    # Skrip Otomasi PowerShell & Batch
│   ├── mumu_tool.ps1           # Engine Menu Interaktif CTT-Style
│   ├── set_cpu.ps1             # Skrip Pengubah vCPU, RAM, dan Audio
│   ├── apply_option_b.ps1      # Skrip Setup Host OS & WSL2 Capping
│   ├── Run_As_Admin_Option_B.bat # Otomasi Registry HKLM (HVCI & IFEO)
│   ├── run_batch_debloat.ps1   # Orkestrator Batch Debloat Armada VM
│   ├── run_debloat_vm.ps1      # Pipeline Debloat per Instans (Root -> ADB -> Lock)
│   ├── mumu_common.ps1         # Pustaka Helper MuMu-CLI & ADB Wrapper
│   ├── mumu_debloater.ps1      # Standalone Quick Debloater
│   ├── launch_staggered_fleet.ps1 # Peluncur 10 Instans dengan Jeda 12s
│   ├── Set-3CPU-4GB.bat        # Shortcut Cepat 3 vCPU / 4 GB RAM
│   ├── Set-3CPU-All.bat        # Shortcut Cepat 3 vCPU
│   └── Set-2CPU-All.bat        # Shortcut Cepat 2 vCPU
│
└── docs/                       # Laporan Riset & Debat Lintas Insinyur
    ├── MUMU_OPTIMIZATION_CONSENSUS_REPORT.md # Laporan Konsensus Lengkap (953 Baris)
    └── PROJECT.md              # Roadmap Arsitektur & Pelacakan Fase Proyek
```

---

## ⚡ Panduan Memulai Cepat (Quick Start)

### 1. Menjalankan Tool Interaktif (Direkomendasikan)
Cukup klik ganda file **`mumu_tool.bat`** di folder root untuk membuka antarmuka konsol:

```text
================================================================================
          MUMU PLAYER 12 ALL-IN-ONE OPTIMIZATION TOOL (CTT-STYLE)                
================================================================================
  Host OS       : Windows 11 (AMD Ryzen 7 5825U · 40GB RAM · Vega 8 iGPU)
  Power Plan    : Ultimate Performance | WSL2 Budget: Active (3GB Limit)
  Active Fleet  : 0 Instance(s) running | Current Spec: 3 vCPU / 4 GB / Audio: Active
--------------------------------------------------------------------------------

  [ HARDWARE SIZING PRESETS ]
    [1] Preset Responsif (3 vCPU / 4 GB RAM / Suara Aktif)  -> Optimal 3-4 Instans
    [2] Preset 10x Fleet (2 vCPU / 3 GB RAM / 30-15 FPS)    -> Skala Penuh 10 Instans
    [3] Preset Solo Peak Gaming (4 vCPU / 6 GB RAM / 120 FPS)-> Main Game Berat 1 VM
    [4] Kustomisasi Bebas (Input vCPU & RAM manual)

  [ AUDIO & MULTIMEDIA ]
    [5] Aktifkan Suara di Seluruh Instans (Unmute All)
    [6] Bisukan Suara di Seluruh Instans (Mute All)

  [ HOST & SYSTEM TWEAKS ]
    [7] Terapkan Optimasi Host (WSL2 3GB Limit, GPU High Pref, Ultimate Power)
    [8] Buka Administrator Tweaks (Matikan HVCI & Set IFEO High Priority)
    [9] Bersihkan Cache Iklan Host MuMu (ProgramAds Wipe & Lock)

  [ ANDROID MAINTENANCE & STORAGE ]
    [10] Jalankan Batch Debloat Android 15 (HeliBoard, Lawnchair, Sinkhole DNS)
    [11] Kompaksi Virtual Disk VDI (Bebaskan 20-40 GB Ruang SSD)

  [ FLEET LIFECYCLE MANAGEMENT ]
    [12] Luncurkan 10 Instans Bertahap (Jeda 12 detik aman boot-storm)
    [13] Matikan Bersih Seluruh Instans yang Sedang Berjalan

  [0] Keluar
--------------------------------------------------------------------------------
```

### 2. Mengubah Alokasi Hardware via Terminal PowerShell
Anda juga dapat menjalankan skrip modular langsung dari terminal:

```powershell
# Mengubah semua instans ke 3 vCPU dan 4 GB RAM dengan suara aktif:
.\scripts\set_cpu.ps1 -Cpu 3 -RamGB 4 -Audio on

# Mengubah hanya instans tertentu (misal VM 14, 15, 16):
.\scripts\set_cpu.ps1 -Cpu 3 -RamGB 4 -VmIndices 14,15,16

# Mengembalikan semua instans ke mode 10x Fleet (2 vCPU / 3 GB RAM):
.\scripts\set_cpu.ps1 -Cpu 2 -RamGB 3 -Audio on
```

---

## 📊 Matriks Perbandingan Performa

Berdasarkan pengujian pada laptop **AMD Ryzen 7 5825U (8C/16T, 15W TDP), RAM 40 GB DDR4, AMD Radeon Vega 8 iGPU**:

| Metrik / Parameter | Sebelum Optimasi | Target Multi-Instance (10x) | Preset Responsif (3–4 VM) |
| :--- | :--- | :--- | :--- |
| **Virtualization Mode** | VirtualBox NEM (*Snail Mode*) | WHPX (*HVCI Off*) / Native SVM | WHPX (*HVCI Off*) |
| **VM-Exit Latency** | 3.200 – 7.500 cycles | **~2.500 cycles** | **~2.500 cycles** |
| **vCPU per Instance** | 6–8 vCPU (68 vCPU total) | **2 vCPU** (20 vCPU total) | **3 vCPU** (9–12 vCPU total) |
| **RAM per Instance** | 12 GB (120 GB total) | **3 GB** (30,72 GB total) | **4 GB** (12–16 GB total) |
| **Pagefile Swap SSD** | Kritis (*Commit Limit Exhaustion*) | **0 MB (100% RAM Fisik)** | **0 MB (100% RAM Fisik)** |
| **Clock GPU Vega 8** | Throttled ke **400 MHz** | **Boost hingga 2.000 MHz** | **Boost hingga 2.000 MHz** |
| **Frame Rate Policy** | Tidak stabil / Drop | **30 FPS Aktif / 15 FPS BG** | **30–60 FPS** |
| **Audio Background** | 10 stream aktif bertabrakan | **Muted pada background VM** | **Aktif / Sesuai Pilihan** |
| **Storage Disk Sistem** | Duplikasi 10x (*Writable*) | **Shared Base Disk (`readonly`)** | **Shared Base Disk (`readonly`)** |

---

## ⚙️ Penjelasan Mode Virtualisasi: Opsi A vs Opsi B

| Kategori | Opsi A: Dual-Boot BCD (Native AMD-V) | Opsi B: Coexistence (Hyper-V + HVCI Off) |
| :--- | :--- | :--- |
| **Akses Virtualisasi** | Direct Bare-Metal SVM (Ring -1) | Type-1 Hyper-V via API WHPX |
| **Latensi VM-Exit** | Terendah (~500 cycles) | Sedang (~2.500 cycles) |
| **Status WSL2 / Docker** | Nonaktif pada sesi boot tersebut | **Tetap aktif normal bersamaan** |
| **Pergantian Mode** | Perlu restart PC (pilih menu boot) | **Tanpa restart (Seamless)** |
| **Rekomendasi** | Gaming kompetitif / Emulasi berat 100% | **Developer yang butuh Docker + MuMu** |

> Repositori ini secara default mengadopsi **Opsi B** untuk menjaga alur kerja pemrograman harian pengguna tetap utuh tanpa friksi reboot.

---

## 🔒 Catatan Keamanan & Kompatibilitas Login Google

- **Autentikasi Google Play Sign-In**: Paket `com.google.android.gms` dan `com.android.vending` sengaja **tidak dihapus** agar game atau aplikasi streaming seperti **REALITY** (`net.wrightflyer.le.reality`) dapat melakukan login dengan akun Google secara lancar tanpa kode error `12500`.
- **Pencadangan Kunci BitLocker**: Jika ingin memodifikasi BCD Windows (Opsi A), pastikan mencadangkan 48-digit Recovery Key terlebih dahulu melalui perintah `manage-bde -protectors -get C:`.

---

## 👤 Penulis & Lisensi

- **Pengembang**: [Isnanto Budi Nurrahman](https://github.com/IsnantoBudi)
- **Lisensi**: Dirilis di bawah lisensi terbuka [MIT License](LICENSE). Bebas digunakan, dimodifikasi, dan didistribusikan kembali.
