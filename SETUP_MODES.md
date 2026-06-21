# Marceline — Mode Rewire (Lenovo Legion 5i / RTX 4060 8GB)

## What changed

| Mode | Model | Behavior |
|---|---|---|
| **Search** (also the default, no button pressed) | `mistral:latest` | General ChatGPT-style assistant. Press the Search pill to additionally ground answers with a real DuckDuckGo web search. |
| **Think** | `deepseek-r1:8b` | Reasoning model — shows its work inside `<thinking>` before the final answer. |
| **Canvas** | removed | The button, state, and submit-prefix were deleted from `index.html`. |
| **Harness** | OpenClaw only | The ENTIRE task ("Open Spotify and play Sai Abhyankar", "open VS Code and make a python program that prints hello world") is handed straight to `openclaw_bridge.run_primitive(task)` — no LLM tool-call loop, no coordinate clicking. |
| **Automate** | `mistral:latest` plans, `pyautogui` + `pywinauto` execute | Mistral converts your instruction into a `STEP N: ACTION | arg` macro, which `workspace/desktop_actions.py` executes locally using pyautogui (typing/keys/screenshots) and pywinauto (UI Automation — window finding, element clicking, UI-tree dumps). |

## One-time setup on your machine

```bash
# 1. Python deps (includes pyautogui + pywinauto)
pip install -r requirements.txt

# 2. OpenClaw CLI (used only by Harness mode)
npm install -g openclaw

# 3. Pull the three Ollama models — all fit comfortably in 8GB VRAM (q4):
ollama pull mistral:latest        # Search / default / Automate planner
ollama pull deepseek-r1:8b        # Think mode reasoning
ollama pull qwen2.5vl:latest      # Vision, used automatically whenever you attach an image

# 4. Start
python server.py
```

## GPU notes (RTX 4060 8GB / i7-13650HX / 24GB RAM)

`MODEL_OPTIONS["num_gpu"] = 99` forces Ollama to offload as many layers as
possible onto the GPU for every model. Mistral-7B-q4 (~4.4GB) and
DeepSeek-R1-8B-q4 (~5GB) both fit entirely in 8GB VRAM individually — Ollama
unloads the previous model automatically when you switch modes, so you won't
run two models in VRAM at once. Qwen2.5-VL only loads when you attach an
image, regardless of which mode you're in.

If you ever see slowdowns from VRAM pressure, lower `num_ctx` in
`MODEL_OPTIONS` / `THINK_MODEL_OPTIONS` in `server.py`.

### Squeezing more out of the GPU

Two changes were made to push GPU usage and response speed further on a
single 8GB card:

1. **Every Ollama call now forces full GPU offload and a shared keep-alive,
   not just the main chat call.** The vision-loop step (`run_vision_guided_automation`)
   and the Automate-mode planner previously sent no `options` at all, so they
   relied on Ollama's defaults instead of explicitly maxing out GPU layers.
   They — plus title generation — now pass `"num_gpu": 99` and
   `"keep_alive": GPU_KEEP_ALIVE` (30 minutes by default, set near the top of
   `server.py`) just like the main chat request does. A longer keep-alive
   means the model you're actively talking to stays resident in VRAM instead
   of Ollama evicting it after its default 5-minute idle timeout and having
   to reload weights from disk on your next message.
2. **Title generation reuses whatever model just answered you** (Mistral,
   DeepSeek, or Qwen) instead of always calling Mistral. Previously, every
   new conversation in Think or vision mode triggered a *second* model swap
   immediately after the first one finished, just to write a 5-word title —
   doubling the GPU load/unload cost per conversation for no reason.

Run `start_ollama_gpu.bat` (Windows) or `start_ollama_gpu.sh` (macOS/Linux)
before `python server.py` to additionally launch Ollama itself with:

- `OLLAMA_FLASH_ATTENTION=1` — faster, lower-VRAM attention kernels.
- `OLLAMA_KV_CACHE_TYPE=q8_0` — quantized KV cache, freeing VRAM so more
  layers fit on the GPU instead of spilling to (much slower) CPU.
- `OLLAMA_GPU_OVERHEAD=0` — don't reserve extra GPU headroom.
- `OLLAMA_NUM_PARALLEL=1` / `OLLAMA_MAX_LOADED_MODELS=1` — Marceline only
  ever has one request in flight from one user, so don't split GPU capacity
  across request slots that will sit idle.

These four are server-level Ollama settings — they can't be sent per-request
from `server.py`, which is why they live in the launcher script instead.

Note: the RAG/project-indexing layer (`TfidfVectorizer` + cosine similarity)
is plain scikit-learn and runs on CPU — that part was never GPU-bound to
begin with, so there was nothing to move there. The actual heavy lifting
(token generation) all happens inside Ollama, which is what the changes
above target.

## Files touched

- `server.py` — model routing per mode, Harness now calls OpenClaw directly,
  default conversational system prompt (was hard-locked to OpenClaw operator
  syntax for every single message before).
- `index.html` — Canvas mode (button + state + submit branch) fully removed.
- `workspace/desktop_actions.py` — **new**. pyautogui/pywinauto backend that
  Automate-mode macros and the legacy tool-call fallback both execute against.
- `requirements.txt` — added `pyautogui`, `pywinauto` (Windows-only extra).
