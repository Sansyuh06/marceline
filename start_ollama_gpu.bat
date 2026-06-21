@echo off
REM ============================================================
REM  Marceline OS - GPU-optimized Ollama launcher (Windows)
REM ============================================================
REM  Ollama's per-request "options" (num_gpu, etc.) only control how a
REM  single model is loaded. A few extra settings can only be set on the
REM  Ollama *server* itself via environment variables, and they make a
REM  real difference on an 8GB single-GPU laptop:
REM
REM    OLLAMA_FLASH_ATTENTION=1   Faster, lower-VRAM attention kernels.
REM    OLLAMA_KV_CACHE_TYPE=q8_0  Quantized KV cache -> frees VRAM so more
REM                               model layers fit on the GPU instead of
REM                               spilling to (slow) CPU.
REM    OLLAMA_GPU_OVERHEAD=0      Don't reserve extra headroom on the GPU;
REM                               let Ollama use what's actually free.
REM    OLLAMA_NUM_PARALLEL=1      Marceline only ever has one user/request
REM                               in flight, so don't split GPU capacity
REM                               across parallel request slots.
REM    OLLAMA_MAX_LOADED_MODELS=1 Matches the existing single-model-at-a-
REM                               time design noted in SETUP_MODES.md.
REM    OLLAMA_KEEP_ALIVE=30m      Backstop for the keep_alive Marceline
REM                               already sends with every request.
REM
REM  This window must stay running (or you can close it once Ollama has
REM  started, since it gets registered as a normal background process).
REM ============================================================

echo Stopping any existing Ollama instance...
taskkill /IM "ollama.exe" /F >nul 2>&1
taskkill /IM "ollama app.exe" /F >nul 2>&1
timeout /t 2 >nul

set OLLAMA_FLASH_ATTENTION=1
set OLLAMA_KV_CACHE_TYPE=q8_0
set OLLAMA_GPU_OVERHEAD=0
set OLLAMA_NUM_PARALLEL=1
set OLLAMA_MAX_LOADED_MODELS=1
set OLLAMA_KEEP_ALIVE=30m

echo.
echo Starting Ollama with GPU-optimized settings...
echo   OLLAMA_FLASH_ATTENTION=%OLLAMA_FLASH_ATTENTION%
echo   OLLAMA_KV_CACHE_TYPE=%OLLAMA_KV_CACHE_TYPE%
echo   OLLAMA_GPU_OVERHEAD=%OLLAMA_GPU_OVERHEAD%
echo   OLLAMA_NUM_PARALLEL=%OLLAMA_NUM_PARALLEL%
echo   OLLAMA_MAX_LOADED_MODELS=%OLLAMA_MAX_LOADED_MODELS%
echo   OLLAMA_KEEP_ALIVE=%OLLAMA_KEEP_ALIVE%
echo.

start "Ollama (GPU-optimized)" ollama serve

echo Ollama is starting in a new window. Once it's ready, run:
echo   python server.py
pause
