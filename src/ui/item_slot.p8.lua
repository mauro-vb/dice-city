-- one inventory slot (12x12, room for an 8x8 icon): shows = the item kind in
-- it (or false), n = how many are stacked (drawn when more than one)
-- usage: item_slot:new({x = 94, y = 119, on_press = ..., enabled = ...})
item_slot = selectable:extend({
	w = 12,
	h = 12,
	n = 0,
	drw = function(_ENV)
		rect(x - 6, y - 6, x + 5, y + 5, is_on(_ENV) and 6 or 5)
		if shows == potion then
			rectfill(x - 1, y - 4, x, y - 2, 6)
			circfill(x, y + 1, 3, 6)
			circfill(x, y + 1, 2, 8)
		elseif shows == bomb then
			circfill(x - 1, y + 1, 3, 6)
			line(x + 1, y - 2, x + 3, y - 4, 8)
		elseif shows == token then
			rect(x - 3, y - 3, x + 2, y + 2, 6)
			pset(x - 1, y - 1, 6)
		end
		if n > 1 then txt(n, x + 6, y + 1, 7, "r", true) end
	end,
	-- show stack i of the run's inventory
	set = function(_ENV, s)
		shows, n = s and s.k or false, s and s.n or 0
	end,
})
