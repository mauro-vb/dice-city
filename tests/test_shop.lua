test("buying a die adds it and returns it", function()
	new_run()
	local d = buy(d6)
	check(d and d.kind == d6 and #run.bag == 1 and run.coins == 12)
end)

test("can't buy without the coins", function()
	new_run()
	run.coins = 4
	check(not buy(d3) and #run.bag == 0 and run.coins == 4)
end)

test("potion heals 5, only when hurt", function()
	new_run()
	check(not can_buy(potion), "full hp")
	run.hp = 10
	check(buy(potion) == true and run.hp == 15 and run.coins == 17)
	run.hp = 18
	buy(potion)
	check(run.hp == 20, "capped at max hp")
end)

test("token: one extra reroll, next fight only", function()
	new_run()
	buy(token)
	run:roll_all()
	check(run.rerolls_left == 2)
	run:roll_all()
	check(run.rerolls_left == 1)
end)

test("bag dice count as coins only after rolling", function()
	new_run()
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
