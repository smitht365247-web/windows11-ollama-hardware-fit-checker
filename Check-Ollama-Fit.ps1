<#
.SYNOPSIS
    Hardened v1.2: Inspects Windows 10/11 RAM, 64-bit GPU VRAM (NVIDIA / AMD / Intel Arc),
    disk space, Ollama server reachability (/api/version & /api/ps), and model fit tier.
#>
[CmdletBinding()]
param([string]$OutputFolder = $PSScriptRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($OutputFolder -match '^[A-Za-z]:$') { $OutputFolder += '\' }
if (-not (Test-Path -LiteralPath $OutputFolder -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}
$OutputFolder = (Resolve-Path -LiteralPath $OutputFolder).ProviderPath

Write-Host "Checking system memory, 64-bit GPU VRAM, and Ollama status..." -ForegroundColor Cyan

$cs = Get-CimInstance -ClassName Win32_ComputerSystem
$totalRamGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)

$gpuSummary = @()
$maxVramGB = 0.0

$nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if ($nvidiaSmi) {
    try {
        $smiLines = @(& nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>$null)
        if ($LASTEXITCODE -eq 0) {
            foreach ($line in $smiLines) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                $parts = $line -split ","
                $gName = $parts[0].Trim()
                $vramMB = 0.0
                if ([double]::TryParse($parts[1].Trim(), [ref]$vramMB)) {
                    $vramGB = [math]::Round($vramMB / 1024.0, 2)
                    if ($vramGB -gt $maxVramGB) { $maxVramGB = $vramGB }
                    $gpuSummary += "$gName ($vramGB GB VRAM via nvidia-smi)"
                }
            }
        }
    } catch { }
}

if ($gpuSummary.Count -eq 0) {
    $regBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    $adapters = @(Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue)
    foreach ($ad in $adapters) {
        $name = $ad.Name
        $qwGB = 0.0
        if ($ad.PNPDeviceID) {
            $subKeys = @(Get-ChildItem -Path $regBase -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' })
            foreach ($sk in $subKeys) {
                $props = Get-ItemProperty -Path $sk.PSPath -ErrorAction SilentlyContinue
                $mId = if ($props.PSObject.Properties['MatchingDeviceId']) { [string]$props.MatchingDeviceId } else { "" }
                $dId = [string]$ad.PNPDeviceID
                if ($mId -and ($dId -like "*$($mId.Split('\')[-1])*")) {
                    if ($props.PSObject.Properties['HardwareInformation.qwMemorySize'] -and $null -ne $props.'HardwareInformation.qwMemorySize') {
                        $qwGB = [math]::Round(([double]$props.'HardwareInformation.qwMemorySize') / 1GB, 2)
                        break
                    }
                }
            }
        }
        if ($qwGB -gt 0) {
            if ($qwGB -gt $maxVramGB) { $maxVramGB = $qwGB }
            $gpuSummary += "$name ($qwGB GB dedicated VRAM via Registry)"
        } else {
            $gpuSummary += "$name (dedicated VRAM not reported by driver; shared iGPU RAM excluded)"
        }
    }
}

$modelsPath = if ($env:OLLAMA_MODELS) { $env:OLLAMA_MODELS } else { Join-Path $env:USERPROFILE ".ollama\models" }
$driveRoot = [System.IO.Path]::GetPathRoot($modelsPath)
$freeGB = "N/A"
if ($driveRoot -match '^[A-Za-z]:\\$' -and (Test-Path -LiteralPath $driveRoot)) {
    $psDrive = Get-PSDrive -Name ($driveRoot.Substring(0, 1)) -ErrorAction SilentlyContinue
    if ($psDrive -and $null -ne $psDrive.Free) {
        $freeGB = [math]::Round($psDrive.Free / 1GB, 2)
    }
}

$ollamaCli = Get-Command ollama -ErrorAction SilentlyContinue
$apiReachable = $false
$ollamaVersion = "N/A"
$loadedModels = @()
try {
    $verResp = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/version" -TimeoutSec 2 -ErrorAction Stop
    $apiReachable = $true
    if ($verResp.PSObject.Properties['version']) { $ollamaVersion = $verResp.version }
    $psResp = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/ps" -TimeoutSec 2 -ErrorAction Stop
    if ($psResp.PSObject.Properties['models'] -and $psResp.models) {
        foreach ($m in $psResp.models) {
            $loadedModels += "$($m.name) (size_vram: $([math]::Round($m.size_vram / 1GB, 2)) GB)"
        }
    }
} catch { $apiReachable = $false }

$fitTier = "CPU / Entry Models (3B-4B quantized, e.g., Q4_K_M)"
$fitNote = "Keep context small (2048-4096 tokens) and avoid heavy concurrent models."
if ($maxVramGB -ge 16 -or $totalRamGB -ge 32) {
    $fitTier = "Mid-to-Large Models (14B-32B quantized depending on VRAM/RAM split)"
    $fitNote = "Check loaded GPU vs. CPU split via /api/ps; models exceeding VRAM offload to RAM."
} elseif ($maxVramGB -ge 8 -or $totalRamGB -ge 16) {
    $fitTier = "Balanced Local Models (7B-8B / 9B quantized, e.g., Q4_K_M)"
    $fitNote = "Fits comfortably on 8 GB+ VRAM or 16 GB+ system RAM with moderate context."
}

$reportFile = Join-Path $OutputFolder ("ollama_fit_report_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$lines = @(
    "WINDOWS 11 OLLAMA HARDWARE & MODEL FIT REPORT (v1.2)",
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "------------------------------------------------------------",
    "System RAM:          $totalRamGB GB",
    "GPU Summary:         $($gpuSummary -join ' | ')",
    "Max Dedicated VRAM:  $maxVramGB GB",
    "OLLAMA_MODELS Path:  $modelsPath",
    "Target Drive Free:   $freeGB GB",
    "Ollama CLI Found:    $(if ($ollamaCli) { $ollamaCli.Source } else { 'Not found in PATH' })",
    "API (11434) Active:  $apiReachable (version: $ollamaVersion)",
    "Loaded Models:       $(if ($loadedModels.Count -gt 0) { $loadedModels -join '; ' } else { 'None currently loaded' })",
    "------------------------------------------------------------",
    "Recommended Fit:     $fitTier",
    "Guidance:            $fitNote"
)

$lines | Set-Content -LiteralPath $reportFile -Encoding UTF8
$lines | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "Saved report to: $reportFile" -ForegroundColor Green
