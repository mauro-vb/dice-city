-- one per scene: hover, press, pick up and drop selectables, mouse only
-- (click, drag, or click to pick up and click again to drop)
--
-- usage:
--   f = focus:new()
--   f:item(button:new({...}))   -- later items sit on top of earlier ones
--   f:upd()  f:drw()            -- f.cur is the hovered item, f.held the carried one
-- cur, held, dragging and last start nil (no globals have these names)

focus = class:extend({
	init = function(_ENV)
		-- mx, my: the pointer, off-screen until the first upd (a scene's first
		-- drw can come before it, right after the click that loaded it).
		-- hover_t: frames the same item has been hovered (tooltips wait for it)
		items, mx, my, hover_t = {}, -1, -1, 0
	end,

	item = function(_ENV, it)
		add(items, it)
		return it
	end,

	-- can a click do something here / can the held item be dropped here
	usable = function(_ENV, it)
		if held then return it.accepts and it:accepts(held) end
		return it.pickable or it.on_press
	end,

	-- topmost item under the pointer; while holding, only drop targets
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
			-- [sfx 34: pluck] a die is picked up
			sfx(34)
		elseif cur.on_press then
			cur.on_press(cur)
		end
	end,

	-- drop on cur if it takes the held item; true if dropped
	-- the item starts from the pointer, so it can glide into place
	drop = function(_ENV)
		if not (cur and cur.accepts and cur:accepts(held)) then return false end
		held.x, held.y = mx, my
		cur:on_drop(held)
		held = false
		-- [sfx 35: place] anything is dropped
		sfx(35)
		return true
	end,

	-- every frame, not only when the mouse moves: items glide under a still mouse
	upd = function(_ENV)
		mx, my = stat(32), stat(33)
		cur = under(_ENV)
		-- mb / pmb: left button now / last frame (src/utils/cursor)
		if mb > pmb then
			if held then
				if not drop(_ENV) then held = false end
			else
				press(_ENV)
				dragging = held
			end
		elseif mb < pmb and dragging then
			dragging = false
			-- released where it was picked up: keep carrying until the next click
			if not drop(_ENV) and not held:contains(mx, my) then held = false end
		end
		hover_t = cur == last and hover_t + 1 or 0
		last = cur
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
			held.x, held.y = mx, my
			held:drw()
			held.x, held.y = ox, oy
		end
		-- pointer: myspr region 15, or 16 while carrying a die or the button is
		-- down; each region's offset puts its tip on the mouse
		mspr(myspr[(held or mb > 0) and 16 or 15], mx, my)
	end,
})
