stat_names = split"atk,spd,def"

player = game_object:extend({
	init = function(_ENV)
		-- starting hp and coins (tools/balance.py MAX_HP, START_COINS)
		hp, max_hp, coins, stage_i, won, bag, items = 40, 40, 10, 0, false, {}, {}
		base = {atk = 1, spd = 1, def = 0}
		slots = {atk = {}, spd = {}, def = {}}
	end,
	place = function(_ENV, d, s)
		unplace(_ENV, d)
		add(slots[s], d)
		d.slot = s
	end,
	unplace = function(_ENV, d)
		if d.slot then
			del(slots[d.slot], d)
		end
		d.slot = false
	end,
	get_stat = function(_ENV, s)
		local sum = base[s]
		for d in all(slots[s]) do
			sum += d.value or 0
		end
		return sum
	end,
	stat_range = function(_ENV, s)
		local lo, hi = base[s], base[s]
		for d in all(slots[s]) do
			local l, h = d:range()
			lo += l
			hi += h
		end
		return lo.."-"..hi
	end,
	-- the whole bag, in order: columns left to right (bottom die first), then
	-- the bag; returns that order (the roll animation lands them in it)
	roll_all = function(_ENV)
		local order = {}
		for k in all(stat_names) do
			for d in all(slots[k]) do
				add(order, d)
			end
		end
		for d in all(unused(_ENV)) do
			add(order, d)
		end
		foreach(order, roll_die)
		return order
	end,
	unused = function(_ENV)
		local u = {}
		for d in all(bag) do
			if not d.slot then add(u, d) end
		end
		return u
	end,
	spend = function(_ENV, value)
		if coins < value then return false end
		coins -= value
		return true
	end,
	add_die = function(_ENV, kind)
		local d = die:new({kind = kind})
		add(bag, d)
		return d
	end,
})
