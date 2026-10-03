test("a roll is always one of the die's faces", function()
	for k in all({d6, d3}) do
		local d = die:new({kind = k})
		for _ = 1, 50 do
			check(count(k.faces, roll_die(d)) > 0, k.name.." rolled a non-face")
		end
	end
end)

test("dice don't share faces", function()
	local a, b = die:new({kind = d6}), die:new({kind = d6})
	a.faces[1] += 2
	check(a.faces[1] == 3)
	check(b.faces[1] == 1 and d6.faces[1] == 1)
end)

test("d3 is wider than d6", function()
	check(die:new({kind = d3}).w == 18 and die:new().w == 16)
end)

test("min_max_table", function()
	check(min_max_table({3, 1, 5}, "max") == 5)
	check(min_max_table({3, 1, 5}, "min") == 1)
end)
