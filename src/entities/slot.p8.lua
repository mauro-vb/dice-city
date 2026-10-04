-- a stat column on the placement screen: takes dropped dice, up to 3
slot = selectable:extend({
	key = "atk",
	w = 38,
	h = 64,
	accepts = function(_ENV, item)
		return item.slot == key or #run.slots[key] < 3
	end,
	on_drop = function(_ENV, d)
		run:place(d, key)
	end,
	drw = function(_ENV)
		local x0, y0 = x - w / 2, y - h / 2
		rect(x0, y0, x0 + w - 1, y0 + h - 1, dark)
	end,
})
