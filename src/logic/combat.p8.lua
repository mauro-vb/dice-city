-- player method: works on locals, never changes hp or the enemy def
-- returns {events, win, hp_left, p_rate, e_rate}
-- each event has the tick it happened on; a bar's fill at tick t is rate * t % 100
-- def blocks up to its value: a hit can do 0. if neither side can hurt the other
-- the fight ends at once as a loss (no events)
player.fight = function(_ENV, foe)
	local events = {}
	local p_hp, e_hp = hp, foe.hp
	local p_bar, e_bar = 0, 0
	local spd = get_stat(_ENV, "spd")
	local p_dmg = max(0, get_stat(_ENV, "atk") - foe.def)
	local e_dmg = max(0, foe.atk - get_stat(_ENV, "def"))
	local p_rate, e_rate = spd + 5, foe.spd + 5
	local res = {events = events, win = false, hp_left = p_hp, p_rate = p_rate, e_rate = e_rate}
	if p_dmg == 0 and e_dmg == 0 then return res end
	for tick = 1, 1000 do
		p_bar += p_rate
		e_bar += e_rate
		-- player first: wins ties
		while p_bar >= 100 and e_hp > 0 do
			p_bar -= 100
			e_hp = max(0, e_hp - p_dmg)
			add(events, {who = "p", tick = tick, dmg = p_dmg, p_hp = p_hp, e_hp = e_hp})
		end
		while e_bar >= 100 and e_hp > 0 and p_hp > 0 do
			e_bar -= 100
			p_hp = max(0, p_hp - e_dmg)
			add(events, {who = "e", tick = tick, dmg = e_dmg, p_hp = p_hp, e_hp = e_hp})
		end
		if p_hp <= 0 or e_hp <= 0 then break end
	end
	res.win, res.hp_left = e_hp <= 0, p_hp
	return res
end
