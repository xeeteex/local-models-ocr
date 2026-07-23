#!/usr/bin/env python3
import argparse
from pathlib import Path

import torch
from PIL import Image
from transformers import LightOnOcrForConditionalGeneration, LightOnOcrProcessor


def pick_device() -> str:
    if torch.backends.mps.is_available():
        return "mps"
    if torch.cuda.is_available():
        return "cuda"
    return "cpu"


def main() -> None:
    parser = argparse.ArgumentParser(description="Run official LightOnOCR with Transformers")
    parser.add_argument("image", help="Input PNG/JPG image")
    parser.add_argument("-o", "--output", required=True, help="Output text file")
    parser.add_argument("--model", default="lightonai/LightOnOCR-2-1B")
    parser.add_argument("--max-new-tokens", type=int, default=1024)
    args = parser.parse_args()

    image = Image.open(args.image).convert("RGB")
    device = pick_device()
    dtype = torch.float32 if device in {"cpu", "mps"} else torch.bfloat16

    processor = LightOnOcrProcessor.from_pretrained(args.model)
    model = LightOnOcrForConditionalGeneration.from_pretrained(
        args.model,
        torch_dtype=dtype,
    ).to(device)
    model.eval()

    # LightOnOCR is image-driven. No text prompt is needed for OCR.
    messages = [{"role": "user", "content": [{"type": "image", "image": image}]}]
    inputs = processor.apply_chat_template(
        messages,
        add_generation_prompt=True,
        tokenize=True,
        return_dict=True,
        return_tensors="pt",
    )
    inputs = {
        key: value.to(device=device, dtype=dtype) if value.is_floating_point() else value.to(device)
        for key, value in inputs.items()
    }

    with torch.inference_mode():
        output_ids = model.generate(**inputs, max_new_tokens=args.max_new_tokens)

    generated_ids = output_ids[0, inputs["input_ids"].shape[-1] :]
    text = processor.decode(generated_ids, skip_special_tokens=True).strip()

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(text + "\n", encoding="utf-8")
    print(f"Plain text: {output_path}")


if __name__ == "__main__":
    main()
