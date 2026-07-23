#!/usr/bin/env python3
import argparse
from pathlib import Path

import torch
from PIL import Image
from transformers import AutoModelForImageTextToText, AutoProcessor


def pick_device() -> str:
    if torch.backends.mps.is_available():
        return "mps"
    if torch.cuda.is_available():
        return "cuda"
    return "cpu"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Tiny local LoRA feasibility smoke test for Surya HF model"
    )
    parser.add_argument("image", help="Input PNG/JPG image")
    parser.add_argument(
        "--target-text",
        default="OCR smoke test",
        help="Short target text used for the training-style loss pass",
    )
    parser.add_argument("--model", default="datalab-to/surya-ocr-2")
    args = parser.parse_args()

    try:
        from peft import LoraConfig, get_peft_model
    except ImportError as exc:
        raise SystemExit(
            "Missing peft. Install with: UV_CACHE_DIR=.uv-cache uv pip install peft"
        ) from exc

    image = Image.open(args.image).convert("RGB")
    device = pick_device()
    dtype = torch.float32 if device in {"cpu", "mps"} else torch.bfloat16

    print(f"device={device}")
    print(f"dtype={dtype}")
    print(f"model={args.model}")

    processor = AutoProcessor.from_pretrained(args.model)
    model = AutoModelForImageTextToText.from_pretrained(
        args.model,
        torch_dtype=dtype,
        low_cpu_mem_usage=True,
    ).to(device)

    # Start with attention projections only. This keeps the adapter tiny.
    lora_config = LoraConfig(
        r=4,
        lora_alpha=8,
        lora_dropout=0.05,
        target_modules=["q_proj", "v_proj"],
        task_type="CAUSAL_LM",
    )
    model = get_peft_model(model, lora_config)
    model.print_trainable_parameters()
    model.train()

    prompt_messages = [
        {
            "role": "user",
            "content": [
                {"type": "image", "image": image},
                {"type": "text", "text": "OCR this document."},
            ],
        }
    ]
    text = processor.apply_chat_template(
        prompt_messages,
        tokenize=False,
        add_generation_prompt=True,
    )

    inputs = processor(
        text=[text + args.target_text],
        images=[image],
        return_tensors="pt",
    )
    inputs = {
        key: value.to(device=device, dtype=dtype) if value.is_floating_point() else value.to(device)
        for key, value in inputs.items()
    }
    inputs["labels"] = inputs["input_ids"].clone()

    print("running one forward/backward pass...")
    output = model(**inputs)
    print(f"loss={output.loss.item():.4f}")
    output.loss.backward()
    print("backward pass succeeded")

    out_dir = Path("lora_smoke_output")
    out_dir.mkdir(exist_ok=True)
    model.save_pretrained(out_dir)
    print(f"saved adapter smoke output to {out_dir}")


if __name__ == "__main__":
    main()
