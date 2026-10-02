-- the only place dice randomness happens
function roll_die(d)
	d.face_i = flr(rnd(#d.faces)) + 1
	d.value = d.faces[d.face_i]
	return d.value
end
