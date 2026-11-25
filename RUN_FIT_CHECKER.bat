@echo off
setlocal enabledelayedexpansion
title Windows 11 Ollama Hardware & Model Fit Checker (v1.0)

:START
cls
echo ====================================================================
echo   WINDOWS 11 OLLAMA HARDWARE ^& MODEL FIT CHECKER (v1.0)
echo   (Portable Windows Toolkit ^| Read-Only ^| No Python or Docker)
echo ====================================================================
echo.
set "outDir=%~dp0"
set /p customOut="Save report in this toolkit folder? Press Enter for default or paste a folder path: "
set "customOut=%customOut:"=%"
if "%customOut:~-1%"=="\" set "customOut=%customOut:~0,-1%"
if not "%customOut%"=="" set "outDir=%customOut%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Check-Ollama-Fit.ps1" -OutputFolder "%outDir%"
echo.
pause
goto START
