-- something focus can hover, press, pick up or drop onto
-- x, y is the centre; enabled can be a function
--
-- usage:
--   b = selectable:new({x = 64, y = 64, w = 20, h = 10, on_press = function() ... end})
--   area = selectable:new({..., accepts = function(_ENV, item) return true end,
--                               on_drop = function(_ENV, item) ... end})

selectable = game_object:extend({
	x = 0,
	y = 0,
	w = 8,
	h = 8,
	enabled = true,
	pickable = false,
	on_press = false,
	accepts = false,
	on_drop = _noop,
	-- a die this item stands for (shop cards), for the hover tooltip
	shows = false,
	contains = function(_ENV, px, py)
		return abs(px - x) * 2 <= w and abs(py - y) * 2 <= h
	end,
	is_on = function(_ENV)
		if type(enabled) == "function" then return enabled() end
		return enabled
	end,
})
