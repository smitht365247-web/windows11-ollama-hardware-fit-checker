# Windows 11 Ollama Hardware & Model Fit Checker (Free, Portable)

A lightweight, read-only Windows 10/11 utility that checks your **system RAM, 64-bit GPU VRAM, free disk space, and local Ollama (`localhost:11434`) status**, then recommends exact Ollama models that fit your PC—no Python, Docker, or coding required.

## Features
- **1-Click Portable Launcher (`RUN_FIT_CHECKER.bat`):** Just unzip and double-click.
- **64-Bit VRAM Detection:** Avoids the Windows 4 GB WMI `AdapterRAM` cap so modern 8–24 GB GPUs report accurately.
- **Native Windows PowerShell:** Zero Python, Docker, or third-party app installs required.

## Quick Start
1. Click **Code -> Download ZIP** (or grab the free pre-packaged ZIP on [Gumroad](https://smitht365.gumroad.com/l/rkhkom)).
2. Extract the ZIP folder to your PC (e.g., `C:\Tools\Ollama-Hardware-Fit-Checker`).
3. Double-click `RUN_FIT_CHECKER.bat` to run the hardware and Ollama fit report.

## Windows SmartScreen Unblock Instructions
Because `.bat` and `.ps1` files downloaded from the internet are unsigned, Windows SmartScreen may show *"Windows protected your PC"* on the first run:
- Click **More info** -> **Run anyway**, **OR**
- Right-click the downloaded `.zip` file **before extracting** -> **Properties** -> check **Unblock** -> **Apply / OK**, then extract.

## Want 1-Click Ollama Management, Safe Drive Migration & Offline Summarization?
Upgrade to the **[Windows 11 Ollama 1-Click Command Center ($19 on Gumroad)](https://smitht365.gumroad.com/l/lfbyfh)** — portable Windows 10/11 suite featuring:
- **1-Click Health & Safe Repair Wizard** (diagnose and fix Ollama service, storage, and API issues)
- **Live HTTP API Tokens/Sec Benchmark** (accurate load & generation speed via `/api/generate`)
- **1-Click Model Manager** (pull, list, unload from RAM, and remove models)
- **Safe `OLLAMA_MODELS` Drive Mover with Rollback** (free up your C: drive safely)
- **Offline Batch Folder Summarizer** (`.txt` and `.md` -> private Markdown report)
- **Local UI & `OLLAMA_ORIGINS` Helper** (safe local CORS setup for Open WebUI)
