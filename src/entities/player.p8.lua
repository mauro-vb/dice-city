stat_names = split"atk,spd,def"

player = game_object:extend({
	init = function(_ENV)
		hp = 20
		max_hp = 20
		coins = 20
		rerolls = 1
		rerolls_left = 1
		stage_i = 0
		won = false
		base = {atk = 1, spd = 1, def = 0}
		slots = {atk = {}, spd = {}, def = {}}
		bag = {}
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
	cycle = function(_ENV, d)
		if not d.slot then return place(_ENV, d, "atk") end
		if d.slot == "atk" then return place(_ENV, d, "spd") end
		if d.slot == "spd" then return place(_ENV, d, "def") end
		unplace(_ENV, d)
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
			lo += d:lowest()
			hi += d:highest()
		end
		return lo.."-"..hi
	end,
	roll_all = function(_ENV)
		for _, ds in pairs(slots) do
			for d in all(ds) do
				roll_die(d)
			end
		end
		rerolls_left = rerolls
	end,
	reroll = function(_ENV, d)
		if rerolls_left <= 0 or not d.slot then return false end
		roll_die(d)
		rerolls_left -= 1
		return true
	end,
	placed = function(_ENV)
		return #bag - #unused(_ENV)
	end,
	unused = function(_ENV)
		local u = {}
		for d in all(bag) do
			if not d.slot then add(u, d) end
		end
		return u
	end,
	dead = function(_ENV)
		return hp <= 0
	end,
	heal = function(_ENV, value)
		hp = min(max_hp, hp + value)
	end,
	hurt = function(_ENV, value)
		hp = max(0, hp - value)
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
	remove_die = function(_ENV, d)
		unplace(_ENV, d)
		del(bag, d)
	end,
})
