#!/usr/bin/env bash
# ============================================================
#  Marceline OS - GPU-optimized Ollama launcher (macOS/Linux)
# ============================================================
#  See start_ollama_gpu.bat for an explanation of each variable.
# ============================================================

echo "Stopping any existing Ollama instance..."
pkill -f "ollama serve" 2>/dev/null
sleep 1

export OLLAMA_FLASH_ATTENTION=1
export OLLAMA_KV_CACHE_TYPE=q8_0
export OLLAMA_GPU_OVERHEAD=0
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_KEEP_ALIVE=30m

echo ""
echo "Starting Ollama with GPU-optimized settings..."
echo "  OLLAMA_FLASH_ATTENTION=$OLLAMA_FLASH_ATTENTION"
echo "  OLLAMA_KV_CACHE_TYPE=$OLLAMA_KV_CACHE_TYPE"
echo "  OLLAMA_GPU_OVERHEAD=$OLLAMA_GPU_OVERHEAD"
echo "  OLLAMA_NUM_PARALLEL=$OLLAMA_NUM_PARALLEL"
echo "  OLLAMA_MAX_LOADED_MODELS=$OLLAMA_MAX_LOADED_MODELS"
echo "  OLLAMA_KEEP_ALIVE=$OLLAMA_KEEP_ALIVE"
echo ""

ollama serve &
echo "Ollama is starting in the background (pid $!)."
echo "Once it's ready, run: python server.py"
