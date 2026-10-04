-- one inventory slot (10x10): shows = the item kind in it (or false),
-- n = how many are stacked (drawn when more than one). carried (an aim item
-- on its way to a die, see focus:drw): just the icon, full size, above the
-- grabbing hand. pickable (carried to a die) when its item has an aim; the
-- scene's ok(i) says whether it can be used there
-- usage: item_slot:new({x = 69, y = 120, on_press = ..., enabled = ...})
item_slot = selectable:extend({
	w = 10,
	h = 10,
	n = 0,
	drw = function(_ENV, carried)
		-- slot i shows stack i of the run's inventory
		local s = run.items[i]
		shows, n, pickable = s and s.k or false, s and s.n or 0, s and s.k.aim
		if carried then return item_icon(shows, x, y - 8, 1) end
		rect(x - 5, y - 5, x + 4, y + 4, is_on(_ENV) and 6 or dark)
		-- the shop's icon at half size (src/scenes/shop.p8.lua)
		if shows then item_icon(shows, x, y, .5) end
		if n > 1 then txt(n, x + 5, y + 1, 7, "r", true) end
	end,
})

-- the run's inventory as inv_size slots added to focus f, in a row at y;
-- press(i) / ok(i) are slot i's action and whether it's allowed
function inv_slots(f, y, press, ok)
	local inv = {}
	for i = 1, inv_size do
		add(inv, f:item(item_slot:new({
			i = i, x = 58 + i * 11, y = y, row = y,
			on_press = function() press(i) end,
			enabled = function() return ok(i) end,
		})))
	end
	return inv
end

-- an aim item carried from slot s and dropped on die d (dice take only
-- item slots: takes_item). focus:drop left the slot where it was dropped,
-- so it goes back to its row, then it's used on d; returns its kind or false
function takes_item(_, s)
	return s.class == item_slot
end

function drop_item(d, s)
	s.x, s.y = 58 + s.i * 11, s.row
	return use_item(s.i, false, d)
end
