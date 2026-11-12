@echo off
title MuMu Player 12 - Set 3 vCPU (Audio Active)
echo ==================================================================
echo   SETTING ALL 10 MUMU INSTANCES TO 3 vCPU (SOUND ACTIVE)
echo ==================================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0set_cpu.ps1" -Cpu 3 -Audio on
echo.
pause
