# Windows 11 Ollama Hardware & Model Fit Checker (Portable)

**Free, 100% offline, zero-install Windows 10/11 PowerShell hardware & Ollama pre-flight checker.** Inspects your 64-bit GPU VRAM, system RAM ceiling, and live `localhost:11434` Ollama API to print max safe GGUF quantization tiers (`Q8_0` through `Q2_K`) for 7B, 14B, and 32B/35B models - no Python or Docker required.

- **Verified Release ZIP (Gumroad `$0+`):** https://smitht365.gumroad.com/l/rkhkom
- **GitHub Releases:** https://github.com/smitht365247-web/windows11-ollama-hardware-fit-checker/releases

## Quick Start
1. Download the latest verified ZIP from [GitHub Releases](https://github.com/smitht365247-web/windows11-ollama-hardware-fit-checker/releases) or [Gumroad](https://smitht365.gumroad.com/l/rkhkom).
2. Right-click the `.zip` -> **Properties** -> check **Unblock** -> **Apply / OK**, then extract.
3. Double-click `RUN_FIT_CHECKER.bat` to view your hardware fit report and GGUF quantization recommendations.

## Free Scanner vs. Paid Pro Toolkit
| Capability | Hardware Fit Checker (`$0+` Free) | [Ollama 1-Click Command Center (`$19`)](https://smitht365.gumroad.com/l/lfbyfh) | [3-in-1 Local AI Suite (`$29`, Save `$28`)](https://smitht365.gumroad.com/l/pfsgkz) |
| :--- | :---: | :---: | :---: |
| 64-bit VRAM, RAM ceiling & GGUF quant estimator | Yes | Yes | Yes |
| 1-click health/repair wizard & tokens/sec benchmark | - | Yes | Yes |
| Safe reversible `OLLAMA_MODELS` drive mover & folder summarizer | - | Yes | Yes |
| Plus Local Whisper Studio + MCP Config Manager | - | - | Yes |

## Windows SmartScreen Unblock Note
Because `.bat` and `.ps1` scripts downloaded from the internet are unsigned, Windows SmartScreen may show *"Windows protected your PC"* on first run:
- **Option A:** Click **More info** -> **Run anyway**.
- **Option B:** Right-click the `.zip` before extracting -> **Properties** -> check **Unblock** -> **Apply / OK** -> extract.
## More Free Windows 11 PowerShell Tools (100% Offline, Zero-Install)
- **Ollama Hardware & Model Fit Checker** - [GitHub](https://github.com/smitht365247-web/windows11-ollama-hardware-fit-checker) | [Gumroad ($0+)](https://smitht365.gumroad.com/l/rkhkom)
- **Local AI Storage Auditor** - [GitHub](https://github.com/smitht365247-web/Win11-Local-AI-Storage-Auditor) | [Gumroad ($0+)](https://smitht365.gumroad.com/l/zhagpn)
- **MCP Config Health Scanner** - [GitHub](https://github.com/smitht365247-web/windows11-mcp-agent-config-scanner) | [Gumroad ($0+)](https://smitht365.gumroad.com/l/ofxozx)
- **Secret & Hardcoded Path Leak Scanner** - [GitHub](https://github.com/smitht365247-web/Win11-Secret-Path-Leak-Scanner) | [Gumroad ($0+)](https://smitht365.gumroad.com/l/aaymt)
- **Local Whisper Preflight Checker** - [GitHub](https://github.com/smitht365247-web/windows11-whisper-preflight-checker) | [Gumroad ($0+)](https://smitht365.gumroad.com/l/inttob)
- **Single-Folder SHA-256 Hash Checker** - [GitHub](https://github.com/smitht365247-web/windows11-sha256-hash-checker) | [Gumroad ($0+)](https://smitht365.gumroad.com/l/olkmxs)
- **Bloat, Telemetry & Privacy Scanner** - [GitHub](https://github.com/smitht365247-web/windows11-bloat-privacy-scanner) | [Gumroad ($0+)](https://smitht365.gumroad.com/l/fydryu)

Browse all 15 portable Windows 10/11 toolkits & bundles: https://smitht365.gumroad.com
