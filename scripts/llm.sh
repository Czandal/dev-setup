#!/usr/bin/env bash
# desc: ollama + korektor-pl, llama-server for completions
. "$(dirname "$0")/lib.sh" "$@"

step "Ollama"
if have ollama; then
    say "already installed: ollama"
elif [ "$PM" = pacman ]; then
    say "GPU builds: ollama-vulkan, ollama-cuda, ollama-rocm"
    pkg ollama && run sudo systemctl enable --now ollama || true
elif confirm "Run the official installer (curl https://ollama.com/install.sh | sh)?"; then
    run sh -c 'curl -fsSL https://ollama.com/install.sh | sh'
fi

step "korektor-pl (Polish proofreading, <leader>b in visual mode)"
if ! have ollama; then
    [ "$DRY_RUN" = 1 ] && run ollama create korektor-pl -f "$ROOT/bielik-korektor.model"
elif ollama list 2>/dev/null | grep -q '^korektor-pl'; then
    say "already created: korektor-pl"
elif confirm "Create korektor-pl (downloads the ~7 GB Bielik model)?"; then
    run ollama create korektor-pl -f "$ROOT/bielik-korektor.model"
fi

step "llama-server (completions for llama.vim)"
if have llama-server; then
    say "already installed: llama-server"
elif [ "$PM" = pacman ]; then
    pkg llama-cpp || true
    confirm "Add the Vulkan GPU backend (ggml-vulkan)?" && pkg ggml-vulkan || true
else
    say "no package here, get a build from https://github.com/ggml-org/llama.cpp/releases"
fi
say "start it before nvim when you want completions:"
say "  llama-server --fim-qwen-3b-default -fa on --port 8012 --batch-size 1024 --cache-reuse 256"
