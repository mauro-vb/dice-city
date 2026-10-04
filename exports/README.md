# Exports

`make export` puts one release here per run, in `<date>_<time>_<commit>/`
(`-dirty` when there were uncommitted changes):

- `index.html` + `index.js` – the web player (open `index.html` to play locally); `splash.p8` is bundled.
- `dice-city-html.zip` – the two files above, ready to upload to itch.io (set the project to HTML, viewport 512×512 or bigger).
- `dice-city.p8.png` – the compressed cart; its label is the splash art. On its own (e.g. the PICO-8 BBS) it can't load `splash.p8`, so the title and game over show no splash.
- `dice-city.p8` – the comment-free source that was exported.

The folders aren't in git (each web build is about 1.8 MB); only this README is.
