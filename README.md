# Local OCR tests

This repo runs OCR locally on Apple Silicon using `llama.cpp`.

It has three OCR paths:

- Surya OCR: best full workflow here; supports PDF, PNG, JPG, and folders.
- GLM-OCR: runs through `llama-cli`; accepts images, so PDFs are rendered page-by-page first.
- LightOnOCR: runs through `llama-cli`; accepts images, so PDFs are rendered page-by-page first.

## 1. Install system tools

Install `llama.cpp` with Homebrew:

```bash
brew install llama.cpp
```

Check that both binaries exist:

```bash
which llama-server
which llama-cli
```

Expected paths look like:

```text
/opt/homebrew/bin/llama-server
/opt/homebrew/bin/llama-cli
```

## 2. Create the Python environment

This project uses `uv` because the macOS system Python can be too old for OCR packages.

Create the virtualenv:

```bash
UV_CACHE_DIR=.uv-cache uv venv --python 3.13 .venv
```

Install Surya OCR:

```bash
UV_CACHE_DIR=.uv-cache uv pip install surya-ocr
```

Check Surya is installed:

```bash
.venv/bin/surya_ocr --help
```

## 3. Surya OCR with llama.cpp

Surya is configured in:

```text
scripts/run_surya_ocr.sh
```

The important setting is:

```bash
SURYA_INFERENCE_BACKEND=llamacpp
```

That tells Surya to start `llama-server` from `llama.cpp` and run the Surya GGUF model locally.

Run OCR only:

```bash
scripts/run_surya_ocr.sh test_pdfs/nepalibad5.PDF
```

Run OCR and extract plain text:

```bash
scripts/run_surya_ocr_to_text.sh test_pdfs/nepalibad5.PDF
```

Run one PDF page only:

```bash
scripts/run_surya_ocr_to_text.sh test_pdfs/nepalibad5.PDF surya_output --page_range 0
```

Run OCR on an image:

```bash
scripts/run_surya_ocr_to_text.sh path/to/image.png
```

Surya outputs:

```text
surya_output/<file-name>/results.json
surya_output/<file-name>/text.txt
```

## 4. GLM-OCR with llama.cpp

GLM-OCR uses `llama-cli` directly with:

```text
ggml-org/GLM-OCR-GGUF:Q8_0
```

Run GLM-OCR on a PDF page:

```bash
scripts/run_glm_pdf_ocr.sh test_pdfs/nepalibad5.PDF 0
```

The page number is zero-based:

```text
0 = page 1
1 = page 2
2 = page 3
```

Run GLM-OCR on an existing PNG/JPG:

```bash
scripts/run_glm_img_ocr.sh glm_input/nepalibad5_page1.png
```

GLM outputs:

```text
glm_input/<file-name>_page1.png
glm_output/<file-name>_page1.txt
```

## 5. LightOnOCR with Transformers

The tested LightOn path uses the official `lightonai/LightOnOCR-2-1B` Transformers model.

```bash
scripts/run_lighton_transformers_pdf_ocr.sh test_pdfs/nepalibad.PDF 0
```

It writes:

```text
lighton_transformers_output/<file-name>_page1.txt
```

For an existing PNG/JPG:

```bash
scripts/run_lighton_transformers_img_ocr.sh lighton_transformers_input/nepalibad_page1.png
```

## 6. What each script does

## 6. Local LoRA smoke test for Surya

This is not full QLoRA training. It only checks whether this machine can load the Surya Transformers model, attach tiny LoRA adapters, and complete one forward/backward pass.

Install PEFT first:

```bash
UV_CACHE_DIR=.uv-cache uv pip install peft
```

Run the smoke test on one rendered PDF page:

```bash
scripts/run_surya_lora_smoke_test.sh test_pdfs/nepalibad5.PDF 0
```

If this fails with memory or speed problems, full local QLoRA is not practical on this device.

## 7. What each script does

```text
scripts/run_surya_ocr.sh
```

Runs Surya OCR and writes `results.json`.

```text
scripts/run_surya_ocr_to_text.sh
```

Runs Surya OCR, then uses `utils/extract_txt_from_json_surya.py` to create `text.txt`.

```text
scripts/run_glm_pdf_ocr.sh
```

Renders one PDF page to PNG with `utils/pdf_page_to_png.py`, then runs GLM-OCR.

```text
scripts/run_glm_img_ocr.sh
```

Runs GLM-OCR directly on a PNG/JPG image.

```text
scripts/run_lighton_transformers_pdf_ocr.sh
```

Renders one PDF page to PNG, then runs official LightOnOCR-2 with Transformers.

```text
scripts/run_lighton_transformers_img_ocr.sh
```

Runs official LightOnOCR-2 with Transformers on a PNG/JPG image.

```text
scripts/run_surya_lora_smoke_test.sh
```

Runs a tiny local LoRA feasibility check for the Surya Transformers model.

## 8. Caches and generated files

These folders are local/generated and should not be committed:

```text
.venv/
.uv-cache/
.hf-cache/
.surya-home/
.surya-cache/
.glm-home/
surya_output/
glm_input/
glm_output/
lighton_transformers_input/
lighton_transformers_output/
lora_smoke_input/
lora_smoke_output/
test_pdfs/
```

The first model run can take longer because it downloads model files. Later runs reuse the cache.
