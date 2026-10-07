#!/usr/bin/env python3
"""make export: one release of the game in exports/<date>_<time>_<commit>/.

Run after `make flat` (the Makefile does both). Exports the comment-free
build/<name>.p8 with PICO-8's headless exporter:
  index.html + index.js   web player, splash.p8 bundled (the title reloads it)
  <name>-html.zip         the two above, ready to upload to itch.io
  <name>.p8.png           the compressed cart; its label is the splash art.
                          a .p8.png can't bundle splash.p8: on its own (e.g.
                          the BBS) the title and game over show no splash
  <name>.p8               the comment-free source that was exported
  <name>.bin/             windows, mac, linux and raspberry pi zips, splash.p8
                          bundled. kept out of git (too big)

HTML export needs a cart label: if the cart has none, the splash art becomes
one (colour 1 as navy, 129, like the game's screen palette).

usage: export.py <pico8 binary> <name>
"""
import shutil
import subprocess
import sys
import zipfile
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT / "build"
EXPORTS = ROOT / "exports"
SPLASH = ROOT / "splash.p8"


def splash_label():
    gfx = SPLASH.read_text().split("__gfx__\n")[1].split("\n__")[0].split()
    # label colours 128-143 are g-v: 1 -> h (129, navy)
    return [row.replace("1", "h") for row in gfx[:128]]


def add_label(cart):
    text = cart.read_text()
    if "\n__label__\n" in text:
        return
    cart.write_text(text.rstrip("\n") + "\n\n__label__\n" + "\n".join(splash_label()) + "\n")


def version():
    git = lambda *a: subprocess.run(["git", *a], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    stamp = datetime.now().strftime("%Y-%m-%d_%H%M")
    dirty = "-dirty" if git("status", "--porcelain", "--untracked-files=no") else ""
    return f"{stamp}_{git('rev-parse', '--short', 'HEAD')}{dirty}"


def export(pico8, cart, out, args):
    # the exporter writes into the folder it runs in
    r = subprocess.run([pico8, str(cart), "-export", args], cwd=out, capture_output=True, text=True, timeout=120)
    if "please capture a label" in r.stdout + r.stderr:
        sys.exit("error: the cart has no label")


def main():
    pico8, name = sys.argv[1], sys.argv[2]
    cart = BUILD / f"{name}.p8"
    if not cart.exists():
        sys.exit(f"error: {cart.relative_to(ROOT)} not found (run make flat)")
    add_label(cart)

    out = EXPORTS / version()
    out.mkdir(parents=True)
    shutil.copy(SPLASH, out / "splash.p8")
    export(pico8, cart, out, "index.html splash.p8")
    export(pico8, cart, out, f"{name}.bin splash.p8")
    export(pico8, cart, out, f"{name}.p8.png")
    (out / "splash.p8").unlink()
    shutil.copy(cart, out / f"{name}.p8")

    missing = [f for f in ("index.html", "index.js", f"{name}.p8.png", f"{name}.bin") if not (out / f).exists()]
    if missing:
        sys.exit(f"error: export failed, missing {', '.join(missing)} in {out.relative_to(ROOT)}")
    with zipfile.ZipFile(out / f"{name}-html.zip", "w", zipfile.ZIP_DEFLATED) as z:
        for f in ("index.html", "index.js"):
            z.write(out / f, f)
    print(f"exported to {out.relative_to(ROOT)}/")
    for f in sorted(out.iterdir()):
        print(f"  {f.name:24s} {f.stat().st_size // 1024:6d} KB")


if __name__ == "__main__":
    main()
