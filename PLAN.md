# AutoRoll – build plan

Each step ends with something you can run or test before moving on.
Steps 1–4 have no real graphics: the rules work and are tested first, then the screens are built on top.
Names follow your template's style (snake_case, `_ENV` methods, `upd`/`drw`); rename them as you like.

Folders: `oop/ utils/ ui/ entities/ scenes/` (loaded in that order by `build.py`), plus `defs/ logic/ fx/` (loaded after scenes, like `levels/` in pacformer).

---

## 0. Setup

- Switch `main` to `_update60` and keep a global `t` frame counter (as in pacformer).
- Add `ui` to `CATEGORIES` in `build.py`, between `particles` and `entities`.
- Copy `utils/input` (`pressed()`) from pacformer.
- Remove particle shapes you won't use, to save tokens. Keep the rest for later.
- Tests: call `srand(seed)` in `boot()` so dice rolls are the same on every run.

**Done when:** `make test` passes with the boot test.

---

## 1. Dice (rules only)

### `defs/dice` – die types
A `die_type()` factory that merges defaults, like `level()` in pacformer.

| field | meaning |
|---|---|
| `id`, `name` | `"classic"`, `"CLASSIC"` |
| `faces` | 3 or 6 values, e.g. `1,2,3,4,5,6` or `1,2,3`. Never assume 6: use `#faces` |
| `body`, `edge` | colours |
| `shape` | `"round"`, `"square"` or `"oct"` for 6 faces · `"tri"` for 3 faces (a 15×12 sprite) |
| `price` | cost in the shop |

Starter types: classic, steady, gambler, medic (6 faces). 3-faced types for the shop: tri (1,2,3), spike (1,1,5), even (2,2,3). Colour = personality, shape = face count.

### `entities/die` – one die the player owns
| field | meaning |
|---|---|
| `kind` | its die type |
| `faces` | **its own copy** of the type's faces (upgrades change one die only) |
| `up` | which face positions were upgraded |
| `face_i`, `value` | last roll: which face, and its value (`nil` until rolled) |
| `slot` | `nil` = in the bag, otherwise `"atk"`, `"spd"`, `"def"` or `"heal"` |

| function | does |
|---|---|
| `init` | copy faces from `kind` |
| `lo`, `hi`, `avg` | smallest face, largest face, average |
| `set_face(i, v)` | change one face and mark it as upgraded |
| `clear` | forget the last roll (before each fight) |

### `logic/roll` – the only place dice randomness happens
| function | does |
|---|---|
| `roll_die(d)` | pick a face position from `1..#faces`, set `face_i` and `value` |
| `roll_many(list)` | roll each die in a list |

Leave a hook for luck here (step 10). For now it's a plain fair roll.

**Tests:** a roll is always one of that die's faces (for 3- and 6-faced dice) · a 3-faced die never rolls a position above 3 · upgrading one classic doesn't change another · `lo`/`hi`/`avg` are right for each type.

---

## 2. Player (the run's state)

### `entities/player`
Not drawn. One per run, stored as `global.run`.

| field | meaning |
|---|---|
| `hp`, `max_hp` | 20 / 20 at the start |
| `coins` | 0 at the start |
| `bag` | **every** die owned (placed or not) |
| `slots` | `{atk={}, spd={}, def={}, heal={}}`, lists of dice |
| `base` | `{atk=1, spd=1, def=0, heal=0}` |
| `cap` | `nil` = unlimited dice per slot (keep for an "extra slot" upgrade later) |
| `rerolls`, `rerolls_left` | per fight / left this fight |
| `stage_i` | current stage number |

| function | does |
|---|---|
| `place(d, k)` | move a die into slot `k` (takes it out of its old slot first), respecting `cap` |
| `unplace(d)` | back to the bag |
| `unused()` | dice with no slot |
| `stat(k)` | `base[k]` + sum of `value` of dice in slot `k` (never stored) |
| `range(k)` | lowest and highest possible total, for the "3–13" preview |
| `roll_all()` | roll every placed die, reset `rerolls_left` |
| `reroll(d)` | if `rerolls_left > 0`, roll that die again |
| `heal(n)`, `hurt(n)`, `dead()` | HP changes, clamped to `0..max_hp` |
| `earn(n)`, `spend(n)` | `spend` returns false if you can't afford it |
| `add_die(kind)`, `remove_die(d)` | for the shop |

**Tests:** `stat` follows placement · moving a die between slots never duplicates it · `range` of the starter layout is right · `spend` refuses when short.

---

## 3. Enemies, stages and the combat calculation

### `defs/enemies`
An `enemy_def()` factory: `id, name, hp, atk, spd, def, col, art` (`art` = a placeholder colour for now, a cart name later).

### `entities/enemy`
Created from a def at the start of each fight: `name, hp, max_hp, atk, spd, def, art` + `hurt(n)`, `dead()`, `drw()` (a rectangle for now).

### `defs/stages`
A list, one entry per fight:

| field | meaning |
|---|---|
| `enemy` | enemy id |
| `reward` | fixed coins for winning |
| `boss` | true for the last fight (no shop afterwards) |
| `luck` | luck strength for this stage (step 10) |
| `shop` | `{pool, offers, always, price_mult}`: which items can appear with weights, how many offers, items that always appear, price change |

### `logic/combat`
`simulate(stats, enemy)` → returns, without changing either side:

- `events`: in order, each `{who, kind, amount, p_hp, e_hp}`. `kind` = `"heal"` (first), `"hit"`
- `win`, `hp_left`

Rules: HEAL applies first, up to max HP · each tick both sides add SPD to a gauge · at 10 they hit and the gauge drops by 10 · ties go to the player · damage = `max(1, atk - def)` · cap the number of ticks to be safe.

The scene, not `simulate`, writes the result back into `run.hp`.

**Tests:** the example fight from the report (Slime, ATK 6, SPD 3, DEF 2 → win at 19 HP) · ties go to the player · minimum 1 damage · **balance:** the starter bag beats stage 1 in ≥ 90% of 500 seeded fights.

---

## 4. Run flow with placeholder screens

Every scene is plain text and keys only. The goal is a full run from start to finish.

- `title_scene` – ❎ = `new_run()` → place
- `place_scene` – a key to auto-place the dice, ❎ roll, ❎ fight
- `combat_scene` – show the result, ❎ continue
- `shop_scene` – ❎ next fight
- `end_scene` – `win` flag, lockout, then ❎ → title (like pacformer's game over)

### `logic/run` (or functions on `player`)
| function | does |
|---|---|
| `new_run()` | new player with the starter bag, `stage_i = 1` |
| `stage()` | current stage def |
| `finish_fight(result)` | apply HP · if lost → end · if boss → end (win) · else → shop |
| `next_stage()` | `stage_i += 1`, clear the dice's rolled values → place |

**Tests:** a scripted run through all stages reaches `end_scene` with `win = true` (force the numbers if needed) · a loss goes to `end_scene` with `win = false`.

---

## 5. Selection system

### `ui/selectable` (extends `game_object`)
| field | meaning |
|---|---|
| `x, y, w, h` | hit box |
| `enabled`, `focused` | state |
| `pressable`, `pickable` | what it allows |
| `accepts(item)` | can it receive a dropped item (slots return true for dice) |
| `on_press`, `on_drop(item)` | callbacks |

Functions: `contains(px, py)`, `center()`.

### `ui/focus` – one per scene
| field | meaning |
|---|---|
| `items` | the selectables on screen |
| `cur` | focused one |
| `held` | picked-up item, or `nil` |
| `mode` | `"keys"` or `"mouse"`, whichever was used last |

| function | does |
|---|---|
| `add / remove / clear` | manage items |
| `move(dx, dy)` | focus the nearest enabled item in that direction (while holding: only items that `accepts(held)`) |
| `upd` | read arrows / ❎ / 🅾️ and the mouse, and send **actions** to the scene |
| `drw` | focus frame; the held item follows the mouse, or floats over the focused target |

Actions sent to the scene: `press(item)`, `pick(item)`, `drop(item, target)`, `cancel(item)`.
Keys: ❎ on a pickable = pick up, ❎ again = drop, 🅾️ = cancel. Mouse: click = press, drag = pick → drop.

### `ui/button`
A selectable with a `label` and a default `drw`, for menus and "Fight" / "Next".

**Tests (keys only, with `hold`):** focus moves to the expected neighbour · pick + drop on a slot calls `run:place` · cancel puts the die back.

---

## 6. Place scene for real

| piece | fields / functions |
|---|---|
| `slot_view` (selectable) | `k`, `icon`, `col`, column position · `accepts` = die · `drw`: column, icon, range or total |
| `die_view` | either fields on `die` (`x, y, drawx, drawy`) or a small wrapper that's a selectable · `drw(opts)`: body, edge, shape, number, dim / upgraded / flash · square dice are drawn with rectangles, triangles from a sprite, so the stack spacing depends on the shape |
| `place_scene` | `state` + `place_states = {placing, rolling, rolled}` · `layout()` puts dice in stacks and the bag · `on_drop` → `run:place` / `unplace` + `layout()` · `start_roll()` · in `rolled`, pressing a die = `run:reroll` · "Fight" button → combat |

The idle dice slowly cycle through their faces in a dim colour. The range shows under each slot until the roll.

**Tests:** snaps of placing and rolled · rerolling uses up `rerolls_left`.

---

## 7. Combat scene playback

| field | meaning |
|---|---|
| `result` | from `simulate` |
| `ev_i`, `wait` | next event and frames until it plays |
| `p_shown`, `e_shown` | HP shown on the bars (tweened towards the real value) |
| `phase` | `intro`, `fight`, `result`, `loot` |
| `fast` | double speed |

Functions: `play_event(e)` (bars, damage number, shake) · `finish()` → `finish_fight` · in `loot`: throw the unused dice and show the reward → `run:earn`.

### `logic/economy`
`leftover_coins(dice)` (uses `roll_die`) · `reward(stage)`.

---

## 8. Shop

### `defs/shop_items`
`id, name, price, icon, target, apply(run, die, face_i)`, where `target` is `nil`, `"die"` or `"face"`.
Items: new dice (one per die type) · potion · heart (+max HP) · sharpen (face) · reforge (die) · reroll token · sell (die, gives coins).

### `logic/economy` (more)
`gen_offers(stage)` (weighted pick from `pool`, no duplicates, plus `always`) · `price(item, stage)` · refresh cost.

### `shop_scene`
`offers`, `focus`, `mode` (`browse`, `pick_die`, `pick_face`), `pending` (item being bought) · `buy(item)` → spend, then apply or switch to target mode · `refresh()` · "Next" → `next_stage`.

**Tests:** buying without enough coins does nothing · sharpen changes exactly one face of the chosen die · stage shop setup controls the offer count and items.

---

## 9. Feel

- `fx/roll_fx`: hop, cycling through the die's real faces, slowing down, squash on landing, flash, one die after another, sparkle on the highest face, thud on the lowest, totals counting up
- `fx/hit_fx`: damage numbers (`textp`), shake
- `fx/coin_fx`: leftover dice → coins
- the transition overlay, ported from breadjam to ptween
- inspect panel: double-size die, its faces in a row (works for 3 and 6), spread bars
- sound effects

---

## 10. Luck and balance

- Add the luck hook in `roll_die`, using `stage().luck` (see the discussion in chat).
- Balance tests: win rate per stage, HP left after each fight, coins per run.

---

## 11. Enemy art and finishing

- Load each enemy's sprite sheet from its own cart with `reload()` before the fight.
- Title and end screens, `make flat`, export, itch page.
