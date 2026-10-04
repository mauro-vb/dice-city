-- a random kind from l, ordered by tier: the first n[1] at first, n[2] from
-- stage 2, n[3] from stage 3
function pick(l, n)
	return l[flr(rnd(n[mid(1, run.stage_i, 3)])) + 1]
end

-- dice first, one enchantment last. shop 1: 2 dice + ench, shop 2: 1 die +
-- 1 item + ench, then 1 die + 2 items + ench. offers can repeat
function gen_offers()
	local s, offers = run.stage_i, {}
	local n = s < 2 and 3 or 4
	for i = 1, n do
		add(offers, i == n and rnd(ench_kinds) or i <= (s < 1 and 2 or 1) and pick(dice_kinds, dice_tiers) or pick(item_kinds, item_tiers))
	end
	return offers
end

-- what an unused die pays on a win: its roll, double for a greedy die
function coin_value(d)
	return (d.value or 0) * (d.ench == greedy and 2 or 1)
end

-- unused dice were rolled with the rest: their values become coins
function leftover_coins(dice)
	local sum = 0
	for d in all(dice) do
		sum += coin_value(d)
	end
	return sum
end

-- inventory items need a stack of their kind with room, or a free slot
-- dice need room in the bag (dice_max)
dice_max = 5

function can_buy(k)
	return run.coins >= k.price and (not k.inv or stack_for(k) or #run.items < inv_size)
		and (not k.faces or #run.bag < dice_max)
end

-- returns the new die for dice, true for items, false if you can't
function buy(k)
	if not can_buy(k) then return false end
	run:spend(k.price)
	if k.inv then
		local s = stack_for(k)
		if s then s.n += 1 else add(run.items, {k = k, n = 1}) end
		return true
	end
	-- a level up
	if k.up then
		for s in all(stat_names) do
			run.base[s] += k.up
		end
		return true
	end
	return run:add_die(k)
end

-- inventory: inv_size slots, each a stack {k = item, n = count} of one kind
-- (up to stack_max). b = the battle when used mid-fight, else false.
-- potion: heals 10 when hurt (the fight's hp in a fight). bomb: 10 damage to
-- the enemy, ignoring def, only in a fight. token: rerolls die d (scenes
-- decide when: after rolling). double: a temporary copy of placed die d.
-- rig: +up to a random face of die d, for good (d.rigged = up on that face).
-- an enchantment (has a col) becomes d.ench, replacing the old one
inv_size, stack_max = 3, 5

function stack_for(k)
	for s in all(run.items) do
		if s.k == k and s.n < stack_max then return s end
	end
end

function can_use(i, b)
	local s = run.items[i]
	if not s then return false end
	if s.k == potion then return (b and b.p_hp or run.hp) < run.max_hp end
	if s.k.aim then return not b end
	return b and b.e_hp > 0
end

-- uses one item from stack i (d = the die for a reroll); returns its kind, or false
function use_item(i, b, d)
	local s = run.items[i]
	-- a double needs a placed die and room in its column (its copy can go
	-- past dice_max: it leaves when the fight starts)
	if not can_use(i, b) or s.k == double and not (d.slot and #run.slots[d.slot] < 3) then return false end
	s.n -= 1
	if s.n == 0 then deli(run.items, i) end
	if s.k == bomb then
		b:blast(10)
	elseif s.k == token then
		roll_die(d)
	elseif s.k == double then
		-- [sfx 45: glass shatter] a temporary copy in the same column (gone
		-- when the fight starts)
		sfx(45)
		local c = run:add_die(d.kind)
		c.faces, c.rigged, c.value, c.face_i, c.temp, c.x, c.y = {unpack(d.faces)}, d.rigged, d.value, d.face_i, true, d.x, d.y
		run:place(c, d.slot)
	elseif s.k.up then
		local f = flr(rnd(#d.faces)) + 1
		d.faces[f] += s.k.up
		d.rigged[f] = s.k.up
	elseif s.k.col then
		-- [sfx 48: enchant]
		sfx(48)
		d.ench = s.k
	else
		-- [sfx 46: heal] a beer
		sfx(46)
		if b then
			b:heal(10)
		else
			run.hp = min(run.max_hp, run.hp + 10)
		end
	end
	return s.k
end

-- dice sell for half their price, rounded down (shop only)
function sell_price(d)
	return flr(d.kind.price / 2)
end

function sell(d)
	run.coins += sell_price(d)
	del(run.bag, d)
end
