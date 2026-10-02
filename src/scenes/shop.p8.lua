shop = scene:extend({
	init = function(_ENV)
		offers = gen_offers(cur_stage())
		build(_ENV)
	end,

	-- rebuilt after each purchase so the bought offer disappears
	build = function(_ENV)
		f = focus:new()
		shown = {}
		for i = 1, #offers do
			local k = offers[i]
			local d = die:new({
				kind = k,
				x = 64 + (i - (#offers + 1) / 2) * 26,
				y = 36,
				on_press = function()
					if not buy(k) then return end
					del(offers, k)
					build(_ENV)
				end,
				enabled = function() return run.coins >= k.price end,
			})
			add(shown, d)
			f:item(d)
		end
		for i = 1, #run.bag do
			local d = run.bag[i]
			d.pickable = false
			d.on_press = false
			d.x = 10 + (i - 1) % 6 * 14
			d.y = 108 + flr((i - 1) / 6) * 14
			f:item(d)
		end
		fight_btn = f:item(button:new({
			label = "fight", x = 110, y = 117, w = 30,
			on_press = function()
				next_stage()
				scene:load(placement)
			end,
			enabled = function() return #run.bag > 0 end,
		}))
	end,

	upd = function(_ENV)
		upd_group(shown)
		upd_group(run.bag)
		f:upd()
	end,

	info = function(_ENV, d)
		local k = d.kind
		print(k.name, 6, 64, k.colors[1])
		print("faces "..join(d.faces, " "), 6, 72, 6)
		print("avg "..d:avg_str(), 6, 80, 6)
		if d.on_press then
			local can = run.coins >= k.price
			print(can and "$"..k.price.." - click to buy" or "$"..k.price.." - not enough coins", 6, 88, can and 10 or 8)
		else
			print("in your bag", 6, 88, 5)
		end
	end,

	drw = function(_ENV)
		cls(0)
		print(run.stage_i == 0 and "shop - pick your dice" or "shop", 2, 2, 7)
		print("$"..run.coins.."  hp "..run.hp.."/"..run.max_hp, 2, 10, 10)
		for d in all(shown) do
			d:drw()
			local p = "$"..d.kind.price
			print(p, d.x - #p * 2 + 1, d.y + 10, d:is_on() and 10 or 8)
		end
		rect(2, 58, 125, 93, 5)
		if f.cur and f.cur:is(die) then
			info(_ENV, f.cur)
		else
			print("hover a die to see it", 6, 74, 5)
		end
		print("your dice", 2, 96, 5)
		for d in all(run.bag) do
			d:drw()
		end
		fight_btn:drw()
		f:drw()
	end
})
