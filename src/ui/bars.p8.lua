-- 6px hp bar: c = hp colour, light gray trail = recent damage, number in the middle
-- usage: hp_bar(2, 114, 92, hp, trail, max_hp, 7, flash_frames > 0)
function hp_bar(x, y, w, hp, trail, max_hp, c, flash)
	rectfill(x, y, x + w - 1, y + 5, 5)
	local tw = flr(w * mid(0, trail / max_hp, 1))
	if tw > 0 then rectfill(x, y, x + tw - 1, y + 5, 6) end
	local hw = flr(w * hp / max_hp)
	if hw > 0 then rectfill(x, y, x + hw - 1, y + 5, c) end
	txt(hp.."/"..max_hp, x + w / 2, y + 1, flash and 8 or 7, "c", true)
end

-- 3px charge bar, frac 0..1
function charge_bar(x, y, w, frac)
	rectfill(x, y, x + w - 1, y + 2, 5)
	local fw = flr(w * frac)
	if fw > 0 then rectfill(x, y, x + fw - 1, y + 2, 6) end
end
