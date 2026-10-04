-- pip layouts on a 3x3 grid (1 = top left, 9 = bottom right); triangles use
-- their own, set low where the triangle is wide
-- Each string lists where the dots go on an imaginary 3×3 grid, numbered in reading order:
--  1 2 3
--  4 5 6
--  7 8 9
pips_sq = split("5,19,159,1379,13579,134679", ",", false)
pips_tri = split("5,28,279", ",", false)

-- black pips centred on x, y, s apart; 0 is a sad face, values without a
-- layout print. num: always print the value (d8). rg: how much a rig (2) or
-- a grower (1) added to the face; the pips not in the layout for rg less are
-- red (a printed value turns red with a black outline)
function draw_pips(x, y, v, s, tri, num, rg)
	if tri then y += s / 2 end
	local set = v == 0 and "1379" or not num and (tri and pips_tri or pips_sq)[v]
	if not set then return txt(v, x, y - 2, rg and 8 or 0, "c", rg) end
	local old = rg and (tri and pips_tri or pips_sq)[v - rg] or ""
	-- triangle dots sit closer together so the outer ones clear the edges
	local r, sp = s \ 4, tri and s - s \ 4 or s
	-- 0 is a sad face: eyes and mouth corners are pips 1 3 7 9, plus a bar
	-- one pip higher between the corners (a frown)
	if v == 0 then
		rectfill(x - sp - r + s \ 2, y + sp - r - s \ 2, x + sp - r - 1, y + sp - r - 1, 0)
	end
	for i = 1, #set do
		local p = tonum(set[i]) - 1
		local px, py, c = x + (p % 3 - 1) * sp, y + (p \ 3 - 1) * sp, rg and 8 or 0
		for j = 1, #old do
			if old[j] == set[i] then c = 0 end
		end
		rectfill(px - r, py - r, px - r + s \ 2 - 1, py - r + s \ 2 - 1, c)
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
		rectfill(bx, y - bh + 1, bx + bw - 1, y, d.value and i == d.face_i and 7 or dark)
	end
end


die = selectable:extend({
	h = 16,
	-- false, not nil: a missing field falls through to globals (e.g. the slot class)
	slot = false,
	face_i = 1,
	-- left nil (no global has these names): value, tx, ty, moving, ench (the
	-- enchantment), temp (a double's copy: drawn inverted, gone when the
	-- fight starts), broke (glass that breaks when the fight starts), and
	-- air_t / ft, which roll_anim sets before they're read
	hop = 0,
	idle_t = 0,
	-- roll animation (visual only, the value is already rolled): air = frames
	-- left in the air of air_t; jump = height offset; flick = the face shown in
	-- the air, ft = frames to the next one; sq = squash (> 0) or stretch (< 0)
	-- in px; land = frames since the final landing
	air = 0,
	jump = 0,
	flick = 0,
	sq = 0,
	land = 9,
	init = function(_ENV)
		kind = kind or d6
		faces, rigged = {}, {}
		for f in all(kind.faces) do
			add(faces, f)
		end
		w = #faces == 3 and 18 or 16
	end,
	-- lowest and highest face
	range = function(_ENV)
		local lo, hi = 99, 0
		for f in all(faces) do
			lo, hi = min(lo, f), max(hi, f)
		end
		return lo, hi
	end,
	-- average face, one decimal, for display
	avg_str = function(_ENV)
		local sum = 0
		for f in all(faces) do
			sum += f
		end
		return flr(sum / #faces * 10) / 10
	end,
	clear = function(_ENV)
		value = false
	end,
	-- start the roll animation; the i-th die lands 10 frames after the one before
	roll_anim = function(_ENV, i)
		air_t = 40 + 10 * i
		air, ft = air_t, 0
	end,
	-- one frame in the air: 3 hops (abs sin arcs) shrinking to 0, faces
	-- flicker slower and slower; the final landing shakes and throws dust
	-- (sparks too on the highest face)
	fly = function(_ENV)
		air -= 1
		local p = 1 - air / air_t
		local f = p * 3 % 1
		jump = sin(f / 2) * 13 * (1 - p) ^ 1.5
		ft -= 1
		if ft <= 0 then
			ft, flick = 2 + 10 * p * p, rnd(faces)
		end
		-- squash touching the ground between hops, stretch while fast
		sq = f < .15 and p > .2 and 1 or (f < .3 or f > .8) and -1 or 0
		if air > 0 then return end
		local lo, hi = range(_ENV)
		land, jump, global.shake = 0, 0, 4
		poof(_ENV)
		if value == hi then spray(_ENV, 8, split"10,9,7", 2.5, .1) end
		-- then a flash in the face's colour (dark grey lowest, yellow highest,
		-- white otherwise)
		circlep({x = x, y = y, size = 18, c = value == lo and dark or value == hi and 10 or 7, wait = 3, maxage = 4})
	end,
	-- dust and a white flash a bit bigger than the die
	poof = function(_ENV)
		spray(_ENV, 10, split"6,7", 1.5, .03)
		circlep({x = x, y = y, size = 20, c = 7, maxage = 2})
	end,
	-- glide to a spot with a tween; a new target waits for the running tween
	move_to = function(_ENV, nx, ny)
		tx, ty = nx, ny
		if moving or x == tx and y == ty then return end
		moving = true
		tw(_ENV, {{f = 8, e = qout, x = tx, y = ty}}, function() moving = false end)
	end,
	upd = function(_ENV)
		if tx then move_to(_ENV, tx, ty) end
		if air > 0 then fly(_ENV) end
		land = min(land + 1, 9)
		if value then return end
		idle_t -= 1
		if idle_t > 0 then return end
		-- restless idle face: a random other face and a small hop (visual only)
		idle_t = 30 + rnd(10)
		face_i = (face_i + flr(rnd(#faces - 1))) % #faces + 1
		tw(_ENV, {{f = 4, e = qout, hop = -2}, {f = 4, e = qin, hop = 0}})
	end,
	drw = function(_ENV)
		-- squash / stretch keeps the bottom edge on the ground: big squash for 3
		-- frames after the final landing, then a small one for 2
		local s = air > 0 and sq or land < 4 and 2 or land < 6 and 1 or 0
		local tri, body, edge = #faces == 3, ench and ench.col or value and 7 or 6, dark
		local yy, w, h = y + hop + jump, w + s, 16 - s
		local l, top, bot = x - w \ 2, yy + 8 - h, yy + 7
		if temp then
			body, edge = dark, 7
			pal(0, 7)
		end
		if tri then
			trifill(x, top, w, h, body)
			-- left side drawn twice: a thicker edge
			line(x - 1, top, l - 1, bot, edge)
			line(x, top, l + w, bot, edge)
			line(l, bot, l + w - 1, bot, edge)
		elseif #faces == 8 then
			ovalfill(l, top, l + w - 1, bot, body)
			oval(l, top, l + w - 1, bot, edge)
		else
			rrectfill(l, top, w, h, 3, body)
			rrect(l, top, w, h, 3, edge)
		end
		draw_pips(x, yy + s / 2, air > 0 and flick or value or faces[face_i], 4, tri, #faces == 8, air == 0 and rigged[face_i])
		pal(0, 0)
	end,
})
