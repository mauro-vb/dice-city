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

test("range: lowest and highest face", function()
	local d = die:new({kind = d6})
	d.faces[1] = 9
	local lo, hi = d:range()
	check(lo == 2 and hi == 9)
end)

test("an enemy's rolling stats roll into a copy", function()
	local seen = {}
	for _ = 1, 50 do
		local f = roll_foe(enemy4)
		check(f.atk == 4 or f.atk == 12, "gambler atk "..tostr(f.atk))
		check(f.def == enemy4.def, "fixed stats copied")
		seen[f.atk] = true
	end
	check(seen[4] and seen[12], "both values come up")
	check(type(enemy4.atk) == "table", "the def itself is untouched")
	check(roll_foe(enemy1).atk == enemy1.atk, "nothing rolls: same stats")
end)

test("every fight stage has a named enemy, the last is the boss", function()
	for i = 1, #stages do
		check(stages[i].enemy and stages[i].enemy.name, "stage "..i)
		check(not stages[i].boss == (i < #stages), "boss only last")
	end
end)

test("grower: the lowest face grows, faces stay in order", function()
	local g = die:new({kind = dgw})
	grow(g)
	check(g.faces[1] == 2 and g.faces[2] == 2, "1 -> 2")
	grow(g)
	check(g.faces[1] == 2 and g.faces[2] == 3 and g.faces[3] == 3, "then 2;3;3")
end)
