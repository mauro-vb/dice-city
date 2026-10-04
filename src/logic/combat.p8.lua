-- one fight, simulated live so items (potions) can change it mid-way
-- usage: b = battle:new({p = run, foe = enemy1}); each tick: hits = b:step()
-- each hit: {who = "p" or "e", dmg, p_hp, e_hp} (hp after the hit)
-- a bar fills by spd + 5 a tick; at 100 that side hits and keeps the leftover.
-- def blocks up to its value, but a hit always does at least 1, so every
-- fight plays out to the end. no randomness: dice are rolled before
-- never changes the player or the enemy def; finish_fight applies the result
battle = class:extend({
	-- stats and the bag's coins are taken now: after this, placement doesn't matter
	init = function(_ENV)
		stats = {}
		for k in all(stat_names) do
			stats[k] = p:get_stat(k)
		end
		coins = leftover_coins(p:unused())
		p_hp, e_hp, max_hp = p.hp, foe.hp, p.max_hp
		p_bar, e_bar, tick = 0, 0, 0
		p_rate, e_rate = stats.spd + 5, foe.spd + 5
		p_dmg = max(1, stats.atk - foe.def)
		e_dmg = max(1, foe.atk - stats.def)
	end,
	over = function(_ENV)
		return p_hp <= 0 or e_hp <= 0 or tick >= 1000
	end,
	won = function(_ENV)
		return e_hp <= 0
	end,
	-- ticks until that side ("p" or "e") hits next
	ticks_to = function(_ENV, who)
		return ceil((100 - _ENV[who.."_bar"]) / _ENV[who.."_rate"])
	end,
	heal = function(_ENV, n)
		p_hp = min(max_hp, p_hp + n)
	end,
	-- item damage: straight to the enemy, ignores def
	blast = function(_ENV, n)
		e_hp = max(0, e_hp - n)
	end,
	-- one tick; returns its hits in order (player first: wins ties)
	step = function(_ENV)
		local hits = {}
		tick += 1
		p_bar += p_rate
		e_bar += e_rate
		while p_bar >= 100 and e_hp > 0 do
			p_bar -= 100
			e_hp = max(0, e_hp - p_dmg)
			add(hits, {who = "p", dmg = p_dmg, p_hp = p_hp, e_hp = e_hp})
		end
		while e_bar >= 100 and e_hp > 0 and p_hp > 0 do
			e_bar -= 100
			p_hp = max(0, p_hp - e_dmg)
			add(hits, {who = "e", dmg = e_dmg, p_hp = p_hp, e_hp = e_hp})
		end
		return hits
	end,
})
