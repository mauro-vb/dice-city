-- place dice, roll, then the fight plays out on this same screen
-- phase: place -> rolled -> intro (columns slide out, big enemy slides in) -> fight -> done

frames_per_tick = 10

placement = scene:extend({
	init = function(_ENV)
		phase = "place"
		foe = cur_stage().enemy
		-- tweened values live in a fresh table per fight, so a tween still
		-- running from the last fight can't write into this one
		bars = {p_trail = run.hp, e_trail = foe.hp, p_charge = {v = 0}, e_charge = {v = 0}}
		-- intro: columns drop by off, the small art leaves to the left (small_x),
		-- the header moves left to centre its bars (hx), the big art comes in (foe_x)
		stage = {off = 0, small_x = 15, hx = 32, foe_x = -30}
		p_shown, e_shown, p_flash, e_flash = run.hp, foe.hp, 0, 0
		tick, ev_i, frames = 0, 0, 0
		result = false
		coins_shown = run.coins
		f = focus:new()
		cols = {}
		for n = 1, #stat_names do
			local k = stat_names[n]
			cols[k] = f:item(slot:new({key = k, x = 21 + (n - 1) * 43, y = 62, h = 46}))
		end
		f:item(selectable:new({
			x = 48, y = 104, w = 92, h = 17,
			accepts = function() return true end,
			on_drop = function(_, d) run:unplace(d) end,
		}))
		for d in all(run.bag) do
			d.pickable = true
			f:item(d)
		end
		roll_btn = f:item(button:new({
			label = "roll", x = 112, y = 104,
			on_press = function()
				run:roll_all()
				phase = "rolled"
			end,
			enabled = function() return phase == "place" end,
		}))
		fight_btn = f:item(button:new({
			label = "fight", x = 112, y = 118,
			on_press = function()
				if phase == "done" then return scene:load(next_scene) end
				start_fight(_ENV)
			end,
			enabled = function() return phase == "rolled" or phase == "done" end,
		}))
		layout(_ENV)
	end,

	-- the result is decided now; the replay starts once the intro tween ends
	start_fight = function(_ENV)
		phase = "intro"
		result = run:fight(foe)
		gain, next_scene = finish_fight(result)
		tween.new(stage):add({
			parallel = true,
			{k = "off", v = 64, f = 18, tr = "quad"},
			{k = "small_x", v = -16, f = 12, tr = "quad"},
			{k = "hx", v = 17, f = 16, tr = "quad", ease = "inout"},
			{k = "foe_x", v = 64, f = 24, tr = "back", ease = "out"},
		}):play(function()
			phase = "fight"
			charge_next(_ENV, "p", 0)
			charge_next(_ENV, "e", 0)
		end)
	end,

	-- empty a side's charge bar and tween it full by the time it attacks next
	-- each charge gets its own table: the previous charge's tween still has one
	-- write left on the frame of the attack, and ptween takes its start value
	-- from the table, so a shared field would start the new tween at 1
	charge_next = function(_ENV, who, from)
		local c = {v = 0}
		bars[who.."_charge"] = c
		for ev in all(result.events) do
			if ev.who == who and ev.tick > from then
				tween.new(c):add({k = "v", v = 1, f = (ev.tick - from) * frames_per_tick}):play()
				return
			end
		end
	end,

	-- column dice stack upward, unused dice fill the bag row; dice glide there
	layout = function(_ENV)
		for k, col in pairs(cols) do
			local ds = run.slots[k]
			local gap = min(17, 30 / max(1, #ds - 1))
			for i = 1, #ds do
				ds[i]:move_to(col.x, 76 - (i - 1) * gap)
			end
		end
		local u = run:unused()
		local gap = min(17, 74 / max(1, #u - 1))
		for i = 1, #u do
			u[i]:move_to(11 + (i - 1) * gap, 104)
		end
	end,

	upd = function(_ENV)
		for d in all(run.bag) do
			d.pickable = phase == "place"
			d.on_press = phase == "rolled" and run.rerolls_left > 0 and reroll
		end
		fight_btn.label = phase == "done" and "next" or "fight"
		f:upd()
		layout(_ENV)
		upd_group(run.bag)
		if phase == "fight" then upd_fight(_ENV) end
		p_flash = max(0, p_flash - 1)
		e_flash = max(0, e_flash - 1)
	end,

	-- replays the precomputed fight, one tick every frames_per_tick frames
	upd_fight = function(_ENV)
		frames += 1
		if frames < frames_per_tick then return end
		frames = 0
		tick += 1
		local evs = result.events
		while ev_i < #evs and evs[ev_i + 1].tick <= tick do
			ev_i += 1
			hit(_ENV, evs[ev_i])
		end
		if ev_i < #evs then return end
		phase = "done"
		coins_shown = run.coins
	end,

	-- one event: snap the hp number, flash, let the trail follow, recharge
	hit = function(_ENV, ev)
		local target = ev.who == "p" and "e" or "p"
		p_shown, e_shown = ev.p_hp, ev.e_hp
		if target == "e" then e_flash = 10 else p_flash = 10 end
		local tw = tween.new(bars)
		tw:add(8)
		tw:add({k = target.."_trail", v = ev[target.."_hp"], f = 20, tr = "quad", ease = "out"})
		tw:play()
		charge_next(_ENV, ev.who, ev.tick)
	end,

	reroll = function(d)
		run:reroll(d)
	end,

	drw = function(_ENV)
		cls(0)
		local hx = stage.hx
		if stage.small_x > -15 then drw_foe(_ENV, stage.small_x, 14, 27) end
		print(foe_label(), hx, 2, 7)
		txt("stage "..run.stage_i.."  $"..coins_shown, 127, 2, 7, "r")
		hp_bar(hx, 9, 94, e_shown, bars.e_trail, foe.hp, 8, e_flash > 0)
		charge_bar(hx, 17, 94, bars.e_charge.v)
		print("atk"..foe.atk.." spd"..foe.spd.." def"..foe.def, hx, 22, 6)
		if phase == "rolled" then txt("reroll "..run.rerolls_left, 127, 22, 6, "r") end
		line(0, 30, 127, 30, 5)

		-- middle band: columns and their dice, dropping out during the intro
		clip(0, 31, 128, 64)
		camera(0, -stage.off)
		for k, col in pairs(cols) do
			txt(k, col.x, 33, 6, "c")
			-- slot boxes only while placing; after the roll only dice and totals
			if phase == "place" then col:drw() end
			txt(phase == "place" and run:stat_range(k) or run:get_stat(k), col.x, 88, 7, "c")
			for d in all(run.slots[k]) do
				if d != f.held then d:drw() end
			end
		end
		camera()
		clip()
		if stage.foe_x > -28 then drw_foe(_ENV, stage.foe_x, 62, 54) end

		rect(2, 95, 94, 112, 5)
		if #run:unused() == 0 then print("bag", 42, 102, 5) end
		if phase != "place" then txt("+"..leftover_coins(run:unused()).."$", 93, 97, 6, "r") end
		for d in all(run:unused()) do
			if d != f.held then d:drw() end
		end
		print("you", 2, 115, 6)
		hp_bar(16, 115, 78, p_shown, bars.p_trail, run.max_hp, 7, p_flash > 0)
		charge_bar(16, 123, 78, bars.p_charge.v)
		roll_btn:drw()
		fight_btn:drw()
		if phase == "done" then drw_result(_ENV) end
		-- column dice are out of sight from the intro on: no tooltip for them
		if stage.off == 0 or not (f.cur and f.cur.slot) then hover_tip(f) end
		f:drw()
	end,

	-- enemy art centred on x, y at size sz (27 in the header, 54 = full size in
	-- the fight); shakes when hit. colour 14 is its transparent background
	drw_foe = function(_ENV, x, y, sz)
		local a = foe.art or enemy_test_spr
		local sx = e_flash > 0 and rnd(3) - 1 or 0
		palt(0, false)
		palt(14, true)
		sspr(a[1], a[2], a[3], a[4], x - sz \ 2 + sx, y - sz \ 2, sz, sz)
		palt(14, false)
		palt(0, true)
	end,

	drw_result = function(_ENV)
		local win = result.win
		local c = win and 7 or 8
		rectfill(24, 46, 103, 72, 0)
		rect(24, 46, 103, 72, c)
		txt(win and "win!" or #result.events == 0 and "no damage" or "defeated", 64, 51, c, "c", true)
		if gain.reward + gain.leftover > 0 then
			txt("+"..gain.reward.." +"..gain.leftover.." from the bag", 64, 62, 6, "c")
		end
	end
})
