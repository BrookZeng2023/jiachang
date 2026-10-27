#!/usr/bin/env python3
"""Subset and rename the open-source fonts bundled with Jiachang.

Output (app/jiachang/Resources/Fonts):
  JiachangKai-{Regular,Medium}.ttf   from LXGW WenKai GB   (SIL OFL 1.1)  - feeling: names, dates, notes
  JiachangHei-Regular.ttf            from LXGW Neo XiHei   (IPA Font License 1.0) - reading: prose, steps
plus the matching license texts. Subsets are Modified Versions, so they are renamed.
Re-run after editing any Localizable.strings so every character on screen is covered.

Usage (from app/):
  uv run --no-project --with fonttools==4.60.1 python -I scripts/build_fonts.py SOURCE_DIR
SOURCE_DIR holds LXGWWenKaiGB-Regular.ttf, LXGWWenKaiGB-Medium.ttf, OFL.txt,
LXGWNeoXiHei.ttf and IPA-Font-License.md.
"""

from __future__ import annotations

import re
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

APP = Path(__file__).resolve().parents[1]
STRINGS = sorted((APP / "jiachang/Interfaces/Localization").glob("*.lproj/Localizable.strings"))
OUTPUT = APP / "jiachang/Resources/Fonts"
RESERVED = ("霞鹜", "霞鶩", "落霞孤鹜", "落霞孤鶩", "LXGW", "IPA")
# Family, subfamily, unique id, full name, PostScript, typographic family/subfamily.
RENAMED_IDS = (1, 2, 3, 4, 6, 16, 17)


@dataclass(frozen=True)
class Face:
    source: str
    family: str
    weight: str


FACES = (
    Face("LXGWWenKaiGB-Regular.ttf", "Jiachang Kai", "Regular"),
    Face("LXGWWenKaiGB-Medium.ttf", "Jiachang Kai", "Medium"),
    Face("LXGWNeoXiHei.ttf", "Jiachang Hei", "Regular"),
)
LICENSES = {"OFL.txt": "OFL.txt", "IPA-Font-License.md": "IPA-Font-License.md"}


def characters() -> str:
    pattern = re.compile(r'^"[^"]+"\s*=\s*"((?:[^"\\]|\\.)*)";', re.MULTILINE)
    text = "".join(m.group(1) for path in STRINGS for m in pattern.finditer(path.read_text("utf-8")))
    ascii_printable = "".join(chr(c) for c in range(0x20, 0x7F))
    extra = "家常，。、；：？！“”‘’（）《》「」—…·"
    # Personal recipes and journals contain text not present in the UI copy.
    # Retain the GB2312 common repertoire; rarer characters use OS fallback.
    common = "".join(bytes([a, b]).decode("gb2312", errors="ignore")
                     for a in range(0xA1, 0xF8) for b in range(0xA1, 0xFF))
    catalog = (APP / "jiachang/Resources/Catalog/recipes.json").read_text("utf-8")
    return "".join(sorted(set(text + ascii_printable + extra + common + catalog)))


def rename(font: TTFont, face: Face) -> str:
    postscript = f"{face.family.replace(' ', '')}-{face.weight}"
    values = {1: face.family, 2: face.weight, 3: f"{postscript};subset", 4: f"{face.family} {face.weight}",
              6: postscript, 16: face.family, 17: face.weight}
    table = font["name"]
    table.names = [n for n in table.names if n.nameID not in RENAMED_IDS]
    for name_id, value in values.items():
        table.setName(value, name_id, 3, 1, 0x409)
        table.setName(value, name_id, 1, 0, 0)
    # Copyright, license and designer records (IDs 0, 7-9, 13, 14) keep the original attribution;
    # only names the system displays or matches are renamed.
    for record in table.names:
        if record.nameID in RENAMED_IDS and any(r in record.toUnicode() for r in RESERVED):
            raise SystemExit(f"Reserved name left in name ID {record.nameID}")
    return postscript


def build(source_dir: Path, face: Face, text: str) -> Path:
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.name_languages = ["*"]
    options.notdef_outline = True
    font = TTFont(source_dir / face.source)
    subsetter = subset.Subsetter(options)
    subsetter.populate(text=text)
    subsetter.subset(font)
    postscript = rename(font, face)
    target = OUTPUT / f"{postscript}.ttf"
    font.save(target)
    return target


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    source_dir = Path(sys.argv[1]).resolve()
    for name in [face.source for face in FACES] + list(LICENSES):
        if not (source_dir / name).is_file():
            raise SystemExit(f"Missing {source_dir / name}")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    text = characters()
    for face in FACES:
        target = build(source_dir, face, text)
        print(f"{target.name}: {target.stat().st_size} bytes, {len(text)} characters")
    for source, destination in LICENSES.items():
        shutil.copyfile(source_dir / source, OUTPUT / destination)


if __name__ == "__main__":
    main()
