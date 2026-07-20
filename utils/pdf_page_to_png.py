#!/usr/bin/env python3
import argparse
from pathlib import Path

import pypdfium2 as pdfium


def main() -> None:
    parser = argparse.ArgumentParser(description="Render one PDF page to PNG")
    parser.add_argument("pdf", help="Input PDF")
    parser.add_argument("-p", "--page", type=int, default=0, help="Zero-based page number")
    parser.add_argument("-o", "--output", help="Output PNG path")
    parser.add_argument("--scale", type=float, default=3.0, help="Render scale; 3.0 is about 216 DPI")
    args = parser.parse_args()

    # GLM-OCR accepts images, so converting pdf to png
    pdf_path = Path(args.pdf)
    output_path = Path(args.output) if args.output else Path("glm_input") / f"{pdf_path.stem}_page{args.page + 1}.png"
    output_path.parent.mkdir(parents=True, exist_ok=True)

    doc = pdfium.PdfDocument(str(pdf_path))
    if args.page < 0 or args.page >= len(doc):
        raise SystemExit(f"Page {args.page} is out of range; PDF has {len(doc)} page(s)")

    page = doc[args.page]
    image = page.render(scale=args.scale).to_pil().convert("RGB")
    image.save(output_path)
    doc.close()

    print(output_path)


if __name__ == "__main__":
    main()
