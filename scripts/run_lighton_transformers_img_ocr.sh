#!/usr/bin/env bash
set -euo pipefail

# Find the repo root from this script location.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/run_lighton_transformers_img_ocr.sh <input.png|input.jpg> [output.txt]" >&2
  exit 2
fi

if [[ ! -x "$REPO_ROOT/.venv/bin/python" ]]; then
  echo "Missing .venv/bin/python. Create the project virtualenv first." >&2
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
output_path="${2:-$REPO_ROOT/lighton_transformers_output/${image_name%.*}.txt}"

# Keep Hugging Face files inside this repo.
export HF_HOME="${HF_HOME:-$REPO_ROOT/.hf-cache}"
export TOKENIZERS_PARALLELISM="${TOKENIZERS_PARALLELISM:-false}"

# Run official LightOnOCR through Transformers.
"$REPO_ROOT/.venv/bin/python" "$REPO_ROOT/utils/lighton_transformers_ocr.py" \
  "$image_path" \
  --output "$output_path"
