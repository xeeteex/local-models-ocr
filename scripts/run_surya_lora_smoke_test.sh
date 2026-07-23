#!/usr/bin/env bash
set -euo pipefail

# Find the repo root from this script location.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/run_surya_lora_smoke_test.sh <input.pdf|input.png|input.jpg> [zero_based_page]" >&2
  exit 2
fi

if [[ ! -x "$REPO_ROOT/.venv/bin/python" ]]; then
  echo "Missing .venv/bin/python. Create the project virtualenv first." >&2
  exit 1
fi

input_path="$1"
page="${2:-0}"

if [[ ! -f "$input_path" ]]; then
  echo "Input file does not exist: $input_path" >&2
  exit 1
fi

case "${input_path##*.}" in
  pdf|PDF)
    stem="$(basename "${input_path%.*}")"
    image_path="$REPO_ROOT/lora_smoke_input/${stem}_page$((page + 1)).png"
    "$REPO_ROOT/.venv/bin/python" "$REPO_ROOT/utils/pdf_page_to_png.py" \
      "$input_path" \
      --page "$page" \
      --output "$image_path" \
      --scale 1.5
    ;;
  png|PNG|jpg|JPG|jpeg|JPEG)
    image_path="$input_path"
    ;;
  *)
    echo "Unsupported input type: $input_path" >&2
    exit 1
    ;;
esac

# Keep downloads/cache files inside this repo.
export HF_HOME="${HF_HOME:-$REPO_ROOT/.hf-cache}"
export TOKENIZERS_PARALLELISM="${TOKENIZERS_PARALLELISM:-false}"

"$REPO_ROOT/.venv/bin/python" "$REPO_ROOT/utils/surya_lora_local_smoke_test.py" "$image_path"
