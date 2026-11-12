@echo off
title MuMu Player 12 Optimization Tool (CTT-Style)
cd /d "%~dp0"

:: Set console codepage to UTF-8
chcp 65001 >nul 2>&1

:: Launch PowerShell Interactive Interface from scripts/
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\mumu_tool.ps1"

exit /b 0
