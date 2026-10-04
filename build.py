#!/usr/bin/env python3
"""Builds the game from src/ and data/ into build/game.lua (comments
stripped, in load order) and points cart.p8's __lua__ section at it.

Only the __lua__ section (header + one #include line) is touched -- __gfx__/__label__/__map__/__sfx__/__music__ are left
byte-for-byte untouched, since those are owned by PICO-8's own sprite/map/
sfx editors and saved back into cart.p8 directly by PICO-8 itself.

Include order -- explicit, because a plain alphabetical walk can't express
"oop before anything that extends it":
  1. src/oop/**        class -> game_object -> scene (extend chain)
  2. src/utils/**       standalone helpers, no cross-file dependencies
  3. data/*.txt         exported sprite/tile data
  4. src/particles/**   extends oop/game_object (particle.p8.lua sorts first
                         in its own folder -- "." < "_" -- so particle_*.p8.lua
                         shapes always load after the base class)
  5. src/entities/**    extends oop/game_object
  6. src/scenes/**       extends oop/scene
  7. anything else under src/ not covered above (new categories, stray
     files) -- alphabetical, so nothing is ever silently skipped. if a new
     category needs specific ordering, add it to CATEGORIES below instead.
  8. src/main.p8.lua    always last

Also writes the two PICO-8-standard header comments right after __lua__
(-- <name> / -- by <author>) -- these are what PICO-8's `ls` console command
and BBS uploads read as the cart's title/author. Pass --name/--author, or
let the Makefile fill them in from the directory name / git config.
"""
import argparse
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent
CART = ROOT / "cart.p8"
SECTION_MARKERS = ("__gfx__", "__label__", "__map__", "__sfx__", "__music__")
CATEGORIES = ["oop", "ui", "utils", "particles", "entities", "scenes"]
TESTS = ROOT / "tests"
TEST_CART = TESTS / "run.p8"
BUILD = ROOT / "build"
GAME = BUILD / "game.lua"
# a string (kept as-is) or a comment (dropped) -- strings first, so "--"
# inside a string is never mistaken for a comment
STRING_OR_COMMENT = re.compile(
    r'("(?:\\.|[^"\\\n])*"|\'(?:\\.|[^\'\\\n])*\'|\[\[.*?\]\])|--\[\[.*?\]\]|--[^\n]*', re.S)


def collect_includes():
    src = ROOT / "src"
    main_file = src / "main.p8.lua"
    seen = set()
    paths = []

    for category in CATEGORIES:
        files = sorted((src / category).glob("**/*.p8.lua"))
        paths.extend(files)
        seen.update(files)
        if category == "utils":
            paths.extend(sorted(ROOT.glob("data/*.txt")))

    rest = sorted(
        p for p in src.glob("**/*.p8.lua") if p != main_file and p not in seen
    )
    paths.extend(rest)

    if main_file.exists():
        paths.append(main_file)

    return [f"#include {p.relative_to(ROOT).as_posix()}" for p in paths]


def split_tests(src):
    """Splits a test file into its shared part (helpers before the first
    test) and one chunk per test("...") block (a line starting with `test(`)."""
    lines = src.splitlines()
    starts = [i for i, line in enumerate(lines) if line.startswith("test(")]
    if not starts:
        return "\n".join(lines), []
    head = "\n".join(lines[: starts[0]])
    ends = starts[1:] + [len(lines)]
    return head, ["\n".join(lines[a:b]) for a, b in zip(starts, ends)]


def write_test_carts(includes):
    """One cart per test for `make test`: harness + game + one test.

    The game alone is close to PICO-8's 8192 tokens, so all tests together
    don't fit in one cart. Each test("...") block gets its own
    tests/run_<file>_<n>.p8 (plus a .lua with the file's shared helpers and
    that one test). They live in tests/ so the harness's ../cart.p8 still
    resolves. The game goes in as build/game.lua (comment-free, see
    write_game), like in cart.p8.
    """
    for old in TESTS.glob("run_*"):
        old.unlink()
    TEST_CART.unlink(missing_ok=True)
    game = ["#include ../build/game.lua"]
    count = 0
    for path in sorted(TESTS.glob("test_*.lua")):
        head, chunks = split_tests(path.read_text())
        for n, chunk in enumerate(chunks, 1):
            stem = f"run_{path.stem.removeprefix('test_')}_{n}"
            (TESTS / f"{stem}.lua").write_text(head + "\n" + chunk + "\n")
            lines = (["pico-8 cartridge // http://www.pico-8.com", "version 43", "__lua__",
                      "#include harness.lua"] + game
                     + [f"#include {stem}.lua", "test_summary()", ""])
            (TESTS / f"{stem}.p8").write_text("\n".join(lines))
            count += 1
    print(f"wrote {count} test carts to tests/run_*.p8")


def write_game(includes):
    """build/game.lua: the whole game in load order, comments dropped, one
    "-- <path>" line before each file (to find where an error line came
    from). cart.p8 includes only this file: PICO-8 caps a cart's code at
    65535 characters, comments included, and src/ is well commented."""
    code = []
    for inc in includes:
        path = inc.removeprefix("#include ")
        code += [f"-- {path}"] + strip_comments((ROOT / path).read_text())
    BUILD.mkdir(exist_ok=True)
    GAME.write_text("\n".join(code) + "\n")


def strip_comments(src):
    src = STRING_OR_COMMENT.sub(lambda m: m.group(1) or "", src)
    return [line.rstrip() for line in src.splitlines() if line.strip()]


def write_flat_cart(cart_lines, lua_i, end_i, header, includes, name):
    """Single-file cart for export/upload: includes inlined, comments dropped.

    Comments count toward PICO-8's compressed code limit, so a well-commented
    src/ can run fine via #include but be too big to export as .p8.png.
    """
    code = []
    for inc in includes:
        code += strip_comments((ROOT / inc.removeprefix("#include ")).read_text())
    BUILD.mkdir(exist_ok=True)
    flat = BUILD / f"{name or 'cart'}.p8"
    flat.write_text("\n".join(cart_lines[: lua_i + 1] + header + code + cart_lines[end_i:]) + "\n")
    print(f"wrote {flat.relative_to(ROOT)} ({len(code)} lines of code)")


def build_header(name, author):
    header = []
    if name:
        header.append(f"-- {name}")
    if author:
        header.append(f"-- by {author}")
    if header:
        header.append("")
    return header


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", default="", help="cart title, written as '-- <name>'")
    parser.add_argument("--author", default="", help="cart author, written as '-- by <author>'")
    parser.add_argument("--test", action="store_true", help="also write tests/run_*.p8 (one cart per test)")
    parser.add_argument("--flat", action="store_true", help="also write build/<name>.p8")
    args = parser.parse_args()

    if not CART.exists():
        sys.exit(f"error: {CART} not found")

    lines = CART.read_text().splitlines()

    try:
        lua_i = lines.index("__lua__")
    except ValueError:
        sys.exit("error: cart.p8 has no __lua__ section")

    end_i = len(lines)
    for i in range(lua_i + 1, len(lines)):
        if lines[i] in SECTION_MARKERS:
            end_i = i
            break

    header = build_header(args.name, args.author)
    includes = collect_includes()
    write_game(includes)
    new_lines = lines[: lua_i + 1] + header + [f"#include {GAME.relative_to(ROOT).as_posix()}", ""] + lines[end_i:]

    CART.write_text("\n".join(new_lines) + "\n")
    print(f"wrote {GAME.relative_to(ROOT)} ({len(includes)} files) and {CART.name}"
          + (f" (title: {args.name!r}, author: {args.author!r})" if header else ""))

    if args.test:
        write_test_carts(includes)

    if args.flat:
        write_flat_cart(lines, lua_i, end_i, header, includes, args.name)


if __name__ == "__main__":
    main()
