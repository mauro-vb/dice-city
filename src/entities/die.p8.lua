-- pip layouts on a 3x3 grid (1 = top left, 9 = bottom right); triangles use
-- their own, set low where the triangle is wide
-- Each string lists where the dots go on an imaginary 3×3 grid, numbered in reading order:
--  1 2 3
--  4 5 6
--  7 8 9
pips_sq = split("5,19,159,1379,13579,134679", ",", false)
pips_tri = split("5,28,279", ",", false)

-- black pips centred on x, y, s apart; 0 is an x, values without a layout print
function draw_pips(x, y, v, s, tri)
	if tri then y += s / 2 end
	if v == 0 then
		local a = s * .75
		line(x - a, y - a, x + a, y + a, 0)
		line(x - a, y + a, x + a, y - a, 0)
		return
	end
	local set = (tri and pips_tri or pips_sq)[v]
	if not set then return txt(v, x, y - 2, 0, "c") end
	-- triangle dots sit closer together so the outer ones clear the edges
	local r, sp = s \ 4, tri and s - s \ 4 or s
	for i = 1, #set do
		local p = tonum(set[i]) - 1
		local px, py = x + (p % 3 - 1) * sp, y + (p \ 3 - 1) * sp
		rectfill(px - r, py - r, px - r + s \ 2 - 1, py - r + s \ 2 - 1, 0)
	end
end

-- filled triangle: tip at (x, y), h rows tall, w wide at the base
-- (pico-8 has no triangle fill: one horizontal line per row, widening evenly)
function trifill(x, y, w, h, c)
	for i = 0, h - 1 do
		local hw = i * w / 2 / (h - 1)
		line(x - hw, y + i, x + hw, y + i, c)
	end
end

-- one bar per face, bottoms on y, from x0 (bw wide, sp apart); height grows with
-- the value (a 0 is a dot); the rolled face is white
function face_bars(d, x0, y, sp, bw)
	for i = 1, #d.faces do
		local bx, bh = x0 + (i - 1) * sp, max(1, d.faces[i] * 1.5)
		rectfill(bx, y - bh + 1, bx + bw - 1, y, d.value and i == d.face_i and 7 or 5)
	end
end


die = selectable:extend({
	h = 16,
	-- false, not nil: a missing field falls through to globals (e.g. the slot class)
	slot = false,
	value = false,
	face_i = 1,
	tx = false,
	ty = false,
	moving = false,
	hop = 0,
	idle_t = 0,
	init = function(_ENV)
		kind = kind or d6
		faces = {}
		for f in all(kind.faces) do
			add(faces, f)
		end
		w = #faces == 3 and 18 or 16
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
	-- glide to a spot with a tween; a new target waits for the running tween
	move_to = function(_ENV, nx, ny)
		tx, ty = nx, ny
		if moving or (x == tx and y == ty) then return end
		moving = true
		tween.new(_ENV):add({
			parallel = true,
			{k = "x", v = tx, f = 8, tr = "quad", ease = "out"},
			{k = "y", v = ty, f = 8, tr = "quad", ease = "out"},
		}):play(function() moving = false end)
	end,
	upd = function(_ENV)
		if tx then move_to(_ENV, tx, ty) end
		if value then return end
		idle_t -= 1
		if idle_t > 0 then return end
		-- restless idle face: a random other face and a small hop (visual only)
		idle_t = 30 + rnd(10)
		face_i = (face_i + flr(rnd(#faces - 1))) % #faces + 1
		local tw = tween.new(_ENV)
		tw:add({k = "hop", v = -2, f = 4, tr = "quad", ease = "out"})
		tw:add({k = "hop", v = 0, f = 4, tr = "quad"})
		tw:play()
	end,
	drw = function(_ENV)
		local yy, body = y + hop, value and 7 or 6
		if #faces == 3 then
			trifill(x, yy - 8, 18, 16, body)
			-- left side drawn twice: a thicker edge
			line(x, yy - 8, x - 9, yy + 7, 5)
			line(x - 1, yy - 8, x - 9, yy + 7, 5)
			line(x, yy - 8, x + 9, yy + 7, 5)
			line(x - 9, yy + 7, x + 9, yy + 7, 5)
		else
			rrectfill(x - 8, yy - 8, 16, 16, 3, body)
			rrect(x - 8, yy - 8, 16, 16, 3, 5)
		end
		draw_pips(x, yy, value or faces[face_i], 4, #faces == 3)
	end,
})
