-- frac (0..1) of a w-wide, h+1-tall bar from x, y in colour c
function bar(x, y, w, h, frac, c)
	local fw = flr(w * mid(0, frac, 1))
	if fw > 0 then rectfill(x, y, x + fw - 1, y + h, c) end
end

-- 6px hp bar: c = hp colour, light gray trail = recent damage, number in the middle
-- usage: hp_bar(2, 114, 92, hp, trail, max_hp, 7, flash_frames > 0)
function hp_bar(x, y, w, hp, trail, max_hp, c, flash)
	bar(x, y, w, 5, 1, dark)
	bar(x, y, w, 5, trail / max_hp, 6)
	bar(x, y, w, 5, hp / max_hp, c)
	txt(hp.."/"..max_hp, x + w / 2, y + 1, flash and 8 or 7, "c", true)
end

-- 3px charge bar, frac 0..1
function charge_bar(x, y, w, frac)
	bar(x, y, w, 2, 1, dark)
	bar(x, y, w, 2, frac, 6)
end
