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
  - over at tick 1000 (a loss); if nobody can do damage, a loss after 30
    ticks (only bombs could win it)

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

# src/defs/dice.p8.lua: d3 / d6 / d8, each with a + (every face +1) and a ++
# (+2), 2 coins more per +
DICE = {}
for _name, _top, _price in (("d3", 3, 1), ("d6", 6, 4), ("d8", 8, 6)):
    for _plus in range(3):
        DICE[_name + "+" * _plus] = dict(faces=[f + 1 + _plus for f in range(_top)],
                                         price=_price + 2 * _plus)
# src/defs/shop_items.p8.lua. the bot never buys "double" (a copy of a placed
# die for one fight, needs a free bag spot: rarely possible with 5 dice).
# enchantments (ENCH) go on a die (d["ench"], one per die): greedy = unused
# pays 2x, grower = placed: lowest face +1 for good, wild = moved after the
# roll, glass = rolls 2x and breaks 1 in 4 when the fight starts
ITEMS = {"potion": 3, "bomb": 6, "reroll": 1, "double": 4,
         "greedy": 3, "grower": 3, "wild": 3, "glass": 3}
ENCH = ("greedy", "grower", "wild", "glass")
# level ups: bought = every base stat + n for the rest of the run (never in
# the inventory)
LVL = {"lvl up": 1, "lvl up+": 2}
ITEMS.update({"lvl up": 6, "lvl up+": 9})
# rigs: + this much to a random face of a die, for good
RIG = {"rig": 1, "rig+": 2, "rig++": 3}
ITEMS.update({"rig": 3, "rig+": 4, "rig++": 6})
# the regular item pool in tier order (gen_offers / pick): the first 6 at
# first, 8 from idx 2, all 9 from idx 3. enchantments: one per shop, last
ITEM_TIERS = ["potion", "bomb", "reroll", "double", "rig", "lvl up", "rig+", "lvl up+", "rig++"]

# src/defs/enemies.p8.lua -- a list is a stat that rolls one of its values
ENEMIES = {
    "tourist":    dict(hp=8, atk=2, spd=1, defn=1),
    "drunk": dict(hp=16, atk=3, spd=10, defn=1),
    "bouncer":    dict(hp=22, atk=5, spd=2, defn=7),
    "gambler":    dict(hp=28, atk=[4, 12], spd=5, defn=1),
    "slot machine":      dict(hp=35, atk=100, spd=-3, defn=2),
    "loan shark": dict(hp=28, atk=22, spd=0, defn=3),
    "the house":  dict(hp=32, atk=list(range(11, 17)), spd=list(range(3, 9)),
                       defn=list(range(5, 11))),
}

# src/defs/stages.p8.lua; the shop after each fight is src/logic/economy.p8.lua
# gen_offers: 4 offers, 3 dice + 1 item in the opening shop, then 2 + 2 or
# 1 + 3 (a coin flip), every kind equally likely
STAGES = [
    dict(reward=0),  # 0: the opening shop, no fight
    dict(enemy="tourist", reward=5),
    dict(enemy="drunk", reward=6),
    dict(enemy="bouncer", reward=7),
    dict(enemy="gambler", reward=8),
    dict(enemy="slot machine", reward=9),
    dict(enemy="loan shark", reward=10),
    dict(enemy="the house", boss=True),
]

# how the bot shops (Run.shop): lam = coins one point of average is worth
# when choosing between dice, upgrade = how much better a die must be to
# replace the weakest, late = from which shop it stocks bombs (up to bombs) and
# a reroll token, potions = how many it keeps, rerolls / keep = rerolls the
# offers while the cost is at most rerolls and keep coins stay, grower / wild
# = what those enchantments are worth in average, ench = from how many dice
# it buys enchantments
POLICY = dict(lam=0.25, upgrade=0.5, late=2, bombs=2, potions=2, rerolls=3, keep=1,
              grower=0.7, wild=0.6, ench=3, lvl_spare=0)

# src/entities/player.p8.lua, src/logic/economy.p8.lua
MAX_HP, START_COINS, BASE = 40, 10, dict(atk=1, spd=1, defn=0)
POTION_HEAL, BOMB_DMG, INV_SIZE, STACK_MAX = 10, 10, 3, 5
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
        self.lvl = 0  # level ups bought: + this to every base stat

    def shop(self, stage, idx=0):
        """buys like a good player (POLICY tunes it; see main --policy):
        potions when hurt, then dice by value (value() below: an enchanted
        die counts its enchantment), upgrades once the bag is full, rig on the
        best die, enchantments (greedy on the weakest die, the rest on the
        best die without one), bombs and a reroll token for the late bosses,
        and rerolls the offers while it can afford to."""
        P = POLICY
        offers = self.offers(idx)
        rerolls = 0
        while True:
            if self.hp <= MAX_HP - POTION_HEAL and self.can_buy_item("potion", offers):
                self.buy_item("potion", offers)
                continue
            # level up: the biggest one offered that it can afford
            lvls = [k for k in LVL if k in offers and self.coins >= ITEMS[k] + P["lvl_spare"]]
            if lvls:
                k = max(lvls, key=LVL.get)
                self.coins -= ITEMS[k]
                self.lvl += LVL[k]
                offers.remove(k)
                continue
            full = len(self.bag) >= BAG_MAX
            dice = [o for o in offers if o in DICE]
            if full:
                # a full bag: only an upgrade, paid partly by selling the weakest
                weakest = min(self.bag, key=lambda d: self.value(d["kind"], d))
                wv = self.value(weakest["kind"], weakest)
                dice = [o for o in dice if self.value(o) > wv + P["upgrade"]
                        and DICE[o]["price"] <= self.coins + sell_price(weakest)]
            else:
                dice = [o for o in dice if DICE[o]["price"] <= self.coins]
            if dice:
                best = max(dice, key=lambda k: self.value(k) - P["lam"] * DICE[k]["price"])
                if full:
                    self.bag.remove(weakest)
                    self.coins += sell_price(weakest)
                self.coins -= DICE[best]["price"]
                self.bag.append(dict(kind=best, faces=list(DICE[best]["faces"])))
                offers.remove(best)
                continue
            # rig: the biggest one offered, on a random face of your best die
            rigs = [k for k in RIG if len(self.bag) >= 4 and self.can_buy_item(k, offers, 2)]
            if rigs:
                k = max(rigs, key=RIG.get)
                self.buy_item(k, offers)
                d = max(self.bag, key=lambda d: self.value(d["kind"], d))
                d["faces"][self.rng.randrange(len(d["faces"]))] += RIG[k]
                continue
            plain = [d for d in self.bag if not d.get("ench")]
            if len(self.bag) >= P["ench"] and plain:
                ench = next((k for k in ENCH if self.can_buy_item(k, offers, 1)), None)
                if ench:
                    self.coins -= ITEMS[ench]
                    offers.remove(ench)
                    pick = min if ench == "greedy" else max
                    pick(plain, key=lambda d: self.value(d["kind"], d))["ench"] = ench
                    continue
            late = idx >= P["late"]
            if late and self.items["bomb"] < P["bombs"] and self.can_buy_item("bomb", offers, 1):
                self.buy_item("bomb", offers)
                continue
            if late and self.items["reroll"] < 1 and self.can_buy_item("reroll", offers, 1):
                self.buy_item("reroll", offers)
                continue
            if self.items["potion"] < P["potions"] and self.can_buy_item("potion", offers, 1):
                self.buy_item("potion", offers)
                continue
            # a shop reroll always costs 1; the bot stops after P["rerolls"]
            if self.coins >= 1 + P["keep"] and rerolls < P["rerolls"]:
                self.coins -= 1
                rerolls += 1
                offers = self.offers(idx)
                continue
            return

    def value(self, kind, d=None):
        """what a die is worth to this bag, in average stat"""
        f = d["faces"] if d else DICE[kind]["faces"]
        v = sum(f) / len(f)
        pk = d and d.get("ench")
        if pk == "glass":
            v *= 1.5  # double, minus the chance of losing it
        elif pk in ("grower", "wild"):
            v += POLICY[pk]
        return v

    def can_buy_item(self, k, offers, spare=0):
        """offered, affordable (with spare coins left), and a stack with room
        or a free inventory slot"""
        stacks = sum(-(-n // STACK_MAX) for n in self.items.values() if n)
        room = self.items[k] % STACK_MAX != 0 or stacks < INV_SIZE
        return k in offers and self.coins >= ITEMS[k] + spare and room

    def buy_item(self, k, offers):
        self.coins -= ITEMS[k]
        self.items[k] += 1
        offers.remove(k)

    def offers(self, idx):
        """src/logic/economy.p8.lua gen_offers: dice first, one enchantment
        last. shop 1 (idx 0) 2 dice + ench, shop 2 1 die + 1 item + ench, then
        1 die + 2 items + ench. + dice and items from idx 2, ++ from idx 3"""
        top = 0 if idx < 2 else 1 if idx < 3 else 2
        dice = [k for k in DICE if k.count("+") <= top]
        items = ITEM_TIERS[:(6, 8, 9)[top]]
        n_dice, n = (2, 3) if idx == 0 else (1, 3) if idx == 1 else (1, 4)
        return ([self.rng.choice(dice) for _ in range(n_dice)]
                + [self.rng.choice(items) for _ in range(n - n_dice - 1)]
                + [self.rng.choice(ENCH)])


def sell_price(d):
    return DICE[d["kind"]]["price"] // 2


def avg(d):
    return sum(d["faces"]) / len(d["faces"])


def kind_avg(kind):
    f = DICE[kind]["faces"]
    return sum(f) / len(f)


def perk(d):
    return d.get("ench")


def roll(rng, d):
    """src/logic/roll.p8.lua roll_die: a glass die rolls double"""
    return rng.choice(d["faces"]) * (2 if perk(d) == "glass" else 1)


def stats_of(bag, place, values, lvl=0):
    """values are the rolls (glass already doubled); an unused greedy die
    pays 2x. lvl: level ups bought, added to every base stat"""
    s = {k: v + lvl for k, v in BASE.items()}
    coins = 0
    for i, dest in enumerate(place):
        if dest == BAG:
            coins += values[i] * (2 if perk(bag[i]) == "greedy" else 1)
        else:
            s[STATS[dest]] += values[i]
    return s, coins


def score(run, enemy, place, samples):
    """mean over pre-rolled samples (common random numbers, so placements are
    compared on the same luck): win chance first, then hp kept, then coins."""
    total = 0.0
    e_hp = ENEMIES[enemy]["hp"]
    for values, foe in samples:
        s, coins = stats_of(run.bag, place, values, run.lvl)
        left = fight(s, foe, run.hp, e_hp)
        if left:
            total += 300 + left + 0.5 * coins
    return total / len(samples)


def sample_rolls(run, enemy, n):
    return [([roll(run.rng, d) for d in run.bag], roll_enemy(enemy, run.rng))
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
    values = [roll(run.rng, d) for d in run.bag]
    # glass decides at the roll whether it breaks when the fight starts
    run.broke = broke = [perk(d) == "glass" and run.rng.random() < 0.25 for d in run.bag]
    foe = roll_enemy(enemy, run.rng)
    e_hp = ENEMIES[enemy]["hp"]
    if style == "smart":
        # wild dice: after seeing the rolls, move each to its best spot
        for i, d in enumerate(run.bag):
            if perk(d) != "wild":
                continue
            best = None
            for dest in range(4):
                if dest != place[i] and not room(place, dest):
                    continue
                trial = place[:]
                trial[i] = dest
                st, c = stats_of(run.bag, trial, values, run.lvl)
                key = (fight(st, foe, run.hp, e_hp), c)
                if best is None or key > best[0]:
                    best = (key, trial)
            place = best[1]
    # growers placed in the fight: lowest face +1 (the last one of that value)
    for i, d in enumerate(run.bag):
        if perk(d) == "grower" and place[i] != BAG:
            f = d["faces"]
            j = max(k for k in range(len(f)) if f[k] == min(f))
            f[j] += 1
    s, coins = stats_of(run.bag, place, values, run.lvl)
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
                wins += fight(stats_of(run.bag, place, v, run.lvl)[0], foe, run.hp, e_hp) > 0
            if wins > best_p:
                best_i, best_p = i, wins
        if best_i is not None:
            run.items["reroll"] -= 1
            values[best_i] = roll(run.rng, run.bag[best_i])
            broke[best_i] = perk(run.bag[best_i]) == "glass" and run.rng.random() < 0.25
            s, coins = stats_of(run.bag, place, values, run.lvl)
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
        run.bag = [d for d, b in zip(run.bag, run.broke) if not b]
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
        run.shop(st, i)
    return len(STAGES), log


def matchup_table(n_samples=400, seed=1):
    """each boss against the same mid-run bag, placed every way: how much does
    the best placement beat the naive ones? (the puzzle, isolated)"""
    rng = random.Random(seed)
    bag = [dict(kind=k, faces=list(DICE[k]["faces"])) for k in ["d6", "d6", "d6+", "d3++", "d8"]]
    print("\nsame bag (2 d6, d6+, d3++, d8), full hp: win % per placement")
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
