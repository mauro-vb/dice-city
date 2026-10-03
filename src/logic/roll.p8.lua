-- the only place dice randomness happens
function roll_die(d)
	d.face_i = flr(rnd(#d.faces)) + 1
	d.value = d.faces[d.face_i]
	return d.value
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
