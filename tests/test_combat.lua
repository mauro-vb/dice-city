-- runs a battle to the end and collects its hits (with their tick)
local function fight(p, foe)
	local b = battle:new({p = p, foe = foe})
	local events = {}
	while not b:over() do
		for ev in all(b:step()) do
			ev.tick = b.tick
			add(events, ev)
		end
	end
	return {events = events, win = b:won(), hp_left = b.p_hp}
end

local function fighter(atk, spd, def)
	local p = player:new()
	p.base = {atk = atk, spd = spd, def = def}
	return p
end

test("a fixed fight gives the expected events", function()
	-- both bars +10 a tick: both act every 10 ticks, player first
	local p = fighter(3, 5, 0)
	local foe = {name = "dummy", hp = 6, atk = 2, spd = 5, def = 1}
	local r = fight(p, foe)
	check(#r.events == 5)
	check(r.events[1].who == "p" and r.events[1].dmg == 2 and r.events[1].e_hp == 4)
	check(r.events[2].who == "e" and r.events[2].p_hp == 38)
	check(r.win and r.hp_left == 36)
end)

test("def can block every point of damage", function()
	local p = fighter(3, 1, 3)
	local r = fight(p, {hp = 6, atk = 2, spd = 1, def = 0})
	for ev in all(r.events) do
		if ev.who == "e" then check(ev.dmg == 0, "enemy hit for "..ev.dmg) end
	end
	check(r.win and r.hp_left == 40)
end)

test("def reduces damage by its value", function()
	local p = fighter(3, 1, 1)
	local r = fight(p, {hp = 30, atk = 5, spd = 50, def = 0})
	check(r.events[1].who == "e" and r.events[1].dmg == 4)
end)

test("nobody can hurt anybody: 30 ticks, then a loss", function()
	local b = battle:new({p = fighter(1, 1, 5), foe = {hp = 6, atk = 2, spd = 1, def = 4}})
	while not b:over() do b:step() end
	check(b:stalemate() and b.tick == 30 and not b:won() and b.p_hp == 40)
end)

test("a bomb can still win a stalemate", function()
	local b = battle:new({p = fighter(1, 1, 5), foe = {hp = 6, atk = 2, spd = 1, def = 4}})
	b:step()
	b:blast(10)
	check(b:over() and b:won())
end)

test("player wins ties", function()
	local p = fighter(1, 1, 0)
	p.hp = 1
	local r = fight(p, {name = "twin", hp = 1, atk = 1, spd = 1, def = 0})
	check(r.win and #r.events == 1)
end)

test("fight changes nothing", function()
	local p, hp = fighter(3, 3, 0), enemy1.hp
	fight(p, enemy1)
	check(p.hp == 40 and enemy1.hp == hp)
end)

test("ticks_to says when a side hits next", function()
	local b = battle:new({p = fighter(1, 5, 0), foe = {hp = 9, atk = 1, spd = 5, def = 0}})
	check(b:ticks_to("p") == 10)
	for _ = 1, 4 do b:step() end
	check(b:ticks_to("p") == 6)
end)

test("heal mid-fight changes the outcome", function()
	local p = fighter(1, 1, 0)
	p.hp = 2
	local foe = {hp = 3, atk = 2, spd = 1, def = 0}
	check(not fight(p, foe).win, "dies without the heal")
	local b = battle:new({p = p, foe = foe})
	b:heal(5)
	while not b:over() do b:step() end
	check(b:won() and p.hp == 2, "survives with it, player untouched")
end)
