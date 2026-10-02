#!/usr/bin/env python3
"""Turns "snap <name> <hex>" lines from tests/.last_run.log into 4x pngs."""
import pathlib
from PIL import Image

BASE = ["000000", "1d2b53", "7e2553", "008751", "ab5236", "5f574f", "c2c3c7", "fff1e8",
        "ff004d", "ffa300", "ffec27", "00e436", "29adff", "83769c", "ff77a8", "ffccaa"]
EXTRA = ["291814", "111d35", "422136", "125359", "742f29", "49333b", "a28879", "f3ef7d",
         "be1250", "ff6c24", "a8e72e", "00b543", "065ab5", "754665", "ff6e59", "ff9d81"]


def rgb(c):
    h = (EXTRA if c & 0x80 else BASE)[c & 0xf]
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


TESTS = pathlib.Path(__file__).parent
(TESTS / "snaps").mkdir(exist_ok=True)

for line in (TESTS / ".last_run.log").read_text().splitlines():
    if not line.startswith("snap "):
        continue
    _, name, hexdata = line.split(" ", 2)
    raw = bytes.fromhex(hexdata)
    out = TESTS / "snaps" / f"{name}.png"
    pal, screen = [rgb(c) for c in raw[:16]], raw[16:]
    img = Image.new("RGB", (128, 128))
    for i, byte in enumerate(screen):
        y, x = divmod(i * 2, 128)
        img.putpixel((x, y), pal[byte & 0xf])
        img.putpixel((x + 1, y), pal[byte >> 4])
    img.resize((512, 512), Image.Resampling.NEAREST).save(out)
    print("snap", out.relative_to(TESTS))
