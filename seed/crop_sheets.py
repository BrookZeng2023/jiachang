#!/usr/bin/env python3
"""Split Image2 2x2 contact sheets into recipe JPEGs."""

import argparse
from pathlib import Path
from PIL import Image

SHEETS = {
    1: ["tomato-eggs", "pepper-potato", "soy-chicken", "mapo-tofu"],
    2: ["scallion-noodles", "tomato-beef-stew", "garlic-broccoli", "egg-fried-rice"],
    3: ["cottage-pie", "mushroom-pasta", "bolognese", "tikka-masala"],
    4: ["roast-salmon", "tomato-soup-toastie", "berry-porridge", "tray-roast-chicken"],
}


def crop(sheet: Path, output: Path, keys: list[str]) -> None:
    image = Image.open(sheet).convert("RGB")
    width, height = image.size
    middle_x, middle_y = width // 2, height // 2
    gutter = max(3, width // 200)
    boxes = [
        (0, 0, middle_x - gutter, middle_y - gutter),
        (middle_x + gutter, 0, width, middle_y - gutter),
        (0, middle_y + gutter, middle_x - gutter, height),
        (middle_x + gutter, middle_y + gutter, width, height),
    ]
    for key, box in zip(keys, boxes):
        panel = image.crop(box)
        panel.save(output / f"{key}.jpg", quality=92, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True, help="folder containing jc-sheetN.network-response")
    parser.add_argument("--output", type=Path, default=Path(__file__).with_name("images"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    for number, keys in SHEETS.items():
        sheet = args.input / f"jc-sheet{number}.network-response"
        if sheet.exists():
            crop(sheet, args.output, keys)
            print(f"cropped sheet {number}: {', '.join(keys)}")


if __name__ == "__main__":
    main()
