#!/usr/bin/env python3
import argparse
import json
import re
from html import unescape
from pathlib import Path


def html_to_text(value: str) -> str:
    text = re.sub(r"<br\s*/?>", "\n", value, flags=re.IGNORECASE)
    text = re.sub(r"</(p|h[1-6]|tr|table)>", "\n", text, flags=re.IGNORECASE)
    text = re.sub(r"<[^>]+>", " ", text)
    text = unescape(text)
    lines = [re.sub(r"\s+", " ", line).strip() for line in text.splitlines()]
    return "\n".join(line for line in lines if line)


def extract_text(results_path: Path) -> str:
    data = json.loads(results_path.read_text(encoding="utf-8"))
    output = []

    for doc_name, pages in data.items():
        if len(data) > 1:
            output.append(f"## {doc_name}")

        for page in pages:
            page_num = page.get("page")
            if page_num is not None and len(pages) > 1:
                output.append(f"\n--- Page {page_num} ---")

            for block in page.get("blocks", []):
                text = html_to_text(block.get("html", ""))
                if text:
                    output.append(text)

    return "\n\n".join(output).strip() + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract plain text from Surya OCR results.json")
    parser.add_argument(
        "results_json",
        nargs="?",
        default="surya_output/nepalibad6/results.json",
        help="Path to Surya results.json",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Output text file. Defaults to text.txt next to results.json",
    )
    args = parser.parse_args()

    results_path = Path(args.results_json)
    output_path = Path(args.output) if args.output else results_path.with_name("text.txt")

    output_path.write_text(extract_text(results_path), encoding="utf-8")
    print(f"Wrote {output_path}")


if __name__ == "__main__":
    main()
