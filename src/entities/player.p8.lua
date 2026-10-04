stat_names = split"atk,spd,def"

player = game_object:extend({
	init = function(_ENV)
		hp = 20
		max_hp = 20
		coins = 20
		stage_i = 0
		won = false
		base = {atk = 1, spd = 1, def = 0}
		slots = {atk = {}, spd = {}, def = {}}
		bag = {}
		items = {}
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
	-- the whole bag: unused dice show the coins you'd get on a win
	roll_all = function(_ENV)
		for d in all(bag) do
			roll_die(d)
		end
	end,
	unused = function(_ENV)
		local u = {}
		for d in all(bag) do
			if not d.slot then add(u, d) end
		end
		return u
	end,
	heal = function(_ENV, value)
		hp = min(max_hp, hp + value)
	end,
	earn = function(_ENV, value)
		coins += value
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
