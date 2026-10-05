pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- dice-city
-- by mauro-vb

_noop = function() end
class = setmetatable({
    extend = function(_ENV, tbl)
        tbl = tbl or {}
        tbl.__index = tbl
        setmetatable(tbl, {
            __index = _ENV,
            __call = function(_ENV, tbl)
                return _ENV:new(tbl)
            end
        })
        return tbl
    end,
    new = function(_ENV, tbl)
        tbl = tbl or {}
        setmetatable(tbl, _ENV)
        tbl.class = _ENV
        tbl:init()
        return tbl
    end,
    init = _noop
}, { __index = _ENV })
class.__index = class
game_object = class:extend({
    upd = _noop,
    drw = _noop,
})
fades = split"0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,129,129,129,129,129,129,129,129,0,0,0,0,0,0,0,2,2,2,130,130,130,130,130,128,128,128,128,128,0,0,3,3,3,131,131,131,131,129,129,129,129,129,0,0,0,4,4,132,132,132,132,132,132,130,128,128,128,128,0,0,5,5,133,133,133,133,130,130,128,128,128,128,128,0,0,6,6,134,13,13,13,141,5,5,5,133,130,128,128,0,7,6,6,6,134,134,134,134,5,5,5,133,130,128,0,8,8,136,136,136,136,132,132,132,130,128,128,128,128,0,9,9,9,4,4,4,4,132,132,132,128,128,128,128,0,10,10,138,138,138,4,4,4,132,132,133,128,128,128,0,11,139,139,139,139,3,3,3,3,129,129,129,0,0,0,12,12,12,140,140,140,140,131,131,131,1,129,129,129,0,13,13,141,141,5,5,5,133,133,130,129,129,128,128,0,14,14,14,134,134,141,141,2,2,133,130,130,128,128,0,15,143,143,134,134,134,134,5,5,5,133,133,128,128,0"
scene = game_object:extend({
    load = function(_ENV, new_scene)
        sfx(33)
        nxt, global.fade_t = new_scene, 0
    end
})
selectable = game_object:extend({
	x = 0,
	y = 0,
	enabled = true,
	contains = function(_ENV, px, py)
		return abs(px - x) * 2 <= w and abs(py - y) * 2 <= h
	end,
	is_on = function(_ENV)
		if type(enabled) == "function" then return enabled() end
		return enabled
	end,
})
function bar(x, y, w, h, frac, c)
	local fw = flr(w * mid(0, frac, 1))
	if fw > 0 then rectfill(x, y, x + fw - 1, y + h, c) end
end
function hp_bar(x, y, w, hp, trail, max_hp, c, flash)
	bar(x, y, w, 5, 1, dark)
	bar(x, y, w, 5, trail / max_hp, 6)
	bar(x, y, w, 5, hp / max_hp, c)
	txt(hp.."/"..max_hp, x + w / 2, y + 1, flash and 8 or 7, "c", true)
end
function charge_bar(x, y, w, frac)
	bar(x, y, w, 2, 1, dark)
	bar(x, y, w, 2, frac, 6)
end
button = selectable:extend({
	label = "",
	w = 28,
	h = 11,
	drw = function(_ENV)
		local lit = is_on(_ENV)
		local x0, y0 = x - w / 2, y - h / 2
		rectfill(x0, y0, x0 + w - 1, y0 + h - 1, lit and dark or bg)
		rect(x0, y0, x0 + w - 1, y0 + h - 1, lit and 6 or dark)
		txt(label, x, y - 2, lit and 7 or dark, "c")
	end,
})
focus = class:extend({
	init = function(_ENV)
		items, mx, my, hover_t = {}, stat(32), stat(33), 0
	end,
	item = function(_ENV, it)
		add(items, it)
		return it
	end,
	usable = function(_ENV, it)
		if held then return it.accepts and it:accepts(held) end
		return it.pickable or it.on_press
	end,
	under = function(_ENV)
		for i = #items, 1, -1 do
			local it = items[i]
			if it != held and it:contains(mx, my) and (not held or usable(_ENV, it)) then
				return it
			end
		end
	end,
	press = function(_ENV)
		if not cur or not cur:is_on() then return end
		if cur.pickable then
			held = cur
			sfx(34)
		elseif cur.on_press then
			cur.on_press(cur)
		end
	end,
	drop = function(_ENV)
		if not (cur and cur.accepts and cur:accepts(held)) then return false end
		held.x, held.y = mx, my
		cur:on_drop(held)
		held = false
		sfx(35)
		return true
	end,
	upd = function(_ENV)
		mx, my = stat(32), stat(33)
		cur = under(_ENV)
		if mb > pmb then
			if held then
				if not drop(_ENV) then held = false end
			else
				press(_ENV)
				dragging = held
			end
		elseif mb < pmb and dragging then
			dragging = false
			if not drop(_ENV) and not held:contains(mx, my) then held = false end
		end
		hover_t = cur == last and hover_t + 1 or 0
		last = cur
	end,
	drw_frame = function(_ENV)
		if not cur or not usable(_ENV, cur) or not cur:is_on() then return end
		local x0, y0 = cur.x - cur.w / 2 - 1, cur.y + (cur.hop or 0) - cur.h / 2 - 1
		rect(x0, y0, x0 + cur.w + 1, y0 + cur.h + 1, 7)
	end,
	drw = function(_ENV)
		if held then
			local ox, oy = held.x, held.y
			held.x, held.y = mx, my
			held:drw(true)
			held.x, held.y = ox, oy
		end
		mspr(myspr[(held or mb > 0) and 16 or 15], mx, my)
	end,
})
item_slot = selectable:extend({
	w = 10,
	h = 10,
	n = 0,
	drw = function(_ENV, carried)
		local s = run.items[i]
		shows, n, pickable = s and s.k or false, s and s.n or 0, s and s.k.aim
		if carried then return item_icon(shows, x, y - 8, 1) end
		rect(x - 5, y - 5, x + 4, y + 4, is_on(_ENV) and 6 or dark)
		if shows then item_icon(shows, x, y, .5) end
		if n > 1 then txt(n, x + 5, y + 1, 7, "r", true) end
	end,
})
function inv_slots(f, y, press, ok)
	local inv = {}
	for i = 1, inv_size do
		add(inv, f:item(item_slot:new({
			i = i, x = 58 + i * 11, y = y, row = y,
			on_press = function() press(i) end,
			enabled = function() return ok(i) end,
		})))
	end
	return inv
end
function takes_item(_, s)
	return s.class == item_slot
end
function drop_item(d, s)
	s.x, s.y = 58 + s.i * 11, s.row
	return use_item(s.i, false, d)
end
screen = scene:extend({
	make = function(_ENV, label, press, ok)
		timer, f = 0, focus:new()
		btn = f:item(button:new({label = label, x = 64, y = 84, w = 24, h = 9, on_press = press, enabled = ok}))
	end,
	upd = function(_ENV)
		timer += 1
		f:upd()
	end,
	drw = function(_ENV)
		cls(bg)
		text(_ENV)
		txt("\^o"..(f.cur == btn and 7 or 0).."ff"..btn.label, 64, 82, 14, "c")
		f:drw()
	end,
})
function tip_box(it, w, h, below)
	local x, y = it.x + it.w / 2 + 3, it.y - it.h / 2
	if x + w > 128 then x = it.x - it.w / 2 - 3 - w end
	if below then x, y = it.x - w / 2, it.y + it.h / 2 + 2 end
	if it.y > 80 then x, y = it.x - w / 2, it.y - it.h / 2 - 2 - h end
	x, y = mid(0, x, 128 - w), mid(0, y, 128 - h)
	rectfill(x, y, x + w - 1, y + h - 1, bg)
	rect(x, y, x + w - 1, y + h - 1, 6)
	return x, y
end
function die_tip(it, d, below)
	local k, n, e = d.kind, #d.faces, d.ench
	local info = e and e.info or "avg "..d:avg_str()
	local tri = n == 3
	local sp = tri and 13 or 10
	local x, y = tip_box(it, max(n * sp + 5, max(#info, #k.name) * 4 + 6), 40, below)
	print(k.name.." "..(e and e.name or ""), x + 3, y + 3, 7)
	for i = 1, n do
		local fx, c = x + (tri and 4 or 3) + (i - 1) * sp, d.value and i == d.face_i and 7 or 6
		if tri then
			trifill(fx + 4, y + 10, 10, 9, c)
		elseif n == 8 then
			circfill(fx + 4, y + 14, 4, c)
		else
			rectfill(fx, y + 10, fx + 8, y + 18, c)
		end
		draw_pips(fx + 4, y + 14, d.faces[i], 2, tri, n == 8, d.rigged[i])
	end
	face_bars(d, x + (tri and 8 or 6), y + 29, tri and 12 or 10, 3)
	print(info, x + 3, y + 32, 6)
end
function item_tip(it, k)
	local x, y = tip_box(it, max(#k.name, #k.info) * 4 + 6, 18, true)
	print(k.name, x + 3, y + 3, 7)
	print(k.info, x + 3, y + 10, 6)
end
function hover_tip(f)
	local it = f.cur
	if f.held or not it or f.hover_t < 30 then return end
	local s = it.shows
	if s then
		if s.faces then return die_tip(it, s, true) end
		return item_tip(it, s)
	end
	if it.faces then die_tip(it, it) end
end
bg = 0
dark = 5
function color_settings()
    palt(0, false)
    palt(11, true)
    poke(0x5f2e, 1)
end
poke(0x5f2d, 1)
mb = 0
function split2d(s)
    local arr = split(s, "|", false)
    for k, v in pairs(arr) do
        arr[k] = split(v)
    end
    return arr
end
function upd_group(group)
    for e in all(group) do
        e:upd()
    end
end
function drw_group(group)
    for e in all(group) do
        e:drw()
    end
end
function txt(s, x, y, c, al, ol)
	s = (ol and "\^o05a" or "")..s
	local w = print(s, 0, -999)
	x -= al == "c" and w \ 2 or al == "r" and w or 0
	print(s, x, y, c)
end
cash = "\fa$"
function defs(keys, s)
	keys = split(keys)
	for row in all(split(s, "|")) do
		local v, t = split(row), {}
		for i = 1, #v do
			local l = split(v[i] .. "", ";")
			t[keys[i]] = #l > 1 and l or v[i]
		end
		_ENV[v[1]] = t
	end
end
function names(s)
	local t = split(s)
	for i = 1, #t do
		t[i] = _ENV[t[i]]
	end
	return t
end
tws = {}
function qin(t) return t * t end
function qout(t) return 1 - (1 - t) ^ 2 end
function qio(t) return t < .5 and 2 * t * t or 1 - 2 * (1 - t) ^ 2 end
function bout(t)
	t = 1 - t
	return 1 - 2.70158 * t ^ 3 + 1.70158 * t ^ 2
end
function tw(o, s, done)
	add(tws, {o = o, s = s, done = done, i = 1, n = 0})
end
function upd_tws()
	for w in all(tws) do
		local s, o = w.s[w.i], w.o
		if w.n == 0 then
			w.a = {}
			for k in pairs(s) do w.a[k] = o[k] end
		end
		w.n += 1
		local p = w.n / s.f
		if s.e then p = s.e(p) end
		for k, v in pairs(s) do
			if k != "f" and k != "e" then o[k] = w.a[k] + (v - w.a[k]) * p end
		end
		if w.n >= s.f then
			w.n, w.i = 0, w.i + 1
			if not w.s[w.i] then
				del(tws, w)
				if w.done then w.done() end
			end
		end
	end
end
function mspr(s, x, y)
    sspr(s[1], s[2], s[3], s[4], x - s[5], y - s[6])
end
myspr=split2d"0,0,32,48,16,24|32,0,55,41,27,20|87,0,35,49,17,25|0,48,40,53,20,27|40,41,30,46,15,24|86,49,42,44,21,24|48,87,26,41,13,20|3,0,23,23,11,13|49,0,23,21,12,12|92,0,23,23,11,14|4,48,27,25,14,15|44,41,20,22,11,14|94,49,23,25,12,16|52,87,15,19,9,13|1,105,22,23,11,8|23,110,21,20,11,3|82,111,13,17,6,8|100,109,15,18,7,9"
parts = parts or {}
function dopart(_ENV)
    if wait then
        wait -= 1
        if (wait <= 0) wait = nil
        return
    end
    age += 1
    x += sx
    y += sy
    sx *= drag
    sy = sy * drag + grav
    size += incrsize
    if age >= maxage or size < 1 then
        del(parts, _ENV)
    end
end
particle = game_object:extend({
    age = 0,
    maxage = 0,
    x = 63,
    y = 63,
    size = 1,
    sx = 0,
    sy = 0,
    drag = 1,
    grav = 0,
    incrsize = 0,
    upd = dopart,
    init = function(_ENV)
        add(parts, _ENV)
    end,
    drw = function(_ENV)
        if (wait) return
        pdrw(_ENV)
    end
})
function spray(d, n, cols, v, g)
    for i = 1, n do
        local a, s = rnd(.5), v / 2 + rnd(v / 2)
        circlep({
            x = d.x, y = d.y + 7,
            c = rnd(cols),
            sx = cos(a) * s, sy = sin(a) * s,
            grav = g, drag = .9,
            maxage = 10 + rnd(2 / g - 10),
        })
    end
end
circlep = particle:extend({
    pdrw = function(_ENV)
        circfill(x, y, size / 2, c)
    end
})
sparkp = particle:extend({
    pdrw = function(_ENV)
        for i = 1, 8 do
            local cx, cy = cos(i / 8) * size, sin(i / 8) * size
            line(x + cx / 3, y + cy / 3, x + cx, y + cy, age < 2 and 7 or age < 4 and 10 or 9)
        end
        circfill(x, y, size / 4, 7)
    end
})
pips_sq = split("5,19,159,1379,13579,134679", ",", false)
pips_tri = split("5,28,279", ",", false)
function draw_pips(x, y, v, s, tri, num, rg)
	if tri then y += s / 2 end
	local set = v == 0 and "1379" or not num and (tri and pips_tri or pips_sq)[v]
	if not set then return txt(v, x, y - 2, rg and 8 or 0, "c", rg) end
	local old = rg and (tri and pips_tri or pips_sq)[v - rg] or ""
	local r, sp = s \ 4, tri and s - s \ 4 or s
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
function trifill(x, y, w, h, c)
	for i = 0, h - 1 do
		local hw = i * w / 2 / (h - 1)
		line(x - hw, y + i, x + hw, y + i, c)
	end
end
function face_bars(d, x0, y, sp, bw)
	for i = 1, #d.faces do
		local bx, bh = x0 + (i - 1) * sp, max(1, d.faces[i] * 1.5)
		rectfill(bx, y - bh + 1, bx + bw - 1, y, d.value and i == d.face_i and 7 or dark)
	end
end
die = selectable:extend({
	h = 16,
	slot = false,
	face_i = 1,
	hop = 0,
	idle_t = 0,
	air = 0,
	jump = 0,
	flick = 0,
	sq = 0,
	land = 9,
	init = function(_ENV)
		kind = kind or d6
		faces, rigged = {unpack(kind.faces)}, {}
		w = #faces == 3 and 18 or 16
	end,
	range = function(_ENV)
		local lo, hi = 99, 0
		for f in all(faces) do
			lo, hi = min(lo, f), max(hi, f)
		end
		return lo, hi
	end,
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
	roll_anim = function(_ENV, i)
		air_t = 40 + 10 * i
		air, ft = air_t, 0
	end,
	fly = function(_ENV)
		air -= 1
		local p = 1 - air / air_t
		local f = p * 3 % 1
		jump = sin(f / 2) * 13 * (1 - p) ^ 1.5
		ft -= 1
		if ft <= 0 then
			ft, flick = 2 + 10 * p * p, rnd(faces)
		end
		sq = f < .15 and p > .2 and 1 or (f < .3 or f > .8) and -1 or 0
		if air > 0 then return end
		if broke then
			sfx(45)
			run:unplace(_ENV)
			del(run.bag, _ENV)
		end
		local lo, hi = range(_ENV)
		land, jump, global.shake = 0, 0, 4
		poof(_ENV)
		if value == hi then spray(_ENV, 8, split"10,9,7", 2.5, .1) end
		circlep({x = x, y = y, size = 18, c = value == lo and dark or value == hi and 10 or 7, wait = 3, maxage = 4})
	end,
	poof = function(_ENV)
		spray(_ENV, 10, split"6,7", 1.5, .03)
		circlep({x = x, y = y, size = 20, c = 7, maxage = 2})
	end,
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
		idle_t = 30 + rnd(10)
		face_i = (face_i + flr(rnd(#faces - 1))) % #faces + 1
		tw(_ENV, {{f = 4, e = qout, hop = -2}, {f = 4, e = qin, hop = 0}})
	end,
	drw = function(_ENV)
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
stat_names = split"atk,spd,def"
player = game_object:extend({
	init = function(_ENV)
		hp, max_hp, coins, stage_i, won, bag, items = 40, 40, 10, 0, false, {}, {}
		base = {atk = 1, spd = 1, def = 0}
		slots = {atk = {}, spd = {}, def = {}}
	end,
	place = function(_ENV, d, s)
		unplace(_ENV, d)
		add(slots[s], d)
		d.slot = s
	end,
	unplace = function(_ENV, d)
		if d.slot then
			del(slots[d.slot], d)
		end
		d.slot = false
	end,
	get_stat = function(_ENV, s)
		local sum = base[s]
		for d in all(slots[s]) do
			sum += d.value or 0
		end
		return sum
	end,
	stat_range = function(_ENV, s)
		local lo, hi = base[s], base[s]
		for d in all(slots[s]) do
			local l, h = d:range()
			lo += l
			hi += h
		end
		return lo.."-"..hi
	end,
	roll_all = function(_ENV)
		local order = {}
		for k in all(stat_names) do
			for d in all(slots[k]) do
				add(order, d)
			end
		end
		for d in all(unused(_ENV)) do
			add(order, d)
		end
		foreach(order, roll_die)
		return order
	end,
	unused = function(_ENV)
		local u = {}
		for d in all(bag) do
			if not d.slot then add(u, d) end
		end
		return u
	end,
	spend = function(_ENV, value)
		if coins < value then return false end
		coins -= value
		return true
	end,
	add_die = function(_ENV, kind)
		local d = die:new({kind = kind})
		add(bag, d)
		return d
	end,
})
slot = selectable:extend({
	key = "atk",
	w = 38,
	h = 64,
	accepts = function(_ENV, item)
		return item.class == die and (item.slot == key or #run.slots[key] < 3)
	end,
	on_drop = function(_ENV, d)
		run:place(d, key)
	end,
	drw = function(_ENV)
		local x0, y0 = x - w / 2, y - h / 2
		rect(x0, y0, x0 + w - 1, y0 + h - 1, dark)
	end,
})
game_over = screen:extend({
	init = function(_ENV)
		make(_ENV, "title", function() scene:load(title) end, function() return timer > 30 end)
	end,
	text = function()
		memcpy(0x6000, 0x8000, 0x2000)
		txt(run.won and "you win!" or "\f8game over", 64, 64, 7, "c", true)
		txt("stage "..run.stage_i, 64, 72, 7, "c", true)
	end,
})
placement = scene:extend({
	fast = false,
	init = function(_ENV)
		global.parts = {}
		phase = "place"
		foe = cur_stage().enemy
		bars = {p_trail = run.hp, e_trail = foe.hp, p_charge = {v = 0}, e_charge = {v = 0}}
		stage = {off = 0, small_x = 15, hx = 32, foe_x = -30}
		lunge = {y = 0}
		say, say_t = false, 0
		story, story_t = cur_stage().story, 0
		if not story then global.want_music("fight1") end
		roll_t, roll_end, global.shake = 0, 0, 0
		p_shown, e_shown, p_flash, e_flash = run.hp, foe.hp, 0, 0
		frames = 0
		b = false
		coins_shown = run.coins
		f = focus:new()
		cols = {}
		for n = 1, #stat_names do
			local k = stat_names[n]
			cols[k] = f:item(slot:new({key = k, x = 21 + (n - 1) * 43, y = 60, h = 47}))
		end
		f:item(selectable:new({
			x = 48, y = 100, w = 92, h = 17,
			accepts = function(_, d) return d.class == die end,
			on_drop = function(_, d) run:unplace(d) end,
		}))
		for d in all(run.bag) do
			d.pickable = true
			f:item(d)
		end
		act_btn = f:item(button:new({
			x = 112, y = 100, h = 17,
			on_press = function()
				if phase == "fight" then fast = not fast return end
				if phase == "done" then return scene:load(next_scene) end
				if phase == "rolled" then return start_fight(_ENV) end
				local order = run:roll_all()
				foe = roll_foe(foe)
				for i = 1, #order do
					order[i]:roll_anim(i - 1)
				end
				for i = 1, min(#order, 3) do
					sfx(split"32,43,44"[i], 4 - i, i * 3 - 3)
				end
				roll_t, roll_end = 0, 40 + 10 * #order
				phase = "rolled"
			end,
			enabled = function() return phase == "place" or phase == "fight" or phase == "rolled" and roll_t >= roll_end or phase == "done" and card.ready end,
		}))
		use_on = function(d, s)
			local k = drop_item(d, s)
			if k == double then f:item(run.bag[#run.bag]) end
			if k == token then
				d:roll_anim(0)
				sfx(32, 3)
			end
		end
		inv = inv_slots(f, 121, function(i) use_at(_ENV, i) end, function(i)
			local s = run.items[i]
			if s and s.k.aim then return count(split(s.k.aim, " "), phase) > 0 end
			return phase != "intro" and phase != "done" and can_use(i, phase == "fight" and b)
		end)
		layout(_ENV)
	end,
	start_fight = function(_ENV)
		phase = "intro"
		sfx(42)
		b = battle:new({p = run, foe = foe})
		for d in all(run.bag) do
			if d.slot and d.ench == grower then grow(d) end
			run:unplace(d)
			if d.temp then
				d:poof()
				del(run.bag, d)
				del(f.items, d)
			end
		end
		for k, col in pairs(cols) do
			del(f.items, col)
		end
		tw(stage, {{f = 18, e = qin, off = 64}})
		tw(stage, {{f = 12, e = qin, small_x = -16}})
		tw(stage, {{f = 16, e = qio, hx = 17}})
		tw(stage, {{f = 24, e = bout, foe_x = 64}}, function()
			phase = "fight"
			fast = false
			say, say_t = foe.walk_in, 150
			charge_next(_ENV, "p")
			charge_next(_ENV, "e")
		end)
	end,
	charge_next = function(_ENV, who)
		local c = {v = 0}
		bars[who.."_charge"] = c
		if b:over() then return end
		tw(c, {{f = b:ticks_to(who) * 10, v = 1}})
	end,
	use_at = function(_ENV, i)
		local k = use_item(i, phase == "fight" and b)
		if k == bomb then
			sfx(39)
			sparks(_ENV, 10, 12)
			return hurt_bar(_ENV, "e", b.e_hp)
		end
		if not k then return end
		p_shown = phase == "fight" and b.p_hp or run.hp
		bars.p_trail = p_shown
	end,
	layout = function(_ENV)
		for k, col in pairs(cols) do
			local ds = run.slots[k]
			local gap = min(16, 32 / max(1, #ds - 1))
			for i = 1, #ds do
				ds[i]:move_to(col.x, 75 - (i - 1) * gap)
			end
		end
		local u = run:unused()
		local gap = min(17, 74 / max(1, #u - 1))
		for i = 1, #u do
			u[i]:move_to(11 + (i - 1) * gap, 100)
		end
	end,
	upd = function(_ENV)
		if story then
			story_t += 1
			if mb > pmb then story = false global.want_music("fight1") end
			return
		end
		for d in all(run.bag) do
			d.pickable = phase == "place" or phase == "rolled" and d.ench == wild
			d.accepts, d.on_drop = takes_item, use_on
		end
		act_btn.label = phase == "place" and "roll" or phase == "done" and "next" or phase == "fight" and (fast and "normal" or "▶▶") or "fight"
		f:upd()
		if scene.current != placement then return end
		layout(_ENV)
		roll_t += 1
		global.shake = max(0, shake - 1)
		upd_group(run.bag)
		upd_group(parts)
		for i = 1, fast and 3 or 1 do
			if phase == "fight" then
				if i > 1 then
					upd_tws()
					upd_group(parts)
				end
				upd_fight(_ENV)
			end
		end
		if card.ready and coins_shown < run.coins and t % 3 == 0 then coins_shown += 1 end
		p_flash, e_flash, say_t = max(0, p_flash - 1), max(0, e_flash - 1), say_t - 1
	end,
	upd_fight = function(_ENV)
		if b:over() then return end_fight(_ENV) end
		frames += 1
		if frames < 10 then return end
		frames = 0
		for ev in all(b:step()) do
			hit(_ENV, ev)
		end
	end,
	end_fight = function(_ENV)
		phase = "done"
		gain, next_scene = finish_fight(b)
		if not b:won() then
			global.stop_music()
			sfx(37)
		end
		bars.p_charge, bars.e_charge = {v = bars.p_charge.v}, {v = bars.e_charge.v}
		say, say_t = b:won() and foe.beaten or foe.beat_you, 120
		card = {y = -80}
		tw(card, {{f = 90}, {f = 30, e = bout, y = 0}}, function()
			card.ready = true
			if b:won() then sfx(49) end
		end)
	end,
	hit = function(_ENV, ev)
		local target = ev.who == "p" and "e" or "p"
		sfx(40)
		frames = -2 - ev.dmg \ 3
		if target == "e" then
			sparks(_ENV, 1 + min(ev.dmg \ 4, 4), min(4 + ev.dmg, 12))
		else
			sfx(41)
			lunge = {y = 0}
			tw(lunge, {{f = 3, e = qin, y = 8}, {f = 8, e = qout, y = 0}})
		end
		hurt_bar(_ENV, target, ev[target.."_hp"])
		charge_next(_ENV, ev.who)
	end,
	sparks = function(_ENV, n, s)
		for i = 1, n do
			sparkp({x = stage.foe_x + rnd(16) - 8, y = 50 + rnd(16), size = s, incrsize = 1, maxage = 6})
		end
	end,
	hurt_bar = function(_ENV, side, hp)
		_ENV[side.."_shown"], _ENV[side.."_flash"] = hp, 10
		tw(bars, {{f = 8}, {f = 20, e = qout, [side.."_trail"] = hp}})
	end,
	drw = function(_ENV)
		cls(bg)
		if story then return drw_story(_ENV) end
		local sx, sy = 0, 0
		if shake > 0 then sx, sy = rnd(3) - 1, rnd(3) - 1 end
		camera(sx, sy)
		local hx = stage.hx
		if stage.small_x > -15 then drw_foe(_ENV, foe.face_art, stage.small_x, 14) end
		print(foe.name, hx, 2, 7)
		hp_bar(hx, 9, 94, e_shown, bars.e_trail, foe.hp, 8, e_flash > 0)
		charge_bar(hx, 17, 94, bars.e_charge.v)
		local stats = ""
		for k in all(stat_names) do
			local v = foe[k]
			stats ..= k..(type(v) == "table" and v[1].."-"..v[#v] or v).." "
		end
		print(stats, hx, 22, 6)
		line(0, 29, 127, 29, dark)
		clip(0, 30, 128, 60)
		camera(sx, sy - stage.off)
		for k, col in pairs(cols) do
			txt(k, col.x, 31, 6, "c")
			if phase == "place" then col:drw() end
			txt(phase == "place" and run:stat_range(k) or b and b.stats[k] or roll_t < roll_end and "" or run:get_stat(k), col.x, roll_t == roll_end and 84 or 85, 7, "c")
			for d in all(run.slots[k]) do
				if d != f.held then d:drw() end
			end
		end
		camera(sx, sy)
		clip()
		if stage.foe_x > -28 then drw_foe(_ENV, foe.art, stage.foe_x, 59 + lunge.y) end
		if say_t > 0 then drw_say(_ENV) end
		rect(2, 91, 94, 108, dark)
		if #run:unused() == 0 then txt("dice bag", 48, 98, dark, "c") end
		txt("stage "..run.stage_i, 126, 114, 7, "r")
		txt(coins_shown..cash, 126, 121, 7, "r")
		if b then
			local s = b.stats
			print("atk"..s.atk.." spd"..s.spd.." def"..s.def, 2, 110, 6)
		else
			txt(phase == "place" and "dice in bag = cash\fa$" or "win: +"..leftover_coins(run:unused())..cash.."\f6 from the bag", 2, 110, 6)
		end
		for d in all(run:unused()) do
			if d != f.held then d:drw() end
			if not b and d.value and d.air == 0 then txt("+"..coin_value(d), d.x, d.y - 10, 10, "c", true) end
		end
		hp_bar(2, 116, 58, p_shown, bars.p_trail, run.max_hp, 7, p_flash > 0)
		charge_bar(2, 124, 58, bars.p_charge.v)
		drw_group(inv)
		act_btn:drw()
		drw_group(parts)
		camera()
		f:drw_frame()
		if phase == "done" then
			camera(0, -card.y)
			drw_result(_ENV)
			camera()
		end
		hover_tip(f)
		f:drw()
	end,
	drw_story = function(_ENV)
		local bs = split(story, "/", false)
		for i = 1, min(#bs, story_t \ 30 + 1) do
			local ls, w = split(bs[i], "\n", false), 0
			for l in all(ls) do
				w = max(w, #l * 4)
			end
			local x, y, h = 6 + (i - 1) * 18, 10 + (i - 1) * 40, #ls * 6 + 7
			rectfill(x + 2, y + 2, x + w + 9, y + h + 1, dark)
			rectfill(x, y, x + w + 7, y + h - 1, 10)
			rect(x + 1, y + 1, x + w + 6, y + h - 2, 0)
			print(bs[i], x + 4, y + 4, 0)
		end
		txt("click to go on", 64, 118, dark, "c")
		mspr(myspr[15], stat(32), stat(33))
	end,
	drw_say = function(_ENV)
		local ls, w = split(say, "\n", false), 0
		for l in all(ls) do
			w = max(w, #l * 4)
		end
		local h = #ls * 6 + 3
		local x, y = min(stage.foe_x + 14, 122 - w), 32
		rrectfill(x, y, w + 5, h, 2, 7)
		line(x + 3, y + h, x, y + h + 3, 7)
		line(x + 4, y + h, x + 1, y + h + 3, 7)
		print(say, x + 3, y + 2, 0)
	end,
	drw_foe = function(_ENV, i, x, y)
		mspr(myspr[i], x + (e_flash > 0 and rnd(3) - 1 or 0), y)
	end,
	drw_result = function(_ENV)
		local win = b:won()
		local c = win and 7 or 8
		rectfill(24, 46, 103, 72, bg)
		rect(24, 46, 103, 72, c)
		txt(win and "win!" or b:stalemate() and "no one can win" or "defeated", 64, 51, c, "c", true)
		if gain.reward + gain.leftover > 0 then
			txt("+"..gain.reward..cash.."\f6 win +"..gain.leftover..cash.."\f6 bag", 64, 62, 6, "c")
		end
	end
})
card = selectable:extend({
	w = 30,
	h = 42,
	drw = function(_ENV)
		local k, can, x0, y0 = shows, is_on(_ENV), x - 15, y - 21
		rect(x0, y0, x0 + 29, y0 + 41, can and 6 or dark)
		if k.faces then
			k:drw()
			face_bars(k, x - (#k.faces * 3 - 1) / 2, 46, 3, 2)
			k = k.kind
		else
			item_icon(k, x, 28, 1)
		end
		txt(k.name, x, y0 + 30, can and 7 or dark, "c")
		txt(k.price..cash, x, y0 + 36, run.coins >= k.price and 7 or 8, "c")
	end,
})
function item_icon(k, x, y, s)
	if k == potion or k == bomb then
		local m = myspr[k == bomb and 18 or 17]
		sspr(m[1], m[2], m[3], m[4], x - m[5] * s, y - m[6] * s, m[3] * s, m[4] * s)
	elseif k == double then
		rrectfill(x - 7 * s, y - 7 * s, 11 * s, 11 * s, 2 * s, 6)
		rrectfill(x - 3 * s, y - 3 * s, 11 * s, 11 * s, 2 * s, 7)
	elseif k == token or k.up then
		rrectfill(x - 8 * s, y - 8 * s, 16 * s, 16 * s, 3 * s, k.up and (k.inv and 7 or 12) or dark)
		txt(k.up and "+"..k.up or "?", x, y - 2, k.up and k.inv and 8 or 7, "c")
	elseif k.col then
		circfill(x, y, 6 * s, k.col)
	end
end
shop = scene:extend({
	init = function(_ENV)
		global.want_music("menu")
		global.parts = {}
		offers = gen_offers()
		reroll_cost = 1
		build(_ENV)
	end,
	build = function(_ENV)
		f = focus:new()
		cards = {}
		for i = 1, #offers do
			local k = offers[i]
			local cx = 64 + (i - (#offers + 1) / 2) * 32
			add(cards, f:item(card:new({
				x = cx, y = 39,
				shows = k.faces and die:new({kind = k, x = cx, y = 28}) or k,
				on_press = function()
					local got = buy(k)
					if not got then return end
					sfx(38)
					if got != true then got.x, got.y = cx, 28 end
					deli(offers, i)
					build(_ENV)
				end,
				enabled = function() return can_buy(k) end,
			})))
		end
		sell_box = f:item(selectable:new({
			x = 112, y = 83, w = 31, h = 21,
			accepts = function(_, d) return d.class == die end,
			on_drop = function(_, d)
				sell(d)
				sfx(38)
				build(_ENV)
			end,
		}))
		local gap = min(17, 81 / max(1, #run.bag - 1))
		for i = 1, #run.bag do
			local d = run.bag[i]
			d.pickable, d.on_press, d.accepts, d.on_drop = true, false, takes_item, drop_item
			d:move_to(11 + (i - 1) * gap, 84)
			f:item(d)
		end
		inv = inv_slots(f, 120, function(i)
			if use_item(i) then build(_ENV) end
		end, function(i)
			local s = run.items[i]
			return s and (s.k == potion or s.k.col or s.k.up) and can_use(i)
		end)
		reroll_btn = f:item(button:new({
			x = 95, y = 104, w = 64,
			on_press = function()
				if not run:spend(reroll_cost) then return end
				sfx(47)
				offers = gen_offers()
				build(_ENV)
			end,
			enabled = function() return run.coins >= reroll_cost end,
		}))
		fight_btn = f:item(button:new({
			label = "fight", x = 112, y = 118,
			on_press = function()
				next_stage()
				scene:load(placement)
			end,
			enabled = function() return #run.bag > 0 or run.stage_i > 0 end,
		}))
	end,
	upd = function(_ENV)
		reroll_btn.label = "refresh shop "..reroll_cost..cash
		for c in all(cards) do
			if c.shows.faces then c.shows:upd() end
		end
		upd_group(run.bag)
		f:upd()
	end,
	drw = function(_ENV)
		cls(bg)
		print(run.stage_i == 0 and "shop - pick your dice" or "shop", 2, 2, 7)
		txt(run.coins..cash, 127, 2, 7, "r")
		line(0, 11, 127, 11, dark)
		drw_group(cards)
		if #cards == 0 then print("sold out", 48, 37, dark) end
		line(0, 66, 127, 66, dark)
		print("your dice", 2, 70, 6)
		if #run.bag == 0 then print("buy a die to start", 2, 82, dark) end
		rect(96, 72, 126, 92, dark)
		txt("sell", 111, 76, 6, "c")
		if f.held and f.held.kind then txt("+"..sell_price(f.held)..cash, 111, 84, 7, "c") end
		for d in all(run.bag) do
			if d != f.held then d:drw() end
		end
		line(0, 95, 127, 95, dark)
		hp_bar(2, 115, 58, run.hp, run.hp, run.max_hp, 7)
		drw_group(inv)
		reroll_btn:drw()
		fight_btn:drw()
		f:drw_frame()
		hover_tip(f)
		f:drw()
	end
})
title = screen:extend({
	init = function(_ENV)
		global.want_music("menu")
		reload(0x8000, 0, 0x2000, "splash.p8")
		make(_ENV, "start", function()
			new_run()
			scene:load(shop)
		end)
	end,
	text = function()
		memcpy(0x6000, 0x8000, 0x2000)
	end,
})
defs("id,name,faces,price", "d3,d3,1;2;3,1|d3p,d3+,2;3;4,3|d3pp,d3++,3;4;5,5|d6,d6,1;2;3;4;5;6,4|d6p,d6+,2;3;4;5;6;7,6|d6pp,d6++,3;4;5;6;7;8,8|d8,d8,1;2;3;4;5;6;7;8,6|d8p,d8+,2;3;4;5;6;7;8;9,8|d8pp,d8++,3;4;5;6;7;8;9;10,10")
dice_kinds, dice_tiers = names"d3,d6,d8,d3p,d6p,d8p,d3pp,d6pp,d8pp", split"3,6,9"
defs("id,name,hp,atk,spd,def,art,face_art,walk_in,beaten,beat_you",
	"enemy1,tHE tOURIST,8,2,1,1,7,14,hERE FOR\nPAIR-A-DICE!,tHIS PLACE\nIS DICEY,sOUVENIR\nACQUIRED!|enemy2,tHE dRUNK,16,3,10,0,5,12,**bELCHHHH**,sEEING\nDOUBLE\nSIXES...,hIC! i'M ON\nA ROLL!|enemy3,tHE bOUNCER,22,5,-1,7,2,9,iM GON DICE\nYOU UP!,i GOT\nROLLED,yOU JUST\nGOT CUBED|enemy4,tHE gAMBLER,28,4;10,2,1,1,8,fEELING\nLUCKY?,i'LL WIN\nIT BACK!,rEAD 'EM\nAND WEEP|enemy5,sLOT mACHINE sPECIALIST,35,100,-3,2,6,13,hAVE YOU\nSEEN MY\nDICE?,bACK IN MY\nDAY DICE HAD\n7 SIDES,rESPECT\nYOUR\nELDERS|enemy6,tHE lOAN sHARK,28,10,2,3,3,10,yOU OWE ME\nBIG TIME,kEEP THE\nCHANGE...,yOU'RE IN\nTOO DEEP|enemy7,tHE hOUSE,32,15,5,6,4,11,mY CASINO\nMY RULES,iMPOSSIBLE\nTHE ODDS!,rOLL AGAIN\nSOMETIME")
defs("id,name,price,info,inv,aim,col", "potion,beer,2,heals 10 hp,1|bomb,bomb,4,10 damage (in a fight),1|token,reroll,0,reroll a die you rolled,1,rolled|double,double,2,copy a placed die (1 fight),1,place rolled|greedy,\fagreedy,3,pays 2x roll when in bag,1,place,10|grower,\fbgrower,3,placed: lowest face +2,1,place,11|wild,\fewild,3,die can move after the roll,1,place,14|glass,\fcglass,3,die scores 2x roll (1/4 breaks),1,place,12")
defs("id,name,price,info,up,inv,aim", "rig,rig,2,+1 to a random face,1,1,place|rigp,rig+,3,+2 to a random face,2,1,place|rigpp,rig++,4,+3 to a random face,3,1,place|lvlup,lv up,6,+1 all base stats,1|lvlupp,lv up+,9,+2 all base stats,2")
item_kinds, item_tiers = names"potion,bomb,token,double,rig,lvlup,rigp,lvlupp,rigpp", split"6,8,9"
ench_kinds = names"greedy,grower,wild,glass"
stages = {[0] = {reward = 0}}
for r in all(split2d"enemy1,5,dice city.\nwhere every street\nis a gamble./fresh off the bus...\nand a tourist is\nalready in your way.|enemy2,6,One last pint.\nlast call was\nhours ago./someone at the bar\nis seeing double.|enemy3,7,there it is.\nthe casino./this is what\nyou came for./a bouncer blocks\nthe door.|enemy4,8,the card tables.\ncards on the table...\ndice in the air./a gambler eyes\nyour bag of dice.|enemy5,9,an unassuming old lady\nwaves at you from\nthe slot machines.|enemy6,10,the cashier cage.\nyour luck was on loan\nall along./time to pay it back.|enemy7,0,the top floor.\na man in a gold suit\nsteps out of the dark./the owner. the house\nalways wins... tonight\nit rolls against you.") do
	add(stages, {enemy = _ENV[r[1]], reward = r[2], story = r[3]})
end
stages[#stages].boss = true
god_mode = false
battle = class:extend({
	init = function(_ENV)
		stats = {}
		for k in all(stat_names) do
			stats[k] = p:get_stat(k)
		end
		coins = leftover_coins(p:unused())
		p_hp, e_hp, max_hp = p.hp, foe.hp, p.max_hp
		p_bar, e_bar, tick = 0, 0, 0
		p_rate, e_rate = stats.spd + 5, foe.spd + 5
		p_dmg = max(0, stats.atk - foe.def)
		e_dmg = max(0, foe.atk - stats.def)
		if god_mode then p_dmg, e_dmg = 9999, 0 end
	end,
	stalemate = function(_ENV)
		return p_dmg + e_dmg == 0
	end,
	over = function(_ENV)
		return p_hp <= 0 or e_hp <= 0 or tick >= (stalemate(_ENV) and 30 or 1000)
	end,
	won = function(_ENV)
		return e_hp <= 0
	end,
	ticks_to = function(_ENV, who)
		return ceil((100 - _ENV[who.."_bar"]) / _ENV[who.."_rate"])
	end,
	heal = function(_ENV, n)
		p_hp = min(max_hp, p_hp + n)
	end,
	blast = function(_ENV, n)
		e_hp = max(0, e_hp - n)
	end,
	step = function(_ENV)
		local hits = {}
		tick += 1
		p_bar += p_rate
		e_bar += e_rate
		while p_bar >= 100 and e_hp > 0 do
			p_bar -= 100
			e_hp = max(0, e_hp - p_dmg)
			add(hits, {who = "p", dmg = p_dmg, p_hp = p_hp, e_hp = e_hp})
		end
		while e_bar >= 100 and e_hp > 0 and p_hp > 0 do
			e_bar -= 100
			p_hp = max(0, p_hp - e_dmg)
			add(hits, {who = "e", dmg = e_dmg, p_hp = p_hp, e_hp = e_hp})
		end
		return hits
	end,
})
function pick(l, n)
	return l[flr(rnd(n[mid(1, run.stage_i, 3)])) + 1]
end
function gen_offers()
	local s, offers = run.stage_i, {}
	local n = s < 2 and 3 or 4
	for i = 1, n do
		add(offers, i == n and rnd(ench_kinds) or i <= (s < 1 and 2 or 1) and pick(dice_kinds, dice_tiers) or pick(item_kinds, item_tiers))
	end
	return offers
end
function coin_value(d)
	return (d.value or 0) * (d.ench == greedy and 2 or 1)
end
function leftover_coins(dice)
	local sum = 0
	for d in all(dice) do
		sum += coin_value(d)
	end
	return sum
end
dice_max = 5
function can_buy(k)
	return run.coins >= k.price and (not k.inv or stack_for(k) or #run.items < inv_size)
		and (not k.faces or #run.bag < dice_max)
end
function buy(k)
	if not can_buy(k) then return false end
	run:spend(k.price)
	if k.inv then
		local s = stack_for(k)
		if s then s.n += 1 else add(run.items, {k = k, n = 1}) end
		return true
	end
	if k.up then
		for s in all(stat_names) do
			run.base[s] += k.up
		end
		return true
	end
	return run:add_die(k)
end
inv_size, stack_max = 3, 5
function stack_for(k)
	for s in all(run.items) do
		if s.k == k and s.n < stack_max then return s end
	end
end
function can_use(i, b)
	local s = run.items[i]
	if not s then return false end
	if s.k == potion then return (b and b.p_hp or run.hp) < run.max_hp end
	if s.k.aim then return not b end
	return b and b.e_hp > 0
end
function use_item(i, b, d)
	local s = run.items[i]
	if not can_use(i, b) or s.k == double and not (d.slot and #run.slots[d.slot] < 3) then return false end
	s.n -= 1
	if s.n == 0 then deli(run.items, i) end
	if s.k == bomb then
		b:blast(10)
	elseif s.k == token then
		roll_die(d)
	elseif s.k == double then
		sfx(45)
		local c = run:add_die(d.kind)
		c.faces, c.rigged, c.value, c.face_i, c.temp, c.x, c.y = {unpack(d.faces)}, d.rigged, d.value, d.face_i, true, d.x, d.y
		run:place(c, d.slot)
	elseif s.k.up then
		local f = flr(rnd(#d.faces)) + 1
		d.faces[f] += s.k.up
		d.rigged[f] = s.k.up
	elseif s.k.col then
		sfx(48)
		d.ench = s.k
	else
		sfx(46)
		if b then
			b:heal(10)
		else
			run.hp = min(run.max_hp, run.hp + 10)
		end
	end
	return s.k
end
function sell_price(d)
	return flr(d.kind.price / 2)
end
function sell(d)
	run.coins += sell_price(d)
	del(run.bag, d)
end
function roll_die(d)
	d.face_i = flr(rnd(#d.faces)) + 1
	d.value = d.faces[d.face_i]
	if d.ench == glass then
		d.value *= 2
		d.broke = rnd(4) < 1
	end
end
function roll_foe(e)
	local f = {}
	for k, v in pairs(e) do
		f[k] = type(v) == "table" and rnd(v) or v
	end
	return f
end
function new_run(seed)
	if seed then srand(seed) end
	global.run = player:new()
end
function cur_stage()
	return stages[run.stage_i]
end
function finish_fight(b)
	local st = cur_stage()
	run.hp = b.p_hp
	if not b:won() or st.boss then
		run.won = b:won()
		return {reward = 0, leftover = 0}, game_over
	end
	run.coins += st.reward + b.coins
	return {reward = st.reward, leftover = b.coins}, shop
end
function next_stage()
	run.stage_i += 1
	for d in all(run.bag) do
		d:clear()
	end
end
function grow(d)
	local lo, j = d:range()
	for i = 1, #d.faces do
		if d.faces[i] == lo then j = i end
	end
	d.faces[j] += 2
	d.rigged[j] = 2
end
global = _ENV
t = 0
segs = {menu = {0, 2}, fight1 = {8, 13}}
function want_music(name) want = name end
function stop_music()
    music(-1)
    want, playing = nil
end
function toggle_music()
    muted, playing = not muted
    music(-1)
    menuitem(1, muted and "music on" or "music off", toggle_music)
end
function toggle_god()
    god_mode = not god_mode
    menuitem(2, god_mode and "god mode: on" or "god mode: off", toggle_god)
end
function music_upd()
    local pat = stat(54)
    if want != playing and not muted then
        if not segs[playing] or pat != ppat then
            music(segs[want][1])
            playing, pat = want, -1
        end
    end
    ppat = pat
end
function _init()
    color_settings()
    music(0)
    want, playing = "menu", "menu"
    menuitem(1, "music off", toggle_music)
    menuitem(2, "god mode: off", toggle_god)
    scene:load(title)
    fade_t = 14
end
function _update60()
	t += 1
    music_upd()
    pmb, mb = mb, stat(34) & 1
    upd_tws()
    fade_t = min(fade_t + 1, 30)
    if fade_t == 15 then
        scene.current = scene.nxt
        scene.current:init()
    end
    if fade_t > 14 then scene.current:upd() end
end
function _draw()
    scene.current:drw()
    local l = min(14, 15 - abs(fade_t - 15))
    for c = 0, 15 do
        pal(c, fades[c * 15 + l + 1], 1)
    end
end
__gfx__
bbbbbbbb1111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111bbbb111bbbbbbbbbbbbbbbbbbb
bbbbbbb111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111b11111bbbbbbbbbbbbbbbbbb
bbbbbb1111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11122222222222221bbbbbbbbbbbbbbbbbbbbbbbbbbbb11111111111111bbbbbbbbbbbbbbbbb
bbbbbb1111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbb1112211111111111221bbbbbbbbbbbbbbbbbbbbbbbbbb1111111111111111bbbbbbbbbbbbbbbb
bbbbb11112222111122111bbbbbbbbbbbbbbbbbbbbbbbbbbbbb1122222222222222221bbbbbbbbbbbbbbbbbbbbbbbbb11111111111111111bbbbbbbbbbbbbbbb
bbbbb11128888222288211bbbbbbbbbbbbbbb1111bbbbbbbbbb1122222211111122221bbbbbbbbbbbbbbbbbbbbbbbb1111111111111111111bbbbbbbbbbbbbbb
bbbbb11128888888888211bbbbbbbbbbbbb112221bbbbbbbbbb1122222222222222221bbbbbbbb1111bbbbbbbbbbb111111111111111111111bbbbbbbbbbbbbb
bbbbb11128111888811121bbbbbbbbbbbb1222221bbbbbbbbbb1122221111222111121bbbbbbbb122211bbbbbbbbbbb11111111111111111111bbbbbbbbbbbbb
bbbbb112882711881172211bbbbbbbbbb12222221bbbbbbbbbb1122222711222271121bbbbbbbb1222221bbbbbbbbbb11111111111111111bbbbbbbbbbbbbbbb
bbbb1112888222882228211bbbbbbbbbb12222221bbbbbbbbb12212222222222212221bbbbbbbb12222221bbbbbbbbb11111721111721111bbbbbbbbbbbbbbbb
bbb18112888888888888211bbbbbbbbbb1222111bbbbbbbbbb12222222222222212221bbbbbbbb12222221bbbbbbbbb11111771111771111bbbbbbbbbbbbbbbb
bbb18112888888888188211bbbbbbbbb1222221bbbbbbbbbbb12222222222222212221bbbbbbbbb1112221bbbbbbbbb11111111111111111bbbbbbbbbbbbbbbb
bbb18111881288888188211bbbbbbbbb122221bbbbbbbbbbbbb1112222222221221221bbbbbbbbbb1222221bbbbbb1111122222222122221bbbbbbbbbbbbbbbb
bbbb1211181288811888111bbbbbbbbb1222221bbbbbbbbbbbb1122222222222112221bbbbbbbbbbb122221bbbbb122218888888881888221bbbbbbbbbbbbbbb
bbbbb121181281111118821bbbbbbbbb1222221bbbbbbbbbbbb1122222222222222221bbbbbbbbbb1222221bbbbb128188888881888188821bbbbbbbbbbbbbbb
bbbbb122281211111111821bbbbbbbbb1222221bbbbbbbbbbbb1112222111111111221bbbbbbbbbb1222221bbbbbb12888888881888188821bbbbbbbbbbbbbbb
bbbbbb12281211222221821bbbbbbbbb1222221bbbbbbbbbbbbb1112222177aa771221bbbbbbbbbb1222221bbbbbbb1288888882111288821bbbbbbbbbbbbbbb
bbbbbbb1281218111181881bbbbbbbbb12222221bbb111bbbbb1111122221111112221bbbbbbbbbb1222221bbbbbbbb128888888222888821bbbbbbbbbbbbbbb
bbbbbbb128811888888881bbbbbbbbbb122222221112221bb111111111222222222221bbbbbbbbb12222221bbbbbbbb112222228888888821bbbbbbbbbbbbbbb
bbbbbbb118888888218881bbbbbbbbbb1222222211122221111112211112222222221bbbbb1111122222221bbbb111111111111881181111111111bbbbbbbbbb
bbbbbbb121188888288881bbbbbbbbbb11222222112222221111a2222111111111111111111111122222221bbbb11111111111188888111111111bbbbbbbbbbb
bbbbbbb122218888888881bbbbbbbbbb112222221122222211122aa22211111111111111112222112222221bbbbb1111111111128818111111111bbbbbbbbbbb
bbbbbbb12222111111111bbbbbbbbbbb11222221122222211111111aaaa2222222aaa111122222212222211bbbbb11111111111111111111111111bbbbbbbbbb
bbbbbb11122222222221bbbbbbbbbbbbb11222222222222111111111122aaaaaaa111111122222222222211bbbb1111111111171eeee1111111111bbbbbbbbbb
bbbbb1ccc128888882211111bbbbbbbbb11122222222221111111111111122221111111112222222222221bbbbb1111111111171eee17111111111bbbbbbbbbb
bbb11c1ccc18888818221c1c1bbbbbbbbb1111222222211111111111111112211111111111222222222211bbbb111111111111771ee17111111111bbbbbbbbbb
bb11ccc1ccc188888821cc1c11bbbbbbbbb11111111111111111111111111111111111111112222222111bbbb1111111111111771ee17111111111bbbbbbbbbb
b1c1ccc11ccc1188881cc1cc1c1bbbbbbbbbbb1111111111111111111111111111111111111111111111bbbb11111111111111771ee17111111111bbbbbbbbbb
b1c1ccc1c1cccc1881cc1c1cc1c1bbbbbbbbbbbbbbbbbb11111111111111111111111111111111111bbbbbbb11111111111111771ee171111111111bbbbbbbbb
1cc1cc1ccc1ccc111cc11c1cc1cc1bbbbbbbbbbbbbbbbb111111111111111111111111111bbbbbbbbbbbbbb111111111111111771ee171111111111bbbbbbbbb
1c1ccc1cc1c111cc111cccc1c1111bbbbbbbbbbbbbbbbbb11111111111111111111111111bbbbbbbbbbbbbb111111111111111771ee171111111111bbbbbbbbb
1c1ccc1cc1cc1ccc1cc1cccc122221bbbbbbbbbbbbbbbbbb111111111111111111111111bbbbbbbbbbbbbbb1111111111111117771e171111111111bbbbbbbbb
1c1c1121c1cc1ccc1cc1cccc118821bbbbbbbbbbbbbbbbbb111111111111111111111111bbbbbbbbbbbbbbb1111111111111117771e171111111111bbbbbbbbb
1c112221c1ccc1cc111111118888221bbbbbbbbbbbbbbbbbb11111111111111111111111bbbbbbbbbbbbbbb1111111111111117771e171111111111bbbbbbbbb
1122888211cc1111188888888888821bbbbbbbbbbbbbbbbbbb111111111111111111111bbbbbbbbbbbbbbbb1111111111111111771e1771111111111bbbbbbbb
12888888211188888888888888888221bbbbbbbbbbbbbbbbbb111111111111111111111bbbbbbbbbbbbbbbb1111111111111111771e1771111111111bbbbbbbb
12888888821222211188888888888821bbbbbbbbbbbbbbbbbbb11111111111111111111bbbbbbbbbbbbbbbb1111111111111111771e1771111111111bbbbbbbb
12888888888111122111188888888821bbbbbbbbbbbbbbbbbbb11111111111111111111bbbbbbbbbbbbbbbbb111111111111111771e1771111111111bbbbbbbb
b18888888888822211ccc1111111111bbbbbbbbbbbbbbbbbbbbb1111111111111111111bbbbbbbbbbbbbbbbb111111111111111771e1771111112111bbbbbbbb
bb18888888888211c1ccc1ccc1bbbbbbbbbbbbbbbbbbbbbbbbbb1111111111111111111bbbbbbbbbbbbbbbbb11111111221111177111771111111211bbbbbbbb
bb1888888888811cc1ccc1ccc1bbbbbbbbbbbbbbbbbbbbbbbbbb1111111111111111111bbbbbbbbbbbbbbbbbb1111112221111177771771111111211bbbbbbbb
bb11888888881c1cc1ccc1ccc1bbbbbbbbbbbbbbbbbbbbbb11bb111bb11bb11bbbbbbbbbbbbbbbbbbbbbbbbbb1111122211111177777771111111111bbbbbbbb
bb1c11888881cc1cc1cccc1cc1bbbbbbbbbbbbbbbbbbbbb12211222112211221bbbbbbbbbbbbbbbbbbbbbbbbb1111122111111177777771111111111bbbbbbbb
bb1c1c188111ccc1cc1ccc1cc1bbbbbbbbbbbbbbbbbbbb122222222222222221bbbbbbbbbbbbbbbbbbbbbbbbbb111111111111117771777111111111bbbbbbbb
bb1c1cc11cc1ccc1cc1ccc1cc1bbbbbbbbbbbbbbbbbbbb122222222222222221bbbbbbbbbbbbbbbbbbbbbbbbbb111111111111117777777111111111bbbbbbbb
bb1cc1cc1ccc1cc1cc1ccc1cc1bbbbbbbbbbbbbbbbbbbb12222221111111221bbbbbbbbbbbbbbbbbbbbbbbbbbb111111111111117777777111111111bbbbbbbb
bb1cc1cc1ccc1cc1cc1ccc1c1bbbbbbbbbbbbbbbbbbbbb12222112222222121bbbbbbbbbbbbbbbbbbbbbbbbbbb111111111111117771777111111111bbbbbbbb
bb11111111111111111111111bbbbbbbbbbbbbbbbbbbbb12221228888888211bbbbbbbbbbbbbbbbbbbbbbbbbbb111111111111117777777111111111bbbbbbbb
bbbbbbbbb111111111111111111bbbbbbbbbbbbbbbbbbb12212888888888821bbbbbbbbbbbbbbbbbbbbbbbbbbb111111111111111111111111111111bbbbbbbb
bbbbbbbbb1111111111111111111bbbbbbbbbbbbbbbbbb12212888888888821bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111bbbbbbbbbbbbbbbbbb
bbbbbbbbb11222221111111122111bbbbbbbbbbbbbbbbb12128211188881111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb117777771111bbbbbbbbbbbbbb
bbbbbbbb1118888822111112882111bbbbbbbbbbbbbbb112128227118817111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb117777777777771bbbbbbbbbbbbb
bbbbbbbb1118888188221121882111bbbbbbbbbbbbbb1881288822228812221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777777777777771bbbbbbbbbbbb
bbbbbbbb1118888811888888118211bbbbbbbbbbbbbb1888888821118811121bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1777777777777777771bbbbbbbbbbb
bbbbbbbb1118888888888888888211bbbbbbbbbbbbbb1888888882228812281bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777777777111777771bbbbbbbbbbb
bbbbbbbb1128888811188881118821bbbbbbbbbbbbbbb181888888888881881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb177777777711222177771bbbbbbbbbbb
bbbbbbbb1288888877188887718821bbbbbbbbbbbbbbbb12888888888881881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1777777771122222211771bbbbbbbbbbb
bbbbbbbb1288888822288812228821bbbbbbbbbbbbbbbbb1288888888812881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777777712288888821771bbbbbbbbbbb
bbbbbbb11188888888888818888821bbbbbbbbbbbbbbbbbb128888888228881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777777128882222222171bbbbbbbbbbb
bbbbbb122218888888888818888821bbbbbbbbbbbbbbbbbb112888881118881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1777777712888888888821bbbbbbbbbbbb
bbbbbb128888888888888881888821bbbbbbbbbbbbbbbbbb121288818888881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb177777771111188811111bbbbbbbbbbbbb
bbbbbbb1228888888888188188821bbbbbbbbbbbbbbbbbbb12212288881881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777117777711177771bbbbbbbbbbbbb
bbbbbbbb118882188888211288821bbbbbbbbbbbbbbbbbbb1222111111211bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17111217777718177771bbbbbbbbbbbbb
bbbbbbbb128888218888822888821bbbbbbbbbbbbbbbbbbb1228822222821bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1222817771718177171bbbbbbbbbbbbb
bbbbbbbb128888218888888888821bbbbbbbbbbbbbbbbbbb1288888881881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1288817777718177771bbbbbbbbbbbbb
bbbbbbbb128888821888888111821bbbbbbbbbbbbbbbbbb11288888888881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1288881111188811111bbbbbbbbbbbbb
bbbbbbbbb1288882188888114411111bbbbbbbbbbbbbbb11111888888881111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17118888882288881281bbbbbbbbbbbbb
bbbbbbbbbb128888218888111144441bbbbbbbbbbbbbb1112221188888122221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb177188888228888118821bbbbbbbbbbbbb
bbbbbbbbbb112288218888222211111bbbbbbbbbbbbb111222222111812222221bbbbbbbbbbbbbbbbbbbbbbbbbbbbb177718888888888888881bbbbbbbbbbbbb
bbbbbbbbb1771128888888888221bbbbbbbbbbbbbbb11122222222221222222221bbbbbbbbbbbbbbbbbbbbbbbbbbbb177771888888888118881bbbbbbbbbbbbb
bbbbbb117777771222228888882111bbbbbbbbbbbb1112222222222222222222221bbbbbbbbbbbbbbbbbbbbbbbbbbbb1777111888818888881bbbbbbbbbbbbbb
bbbb1171117777711111222222177711bbbbbbbbbb1122222222222212222222221bbbbbbbbbbbbbbbbbbbbbbbbbbb11111222111118888881bbbbbbbbbbbbbb
bbb177777111777777711111117771771bbbbbbbb112222222222221812222222221bbbbbbbbbbbbbbbbbbbbbbbbb144444444212221888811bbbbbbbbbbbbbb
bb17777777771177777111117777177771bbbbbbb112222222222221812222222221bbbbbbbbbbbbbbbbbbbbbbbb1444444444421222111111bbbbbbbbbbbbbb
b1777777777771117711111117111777771bbbbbb1122222122222188812221222221bbbbbbbbbbbbbbbbbbbbbb144444444444217771221221bbbbbbbbbbbbb
177777777777711711771117717117777771bbbbb1222222122222111112222122221bbbbbbbbbbbbbbbbbbbbb14444444444442177712221221bbbbbbbbbbbb
1777777777777117777711177171177777771bbbb1222221222221444441222212221bbbbbbbbbbbbbbbbbbbb1444444444444421777122212441bbbbbbbbbbb
1777777717777117777771117771177777771bbb12222221222221144414122212221bbbbbbbbbbbbbbbbbbb1444444444441142177771222124411bbbbbbbbb
17777777177771117777711177711777777771bb122222211222214144441222122221bbbbbbbbbbbbbbbbbb14444124444444111777712221244441bbbbbb11
177777777177771177777111717117777777771b122221188111141111111222122221bbbbbbbbbbbbbbbbb1444442124444444411777712212444441bbbb141
177777777717771177777111777117717777771b122218888888818888812222122221bbbbbbbbbbbbbbbbb14444421244444444441777122124444441bb141b
b17777777771171177777111117117771777771b121188888888888888812222111111bbbbbbbbbbbbbbbbb14444442124444444444177122212444421b141bb
b17777777777711177777111881881771777771bb1888888888888188881222218881bbbbbbbbbbbbbbbbbb14444444212244444444411122221222421141bbb
bb17777777777771177771888818881177777771bb188888811111111111222218881bbbbbbbbbbbbbbbbbb1444444442112444444444441222211122181bbbb
bbb1777777777771a11118811181188817777771bbb11111122221414414122218881bbbbbbbbbbbbbbbbbb14444444422212224444444441111bbb118821bbb
bbb1777777777771aa122888a81a818821777771bbbbbb12222221444144122218881bbbbbbbbbbbbbbbbb1444444444422211122244444441881b1414221bbb
bbbb177777777771aa128881111188882177771bbbbbbb11111111111111111111111bbbbbbbbbbbbbbbbb144444444444222221112244444188211441111bbb
bbbb117777777771aa128888a1881888217771bbbbbbbbbbbbbbbbb1111111111bbbbbbbbbbbbbbbbbbbbb144444444444422222211122211182214121bbbbbb
bbb1771117777771aa1281111111888221711bbbbbbbbbbbbbbbbb111111111111bbbbbbbbbbbbbbbbbbbb144444444444442222217711112211114211bbbbbb
bbb1777771111771a1111111777111111111bbbbbbbbbbbbbbbbb11111111111111bbbbbbbbbbbbbbbbbbb144444444444444222221777712221bb1121bbbbbb
bbb1777777777111177771117771177771bbbbbbbbbbbbbbbbbbb11111111111111bbbbbbbbbbbbbbbbbbb144444444444444422221777771221bbbb141bbbbb
bbb1777777777711777771117171177771bbbbbbbbbbbbbbbbbbb11112222222221bbbbbbbbbbbbbbbbbbbb1444444444444444222177777121bbbbb111bbbbb
bbb1777777777711777777117771177771bbbbbbbbbbbbbbbbbbb11122222222221bbbbbbbbbbbbbbbbbbbb1111111111111111111111111111bbbbb141bbbbb
bbb1777777777711777777117771177771bbbbbbbbbbbbbbbbbbb11111111121111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb177777777711777777777771177771bbbbbbbbbbbbbbbbbbb11222171111711bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb177777777711717777777171177771bbbbbbbbbbbbbbbbbb112222111121111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb1777777771171777777777117771bbbbbbbbbbbbbbbbbbb122222222221221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbb17777777117177777777711771bbbbbbbbbbbbbbbbbbbb122122222222121bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbb177777711771777777771171bbbbbbbbbbbbbbbbbbbbbb11122222222121bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbb1111111111b11777717111bbbbbbbbbbbbbbbbbbbbbbb11222222211221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbb11111111bbbbbbbbbbbbbbbbbbbbbbbb11222222222221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1222222211221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb122222222221bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11122222222211bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1777122221221771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1171777111111177171bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbb11bbb1881bb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb177771177111117717771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb1881b18881b1881bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb177777717711177177771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb188811888818821bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb17777777711111117777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb188811888218821b11bbbbbbbbbbbbbbbbbbbbbbbbbbb17777777777717777777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8bbbbbbbbbbbbbbbbbb
bbbb1888818882188211821bbbbbbbbbb111b111bbbbbbbbb177711111777171777777771bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9bbbbbbbbbbbbbbbbbbb
bbbb1882818888188811821bbbbb111b1882122211bbbbbb177771aaa1777177777777771bbbbbbbbbbbbb777bbbbbbbbbbbbbbbbbb4bbbbbbbbbbbbbbbbbbbb
bbbbb188218882188218821bbbb1882128821aaa121bbbbb1777711111777171777771771bbbbbbbbbbb77777fbbbbbbbbbbbbbbb88488bbbbbbbbbbbbbbbbbb
bbbbb1882188821aaa18821bbbb18821288219991221bbbb1777777777777177777771771bbbbbbbbbb7777777fbbbbbbbbbbbb888848888bbbbbbbbbbbbbbbb
bb111b1882188219991821bbbb188218122181228821bbbb1777717777777177777771771bbbbbbbbb77ff7777ffbbbbbbbbbb88888288888bbbbbbbbbbbbbbb
b188211882188212218821bb11888888888888888821bbbb1777717777777177777717771bbbbbbbbbf777f77f44bbbbbbbbb8888822288882bbbbbbbbbbbbbb
b18882188888888888821bb122188888888888888821bbbb1777717777777177777717771bbbbbbbbbbf77fff499bbbbbbbbb8888888888882bbbbbbbbbbbbbb
bb1888218821821821821bb182188888218218818821bbbb1777771777777177777717771bbbbbbbbbb4ff444999bbbbbbbb888888888888882bbbbbbbbbbbbb
bb1888818821821821821bb182188888818818818821bbbb1777777177777717777177711bbbbbbbbbb4f4994949666bbbbb888888888888882bbbbbbbbbbbbb
bb188888882182182181bbb18888888882182182121bbbbb117777771711111111717771bbbbbbbbbbb94f494999bb6bbbbb888888888888822bbbbbbbbbbbbb
bbb18888882182182121bbb18888888882182182121bbbbbbb177777717777777717771bbbbbbbbbbbb99f494949bb6bbbbb888888888888822bbbbbbbbbbbbb
bbb18888888888888821bbbb1888888888888888821bbbbbbbb1777771777777777171bbbbbbbbbbbbb994999949bb6bbbbb888888888888222bbbbbbbbbbbbb
bbbb1888888888888821bbbbb188888888888888821bbbbbbbbb117771777777777111bbbbbbbbbbbbb994994949bb6bbbbbb8888888888222bbbbbbbbbbbbbb
bbbb1888888888888221bbbbbb18888888888888221bbbbbbbbb171111111111111171bbbbbbbbbbbbb994994999bb6bbbbbb8888888882222bbbbbbbbbbbbbb
bbbbb18888888888221bbbbbbbb188888888888221bbbbbbbbbb177777777717777771bbbbbbbbbbbbb999999994bb6bbbbbbb22288822222bbbbbbbbbbbbbbb
bbbbbb1888888882221bbbbbbbbb18888888882221bbbbbbbbbb111111111111111111bbbbbbbbbbbbb499999946666bbbbbbbb222222222bbbbbbbbbbbbbbbb
bbbbbbb122222222221bbbbbbbbbb1222222222221bbbbbbbbbb111111111111111111bbbbbbbbbbbbb644444446bbbbbbbbbbbbb22222bbbbbbbbbbbbbbbbbb
bbbbbbbb1111111111bbbbbbbbbbbb11111111111bbbbbbbbbbb111111111111111111bbbbbbbbbbbbbb66666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
__sfx__
901000002b0302b0152a0302a0151b0301b0151a0301a015220302203022015220151e0301e01500000000002b0002b0002a0002a0001b0001b0001a0001a000220002200022000220001e0001e0000000000000
000800202b7202b7152a7202a7151b7201b7151a7201a715227202272022715227151e7201e71500700007002b7002b7002a7002a7001b7001b7001a7001a700227002270022700227001e7001e7000070000700
011000001373313710137330071002733027100773307732077100771002733027100070000700137301371013730137100773007710007300071002730027300771007710077300771002030020300201500000
010400200611006110061100611006110061100611006110061100611006110061100611006110061100611000110001100011000110001100011000110001100011000110001100011000110001100011000110
010800001373313710137331371000733007100273302710077330773207710077100273302710007000070013730137101373013710007300071002730027100773007730077100771002730027100070000700
010800000e1300e1300e1100e1100f1300f1300f1100f1101313013130131101311012130121100e1300e11000000000000000000000000000000000000000000000000000000000000000000000000000000000
01fa00020002303013000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
018e00020001303023000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9110001026710277100000000000000000000000000000000000000000000001c0001e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a003000005653000001c6330560005643000001c6001c623000000560305620056031c600286002962026600006002b62014b401fb232a84005b2300000000000000000000000000000000000000000000000000
c00200001205300000180531575015733157010010024000000000560005600056001c600286002960026600006002b6000000031600000000000000000000000000000000000000000000000000000000000000
5b0100003d65035673336500060000600256000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
920100003f6503a6633c6700060000600256000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
06060000100530d0020a002010020c05209002100000f050070000500010000000500e00010000000000c0000e0000e0000e000000000e0000e0000e0000e0000000000000000000000000000000000000000000
180b00000b7310b7310b7310b7310b7310b7310c7310e7410f7510f7510d7410c7420b7320b7320b7320b7220b7220b7220b7120b7000b7000b7000b700177001770000700007000070000700007000070000700
340900003272037720377203772500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040500000a6730a6710a6610a6610a6510a6310a6210a6110a6100a610006000060000600006002e6000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
010d000000024180530001329005280002800025000270002800028000280002800028000020000400005000070000b0000b0000b0000b0000000000000000000000000000000000000000000000000000000000
010d000000014300330c01329005280002800025000270002800028000280002800028000020000400005000070000b0000b0000b0000b0000000000000000000000000000000000000000000000000000000000
4305000028230282202a20029200282302822025200272002823028230282202821028210022000420005200072000b2000b2000b2000b2000020000200002000020000200002000020000200002000020000200
a003000005653000001c6330560005643000001c6001c623000000560305620056031c600286002962026600006002b62014b401fb232a84005b2300000000000000000000000000000000000000000000000000
a103000005653000001c6330560005643000001c6001c623000000560305620056031c600286002962026600006002b62014b401fb232a84005b2300000000000000000000000000000000000000000000000000
410b00003f6433f4333f4213f4113f415005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
a1050000246243f651246132461524615246243f651186132461524615246233f621186132461524615246243f621186110060000600006000060000600006000060000600006000060000600006000060000600
490200001a6201a6301e34300000180001c0000c6000000000000000001a6201a6303f34300000000000000000000000001a6201a6303f343180001a6201a6303f34300000000000000000000000000000000000
180200000116700617071670061708367006170835700617083570061703157006170514700617051470061704047006170403700617040370061704727006170472700617057170061704117006170311700617
011000001b1501c1501b15020150201101e1502015020120201202012500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 40020644
00 40020644
02 06024344
00 40434444
00 41434444
02 45434444
00 41424344
00 41424344
01 01040644
00 08070444
00 01060444
00 08070444
00 01060444
02 05030444

__label__
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222272222722227222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222722222222
2222222222222222222222222222222222222222222222222222222222222222222222222a222222222222222222222222222222222222222222722722722222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222272777222222
2222222222222222222222222222222222222222222222222222222222222222222222222a222222222222222222222222222222222222222222227772222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222772a77a77777a22
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222227222227772222222
2222222222222222222222222222222222222222222222222222222222222222222222222a222222222222222222222222222222222222222222272727222222
22222222222222222222222222222222222222222222222222222222222222222222aa22a7a2aa22222222222222222222222222222222222222722722722222
2222222222222222722222222222222222222222222222222222222222222222222222222a222222222222222222222222222222222222222222222722222222
88888878888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888878888788887888
2222222222272222222222222222222222222222222222222222222222222222222222222a222222222222222222222222222222222222222222722a22222222
2222222222222272222222222222222222222222222222222222222222222222222222222a222222222222222222222222222222222222222222222222222222
22222272272722227222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222a22222222
22222222222722222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222722722722272222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22227272272227227222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
88888888888887777788888888888888777788888888888888888888888888888888888888888888888888877778888888888888888888888888888a88888888
88788778a7877eeeee77788888888887eeee788888888888888888888888888888888888888777778888887eeee7888888888888888888888888888a88888888
222222222227eeeeeeeee77772222227eeee722222222222222222222222222222222222277eeeee7227227eeee7222277722222222222222222222a22222222
2222227227227eeeee777eeee722227eeeeee722222222222222222222222222222222277eee7777e772227eeee77277eee72222222222222222222222222222
2222222272277eeeee72277eee722227eeee72222222222222c22222222222222222227eeee722227ee7227eeee727eeeee72222222222222222222222222222
2222722222277eeeee72227eeee72222777722222222222222222222222222222222227eeee7222227e72c27777227eeeee72222222222222222222a22222222
8888887887887eeeee77887eeeee787777778888887777778888887777778888888887eeee78888887e78777777787eeeee77788888888888888888a88888888
88888888888a7eeeee788887eeee77eeeeee788877eeeeee77c877eeeeee7888888887eeee788888887e7eeeeee77eeeeeeeee77777777888777788a88888888
88888888788a7eeeee788887eeeee777eeee7887eeeeeeeeec77eee777eee78888887eeeee78888887e7c77eeee787eeeee7777eeeeeee787eeee78a88888888
8888888888887eeeee788887eeeee787eeee787eeeeeeeeeee7eeee787eeee7888887eeeee7888888878887eeee787eeeee788877eeee78887e7788888888888
88888888888a7eeeee788887eeeee787eeee787eeeee7eeeee7eeee787eeee7888887eeeee7888888888887eeee787eeeee788887eeeee7887e7888888888888
2222222222227eeeee722227eeeee727eeee77eeeee727eee7eeeee777eeee7222227eeeee7222222222227eeee727eeeee722227eeeee727e72222222222222
2222222222227eeeee722227eeeee727eeee77eeeee7227777eeeeeeeeeeee7222227eeeee7222222272227eeee727eeeee7222227eeee727e72222222222222
2222222222227eeeee722227eeeee727eeee77eeeee7222227eeeeee7777772222227eeeee72222227e7227eeee777eeeee7222227eeeee77e72222222222222
22222222222a7eeeee722227eeee7227eeee77eeeee7222227eeeee72222272222227eeeee722222227e727eeee727eeeee7227227eeeee7e722222222222222
22222222222a7eeeee72227eeeee7227eeee727eeee722227e7eeee722227e72222227eeee722222227e727eeee727eeeee727e7227eeee7e722222222222222
22222222222a7eeeee72227eeee72227eeee727eeee722227e7eeeee72227e72222227eeeee7222227ee727eeee7227eeee727e7227eeeeee722222222222222
8888888888887eeeee78887eee778877eeee7787eeee7777e787eeee7777e7888888887eeee7888887e7877eeee7787eeee77e78887eeeee7888888888888888
8888888888887eeeee7777eee78887eeeeeeee787eeeeeee78887eeeeeee788888a88887eeee77777ee77eeeeeeee787eeeee7878887eeee7788888888888888
888888888887eeeeeeeeeee77888887777777788877777778888877777778888888888887eeeeeeeee77877777777888777778888887eee78888888888888888
88888888888a777777777778888888878888888888888888888888888888888888888888888777777777788c88888888888888888777eee78888888888888888
22222222222a2222222222222222222222222222222222222222222a2222222222222222222222222222222c222222222222222227eeee722222222222222222
22222222222a222222222222227222272222722222222222222222222222222222222222222222222222222222222222222222777eeee7722222222222222222
2222222222222222222222222222222722222222222a2222222222222a222222222222222222aa222222222c22222222222227eeeeee727777a2222222222222
22222222222222222222222222227227227222222222a2222222200022222222aaa22222a222222222222222222222222222227eeeee72222222222222222222
222222222222222222222222222227222722222222222a2222220777000002a222222222222000002222a22c2222222222222227eee722722222222222222222
22222222222222222222222222222222222222222222222a2220777777777002222a220000077777022a22222222222222222222777272272222222222222222
8888888888888888888888888778c78787777c888888888880077777777777708888a06087777778708888888888888888888888888878888888888888888888
88888888888888888888888888888888888888888888888807777777077777008888806808778807770888888888888888888887888878888788888888888888
888888888888888888888888888887888788888888888880877777777777806088880666802877777770888a88888888888888888788a8888888888888888888
88888888888888888888888888887887887888888888888028777007777808608888066868008882288088a88888888888888888888888888888888888888878
888888888888888888888888888888878888888888888880008877778770686088806662662200000000888888888888888888888888a8888888888888888878
888888888888888888888888887888878888788888888880680077777806666088806660668622022886088888888888888888888888888888888888888888a8
8888888888888888888888888888888c888888888888888066280888708686608880666666866026660608888888888888888888888888888888888888888888
8888888888888888888888888888888c8888888888888880606622200866866088806666606660866666088a88888888888888888888888888888888888888a8
8888888888888888888888888888888c8888a888888888806066888808660660888066666066068666660888a8888888888888888888a88888888888888888a8
22222222222222222222222222222222222222222222a220666866620866666022206668666066680666022222222222222222222222a22222222222222222a2
2222222222222222222222222222222c2222222222222220066066680686660222220666666066666660222222222222222222222222a22222222222222222a2
2222222222222222222222222222222c2222222222222222066666680666602222222066666066066660222222222222222222222222222222222222222222a2
2222222222222222222222222222222c2222222222222222066660060686022222222a0666066666000222222222222222222222222222222222222222222222
8888888888888888888888888888888788888888888888a8800668860660888888888a80660600008888888888888888888888888888a88888888888888888a8
8888888888888888888888888888888c88888888888888888880000000088a8888888a88000088888888888888888888888888888888a8888888888888888888
8888888888888888888888888888888c8888888888888888888888888888888888888a8a888888888888888888888888888888888888a8888888888888888888
8888888888888888888888888888888888888888888a88888888a8888888888888888a88888888888888a88888888888888888888888a8888888888888888888
8888888888888888888888888888888c88888888888888888888a8888888888888888a888888888888888a888888888888888888888888888888888888888888
8888888882888888888888888888888c8888888888888888888a888888888888888888a888888888888888888888888888888888888888888888888888888888
2222222222222222222222222222222c2222222222222222222a222222222222aa22222222222222222222222222222222222222222222222222222222222222
222222222222222222222222222222222222222222222222222222222222222222222a2222222222222222222222222222222222222222222222222222222222
2222222222222222222222222222222c2222222222222222222222222222222222222a2222222222222222222222222222222222222222222222222222222222
8888888882888888888888888888888c8888888888888888888882288888888888888a8888888888888888888888888888888888888888888888888888822888
8888888222228888888888888888888c8888888888888888888882288888888888888a8888888888888888888888888888888888888888888888888888822888
8888888222228888888888888888888c888888888888888888888228888888888888888888888888888888888888888888888888888888888888888888822888
888882222222228888888888888888888888888888888888888882288888888888888a8888888888888888888888888888888888888888888888888888222222
888882222222228888888888888888888888888888888888888882288888888888888a8888888888888888888888888888888888888888888888888888222222
888222222222222288888888888888888888888888888888888882288888888888888a8888888888888888888888888888888888888888888888888888222222
88822222222222228888888888888888888888888888888888882222888888888888888888888888888888888888888888888888888888888888888882222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222722222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222722222222222222222222222222222222222222222222222222222222222222222222222222222222222
88222222222222222888888888888888888888888888788888222222222888888888888888888888888888888888888888888888888888888888888822222222
88222222222222222888888888888888888888888888a88822222222222228888888888888888888888888888888888888888888888888888888888822222222
88222222222222222888888888888888888888888888888822222222222228888888888888888888888888888888888888888888888888888888888822222222
88222222222c22222888888822222222222222222288a88822222222222228888888888888888888888888888888888888888888888888888888888822222222
88222222222c22222888888822222222222222222222222222222222222222222228888888888888888888888888888888888888888888888888888822222222
88222222222c22222888888222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222722222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222c22222222222222222222222222222222222222222222222222222228888888888888888888888888888888888888888888888888888822222222
88222222222c22222888822222222222222222222222222222222222222222222228888888888888888888888888888888888888888888888888888822222222
88222222222222222888822222222222222222222222222222222222222222222222228888888888888888888888888888888888888888888888888822222222
22222222222222222222822222222222222222222222222222222222222222222222228888888888888888888888888888888888888888888888888822222222
88222222222c22222882822222222222222222222222222222222222222222222222228888888888888888888888888888888888888888888888888822222222
22222222222222222222822222222222222222222999999922aaaaaaa2222222222222888888888888888888888888888888888888888888888888882229922a
22222222222222222222822222222222222222222999999922aaaaaaa2222222222222222888888888888888888888888888888888888888888888882229922a
22222222222222222222222222222222222222222999999922aaaaaaa2222222222222222888888888888888222222222222222228888888888888882229922a
22222222222222222222222222222222222222222999999922aaaaaaa2222222222222222888888888888888288882888882888828888888888888882229922a
22222222222222222222222222222222222222222999999922aaaaaaa2222222222222222222222222222222222222222222222228888888888888882229922a
2222222222222222222222222222222222222222222222222222222222222222222222222222288888888888222222222222222222222222222222222229922a
2222222222222222222222222222222222222222222222222222222222222222222222222222288888888888222222222222222228888888888888882229922a
2222222222222222222222222222222222222222222222222222222222222222222222222222222888888888222222222222222228888888888888882229922a
2222222222222222222222222222222222222222222222222222222222222222222222222222222888888888222222222222222228888888888888882229922a
2aaaaaa22aaa2299999922222222222222222222299999992222222222299999992222222222222888888888222222222222222228888888888888882229922a
2aaaaaa22aaa2299999922222222222222222222299999992222222222299999992222222222222888822222222222222222222222222228888888882229922a
2aaaaaa22aaa2299999922222222222222222222299999992222222222299999992222222222222888822222222222222222222222222228888888882229922a
2222222222222222222222222222222222222222299999992222222222299999992222222222222888822222222222222222222222222228888888882229922a
2222222222222222222222222222222222222222299999992222222222299999992222222222222822222222222222222222222222222222288888882229922a
2222222222222222222222222222222222222222222222222222222222222222222222222222222822222222222222222222222222222222288888822229922a
299999922aaa22aaaaaa22222222222222222222222222222222222222222222222222222222222822222222222222222222222222222222288888822229922a
299999922aaa22aaaaaa22222222222222222222222222222222222222222222222222222222222822aaaaaaaaaaaaa222aaaaaaaaaaaaa2288888822229922a
299999922aaa22aaaaaa22222222222222222222222222222222222222222222222222222222222822aaaaaaaaaaaaa222aaaaaaaaaaaaa2288888822229922a
22222222222222222222222222222222222222222222222222999999922aaaaaaa2222222222222822aaaaaaaaaaaaa222aaaaaaaaaaaaa2288888222229922a
22222222222222222222222222222222222222222222222222999999922aaaaaaa2222222222222822222222222222222222222222222222288888222229922a
22222222222222222222222222222222222222222222222222999999922aaaaaaa2222222222222822222222222222222222222222222222222882222229922a
2aaaaaa2222222999999222222222222222222222222222222999999922aaaaaaa22222222222228222222222222222222222222222222222222222222222222
2aaaaaa2222222999999222222222222222222222222222222999999922aaaaaaa22222222222222222222222222222222999999999999922222222222222222
2aaaaaa22222229999992222222222222222222222222222222222222222222222222222222222222222222222222222229999999999999222222222222aa229
222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222229999999999999222222222222aa229
222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222aa229
22222222222222222222222222222222222222222aaaaaaa229999999229999999222222222222222222222222222222222222222222222222222222222aa229
299999922aaa22999999222222222222222222222aaaaaaa229999999229999999222222222222222222222222222222222222222222222222222222222aa229
299999922aaa22999999222222222222222222222aaaaaaa22999999922999999922222222222222229999999999999222aaaaaaaaaaaaa222222222222aa229
299999922aaa22999999222222222222222222222aaaaaaa22999999922999999922222222222222229999999999999222aaaaaaaaaaaaa222222222222aa229
22222222222222222222222222222222222222222aaaaaaa22999999922999999922222222222222229999999999999222aaaaaaaaaaaaa222222222222aa229
222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222aa229
222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222aa229
2aaaaaa2222222aaaaaa2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222aa229
2aaaaaa2222222aaaaaa22222222222222222222299999992222222222222222222222222222222222aaaaaaaaaaaaa2222222222222222222222222222aa229
2aaaaaa2222222aaaaaa22222222222222222222299999992222222222222222222222222222222222aaaaaaaaaaaaa2222222222222222222222222222aa229
2222222222222222222222222222222222222222299999992222222222222222222222222222222222aaaaaaaaaaaaa2222222222222222222222222222aa229
222222222222222222222222222222222222222229999999222222222222222222222222222222222222222222222222222222222222222222222222222aa229
222222222222222222222222222222222222222229999999222222222222222222222222222222222222222222222222222222222222222222222222222aa229
299999922222229999992222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222aa229
