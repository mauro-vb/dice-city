-- one inventory slot (10x10): shows = the item kind in it (or false),
-- n = how many are stacked (drawn when more than one)
-- usage: item_slot:new({x = 69, y = 119, on_press = ..., enabled = ...})
item_slot = selectable:extend({
	w = 10,
	h = 10,
	n = 0,
	drw = function(_ENV)
		-- slot i shows stack i of the run's inventory
		local s = run.items[i]
		shows, n = s and s.k or false, s and s.n or 0
		rect(x - 5, y - 5, x + 4, y + 4, is_on(_ENV) and 6 or dark)
		-- bomb: no icon yet (sprite coming). beer (potion): myspr region 17
		-- shrunk to 7x9 to fit the slot
		if shows == potion then
			local s = myspr[17]
			sspr(s[1], s[2], s[3], s[4], x - 4, y - 5, 7, 9)
		elseif shows == double then
			rect(x - 3, y - 3, x, y, 6)
			rect(x - 1, y - 1, x + 2, y + 2, 7)
		elseif shows == token then
			rect(x - 2, y - 2, x + 1, y + 1, 6)
		end
		if n > 1 then txt(n, x + 5, y + 1, 7, "r", true) end
	end,
})

-- the run's inventory as inv_size slots added to focus f, in a row at y;
-- press(i) / ok(i) are slot i's action and whether it's allowed
function inv_slots(f, y, press, ok)
	local inv = {}
	for i = 1, inv_size do
		add(inv, f:item(item_slot:new({
			i = i, x = 58 + i * 11, y = y,
			on_press = function() press(i) end,
			enabled = function() return ok(i) end,
		})))
	end
	return inv
end
