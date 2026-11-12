# Project: MuMu Player 12 / Android 15 Holistic Optimization & Multi-Instance Tuning

## Architecture
- **Host Platform**: Windows 11 Home Single Language (Build 26200), AMD Ryzen 7 5825U (8C/16T Zen 3, 15W TDP, 16MB L3 Cache), 40 GB Physical RAM (DDR4-3200 Flex Mode: 16 GB Dual-Channel + 24 GB Single-Channel), AMD Radeon Vega 8 iGPU (2 GB dedicated VRAM, shared UMA), Samsung PM991a 512 GB NVMe SSD.
- **Virtualization Engine**: Oracle VirtualBox 7.2.4_OSE customized by NetEase (`MuMuNxVbox`) with ring-0 support driver `MuMuNxSup.sys`. Currently trapped in NEM (Native Execution Manager / WHPX) "Snail execution mode" due to Windows Virtualization-Based Security (VBS/HVCI) and WSL2.
- **Guest OS**: NetEase MuMu Player 12 Global (version 6.8.9.0) running Android 15 (VanillaIceCream, API Level 35 64-bit) on Linux kernel 6.1.90 with `libnb.so` dynamic ARM64-to-x86_64 translation bridge.
- **Workload**: REALITY avatar livestreaming (`net.wrightflyer.le.reality` v26.41.0, Unity 3D engine) across up to 10 instances (`MuMuPlayerGlobal-15.0-14` through `23`).

## Feature Inventory
| # | Feature / Issue Area | Description | Milestone | Source |
|---|----------------------|-------------|-----------|--------|
| 1 | Hypervisor & Virtualization Tuning | Reclaim direct AMD-V (SVM) hardware execution or optimize WHPX coexistence mode, eliminating "Snail execution mode" (15-35% CPU penalty). | M1, M2 | Survey 1, 3 |
| 2 | Memory Right-Sizing & Pagefile Protection | Correct gross over-allocation (12 GB -> 3-4 GB per instance) to eliminate host virtual commit exhaustion and SSD swap thrashing. | M1, M2 | Survey 1, 2, 3 |
| 3 | CPU Thread & Scheduler Tuning | Downsize vCPUs from 6-8 vCPUs to 2-3 vCPUs per instance, keeping total vCPUs <= 1.25x host threads (20 vCPUs for 10 instances) to eliminate core contention and thermal throttling. | M1, M2 | Survey 1, 2, 3 |
| 4 | Graphics Renderer & GPU Registration | Maintain Vulkan backend (`vk`), register `MuMuNxDevice.exe` in Windows Graphics High Performance preferences (`GpuPreference=2`), and tune texture policies. | M1, M2 | Survey 1, 2, 3 |
| 5 | Power Plan & OS Optimization | Switch Windows Power Plan from Balanced to Ultimate Performance; tune process priority and timer resolution. | M1, M2 | Survey 1, 3 |
| 6 | Android Guest Debloating | Disable Sogou Chinese IME (105 MB RSS), configure HeliBoard/Lawnchair, freeze unneeded GMS background daemons, deploy ad/telemetry DNS sinkhole. | M1, M2 | Survey 2, 3 |
| 7 | Storage, Shared Disk & VDI Compaction | Restore `system_disk_readonly = true` for shared base image savings; execute `vbox-img compact` to reclaim 25-40 GB disk space. | M1, M2 | Survey 2, 3 |
| 8 | Multi-Instance Concurrency & Background Limits | Cap active instances at 30 FPS, background instances at 15 FPS, mute background audio, configure deterministic ADB management ports (`16384 + index * 32`). | M1, M2 | Survey 2, 3 |
| 9 | Single vs Multi-Instance Configuration Profiles | Deliver explicit, production-ready configuration matrices for both Single-Instance Peak Gaming (120 FPS) and 10x Multi-Instance Farming. | M2, M3 | Survey 3 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M0 | Survey & System Inspection | Collect hardware specs, VBox logs, instance configs, ADB dumps, and community benchmarks. | None | DONE |
| M1 | Multi-Role Technical Debate & Cross-Examination | 4-way debate: Virtualization Specialist vs Android Debloat Engineer vs Graphics Tuner vs Multi-Instance Architect. | M0 | DONE |
| M2 | Consensus Synthesis & Actionable Implementation Plan | Synthesize unanimous engineering consensus report with concrete CLI commands, registry scripts, and ADB debloat pipelines. | M1 | DONE |
| M3 | Quality Review & Verification Audit | Verify technical accuracy, command syntax, safety caveats, and layout conformance. | M2 | DONE |

## Interface Contracts
### M1 ↔ M2 (Debate Handoff to Synthesis Worker)
- M1 produces `DEBATE_FINDINGS.md` synthesizing the arguments, rebuttals, trade-offs, and agreed parameters across all four engineering domains.
- M2 ingests `DEBATE_FINDINGS.md` and generates `MUMU_OPTIMIZATION_CONSENSUS_REPORT.md` with copy-paste runnable PowerShell/ADB commands and JSON configuration snippets.

## Code & Artifact Layout
- `PROJECT.md` — Global architecture, feature inventory, milestones, and status.
- `.agents/teamwork/orchestrator_1/` — Orchestrator BRIEFING.md, progress.md, DISPATCH.md.
- `.agents/teamwork/explorer_survey_1/handoff.md` — Host & Virtualization Survey.
- `.agents/teamwork/explorer_survey_2/handoff.md` — MuMu Instance & Config Survey.
- `.agents/teamwork/explorer_survey_3/handoff.md` — Community Docs & Benchmarks Survey.
- `.agents/teamwork/debate_virtualization/handoff.md` — Virtualization Specialist Position.
- `.agents/teamwork/debate_debloat/handoff.md` — Android Debloat Specialist Position.
- `.agents/teamwork/debate_graphics/handoff.md` — Graphics & Vulkan Tuner Position.
- `.agents/teamwork/debate_multi_instance/handoff.md` — Multi-Instance Architect Position.
- `MUMU_OPTIMIZATION_CONSENSUS_REPORT.md` — Final User-Facing Consensus Optimization Report.
