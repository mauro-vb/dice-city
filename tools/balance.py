#!/usr/bin/env python3
"""Balance simulator for the boss ladder: plays thousands of runs with a
scripted player and prints win rates per boss, so tuning src/defs/enemies.p8.lua
and src/defs/stages.p8.lua is driven by numbers instead of guesses.

    python3 tools/balance.py            # full report (~1 min)
    python3 tools/balance.py --runs 100 # quicker, noisier

Pure python, no dependencies. The numbers below are COPIES of the lua defs:
if you change a die, an enemy or a stage in src/defs/, change it here too
(or the report describes a different game).

How a fight resolves (mirrors src/logic/combat.p8.lua, verified against
tests/test_combat.lua): stats are fixed once the dice are rolled, so a fight is
deterministic and has a closed form instead of a tick loop:
  - a side with speed s fills its bar by s + 5 a tick and hits at 100, so its
    k-th hit lands on tick ceil(100 * k / (s + 5))
  - a hit does max(0, atk - other side's def)
  - the player needs n = ceil(enemy hp / dmg) hits, landing on tick t
  - the enemy gets floor((t - 1) * rate / 100) hits in before that (the
    player hits first within a tick, so a hit on tick t itself never lands)
  - over at tick 1000, and a fight nobody can win is a loss

The scripted players:
  smart  - searches dice placements for the best win chance (then hp kept,
           then coins), uses the reroll token on a losing roll, drinks
           potions and throws bombs when that flips a loss
  atk    - "naive": every die on atk
  even   - "naive": dice dealt round-robin over atk/spd/def, biggest first
All three shop the same way, so the gap between them is placement skill:
that gap is what makes a boss a puzzle.
"""
import argparse
import random
from collections import Counter

# --- copies of src/defs ----------------------------------------------------

DICE = {  # src/defs/dice.p8.lua
    "d3": dict(faces=[1, 2, 3], price=1),
    "d6": dict(faces=[1, 2, 3, 4, 5, 6], price=4),
    "gambler": dict(faces=[0, 0, 0, 6, 6, 6], price=3),
    "d3+": dict(faces=[3, 4, 5], price=5),
    "d8": dict(faces=[1, 2, 3, 4, 5, 6, 7, 8], price=6),
    "d3++": dict(faces=[4, 5, 6], price=7),
}
# src/defs/shop_items.p8.lua. the bot never buys "double" (a copy of a placed
# die for one fight, needs a free bag spot: rarely possible with 5 dice)
ITEMS = {"potion": 3, "bomb": 4, "reroll": 3, "double": 4, "rig": 4}

# src/defs/enemies.p8.lua -- a list is a stat that rolls one of its values
ENEMIES = {
    "tourist":    dict(hp=8, atk=2, spd=1, defn=0),
    "pickpocket": dict(hp=14, atk=3, spd=14, defn=0),
    "bouncer":    dict(hp=24, atk=4, spd=2, defn=6),
    "gambler":    dict(hp=24, atk=[3, 8], spd=6, defn=0),
    "card sharp": dict(hp=8, atk=20, spd=8, defn=1),
    "loan shark": dict(hp=24, atk=21, spd=0, defn=3),
    "the house":  dict(hp=26, atk=list(range(9, 15)), spd=list(range(2, 8)),
                       defn=list(range(4, 10))),
}

# src/defs/stages.p8.lua; the shop after each fight is src/logic/economy.p8.lua
# gen_offers: 4 offers, 3 dice + 1 item in the opening shop, then 2 + 2 or
# 1 + 3 (a coin flip), every kind equally likely
STAGES = [
    dict(reward=0),  # 0: the opening shop, no fight
    dict(enemy="tourist", reward=2),
    dict(enemy="pickpocket", reward=2),
    dict(enemy="bouncer", reward=3),
    dict(enemy="gambler", reward=3),
    dict(enemy="card sharp", reward=4),
    dict(enemy="loan shark", reward=4),
    dict(enemy="the house", boss=True),
]

# src/entities/player.p8.lua, src/logic/economy.p8.lua
MAX_HP, START_COINS, BASE = 20, 20, dict(atk=1, spd=1, defn=0)
POTION_HEAL, BOMB_DMG, INV_SIZE, STACK_MAX = 5, 4, 3, 5
STATS = ("atk", "spd", "defn")
BAG = 3  # placement destination index for "unused": its value becomes coins
BAG_MAX = 5  # most dice you can own (src/logic/economy.p8.lua dice_max)
COL_MAX = 3  # most dice in one stat column (src/entities/slot.p8.lua)

# --- combat ----------------------------------------------------------------


def fight(p, e, p_hp, e_hp):
    """p, e: dicts of atk/spd/defn. returns hp left (> 0 means a win, 0 a loss)."""
    pd, ed = max(0, p["atk"] - e["defn"]), max(0, e["atk"] - p["defn"])
    if pd == 0:
        return 0
    t = -(-100 * -(-e_hp // pd) // (p["spd"] + 5))  # ceil(100 * ceil(hp/pd) / rate)
    if t > 1000:
        return 0
    return max(0, p_hp - ed * ((t - 1) * (e["spd"] + 5) // 100))


def roll_enemy(name, rng):
    """a stat given as a list rolls one of its values (src/logic/roll.p8.lua roll_foe)"""
    e = ENEMIES[name]
    return {k: rng.choice(e[k]) if isinstance(e[k], list) else e[k] for k in STATS}


# --- the scripted player ---------------------------------------------------


class Run:
    def __init__(self, rng):
        self.rng = rng
        self.hp, self.coins = MAX_HP, START_COINS
        self.bag = []  # dice: {"kind": name, "faces": [...]} (rig changes faces)
        self.items = Counter()

    def can_buy_potion(self, offers):
        """offered, affordable, and a stack with room or a free inventory slot"""
        stacks = sum(-(-n // STACK_MAX) for n in self.items.values() if n)
        room = self.items["potion"] % STACK_MAX != 0 or stacks < INV_SIZE
        return "potion" in offers and self.coins >= ITEMS["potion"] and room

    def shop(self, stage):
        """buys like a sensible player: potions when hurt, then the dice with
        the most stat per coin, rerolling the offers while it's cheap."""
        offers = self.offers(stage)
        reroll_cost = 1
        while True:
            if self.hp <= MAX_HP - POTION_HEAL and self.can_buy_potion(offers):
                self.coins -= ITEMS["potion"]
                self.items["potion"] += 1
                offers.remove("potion")
                continue
            dice = [o for o in offers if o in DICE and DICE[o]["price"] <= self.coins]
            full = len(self.bag) >= BAG_MAX
            if full:
                # a full bag: only an upgrade, paid partly by selling the weakest
                weakest = min(self.bag, key=avg)
                dice = [o for o in dice if kind_avg(o) > avg(weakest) + 0.5
                        and DICE[o]["price"] <= self.coins + sell_price(weakest)]
            if dice:
                if full:
                    best = max(dice, key=kind_avg)
                    self.bag.remove(weakest)
                    self.coins += sell_price(weakest)
                else:
                    best = max(dice, key=lambda k: (kind_avg(k) / DICE[k]["price"], kind_avg(k)))
                self.coins -= DICE[best]["price"]
                self.bag.append(dict(kind=best, faces=list(DICE[best]["faces"])))
                offers.remove(best)
                continue
            # rig: +2 on a random face of your best die, for good
            if "rig" in offers and full and self.coins >= ITEMS["rig"] + 2:
                self.coins -= ITEMS["rig"]
                d = max(self.bag, key=avg)
                d["faces"][self.rng.randrange(len(d["faces"]))] += 2
                offers.remove("rig")
                continue
            if self.coins >= reroll_cost + 1 and reroll_cost <= 3:
                self.coins -= reroll_cost
                reroll_cost += 1
                offers = self.offers(stage)
                continue
            if self.items["potion"] < 2 and self.can_buy_potion(offers):
                self.coins -= ITEMS["potion"]
                self.items["potion"] += 1
                offers.remove("potion")
                continue
            return

    def offers(self, stage):
        n = 3 if "enemy" not in stage else self.rng.choice([1, 2])
        return [self.rng.choice(list(DICE) if i < n else list(ITEMS)) for i in range(4)]


def sell_price(d):
    return DICE[d["kind"]]["price"] // 2


def avg(d):
    return sum(d["faces"]) / len(d["faces"])


def kind_avg(kind):
    f = DICE[kind]["faces"]
    return sum(f) / len(f)


def stats_of(bag, place, values):
    s = dict(BASE)
    coins = 0
    for i, dest in enumerate(place):
        if dest == BAG:
            coins += values[i]
        else:
            s[STATS[dest]] += values[i]
    return s, coins


def score(run, enemy, place, samples):
    """mean over pre-rolled samples (common random numbers, so placements are
    compared on the same luck): win chance first, then hp kept, then coins."""
    total = 0.0
    e_hp = ENEMIES[enemy]["hp"]
    for values, foe in samples:
        s, coins = stats_of(run.bag, place, values)
        left = fight(s, foe, run.hp, e_hp)
        if left:
            total += 300 + left + 0.5 * coins
    return total / len(samples)


def sample_rolls(run, enemy, n):
    return [([run.rng.choice(d["faces"]) for d in run.bag], roll_enemy(enemy, run.rng))
            for _ in range(n)]


def best_place(run, enemy, n_samples=48):
    """local search over placements (move one die at a time), from a few
    starting points. dice of the same kind are interchangeable, so only one
    die per (kind, slot) is tried as a move."""
    samples = sample_rolls(run, enemy, n_samples)
    n = len(run.bag)
    order = sorted(range(n), key=lambda i: -avg(run.bag[i]))
    starts = [[0] * n, [i % 3 for i in range(n)], [[0, 2, 0, 1][i % 4] for i in range(n)],
              [[2, 0, 2, 0][i % 4] for i in range(n)]]
    best, best_s = None, -1
    for start in starts:
        place = [0] * n
        for rank, i in enumerate(order):
            place[i] = start[rank]
        place = fit(place, order)
        cur = score(run, enemy, place, samples)
        improved = True
        while improved:
            improved = False
            tried = set()
            for i in range(n):
                for dest in range(4):
                    key = (tuple(run.bag[i]["faces"]), place[i], dest)
                    if dest == place[i] or key in tried or not room(place, dest):
                        continue
                    tried.add(key)
                    old = place[i]
                    place[i] = dest
                    s = score(run, enemy, place, samples)
                    if s > cur + 1e-9:
                        cur, improved = s, True
                        break
                    place[i] = old
                if improved:
                    break
        if cur > best_s:
            best, best_s = place[:], cur
    return best


def room(place, dest):
    return dest == BAG or place.count(dest) < COL_MAX


def fit(place, order):
    """biggest dice first; a die whose column is full goes to the bag"""
    out = [BAG] * len(place)
    for i in order:
        if room(out, place[i]):
            out[i] = place[i]
    return out


def naive_place(run, style):
    """atk: atk first (a full column spills into spd, then def).
    even: biggest dice dealt round-robin over atk/spd/def"""
    n = len(run.bag)
    order = sorted(range(n), key=lambda i: -avg(run.bag[i]))
    place = [BAG] * n
    for rank, i in enumerate(order):
        if style == "even":
            place[i] = rank % 3
        else:
            place[i] = next(d for d in range(3) if room(place, d))
    return place


def play_fight(run, enemy, style):
    """one fight with the items the policy allows; returns hp left (0 = lost)."""
    place = best_place(run, enemy) if style == "smart" else naive_place(run, style)
    values = [run.rng.choice(d["faces"]) for d in run.bag]
    foe = roll_enemy(enemy, run.rng)
    e_hp = ENEMIES[enemy]["hp"]
    s, coins = stats_of(run.bag, place, values)
    run.last_stats = s
    left = fight(s, foe, run.hp, e_hp)
    if style != "smart":
        return left, coins
    # reroll token: on a losing roll, reroll the placed die with the best odds
    if not left and run.items["reroll"]:
        best_i, best_p = None, 0
        for i, dest in enumerate(place):
            if dest == BAG:
                continue
            wins = 0
            for f in run.bag[i]["faces"]:
                v = values[:]
                v[i] = f
                wins += fight(stats_of(run.bag, place, v)[0], foe, run.hp, e_hp) > 0
            if wins > best_p:
                best_i, best_p = i, wins
        if best_i is not None:
            run.items["reroll"] -= 1
            values[best_i] = run.rng.choice(run.bag[best_i]["faces"])
            s, coins = stats_of(run.bag, place, values)
            left = fight(s, foe, run.hp, e_hp)
    # potions and bombs mid-fight, only when they turn the loss around
    # (approximation: a potion counts as +5 hp, as if drunk at the right moment)
    pots, bombs = 0, 0
    while not left and (pots < run.items["potion"] or bombs < run.items["bomb"]):
        if bombs < run.items["bomb"]:
            bombs += 1
        else:
            pots += 1
        left = fight(s, foe, run.hp + POTION_HEAL * pots, max(1, e_hp - BOMB_DMG * bombs))
    if left:
        run.items["potion"] -= pots
        run.items["bomb"] -= bombs
        left = min(left, MAX_HP)
    return left, coins


def play_run(seed, style):
    """returns the stage reached (len(STAGES) = beat the final boss) and a
    per-fight log of (hp going in, dice in bag, rolled stats)."""
    run = Run(random.Random(seed))
    run.shop(STAGES[0])
    log = []
    for i in range(1, len(STAGES)):
        st = STAGES[i]
        left, coins = play_fight(run, st["enemy"], style)
        log.append((run.hp, len(run.bag), run.last_stats))
        if not left:
            return i, log
        run.hp = left
        if st.get("boss"):
            return len(STAGES), log
        run.coins += st["reward"] + coins
        while run.hp <= MAX_HP - POTION_HEAL and run.items["potion"]:
            run.items["potion"] -= 1
            run.hp += POTION_HEAL
        run.shop(st)
    return len(STAGES), log


def matchup_table(n_samples=400, seed=1):
    """each boss against the same mid-run bag, placed every way: how much does
    the best placement beat the naive ones? (the puzzle, isolated)"""
    rng = random.Random(seed)
    bag = [dict(kind=k, faces=list(DICE[k]["faces"])) for k in ["d6", "d6", "d6", "d3+", "d8"]]
    print("\nsame bag (3 d6, d3+, d8), full hp: win % per placement")
    print(f"{'boss':12} {'smart':>6} {'all atk':>8} {'even':>6}  smart placement (atk/spd/def/bag dice)")
    for name in ENEMIES:
        run = Run(rng)
        run.bag = bag
        res = {}
        for style in ("smart", "atk", "even"):
            place = best_place(run, name, 96) if style == "smart" else naive_place(run, style)
            samples = sample_rolls(run, name, n_samples)
            wins = sum(fight(stats_of(bag, place, v)[0], f, MAX_HP, ENEMIES[name]["hp"]) > 0
                       for v, f in samples)
            res[style] = (100 * wins / n_samples, place)
        sp = res["smart"][1]
        desc = "/".join(str(sum(1 for d in sp if d == k)) for k in range(4))
        print(f"{name:12} {res['smart'][0]:6.0f} {res['atk'][0]:8.0f} {res['even'][0]:6.0f}  {desc}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=400)
    args = ap.parse_args()
    names = [st["enemy"] for st in STAGES[1:]]
    for style in ("smart", "atk", "even"):
        reached = Counter()
        hp_in, dice_in, split = Counter(), Counter(), {}
        for seed in range(args.runs):
            r, log = play_run(seed, style)
            reached[r] += 1
            for i, (hp, n, st) in enumerate(log):
                hp_in[i] += hp
                dice_in[i] += n
                sp = split.setdefault(i, Counter())
                sp.update(st)
        print(f"\n{style} player, {args.runs} runs")
        print(f"  {'boss':12} {'reach%':>7} {'win%':>6} {'hp in':>6} {'dice':>5}  avg atk/spd/def")
        alive = args.runs
        for i, name in enumerate(names):
            got = sum(v for k, v in reached.items() if k > i + 1)
            fought = alive
            if fought:
                print(f"  {name:12} {100 * fought / args.runs:7.0f} {100 * got / fought:6.0f}"
                      f" {hp_in[i] / fought:6.1f} {dice_in[i] / fought:5.1f}  "
                      + "/".join(f"{split[i][k] / fought:.0f}" for k in STATS))
            alive = got
        print(f"  run win rate: {100 * reached[len(STAGES)] / args.runs:.0f}%")
    matchup_table()


if __name__ == "__main__":
    main()
