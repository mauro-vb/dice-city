-- the only place dice randomness happens. glass rolls double, and decides
-- here whether it breaks when the fight starts (1 in 4)
function roll_die(d)
	d.face_i = flr(rnd(#d.faces)) + 1
	d.value = d.faces[d.face_i]
	if d.ench == glass then
		d.value *= 2
		d.broke = rnd(4) < 1
	end
end

-- a fight's copy of enemy e with its rolling stats (lists, see
-- src/defs/enemies.p8.lua) rolled: each becomes one of its values
function roll_foe(e)
	local f = {}
	for k, v in pairs(e) do
		f[k] = type(v) == "table" and rnd(v) or v
	end
	return f
end
