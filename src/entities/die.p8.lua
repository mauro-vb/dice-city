die = selectable:extend({
	w = 13,
	h = 13,
	-- false, not nil: a missing field falls through to globals (e.g. the slot class)
	slot = false,
	value = false,
	face_i = 1,
	init = function(_ENV)
		kind = kind or classic
		faces = {}
		for f in all(kind.faces) do
			add(faces, f)
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
	-- one decimal, for display
	avg_str = function(_ENV)
		return tostr(flr(average(_ENV) * 10) / 10)
	end,
	upgrade_face = function(_ENV, i, v)
		faces[i] += v
	end,
	clear = function(_ENV)
		value = false
	end,
	upd = function(_ENV)
		if not value and t % 20 == 0 then
			face_i = face_i % #faces + 1
		end
	end,
	drw = function(_ENV)
		local ny = y
		if #faces == 3 then
			for i=1, 12 do
				line(x - 6 + i/1.75, y + 6 - i, x + 7 - i/1.75, y + 6 - i, kind.colors[1])
			end
			line(x - 6, y + 6, x + 6, y + 6, kind.colors[2])
			line(x - 7, y + 6, x, y - 6, kind.colors[2])
			line(x + 7, y + 6, x, y - 6, kind.colors[2])

		end
		if #faces == 6 then
			ny = y - 2
			rrectfill(x - 6, y - 6, 12, 12, 2, kind.colors[1])
			rrect(x - 6, y - 6, 12, 12, 2, kind.colors[2])
		end
		print(value or faces[face_i], x - 1, ny, kind.colors[2])
	end,
	roll = function(_ENV)
		return roll_die(_ENV)
	end
})
