-- player method: works on locals, never changes hp or the enemy def
-- returns {events, win, hp_left}
player.fight = function(_ENV, foe)
	local events = {}
	local p_hp, e_hp = hp, foe.hp
	local p_bar, e_bar = 0, 0
	local atk, spd, def = get_stat(_ENV, "atk"), get_stat(_ENV, "spd"), get_stat(_ENV, "def")
	for i = 1, 1000 do
		p_bar += spd + 5
		e_bar += foe.spd + 5
		-- player first: wins ties
		while p_bar >= 100 and e_hp > 0 do
			p_bar -= 100
			local dmg = max(1, atk - foe.def)
			e_hp = max(0, e_hp - dmg)
			add(events, {who = "p", dmg = dmg, p_hp = p_hp, e_hp = e_hp})
		end
		while e_bar >= 100 and e_hp > 0 and p_hp > 0 do
			e_bar -= 100
			local dmg = max(1, foe.atk - def)
			p_hp = max(0, p_hp - dmg)
			add(events, {who = "e", dmg = dmg, p_hp = p_hp, e_hp = e_hp})
		end
		if p_hp <= 0 or e_hp <= 0 then break end
	end
	return {events = events, win = e_hp <= 0, hp_left = p_hp}
end
