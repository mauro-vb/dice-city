test("a roll is always one of the die's faces", function()
	for k in all({classic, jackpot, chip, crown}) do
		local d = die:new({kind = k})
		for _ = 1, 50 do
			check(count(k.faces, roll_die(d)) > 0, k.name.." rolled a non-face")
		end
	end
end)

test("dice don't share faces", function()
	local a, b = die:new({kind = classic}), die:new({kind = classic})
	a:upgrade_face(1, 2)
	check(a.faces[1] == 2)
	check(b.faces[1] == 0 and classic.faces[1] == 0)
end)

test("min_max_table", function()
	check(min_max_table({3, 1, 5}, "max") == 5)
	check(min_max_table({3, 1, 5}, "min") == 1)
end)
