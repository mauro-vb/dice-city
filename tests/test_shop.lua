-- most tests start from an empty inventory
local function fresh()
	new_run()
	run.items = {}
end

-- dice tier: 0 plain, 1 = +, 2 = ++ (by name)
function dice_tier(k)
	local n = 0
	for i = 1, #k.name do
		if sub(k.name, i, i) == "+" then n += 1 end
	end
	return n
end

test("buying a die adds it and returns it", function()
	fresh()
	local d = buy(d6)
	check(d and d.kind == d6 and #run.bag == 1 and run.coins == 10 - d6.price)
end)

test("can't buy without the coins", function()
	fresh()
	run.coins = d4.price - 1
	check(not buy(d4) and #run.bag == 0 and run.coins == d4.price - 1)
end)

test("same items stack in one slot, up to stack_max", function()
	fresh()
	run.coins = 999
	for i = 1, stack_max do
		buy(potion)
	end
	check(#run.items == 1 and run.items[1].n == stack_max)
	buy(potion)
	check(#run.items == 2 and run.items[2].n == 1, "full stack: new slot")
	buy(bomb)
	check(#run.items == 3 and run.items[3].k == bomb, "other kind: own slot")
	for i = 2, stack_max do
		buy(bomb)
	end
	check(run.items[3].n == stack_max and not can_buy(bomb), "bomb stack full, no free slot")
	check(can_buy(potion), "second potion stack still has room")
	check(run.hp == run.max_hp, "buying doesn't heal")
end)

test("potion: heals 10 when hurt, one from the stack", function()
	fresh()
	buy(potion)
	buy(potion)
	check(not use_item(1), "full hp: can't use")
	run.hp = run.max_hp - 2
	check(use_item(1) == potion and run.hp == run.max_hp and run.items[1].n == 1, "capped at max hp")
	run.hp = 10
	use_item(1)
	check(run.hp == 20 and #run.items == 0, "last one frees the slot")
end)

test("potion mid-fight heals the battle, not the run", function()
	fresh()
	buy(potion)
	run.hp = 10
	local b = battle:new({p = run, foe = enemy1})
	check(use_item(1, b) == potion and b.p_hp == 20 and run.hp == 10)
end)

test("bomb: 10 damage ignoring def, only in a fight", function()
	fresh()
	buy(bomb)
	check(not use_item(1), "no fight: can't use")
	local b = battle:new({p = run, foe = {hp = 12, atk = 1, spd = 1, def = 9}})
	check(use_item(1, b) == bomb and b.e_hp == 2 and #run.items == 0)
end)

test("a bomb can finish the fight", function()
	fresh()
	buy(bomb)
	local b = battle:new({p = run, foe = {hp = 9, atk = 1, spd = 1, def = 0}})
	use_item(1, b)
	check(b:over() and b:won())
end)

test("reroll item rerolls one die, not in a fight", function()
	fresh()
	buy(token)
	local d = run:add_die({name = "t", faces = {1, 2, 3}, price = 0})
	check(not can_use(1, battle:new({p = run, foe = enemy1})), "not mid-fight")
	check(use_item(1, false, d) == token and d.value and #run.items == 0)
end)

test("bag dice count as coins only after rolling", function()
	fresh()
	local k = {name = "t", faces = {2, 2, 2}, price = 0}
	run:add_die(k)
	run:add_die(k)
	check(leftover_coins(run:unused()) == 0)
	run:roll_all()
	check(leftover_coins(run:unused()) == 4)
end)

test("shop 1: 2 plain dice + 1 enchantment; shop 2: 1 die + 1 item + 1 enchantment", function()
	new_run(3)
	for i = 1, 20 do
		local o = gen_offers()
		check(#o == 3 and o[1].faces and o[2].faces and o[3].col, "2 + ench")
		check(dice_tier(o[1]) == 0 and dice_tier(o[2]) == 0, "plain dice only")
	end
	run.stage_i = 1
	for i = 1, 20 do
		local o = gen_offers()
		check(#o == 3 and o[1].faces and not o[2].faces and not o[2].col and o[3].col, "1 + 1 + ench")
		check(dice_tier(o[1]) == 0, "plain die only")
	end
end)

test("from shop 3: 1 die + 2 items + 1 enchantment; + dice from stage 2, ++ from 3", function()
	new_run(3)
	local top = {}
	for s = 2, 5 do
		run.stage_i = s
		top[s] = 0
		for i = 1, 60 do
			local o = gen_offers()
			check(#o == 4 and o[1].faces and not o[2].faces and not o[3].col and o[4].col, "1 + 2 + ench")
			top[s] = max(top[s], dice_tier(o[1]))
		end
	end
	check(top[2] == 1 and top[3] == 2 and top[5] == 2, "tiers "..top[2]..top[3]..top[5])
end)

test("greedy: unused it pays double its roll", function()
	fresh()
	local g, d = run:add_die(d4), run:add_die(d4)
	g.ench, g.value, d.value = greedy, 3, 3
	check(leftover_coins(run:unused()) == 9)
end)

test("same seed, same opening shop", function()
	new_run(7)
	local a = gen_offers()
	new_run(7)
	local b = gen_offers()
	for i = 1, #a do
		check(a[i] == b[i])
	end
end)

test("bag coins are counted when the fight starts, not after", function()
	fresh()
	local k = {name = "t", faces = {2, 2, 2}, price = 0}
	local a, c = run:add_die(k), run:add_die(k)
	run:place(a, "atk")
	run:roll_all()
	local b = battle:new({p = run, foe = enemy1})
	run:unplace(a)
	check(b.coins == 2 and b.stats.atk == 3, "only the unplaced die pays; atk kept")
end)

test("selling: half the price rounded down, die leaves the bag", function()
	fresh()
	run.coins = 0
	local d = run:add_die(d6p)
	check(sell_price(d) == flr(d6p.price / 2))
	sell(d)
	check(#run.bag == 0 and run.coins == flr(d6p.price / 2))
end)

test("at most dice_max dice", function()
	fresh()
	run.coins = 999
	for i = 1, dice_max do
		check(buy(d4))
	end
	check(not can_buy(d4) and #run.bag == dice_max, "bag full")
	check(can_buy(potion), "items still fine")
	sell(run.bag[1])
	check(can_buy(d4), "room again after selling")
end)

test("a column takes at most 3 dice", function()
	fresh()
	local col = slot:new({key = "atk"})
	for i = 1, 4 do
		run:add_die(d6)
	end
	for i = 1, 3 do
		check(col:accepts(run.bag[i]))
		run:place(run.bag[i], "atk")
	end
	check(not col:accepts(run.bag[4]), "full")
	check(col:accepts(run.bag[1]), "a die already in it can move within it")
end)

test("d8 rolls 1-8 and prints its value", function()
	local d = die:new({kind = d8})
	for _ = 1, 30 do
		roll_die(d)
		check(d.value >= 1 and d.value <= 8)
	end
	check(d.w == 16)
end)

test("double: a temporary copy in the same column, if it fits", function()
	fresh()
	run.coins = 99
	buy(double)
	buy(double)
	local d = run:add_die(d6)
	check(not use_item(1, false, d) and run.items[1].n == 2, "not placed: refused, not used up")
	run:place(d, "atk")
	roll_die(d)
	check(use_item(1, false, d) == double and #run.slots.atk == 2)
	local c = run.slots.atk[2]
	check(c.temp and c.value == d.value and c.kind == d6 and c.faces != d.faces, "same value, own faces")
	check(not c.ench, "never enchanted")
	run:place(run:add_die(d4), "atk")
	check(not use_item(1, false, d), "column full")
end)

test("enchant: becomes the die's ench, a new one replaces it", function()
	fresh()
	run.coins = 99
	buy(greedy)
	buy(wild)
	local d = run:add_die(d6)
	check(use_item(1, false, d) == greedy and d.ench == greedy)
	check(use_item(1, false, d) == wild and d.ench == wild, "replaced")
	check(#run.items == 0, "both used")
end)

test("rig+ marks its face +2", function()
	fresh()
	run.items = {{k = rigp, n = 1}}
	local d = run:add_die(d6)
	use_item(1, false, d)
	local n = 0
	for i = 1, 6 do
		if d.rigged[i] then
			n += 1
			check(d.rigged[i] == 2 and d.faces[i] == i + 2)
		end
	end
	check(n == 1)
end)
