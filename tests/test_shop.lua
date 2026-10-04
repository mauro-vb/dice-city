-- most tests start from an empty inventory
local function fresh()
	new_run()
	run.items = {}
end

test("buying a die adds it and returns it", function()
	fresh()
	local d = buy(d6)
	check(d and d.kind == d6 and #run.bag == 1 and run.coins == 20 - d6.price)
end)

test("can't buy without the coins", function()
	fresh()
	run.coins = d3.price - 1
	check(not buy(d3) and #run.bag == 0 and run.coins == d3.price - 1)
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
	check(run.hp == 20, "buying doesn't heal")
end)

test("potion: heals 5 when hurt, one from the stack", function()
	fresh()
	buy(potion)
	buy(potion)
	check(not use_item(1), "full hp: can't use")
	run.hp = 18
	check(use_item(1) == potion and run.hp == 20 and run.items[1].n == 1, "capped at max hp")
	run.hp = 10
	use_item(1)
	check(run.hp == 15 and #run.items == 0, "last one frees the slot")
end)

test("potion mid-fight heals the battle, not the run", function()
	fresh()
	buy(potion)
	run.hp = 10
	local b = battle:new({p = run, foe = enemy1})
	check(use_item(1, b) == potion and b.p_hp == 15 and run.hp == 10)
end)

test("bomb: 4 damage ignoring def, only in a fight", function()
	fresh()
	buy(bomb)
	check(not use_item(1), "no fight: can't use")
	local b = battle:new({p = run, foe = {hp = 6, atk = 1, spd = 1, def = 9}})
	check(use_item(1, b) == bomb and b.e_hp == 2 and #run.items == 0)
end)

test("a bomb can finish the fight", function()
	fresh()
	buy(bomb)
	local b = battle:new({p = run, foe = {hp = 3, atk = 1, spd = 1, def = 0}})
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

test("opening shop: 3 dice + 1 item, later 1-2 dice then items", function()
	new_run(3)
	local o = gen_offers()
	check(#o == 4 and o[3].faces and not o[4].faces, "3 + 1")
	run.stage_i = 2
	for i = 1, 20 do
		o = gen_offers()
		check(o[1].faces and not o[3].faces and not o[4].faces, "dice first")
	end
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
	local d = run:add_die(d6g)
	check(sell_price(d) == flr(d6g.price / 2))
	sell(d)
	check(#run.bag == 0 and run.coins == flr(d6g.price / 2))
end)

test("at most dice_max dice", function()
	fresh()
	run.coins = 999
	for i = 1, dice_max do
		check(buy(d3))
	end
	check(not can_buy(d3) and #run.bag == dice_max, "bag full")
	check(can_buy(potion), "items still fine")
	sell(run.bag[1])
	check(can_buy(d3), "room again after selling")
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
		local v = roll_die(d)
		check(v >= 1 and v <= 8)
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
	run:place(run:add_die(d3), "atk")
	check(not use_item(1, false, d), "column full")
end)
