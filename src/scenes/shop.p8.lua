shop = scene:extend({
	init = function(_ENV)
		offers = gen_offers(cur_stage())
		build(_ENV)
	end,

	-- rebuilt after each purchase so the bought offer disappears
	build = function(_ENV)
		m = menu:new({x = 4, y = 30})
		for k in all(offers) do
			m:item(
				k.name.." "..join(k.faces, ",").." $"..k.price,
				function()
					if buy(k) then
						del(offers, k)
						build(_ENV)
					end
				end,
				function() return run.coins >= k.price end
			)
		end
		m:item("next fight", function()
			next_stage()
			scene:load(placement)
		end, function() return #run.bag > 0 end)
	end,

	upd = function(_ENV)
		m:upd()
	end,

	drw = function(_ENV)
		cls(0)
		print(run.stage_i == 0 and "shop - pick your dice" or "shop", 4, 4, 7)
		print("coins "..run.coins.."  hp "..run.hp.."/"..run.max_hp, 4, 14, 10)
		m:drw()
	end
})
