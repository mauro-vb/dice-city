-- most tests start from an empty inventory (a new run has one reroll)
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

test("offers repeat from the pool", function()
	local o = gen_offers(stage_def({pool = {d3}, offers = 4}))
	check(#o == 4 and o[1] == d3 and o[4] == d3)
end)

test("same seed, same opening shop", function()
	new_run(7)
	local a = gen_offers(stages[0])
	new_run(7)
	local b = gen_offers(stages[0])
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
