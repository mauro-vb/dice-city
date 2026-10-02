die = game_object:extend({
	x = 0,
	y = 0,
	kind = classic, --
	faces = {},
	upgrades = {},
	slot = nil,
	value = nil,
	face_i = nil,
	init = function(_ENV)
		faces = kind.faces
		for i = 1, #kind.faces do
			upgrades[i] = 0
		end
	end,
	lowest = function(_ENV)
		return min_max_table(faces, "min")
	end,
	highest = function(_ENV)
		return min_max_table(faces, "max")
	end,
	average = function(_ENV)
		local sum = 0
		for face in all(faces) do
			sum += face
		end
		return sum / #faces
	end,
	upgrade_face = function(_ENV, i, v)
		upgrades[i] += v
	end,
	clear = function(_ENV)
		value = nil
	end,
	upd = function(_ENV)
		if value == nil and t%20 == 0 then
			dummy_roll(_ENV)
		end
	end,
	drw = function(_ENV)

		if #faces == 3 then end
		if #faces == 6 then
			rrectfill(x, y, 12, 12, 2, kind.colors[1])
			rrect(x, y, 12, 12, 2, kind.colors[2])
			print(faces[face_i], x + 5, y + 4,kind.colors[2])
		end
	end,
	dummy_roll = function(_ENV)
		face_i = flr(1 + rnd(#faces))
	end,
	roll = function(_ENV)
		dummy_roll(_ENV)
		value = faces[face_i]
	end
})
