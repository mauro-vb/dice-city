local function new_player()
	local p = player:new()
	for k in all({d6, d6, d3, d3}) do
		p:add_die(k)
	end
	return p
end

test("a new run starts with no dice and no items", function()
	local p = player:new()
	check(#p.bag == 0 and p.coins == 10 and p.stage_i == 0)
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

test("roll_all: every die, columns left to right, then the bag", function()
	local p = player:new()
	local a, b, c = p:add_die(d3), p:add_die(d8), p:add_die(d6)
	p:place(b, "atk")
	p:place(c, "spd")
	local order = p:roll_all()
	check(order[1] == b and order[2] == c and order[3] == a, "atk, spd, then the bag")
	check(a.value and b.value and c.value, "all rolled")
	check(p:get_stat("atk") == 1 + b.value)
end)

test("glass: rolls double its face, breaks about 1 in 4", function()
	local d, broke = die:new({kind = d6}), 0
	d.ench = glass
	for _ = 1, 400 do
		roll_die(d)
		check(d.value == d.faces[d.face_i] * 2)
		if d.broke then broke += 1 end
	end
	check(broke > 60 and broke < 140, "about 100 of 400")
end)
