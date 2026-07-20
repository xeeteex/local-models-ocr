#!/usr/bin/env bash
set -euo pipefail

# Find the repo root from this script location.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/run_glm_pdf_ocr.sh <input.pdf> [zero_based_page] [output.txt]" >&2
  exit 2
fi

if [[ ! -x "$REPO_ROOT/.venv/bin/python" ]]; then
  echo "Missing .venv/bin/python. Create the project virtualenv first." >&2
  exit 1
fi

# First arg is the PDF to OCR.
pdf_path="$1"

if [[ ! -f "$pdf_path" ]]; then
  echo "Input PDF does not exist: $pdf_path" >&2
  exit 1
fi

# Second arg is optional zero-based page number.
page="${2:-0}"

# Build default PNG and text output paths.
pdf_name="$(basename "$pdf_path")"
stem="${pdf_name%.*}"
image_path="$REPO_ROOT/glm_input/${stem}_page$((page + 1)).png"
output_path="${3:-$REPO_ROOT/glm_output/${stem}_page$((page + 1)).txt}"

# GLM-OCR accepts images, so render one PDF page first.
"$REPO_ROOT/.venv/bin/python" "$REPO_ROOT/utils/pdf_page_to_png.py" \
  "$pdf_path" \
  --page "$page" \
  --output "$image_path"

# Run GLM-OCR on the rendered page image.
"$SCRIPT_DIR/run_glm_img_ocr.sh" "$image_path" "$output_path"
