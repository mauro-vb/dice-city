-- vertical text menu: up/down to move, x to press
-- label and enabled can be functions, so items update without rebuilding
--
-- usage:
--   m = menu:new({x = 4, y = 80})
--   m:item("start", function() scene:load(placement) end)
--   m:item("fight", go, function() return rolled end)
--   m:upd()  m:drw()

menu = class:extend({
	x = 4,
	y = 80,
	init = function(_ENV)
		items = {}
		i = 1
	end,
	item = function(_ENV, label, on_press, enabled)
		add(items, {label = label, on_press = on_press, enabled = enabled})
	end,
	on = function(_ENV, it)
		return not it.enabled or it.enabled()
	end,
	move = function(_ENV, dir)
		for _ = 1, #items do
			i = (i - 1 + dir) % #items + 1
			if on(_ENV, items[i]) then return end
		end
	end,
	upd = function(_ENV)
		-- read x every frame so pressed() never misses a release
		local go = pressed(5)
		if #items == 0 then return end
		if not on(_ENV, items[i]) then move(_ENV, 1) end
		if btnp(2) then move(_ENV, -1) end
		if btnp(3) then move(_ENV, 1) end
		if go and on(_ENV, items[i]) then items[i].on_press() end
	end,
	drw = function(_ENV)
		for n = 1, #items do
			local it = items[n]
			local label = type(it.label) == "function" and it.label() or it.label
			local ly = y + (n - 1) * 7
			if n == i then print(">", x, ly, 10) end
			print(label, x + 6, ly, on(_ENV, it) and 7 or 5)
		end
	end,
})
