-- a shop offer: shows = a die (for dice) or the item def
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

-- item k's icon centred on x, y at scale s: 1 on a shop card, .5 in an
-- inventory slot (src/ui/item_slot.p8.lua). double: two overlapping filled
-- dice; reroll, rig, level up: a filled die with a label; beer (potion):
-- myspr region 17; bomb: region 18; an enchantment: a circle in its colour
function item_icon(k, x, y, s)
	if k == potion or k == bomb then
		local m = myspr[k == bomb and 18 or 17]
		sspr(m[1], m[2], m[3], m[4], x - m[5] * s, y - m[6] * s, m[3] * s, m[4] * s)
	elseif k == double then
		rrectfill(x - 7 * s, y - 7 * s, 11 * s, 11 * s, 2 * s, 6)
		rrectfill(x - 3 * s, y - 3 * s, 11 * s, 11 * s, 2 * s, 7)
	elseif k == token or k.up then
		-- a filled die with a label: reroll dark grey "?", rig white with a
		-- red +up, level up blue +up
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

	-- rebuilt after each purchase or reroll
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
					-- [sfx 38: buy]
					sfx(38)
					-- a bought die flies from its card to your row
					if got != true then got.x, got.y = cx, 28 end
					deli(offers, i)
					build(_ENV)
				end,
				enabled = function() return can_buy(k) end,
			})))
		end
		-- your dice: drag one onto the sell box to sell it
		sell_box = f:item(selectable:new({
			x = 112, y = 83, w = 31, h = 21,
			accepts = function(_, d) return d.class == die end,
			on_drop = function(_, d)
				sell(d)
				-- [sfx 38: buy] selling too
				sfx(38)
				build(_ENV)
			end,
		}))
		local gap = min(17, 81 / max(1, #run.bag - 1))
		for i = 1, #run.bag do
			local d = run.bag[i]
			-- drag to sell, or drop an enchantment or rig on it
			d.pickable, d.on_press, d.accepts, d.on_drop = true, false, takes_item, drop_item
			d:move_to(11 + (i - 1) * gap, 84)
			f:item(d)
		end
		-- inventory: beers, and enchantments and rigs (dropped on a die)
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
				-- [sfx 47: reroll shop]
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
			-- the opening shop needs a die; later an empty bag (the last glass die
			-- broke) still fights on base stats, so a run can't get stuck
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
