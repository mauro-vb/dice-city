local function new_player()
	local p = player:new()
	for k in all({d6, d6, d3, d3}) do
		p:add_die(k)
	end
	return p
end

test("a new run starts with no dice and no items", function()
	local p = player:new()
	check(#p.bag == 0 and p.coins == 20 and p.stage_i == 0)
	check(#p.items == 0)
end)

test("place and unplace never duplicate", function()
	local p = new_player()
	local d = p.bag[1]
	p:place(d, "atk")
	p:place(d, "spd")
	check(#p.slots.atk == 0 and #p.slots.spd == 1)
	p:unplace(d)
	check(#p.slots.spd == 0 and #p.bag == 4 and not d.slot)
end)

test("get_stat includes the base", function()
	local p = new_player()
	check(p:get_stat("atk") == 1 and p:get_stat("def") == 0)
	p:place(p:add_die({name = "t", faces = {1, 1, 1}, price = 0}), "atk")
	check(p:get_stat("atk") == 1)
	p:roll_all()
	check(p:get_stat("atk") == 2)
	check(p:stat_range("atk") == "2-2")
end)

test("roll_all rolls the whole bag", function()
	local p = new_player()
	p:place(p.bag[1], "atk")
	p:roll_all()
	check(p.bag[1].value and p.bag[2].value and p.bag[4].value)
end)

test("new players don't share dice", function()
	local a, b = new_player(), new_player()
	a:add_die(d3)
	check(#a.bag == 5 and #b.bag == 4)
end)

test("clone: copies the die rolled before it, columns then bag", function()
	local p = player:new()
	local c0, a, c1, c2 = p:add_die(dcl), p:add_die(d8), p:add_die(dcl), p:add_die(dcl)
	p:place(c0, "atk")
	p:place(a, "spd")
	p:place(c1, "spd")
	local order = p:roll_all()
	check(order[1] == c0 and order[4] == c2, "atk, spd, then the bag")
	check(c0.value == 0, "first: nothing to copy")
	check(c1.value == a.value and c2.value == a.value, "the die below, then the last rolled")
	check(p:get_stat("spd") == 1 + 2 * a.value)
	c1.faces[1], c1.faces[2] = 2, 2
	p:roll_all()
	check(c1.value == a.value + 2, "a rigged clone adds its face")
end)
