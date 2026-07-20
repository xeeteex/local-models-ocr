#!/usr/bin/env bash
set -euo pipefail

# Find the repo root from this script location.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/run_surya_ocr.sh <input.pdf|input.png|input_dir> [output_dir] [extra surya_ocr args...]" >&2
  exit 2
fi

if [[ ! -x "$REPO_ROOT/.venv/bin/surya_ocr" ]]; then
  echo "Missing .venv/bin/surya_ocr. Run: UV_CACHE_DIR=.uv-cache uv pip install surya-ocr" >&2
  exit 1
fi

# Surya's Apple Silicon path needs llama-server from llama.cpp.
if ! command -v llama-server >/dev/null 2>&1; then
  echo "Missing llama-server. Run: brew install llama.cpp" >&2
  exit 1
fi

# First arg is the file/folder to OCR.
input_path="$1"
shift

# Second arg is optional output directory.
output_path="${1:-$REPO_ROOT/surya_output}"
if [[ $# -gt 0 ]]; then
  shift
fi

# Keep all generated caches inside this repo.
export MODEL_CACHE_DIR="${MODEL_CACHE_DIR:-$REPO_ROOT/.surya-cache/models}"
export HF_HOME="${HF_HOME:-$REPO_ROOT/.hf-cache}"
export HOME="${SURYA_HOME:-$REPO_ROOT/.surya-home}"
export TOKENIZERS_PARALLELISM="${TOKENIZERS_PARALLELISM:-false}"

# Force Surya to use llama.cpp instead of vLLM.
export SURYA_INFERENCE_BACKEND="${SURYA_INFERENCE_BACKEND:-llamacpp}"

# Conservative defaults for a 16 GB Apple Silicon Mac.
export SURYA_INFERENCE_PARALLEL="${SURYA_INFERENCE_PARALLEL:-1}"
export SURYA_INFERENCE_CTX_SIZE="${SURYA_INFERENCE_CTX_SIZE:-16384}"

# Run Surya OCR.
"$REPO_ROOT/.venv/bin/surya_ocr" "$input_path" --output_dir "$output_path" "$@"
