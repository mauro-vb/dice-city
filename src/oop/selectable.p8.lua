-- something focus can hover, press, pick up or drop onto
-- x, y is the centre (w, h are always given); enabled can be a function.
-- optional, read only as true / false, so left nil (no globals have these
-- names): pickable, on_press, accepts, on_drop (only called after accepts),
-- shows (what a shop card or item slot stands for, for the hover tooltip)
--
-- usage:
--   b = selectable:new({x = 64, y = 64, w = 20, h = 10, on_press = function() ... end})
--   area = selectable:new({..., accepts = function(_ENV, item) return true end,
--                               on_drop = function(_ENV, item) ... end})

selectable = game_object:extend({
	x = 0,
	y = 0,
	enabled = true,
	contains = function(_ENV, px, py)
		return abs(px - x) * 2 <= w and abs(py - y) * 2 <= h
	end,
	is_on = function(_ENV)
		if type(enabled) == "function" then return enabled() end
		return enabled
	end,
})
