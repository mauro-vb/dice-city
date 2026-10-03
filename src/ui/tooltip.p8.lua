-- floating box next to the hovered thing: dice show their faces as mini dice and
-- value bars (the rolled face is white), items show their effect
-- beside the item (flips near the edge), or below it for shop cards

-- frame of size w x h placed for item it; returns its top-left corner
function tip_box(it, w, h, below, c)
	local x, y = it.x + it.w / 2 + 3, it.y - it.h / 2
	if x + w > 128 then x = it.x - it.w / 2 - 3 - w end
	if below then x, y = it.x - w / 2, it.y + it.h / 2 + 2 end
	x, y = mid(0, x, 128 - w), mid(0, y, 128 - h)
	-- focus won't hover through it (see focus.under)
	tip_area = {x, y, x + w - 1, y + h - 1}
	rectfill(x, y, x + w - 1, y + h - 1, 0)
	rect(x, y, x + w - 1, y + h - 1, 6)
	return x, y
end

function die_tip(it, d, below)
	local k, n = d.kind, #d.faces
	local info = "avg "..d:avg_str()
	if below then info ..= "  $"..k.price end
	local x, y = tip_box(it, max(n * 10 + 5, #info * 4 + 6), 40, below)
	local isd6 = #d.faces == 6
	print(k.name, x + 3, y + 3, 7)

	if isd6 then
		for i = 1, n do
			local fx = x + 3 + (i - 1) * 10
			rectfill(fx, y + 10, fx + 8, y + 18, d.value and i == d.face_i and 7 or 6)
			draw_pips(fx + 4, y + 14, d.faces[i], 2, n == 3)
		end
	else
		for i = 1, n do
			local fx = x + 4 + (i - 1) * 13
			-- trifill(tip x, tip y, width, height): tip at the top middle of the 9x9 cell
			trifill(fx + 4, y + 10, 10, 9, d.value and i == d.face_i and 7 or 6)
			draw_pips(fx + 4, y + 14, d.faces[i], 2, n == 3)
		end
	end
	face_bars(d, isd6 and x + 6 or x + 8, y + 29, isd6 and 10 or 12, 3)
	print(info, x + 3, y + 32, 6)
end

-- "yes" if SOME_BOOL else "no"
-- SOME_BOOL and "yes" or "no"

function item_tip(it, k)
	local x, y = tip_box(it, max(#k.name, #k.info) * 4 + 6, 25, true)
	print(k.name, x + 3, y + 3, 7)
	print(k.info, x + 3, y + 10, 6)
	print("$"..k.price, x + 3, y + 17, 6)
end

-- tip for whatever focus hovers: a die, or a shop card (die or item, tip below)
-- only after half a second on the same item
function hover_tip(f)
	tip_area = false
	local it = f.cur
	if f.held or not it or f.hover_t < 30 then return end
	local s = it.shows
	if s then
		if s.faces then return die_tip(it, s, true) end
		return item_tip(it, s)
	end
	if it:is(die) then die_tip(it, it) end
end
