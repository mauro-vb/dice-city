player = game_object:extend({
	hp = 20,
	max_hp = 20,
	coins = 10,
	bag = {},
	slots = {
		atk = {}, spd = {}, def = {}
	},
	rerolls = 0,
	rerolls_left = 0,
	stage_i = 1,
	place = function(_ENV, d, slot)
		del(slots[d.slot], d)
		add(slots[slot], d)
		d.slot = slot
	end,
	unplace = function(_ENV, d)
		del(slots[d.slot], d)
		add(bag, d)
		d.slot = nil
	end,
	get_stat = function(_ENV, slot)
		local sum = 0
		for d in all(slots[slot]) do
			sum += d.value
		end
	end,
	stat_range = function(_ENV, slot)
		local min_val = 0
		local max_val = 0
		for d in all(slots[slot]) do
			min_val += d:lowest()
			max_val += d:highest()
		end
		return tostr(min_val).."-"..totstr(max_val)
	end,
	roll_all = function(_ENV)
		for slot in all(slots) do
			for d in all(slot) do
				d:roll()
			end
		end
		rerolls_left = rerolls
	end,
	reroll = function(_ENV, d)
		if rerolls > 0 then return false end
		d:roll()
		rerolls -= 1
		return true
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
		add(bag, die:new({kind=kind}))
	end,
	add_die = function(_ENV, d)
		del(bag, d)
	end,

})
