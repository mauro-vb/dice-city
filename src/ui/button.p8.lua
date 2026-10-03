-- usage: button:new({label = "roll", x = 112, y = 103, on_press = roll, enabled = can_roll})

button = selectable:extend({
	label = "",
	w = 28,
	h = 11,
	drw = function(_ENV)
		local lit = is_on(_ENV)
		local x0, y0 = x - w / 2, y - h / 2
		rectfill(x0, y0, x0 + w - 1, y0 + h - 1, lit and 5 or 0)
		rect(x0, y0, x0 + w - 1, y0 + h - 1, lit and 6 or 5)
		txt(label, x, y - 2, lit and 7 or 5, "c")
	end,
})
