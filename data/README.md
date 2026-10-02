# data/

Exported sprite/tile data goes here as `.txt` files (e.g. `myspr.txt`,
generated as `myspr=split2d"0,112,16,16,0,0|..."`) -- `build.py` automatically
includes every `data/*.txt` file, after `src/utils/` and before
`src/particles/`, `src/entities/`, and `src/scenes/`.

`myspr.txt` is edited with the standalone sprite-region editor,
`spritedit_tool.p8`, at the project root (`make spritedit`, or
`pico8 spritedit_tool.p8` directly) -- not part of the game cart's #include
chain. It reloads `cart.p8`'s spritesheet at startup so you can preview real
sprites while defining regions; arrow keys + (x)/(o) navigate/edit, and the
"export" menu item (or pressing p) writes the table back out to
`myspr.txt`. `myspr.txt` ships with one placeholder 8x8 region so the tool
has something to load before you've exported anything -- replace/extend it
once you've drawn real sprites.
