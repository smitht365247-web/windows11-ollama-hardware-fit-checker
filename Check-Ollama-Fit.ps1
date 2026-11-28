<#
.SYNOPSIS
    Hardened v1.3: Inspects Windows 10/11 RAM, 64-bit GPU VRAM (NVIDIA / AMD / Intel Arc),
    disk space, Ollama server reachability (/api/version & /api/ps), model fit tier,
    and RAM-ceiling / GGUF quantization tier recommendations (7B, 14B, 32B/35B).
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

function Get-MaxGgufQuantTier {
    param(
        [double]$BudgetGB,
        [string]$ModelClass
    )
    $tiers = @()
    if ($ModelClass -eq "7B") {
        $tiers = @(
            @{ Name = "Q8_0";   ReqGB = 9.5 },
            @{ Name = "Q6_K";   ReqGB = 7.5 },
            @{ Name = "Q5_K_M"; ReqGB = 6.5 },
            @{ Name = "Q4_K_M"; ReqGB = 5.5 },
            @{ Name = "Q3_K_M"; ReqGB = 4.5 },
            @{ Name = "Q2_K";   ReqGB = 3.8 }
        )
    } elseif ($ModelClass -eq "14B") {
        $tiers = @(
            @{ Name = "Q8_0";   ReqGB = 17.5 },
            @{ Name = "Q6_K";   ReqGB = 14.0 },
            @{ Name = "Q5_K_M"; ReqGB = 12.0 },
            @{ Name = "Q4_K_M"; ReqGB = 10.5 },
            @{ Name = "Q3_K_M"; ReqGB = 8.5 },
            @{ Name = "Q2_K";   ReqGB = 7.0 }
        )
    } else {
        $tiers = @(
            @{ Name = "Q8_0";   ReqGB = 38.0 },
            @{ Name = "Q6_K";   ReqGB = 30.0 },
            @{ Name = "Q5_K_M"; ReqGB = 26.0 },
            @{ Name = "Q4_K_M"; ReqGB = 22.0 },
            @{ Name = "Q3_K_M"; ReqGB = 18.0 },
            @{ Name = "Q2_K";   ReqGB = 14.5 }
        )
    }
    foreach ($t in $tiers) {
        if ($BudgetGB -ge $t.ReqGB) {
            return ("{0} (~{1} GB est. incl. KV cache)" -f $t.Name, $t.ReqGB)
        }
    }
    return "Exceeds safe memory ceiling"
}

Write-Host "Checking system memory, 64-bit GPU VRAM, GGUF quantization ceilings, and Ollama status..." -ForegroundColor Cyan

$cs = Get-CimInstance -ClassName Win32_ComputerSystem
$totalRamGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)

$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
$freeRamGB = 0.0
if ($os -and $null -ne $os.FreePhysicalMemory) {
    $freeRamGB = [math]::Round(($os.FreePhysicalMemory * 1KB) / 1GB, 2)
}

$gpuSummary = @()
$maxVramGB = 0.0
$hasIntegratedGpu = $false

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
            $subKeys = @(Get-ChildItem -LiteralPath $regBase -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' })
            foreach ($sk in $subKeys) {
                $props = Get-ItemProperty -LiteralPath $sk.PSPath -ErrorAction SilentlyContinue
                $mId = if ($props -and $props.PSObject.Properties['MatchingDeviceId']) { [string]$props.MatchingDeviceId } else { "" }
                $dId = [string]$ad.PNPDeviceID
                if ($mId -and ($dId -like "*$($mId.Split('\')[-1])*")) {
                    if ($props.PSObject.Properties['HardwareInformation.qwMemorySize'] -and $null -ne $props.'HardwareInformation.qwMemorySize') {
                        $qwGB = [math]::Round(([double]$props.'HardwareInformation.qwMemorySize') / 1GB, 2)
                        break
                    }
                }
            }
        }
        $dacType = if ($ad.PSObject.Properties['AdapterDACType'] -and $null -ne $ad.AdapterDACType) { [string]$ad.AdapterDACType } else { "" }
        $isIntegrated = ($qwGB -lt 1.0) -or ($dacType -ieq "Internal")
        if (-not $isIntegrated) {
            if ($qwGB -gt $maxVramGB) { $maxVramGB = $qwGB }
            $gpuSummary += "$name ($qwGB GB dedicated VRAM via Registry)"
        } else {
            $hasIntegratedGpu = $true
            $gpuSummary += "$name (integrated/shared GPU memory via system RAM)"
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
    if ($verResp -and $verResp.PSObject.Properties['version']) { $ollamaVersion = $verResp.version }
} catch { $apiReachable = $false }

if ($apiReachable) {
    try {
        $psResp = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/ps" -TimeoutSec 2 -ErrorAction Stop
        if ($psResp -and $psResp.PSObject.Properties['models'] -and $psResp.models) {
            foreach ($m in $psResp.models) {
                $mName = if ($m.PSObject.Properties['name']) { [string]$m.name } else { "unknown" }
                if ($m.PSObject.Properties['size_vram'] -and $null -ne $m.size_vram) {
                    $loadedModels += "$mName (size_vram: $([math]::Round(([double]$m.size_vram) / 1GB, 2)) GB)"
                } else {
                    $loadedModels += "$mName (size_vram: N/A)"
                }
            }
        }
    } catch { }
}

$safeRamCeilingGB = [math]::Round([math]::Max(0.0, ($totalRamGB - 4.0)), 2)
$effectiveHybridBudgetGB = [math]::Round(($safeRamCeilingGB + $maxVramGB), 2)
$gpuBudgetGB = if ($maxVramGB -gt 0) { [math]::Round([math]::Max(0.0, ($maxVramGB - 0.5)), 2) } elseif ($hasIntegratedGpu) { [math]::Round(($totalRamGB * 0.5), 2) } else { 0.0 }
$gpuBudgetLabel = if ($maxVramGB -gt 0) { "Full-GPU Offload ($gpuBudgetGB GB usable VRAM)" } elseif ($hasIntegratedGpu) { "Shared iGPU Budget (~$gpuBudgetGB GB max shared)" } else { "No Dedicated GPU Detected" }

$quant7BGpu  = Get-MaxGgufQuantTier -BudgetGB $gpuBudgetGB -ModelClass "7B"
$quant14BGpu = Get-MaxGgufQuantTier -BudgetGB $gpuBudgetGB -ModelClass "14B"
$quant32BGpu = Get-MaxGgufQuantTier -BudgetGB $gpuBudgetGB -ModelClass "32B"

$quant7BHybrid  = Get-MaxGgufQuantTier -BudgetGB $effectiveHybridBudgetGB -ModelClass "7B"
$quant14BHybrid = Get-MaxGgufQuantTier -BudgetGB $effectiveHybridBudgetGB -ModelClass "14B"
$quant32BHybrid = Get-MaxGgufQuantTier -BudgetGB $effectiveHybridBudgetGB -ModelClass "32B"

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
    "WINDOWS 11 OLLAMA HARDWARE & MODEL FIT REPORT (v1.3)",
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "------------------------------------------------------------",
    "System RAM:             $totalRamGB GB (Free now: $freeRamGB GB)",
    "Safe RAM Ceiling:       $safeRamCeilingGB GB (reserving 4 GB for Windows)",
    "GPU Summary:            $($gpuSummary -join ' | ')",
    "Max Dedicated VRAM:     $maxVramGB GB",
    "Hybrid RAM+VRAM Budget: $effectiveHybridBudgetGB GB",
    "OLLAMA_MODELS Path:     $modelsPath",
    "Target Drive Free:      $freeGB GB",
    "Ollama CLI Found:       $(if ($ollamaCli) { $ollamaCli.Source } else { 'Not found in PATH' })",
    "API (11434) Active:     $apiReachable (version: $ollamaVersion)",
    "Loaded Models:          $(if ($loadedModels.Count -gt 0) { $loadedModels -join '; ' } else { 'None currently loaded' })",
    "------------------------------------------------------------",
    "RAM-CEILING & GGUF QUANTIZATION ESTIMATOR (4K Context)",
    "  GPU Mode ($gpuBudgetLabel):",
    "    7B  Model: $quant7BGpu",
    "    14B Model: $quant14BGpu",
    "    32B/35B:   $quant32BGpu",
    "  CPU + RAM Hybrid Ceiling ($effectiveHybridBudgetGB GB):",
    "    7B  Model: $quant7BHybrid",
    "    14B Model: $quant14BHybrid",
    "    32B/35B:   $quant32BHybrid",
    "------------------------------------------------------------",
    "Recommended Fit:        $fitTier",
    "Guidance:               $fitNote"
)

$lines | Set-Content -LiteralPath $reportFile -Encoding UTF8
$lines | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "Saved report to: $reportFile" -ForegroundColor Green
