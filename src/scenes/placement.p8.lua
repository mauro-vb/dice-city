placement = scene:extend({
	init = function(_ENV)
		rolled = false
		f = focus:new()
		cols = {}
		for n = 1, #stat_names do
			local k = stat_names[n]
			cols[k] = f:item(slot:new({key = k, x = 21 + (n - 1) * 43, y = 52}))
		end
		f:item(selectable:new({
			x = 48, y = 111, w = 92, h = 30,
			accepts = function() return true end,
			on_drop = function(_, d) run:unplace(d) end,
		}))
		for d in all(run.bag) do
			d.pickable = true
			d.on_press = false
			f:item(d)
		end
		roll_btn = f:item(button:new({
			label = "roll", x = 112, y = 103,
			on_press = function()
				run:roll_all()
				rolled = true
			end,
			enabled = function() return not rolled and run:placed() > 0 end,
		}))
		fight_btn = f:item(button:new({
			label = "fight", x = 112, y = 117,
			on_press = function() scene:load(combat) end,
			enabled = function() return rolled end,
		}))
		layout(_ENV)
	end,

	-- column dice stack upward, unused dice fill the bag rows
	layout = function(_ENV)
		for k, col in pairs(cols) do
			local ds = run.slots[k]
			local gap = min(13, 52 / max(1, #ds - 1))
			for i = 1, #ds do
				ds[i].x, ds[i].y = col.x, 76 - (i - 1) * gap
			end
		end
		local u = run:unused()
		for i = 1, #u do
			u[i].x = 10 + (i - 1) % 6 * 14
			u[i].y = 104 + flr((i - 1) / 6) * 14
		end
	end,

	upd = function(_ENV)
		for d in all(run.bag) do
			d.pickable = not rolled
			d.on_press = rolled and d.slot and run.rerolls_left > 0 and reroll
		end
		upd_group(run.bag)
		f:upd()
		layout(_ENV)
	end,

	reroll = function(d)
		run:reroll(d)
	end,

	drw = function(_ENV)
		cls(0)
		local e = cur_stage().enemy
		print("stage "..run.stage_i.."  hp "..run.hp.."/"..run.max_hp.."  $"..run.coins, 2, 2, 7)
		print(foe_label().."  hp"..e.hp.." atk"..e.atk.." spd"..e.spd.." def"..e.def, 2, 10, e.col)
		for k, col in pairs(cols) do
			col:drw()
			local s = k.." "..(rolled and run:get_stat(k) or run:stat_range(k))
			print(s, col.x - #s * 2 + 1, 87, 6)
		end
		rect(2, 96, 94, 126, 5)
		if #run:unused() == 0 then print("bag", 40, 109, 5) end
		for d in all(run.bag) do
			if d != f.held then d:drw() end
		end
		roll_btn:drw()
		fight_btn:drw()
		if rolled then print("reroll "..run.rerolls_left, 97, 124, 5) end
		f:drw()
	end
})
