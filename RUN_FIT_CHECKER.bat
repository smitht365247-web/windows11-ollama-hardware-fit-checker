@echo off
setlocal DisableDelayedExpansion
cd /d "%~dp0"
title Windows 11 Ollama Hardware ^& Model Fit Checker (v1.3)

:START
cls
echo ====================================================================
echo   WINDOWS 11 OLLAMA HARDWARE ^& MODEL FIT CHECKER (v1.3)
echo   (Portable Windows Toolkit ^| Read-Only ^| No Python or Docker)
echo ====================================================================
echo.
set "outDir=%~dp0."
set "customOut="
set /p "customOut=Save report in this toolkit folder? Press Enter for default or paste a folder path: "
if not defined customOut goto RUN
set "customOut=%customOut:"=%"
if not defined customOut goto RUN
call :StripSlash
if not defined customOut goto RUN
if "%customOut%"=="" goto RUN
set "outDir=%customOut%"

:RUN
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Check-Ollama-Fit.ps1" -OutputFolder "%outDir%"
echo.
pause
goto START

:StripSlash
if not defined customOut goto :eof
if "%customOut:~-1%"=="\" set "customOut=%customOut:~0,-1%"
goto :eof
