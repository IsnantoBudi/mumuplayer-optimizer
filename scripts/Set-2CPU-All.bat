@echo off
title MuMu Player 12 - Set 2 vCPU
echo ==================================================================
echo   SETTING ALL MUMU INSTANCES TO 2 vCPU (10x FLEET PRESET)
echo ==================================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0set_cpu.ps1" -Cpu 2
echo.
pause
