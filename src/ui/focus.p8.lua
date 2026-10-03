-- one per scene: hover, press, pick up and drop selectables
-- mouse: hover, click, drag (or click to pick up, click again to drop)
-- keys: arrows move to the nearest item that way, x picks/drops/presses, o cancels
--
-- usage:
--   f = focus:new()
--   f:item(button:new({...}))   -- later items sit on top of earlier ones
--   f:upd()  f:drw()            -- f.cur is the hovered item, f.held the carried one

focus = class:extend({
	init = function(_ENV)
		items = {}
		cur = false
		held = false
		dragging = false
		mouse_on = false
		mx, my = cursor.x, cursor.y
		-- frames the same item has been hovered (tooltips wait for it)
		hover_t, last = 0, false
		-- global, written by the tooltip (a field here would hide it)
		global.tip_area = false
	end,

	item = function(_ENV, it)
		add(items, it)
		if not cur and usable(_ENV, it) then cur = it end
		return it
	end,

	-- can keys land here / can a click do something
	usable = function(_ENV, it)
		if held then return it.accepts and it:accepts(held) end
		return it.pickable or it.on_press
	end,

	-- topmost item under the point; while holding, only drop targets
	-- over an open tooltip nothing behind it gets hovered: cur stays
	under = function(_ENV, px, py)
		local a = tip_area
		if a and px >= a[1] and px <= a[3] and py >= a[2] and py <= a[4] then return cur end
		for i = #items, 1, -1 do
			local it = items[i]
			if it != held and it:contains(px, py) and (not held or usable(_ENV, it)) then
				return it
			end
		end
		return false
	end,

	-- nearest usable item that way; prefers items inside a 45° cone
	move = function(_ENV, dx, dy)
		local best, best_s = false, 32767
		for it in all(items) do
			if it != cur and it != held and usable(_ENV, it) then
				if not cur then
					cur = it
					return
				end
				local ox, oy = it.x - cur.x, it.y - cur.y
				local main = ox * dx + oy * dy
				local cross = abs(ox * dy) + abs(oy * dx)
				local s = main + 2 * cross
				if main < cross then s += 1000 end
				if main > 0 and s < best_s then
					best, best_s = it, s
				end
			end
		end
		if best then cur = best end
	end,

	press = function(_ENV)
		if not cur or not cur:is_on() then return end
		if cur.pickable then
			held = cur
		elseif cur.on_press then
			cur.on_press(cur)
		end
	end,

	-- where the carried item is drawn: at the mouse, or above cur for keys
	held_pos = function(_ENV)
		if mouse_on then return mx, my end
		if cur then return cur.x, cur.y - 10 end
		return held.x, held.y
	end,

	-- drop on cur if it takes the held item; true if dropped
	-- the item starts from where it was drawn, so it can glide into place
	drop = function(_ENV)
		if not (cur and cur.accepts and cur:accepts(held)) then return false end
		held.x, held.y = held_pos(_ENV)
		cur:on_drop(held)
		held = false
		return true
	end,

	upd = function(_ENV)
		local x_hit, o_hit = pressed(5), pressed(4)
		if cursor.x != mx or cursor.y != my then
			mx, my = cursor.x, cursor.y
			mouse_on = true
		end
		-- every frame, not only when the mouse moves: items glide under a still mouse
		if mouse_on then cur = under(_ENV, mx, my) end
		upd_mouse(_ENV)
		upd_keys(_ENV, x_hit, o_hit)
		hover_t = cur == last and hover_t + 1 or 0
		last = cur
	end,

	upd_mouse = function(_ENV)
		if cursor:just_pressed() then
			mouse_on = true
			cur = under(_ENV, mx, my)
			if held then
				if not drop(_ENV) then held = false end
				return
			end
			press(_ENV)
			dragging = held
			return
		end
		if not (cursor:is_released() and dragging) then return end
		dragging = false
		cur = under(_ENV, mx, my)
		if drop(_ENV) then return end
		-- released where it was picked up: keep carrying until the next click
		if not held:contains(mx, my) then held = false end
	end,

	upd_keys = function(_ENV, x_hit, o_hit)
		local dirs = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}}
		for b = 0, 3 do
			if btnp(b) then
				mouse_on = false
				move(_ENV, dirs[b + 1][1], dirs[b + 1][2])
			end
		end
		if x_hit then
			if held then drop(_ENV) else press(_ENV) end
		end
		if o_hit then held = false end
	end,

	-- the hover frame: draw it before cards (tooltip, result box) so they cover it
	drw_frame = function(_ENV)
		-- frame only on things you can pick up, press or drop onto right now:
		-- usable = has an action, is_on = the action is allowed (e.g. fight
		-- during the fight, an empty item slot)
		if not cur or not usable(_ENV, cur) or not cur:is_on() then return end
		local x0, y0 = cur.x - cur.w / 2 - 1, cur.y + (cur.hop or 0) - cur.h / 2 - 1
		rect(x0, y0, x0 + cur.w + 1, y0 + cur.h + 1, 7)
	end,

	-- the carried item and the pointer: always on top, draw last
	drw = function(_ENV)
		if held then
			local ox, oy = held.x, held.y
			held.x, held.y = held_pos(_ENV)
			held:drw()
			held.x, held.y = ox, oy
		end
		if mouse_on then
			line(mx, my, mx, my + 5, 7)
			line(mx, my, mx + 3, my + 3, 7)
		end
	end,
})
