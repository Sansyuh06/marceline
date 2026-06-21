# Marceline OS 🦇

Ever get annoyed that most "autonomous" AI agents are just thin wrappers around an expensive OpenAI API key? Or that they require you to spin up Docker containers, manage Node modules, and juggle five different terminal windows just to edit a text file?

I built **Marceline OS** to fix that.

Marceline is a fully autonomous, offline-first AI operating system that runs entirely on your local machine using Ollama. It reads your codebase, edits files, executes terminal commands, and answers questions—all bundled into **one single Python file**.

## 🔴 The Problem
Modern AI coding assistants are heavily tethered to the cloud. This brings up huge privacy concerns if you're working on proprietary code, and it means you're out of luck if you're offline. Furthermore, existing local solutions often lack the "agentic" capabilities (like running shell commands or modifying files) because securing those actions locally is hard.

## 🟢 The Solution
I wanted to build an agent that felt like an OS. Marceline uses a monolithic architecture where the entire React frontend is compiled, compressed, and encoded as a Base64 string directly inside the Python backend. When you run `marceline_os.py`, it unpacks itself, spins up a local Flask server bound strictly to `127.0.0.1`, opens a native desktop window via `pywebview`, and hooks into your local Ollama models.

No API keys. No cloud servers. No messy deployments. 

## 🛠️ Tech Stack
- **AI Runtime:** Ollama (defaulting to `mistral:latest`)
- **Vector Database (RAG):** Keyword Search (`TfidfVectorizer`)
- **Backend:** Python, Flask, SQLite (with WAL mode)
- **Frontend:** React, Vite (Base64 injected)
- **Desktop Window:** `pywebview`

> **GPU performance:** every Ollama call is configured for full GPU offload
> with a shared keep-alive, and there's a `start_ollama_gpu.bat` /
> `start_ollama_gpu.sh` launcher that sets Ollama's flash-attention and
> quantized-KV-cache flags for you. See the "GPU notes" section in
> [`SETUP_MODES.md`](./SETUP_MODES.md) for details.

## ✨ Features
- **Zero-Dependency Deployment:** The entire frontend is baked into `marceline_os.py`. You literally just run `py marceline_os.py` and the GUI pops up.
- **Project Indexing:** Point Marceline at a local directory, and it will index the codebase using TF-IDF, creating a keyword-based RAG context for queries.
- **Agent Modes:** Use specific tags to trigger behaviors:
  - `[Project]`: Focuses the context strictly on your codebase.
  - `[Automate]`: Generates RPA scripts using `pyautogui`.
  - `[Harness]`: Enforces a strict Plan -> Work -> Review loop.
  - `[Think]`: Explains its reasoning step-by-step.
- **Autonomous Tooling:** The LLM can read files, write files, list directories, and execute shell or Python commands, all strictly sandboxed within the local `workspace/` folder to prevent path traversal.
- **Persistent History:** Real-time conversations are saved to a local SQLite database, streamed back to the UI via Server-Sent Events (SSE).

## 🚀 Impact
This project proves that you don't need a massive, bloated microservice architecture to build a highly capable, context-aware AI agent. By tightly coupling the UI and the backend, Marceline serves as a portable, drop-in pair programmer that respects your privacy.

## 🧠 What I Learnt
Building this wasn't just throwing together a few libraries. I had to solve some uniquely weird problems:
- **SQLite Locking with SSE:** When streaming tokens from the LLM back to the frontend, SQLite would constantly throw "database is locked" errors because of concurrent read/write operations. I solved this by enabling Write-Ahead Logging (`PRAGMA journal_mode=WAL`), allowing simultaneous reads and writes without blocking the event stream.
- **The Base64 Frontend Hack:** I learnt that you can completely bypass complex deployment pipelines by taking a compiled Vite/React build, turning `index.html` into a Base64 string, and having Flask decode and serve it from memory on the fly. It feels illegal, but it's incredibly effective for shipping single-file apps.
- **Regex over JSON:** Initially, I tried forcing the local LLM to output perfect JSON for tool calling. Local models are notoriously bad at this. I pivoted to a custom regex parser (`<tool_call>...</tool_call>`) which turned out to be far more resilient to the model's occasional formatting hallucinations.
- **Path Traversal Security:** Giving an LLM the ability to execute `write_file` is terrifying. I had to implement a strict `os.path.abspath` sandbox validation to ensure the model couldn't accidentally (or maliciously) overwrite system files outside the designated workspace.
