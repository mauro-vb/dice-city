local function fighter(atk, spd, def)
	local p = player:new()
	p.base = {atk = atk, spd = spd, def = def}
	return p
end

test("a fixed fight gives the expected events", function()
	-- both bars +10 a tick: both act every 10 ticks, player first
	local p = fighter(3, 5, 0)
	local foe = {name = "dummy", hp = 6, atk = 2, spd = 5, def = 1}
	local r = p:fight(foe)
	check(#r.events == 5)
	check(r.events[1].who == "p" and r.events[1].dmg == 2 and r.events[1].e_hp == 4)
	check(r.events[2].who == "e" and r.events[2].p_hp == 18)
	check(r.win and r.hp_left == 16)
end)

test("min 1 damage", function()
	local p = fighter(1, 1, 0)
	local r = p:fight({name = "wall", hp = 2, atk = 0, spd = 1, def = 10})
	check(r.events[1].dmg == 1 and r.events[2].dmg == 1)
end)

test("player wins ties", function()
	local p = fighter(1, 1, 0)
	p.hp = 1
	local r = p:fight({name = "twin", hp = 1, atk = 1, spd = 1, def = 0})
	check(r.win and #r.events == 1)
end)

test("fight changes nothing", function()
	local p = fighter(3, 3, 0)
	p:fight(enemy1)
	check(p.hp == 20 and enemy1.hp == 6)
end)
