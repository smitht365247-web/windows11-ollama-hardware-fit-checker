========================================================================
  Windows 11 Ollama Hardware & Model Fit Checker (v1.2)
========================================================================

Just unzip this folder and double-click RUN_FIT_CHECKER.bat - no Python,
Docker, or coding required.

- Checks System RAM, 64-bit GPU VRAM, OLLAMA_MODELS free space, and
  localhost:11434 (/api/version + /api/ps).
- You can press Enter to save the report in this toolkit folder, or paste
  another folder path. Quoted paths and trailing backslashes are handled
  correctly by the launcher.

------------------------------------------------------------------------
WINDOWS SMARTSCREEN UNBLOCK INSTRUCTIONS
------------------------------------------------------------------------
Because .bat and .ps1 files downloaded from the internet are unsigned,
Windows SmartScreen may show "Windows protected your PC" on first run:
  Option A: Click "More info" -> "Run anyway".
  Option B: Right-click the downloaded .zip file BEFORE extracting ->
            Properties -> check "Unblock" -> Apply / OK -> then extract.
