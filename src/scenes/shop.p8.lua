shop = scene:extend({
	init = function(_ENV)
		offers = gen_offers(cur_stage())
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
			add(cards, f:item(selectable:new({
				x = cx, y = 39, w = 30, h = 42,
				shows = k.faces and die:new({kind = k, x = cx, y = 28}) or k,
				on_press = function()
					local got = buy(k)
					if not got then return end
					-- a bought die flies from its card to your row
					if got != true then got.x, got.y = cx, 28 end
					deli(offers, i)
					build(_ENV)
				end,
				enabled = function() return can_buy(k) end,
			})))
		end
		local gap = min(17, 106 / max(1, #run.bag - 1))
		for i = 1, #run.bag do
			local d = run.bag[i]
			d.pickable = false
			d.on_press = false
			d:move_to(11 + (i - 1) * gap, 84)
			f:item(d)
		end
		-- inventory: only potions can be used in the shop
		inv = {}
		for i = 1, inv_size do
			add(inv, f:item(item_slot:new({
				x = 81 + i * 13, y = 119,
				-- potions can be drunk here too
				on_press = function()
					if use_item(i) then build(_ENV) end
				end,
				enabled = function()
					local s = run.items[i]
					return s and s.k == potion and can_use(i)
				end,
			})))
			inv[i]:set(run.items[i])
		end
		reroll_btn = f:item(button:new({
			x = 65, y = 103, w = 44,
			on_press = function()
				if not run:spend(reroll_cost) then return end
				offers = gen_offers(cur_stage())
				reroll_cost += 1
				build(_ENV)
			end,
			enabled = function() return run.coins >= reroll_cost end,
		}))
		fight_btn = f:item(button:new({
			label = "fight", x = 107, y = 103, w = 38,
			on_press = function()
				next_stage()
				scene:load(placement)
			end,
			enabled = function() return #run.bag > 0 end,
		}))
	end,

	upd = function(_ENV)
		reroll_btn.label = "reroll $"..reroll_cost
		for c in all(cards) do
			if c.shows.faces then c.shows:upd() end
		end
		upd_group(run.bag)
		f:upd()
	end,

	drw_card = function(_ENV, c)
		local k, can = c.shows, c:is_on()
		local x0, y0 = c.x - c.w / 2, c.y - c.h / 2
		rect(x0, y0, x0 + c.w - 1, y0 + c.h - 1, can and 6 or 5)
		if k.faces then
			k:drw()
			local n = #k.faces
			face_bars(k, c.x - (n * 3 - 1) / 2, 46, 3, 2)
			k = k.kind
		else
			drw_icon(k, c.x, 28)
		end
		txt(k.name, c.x, y0 + 30, can and 7 or 5, "c")
		txt("$"..k.price, c.x, y0 + 36, run.coins >= k.price and 7 or 8, "c")
	end,

	-- potion: a bottle with red inside; bomb: a ball with a red fuse;
	-- reroll token: a die outline with +1
	drw_icon = function(k, x, y)
		if k == bomb then
			circfill(x - 1, y + 2, 6, 6)
			line(x + 3, y - 4, x + 5, y - 7, 8)
			return
		end
		if k == potion then
			rectfill(x - 2, y - 8, x + 1, y - 4, 6)
			circfill(x, y + 2, 6, 6)
			circfill(x, y + 3, 4, 8)
			return
		end
		rrect(x - 8, y - 8, 16, 16, 3, 6)
		print("+1", x - 3, y - 2, 7)
	end,

	drw = function(_ENV)
		cls(0)
		print(run.stage_i == 0 and "shop - pick your dice" or "shop", 2, 2, 7)
		txt("$"..run.coins, 127, 2, 7, "r")
		line(0, 11, 127, 11, 5)
		for c in all(cards) do
			drw_card(_ENV, c)
		end
		if #cards == 0 then print("sold out", 48, 37, 5) end
		line(0, 66, 127, 66, 5)
		print("your dice", 2, 70, 6)
		if #run.bag == 0 then print("buy a die to start", 2, 82, 5) end
		for d in all(run.bag) do
			d:drw()
		end
		line(0, 95, 127, 95, 5)
		hp_bar(2, 115, 44, run.hp, run.hp, run.max_hp, 7)
		drw_group(inv)
		reroll_btn:drw()
		fight_btn:drw()
		f:drw_frame()
		hover_tip(f)
		f:drw()
	end
})
