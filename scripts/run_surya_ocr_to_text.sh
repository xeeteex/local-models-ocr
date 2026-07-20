#!/usr/bin/env bash
set -euo pipefail

# Find the repo root from this script location.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/run_surya_ocr_to_text.sh <input.pdf|input.png|input.jpg> [output_dir]" >&2
  exit 2
fi

# First arg is the file to OCR.
input_path="$1"

# Second arg is optional output directory.
output_dir="${2:-$REPO_ROOT/surya_output}"

if [[ ! -f "$input_path" ]]; then
  echo "Input file does not exist: $input_path" >&2
  exit 1
fi

base_name="$(basename "$input_path")"
stem="${base_name%.*}"
results_path="$output_dir/$stem/results.json"
text_path="$output_dir/$stem/text.txt"

# Run Surya first, producing results.json.
"$SCRIPT_DIR/run_surya_ocr.sh" "$input_path" "$output_dir"

# Extract plain text from Surya's JSON output.
"$REPO_ROOT/utils/extract_txt_from_json_surya.py" "$results_path" -o "$text_path"

echo "OCR JSON: $results_path"
echo "Plain text: $text_path"
