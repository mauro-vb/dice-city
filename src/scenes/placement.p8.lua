placement = scene:extend({
	init = function(_ENV)
		rolled = false
		m = menu:new({x = 4, y = 50})
		for d in all(run.bag) do
			m:item(
				function() return die_label(_ENV, d) end,
				function() press_die(_ENV, d) end,
				function() return not rolled or (d.slot and run.rerolls_left > 0) end
			)
		end
		m:item("roll", function()
			run:roll_all()
			rolled = true
		end, function() return not rolled and run:placed() > 0 end)
		m:item("fight", function() scene:load(combat) end, function() return rolled end)
	end,

	die_label = function(_ENV, d)
		local s = d.kind.name.." > "..(d.slot or "-")
		if rolled and d.slot then s ..= " = "..d.value end
		return s
	end,

	press_die = function(_ENV, d)
		if rolled then
			run:reroll(d)
			return
		end
		run:cycle(d)
	end,

	upd = function(_ENV)
		m:upd()
	end,

	drw = function(_ENV)
		cls(0)
		local st = cur_stage()
		local e = st.enemy
		print("stage "..run.stage_i, 4, 4, 7)
		print(foe_label().."  hp"..e.hp.." atk"..e.atk.." spd"..e.spd.." def"..e.def, 4, 12, e.col)
		print("you  hp"..run.hp.."/"..run.max_hp.."  coins "..run.coins, 4, 20, 7)
		for n = 1, #stat_names do
			local s = stat_names[n]
			local v = rolled and run:get_stat(s) or run:stat_range(s)
			print(s.." "..v, 4 + (n - 1) * 42, 32, 6)
		end
		if rolled then print("rerolls "..run.rerolls_left, 4, 40, 5) end
		m:drw()
	end
})
