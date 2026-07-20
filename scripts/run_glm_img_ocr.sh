#!/usr/bin/env bash
set -euo pipefail

# Find the repo root from this script location.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/run_glm_img_ocr.sh <input.png|input.jpg> [output.txt]" >&2
  exit 2
fi

# GLM-OCR runs through llama-cli from llama.cpp.
if ! command -v llama-cli >/dev/null 2>&1; then
  echo "Missing llama-cli. Run: brew install llama.cpp" >&2
  exit 1
fi

# First arg is the image to OCR.
image_path="$1"

if [[ ! -f "$image_path" ]]; then
  echo "Input image does not exist: $image_path" >&2
  exit 1
fi

# Second arg is optional output text path.
image_name="$(basename "$image_path")"
output_path="${2:-$REPO_ROOT/glm_output/${image_name%.*}.txt}"
mkdir -p "$(dirname "$output_path")"

# Keep llama.cpp/Hugging Face cache files inside this repo.
export HOME="${GLM_HOME:-$REPO_ROOT/.glm-home}"

# Run GLM-OCR Q8_0. First run downloads the GGUF model.
llama-cli \
  -hf ggml-org/GLM-OCR-GGUF:Q8_0 \
  --image "$image_path" \
  -p "OCR" \
  --temp 0.1 \
  --top-k 1 \
  -n 4096 \
  --no-display-prompt \
  --simple-io \
  -o "$output_path"

echo "Plain text: $output_path"
