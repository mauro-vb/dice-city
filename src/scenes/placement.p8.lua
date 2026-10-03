-- place dice, roll, then the fight plays out live on this same screen
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
		ev_i, frames = 0, 0
		b = false
		coins_shown = run.coins
		f = focus:new()
		cols = {}
		for n = 1, #stat_names do
			local k = stat_names[n]
			cols[k] = f:item(slot:new({key = k, x = 21 + (n - 1) * 43, y = 62, h = 46}))
		end
		f:item(selectable:new({
			x = 44, y = 104, w = 85, h = 17,
			accepts = function() return true end,
			on_drop = function(_, d) run:unplace(d) end,
		}))
		for d in all(run.bag) do
			d.pickable = true
			f:item(d)
		end
		-- one action button: roll -> fight -> next (never two at once)
		act_btn = f:item(button:new({
			x = 107, y = 103, w = 38,
			on_press = function()
				if phase == "done" then return scene:load(next_scene) end
				if phase == "rolled" then return start_fight(_ENV) end
				run:roll_all()
				phase = "rolled"
			end,
			enabled = function() return phase == "place" or phase == "rolled" or phase == "done" end,
		}))
		-- inventory: potions any time, bombs mid-fight, rerolls after rolling
		-- (press the reroll, then a die: aim = the slot being aimed)
		aim = false
		pick = function(d)
			use_item(aim, false, d)
			aim = false
		end
		inv = {}
		for i = 1, inv_size do
			add(inv, f:item(item_slot:new({
				x = 81 + i * 13, y = 119,
				on_press = function() use_at(_ENV, i) end,
				enabled = function()
					local s = run.items[i]
					if s and s.k == token then return phase == "rolled" end
					return phase != "intro" and phase != "done" and can_use(i, phase == "fight" and b)
				end,
			})))
		end
		layout(_ENV)
	end,

	-- the battle runs live once the intro tween ends
	start_fight = function(_ENV)
		phase, aim = "intro", false
		-- the battle takes the stats and bag coins now; then every die goes back
		-- to the bag (placement only matters before the fight) and the columns
		-- leave, so they can't be hovered any more
		b = battle:new({p = run, foe = foe})
		for d in all(run.bag) do
			run:unplace(d)
		end
		for k, col in pairs(cols) do
			del(f.items, col)
		end
		tween.new(stage):add({
			parallel = true,
			{k = "off", v = 64, f = 18, tr = "quad"},
			{k = "small_x", v = -16, f = 12, tr = "quad"},
			{k = "hx", v = 17, f = 16, tr = "quad", ease = "inout"},
			{k = "foe_x", v = 64, f = 24, tr = "back", ease = "out"},
		}):play(function()
			phase = "fight"
			charge_next(_ENV, "p")
			charge_next(_ENV, "e")
		end)
	end,

	-- empty a side's charge bar and tween it full by the time it attacks next
	-- each charge gets its own table: the previous charge's tween still has one
	-- write left on the frame of the attack, and ptween takes its start value
	-- from the table, so a shared field would start the new tween at 1
	charge_next = function(_ENV, who)
		local c = {v = 0}
		bars[who.."_charge"] = c
		if b:over() then return end
		tween.new(c):add({k = "v", v = 1, f = b:ticks_to(who) * frames_per_tick}):play()
	end,

	-- use the item in slot i: a bomb hits the enemy like an attack would,
	-- a potion fills your bar (the fight's hp mid-fight, the run's before)
	use_at = function(_ENV, i)
		if run.items[i].k == token then
			aim = aim != i and i
			return
		end
		local k = use_item(i, phase == "fight" and b)
		if k == bomb then return hurt_bar(_ENV, "e", b.e_hp) end
		if not k then return end
		p_shown = phase == "fight" and b.p_hp or run.hp
		bars.p_trail = p_shown
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
		local gap = min(17, 67 / max(1, #u - 1))
		for i = 1, #u do
			u[i]:move_to(11 + (i - 1) * gap, 104)
		end
	end,

	upd = function(_ENV)
		for d in all(run.bag) do
			d.pickable = phase == "place"
			d.on_press = aim and pick
		end
		act_btn.label = phase == "place" and "roll" or phase == "done" and "next" or "fight"
		f:upd()
		layout(_ENV)
		upd_group(run.bag)
		for i = 1, inv_size do
			inv[i]:set(run.items[i])
		end
		if phase == "fight" then upd_fight(_ENV) end
		p_flash = max(0, p_flash - 1)
		e_flash = max(0, e_flash - 1)
	end,

	-- steps the battle one tick every frames_per_tick frames
	upd_fight = function(_ENV)
		if b:over() then return end_fight(_ENV) end
		frames += 1
		if frames < frames_per_tick then return end
		frames = 0
		for ev in all(b:step()) do
			hit(_ENV, ev)
		end
	end,

	end_fight = function(_ENV)
		phase = "done"
		gain, next_scene = finish_fight(b)
		coins_shown = run.coins
	end,

	-- one event: snap the hp number, flash, let the trail follow, recharge
	hit = function(_ENV, ev)
		ev_i += 1
		local target = ev.who == "p" and "e" or "p"
		hurt_bar(_ENV, target, ev[target.."_hp"])
		charge_next(_ENV, ev.who)
	end,

	-- a side ("p" / "e") took damage: snap its number, flash, let the trail follow
	hurt_bar = function(_ENV, side, hp)
		_ENV[side.."_shown"], _ENV[side.."_flash"] = hp, 10
		local tw = tween.new(bars)
		tw:add(8)
		tw:add({k = side.."_trail", v = hp, f = 20, tr = "quad", ease = "out"})
		tw:play()
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
		if aim then txt("pick a die", 127, 22, 8, "r") end
		line(0, 30, 127, 30, 5)

		-- middle band: columns and their dice, dropping out during the intro
		clip(0, 31, 128, 64)
		camera(0, -stage.off)
		for k, col in pairs(cols) do
			txt(k, col.x, 33, 6, "c")
			-- slot boxes only while placing; after the roll only dice and totals
			if phase == "place" then col:drw() end
			txt(phase == "place" and run:stat_range(k) or b and b.stats[k] or run:get_stat(k), col.x, 88, 7, "c")
			for d in all(run.slots[k]) do
				if d != f.held then d:drw() end
			end
		end
		camera()
		clip()
		if stage.foe_x > -28 then drw_foe(_ENV, stage.foe_x, 62, 54) end

		rect(2, 95, 86, 112, 5)
		if #run:unused() == 0 then txt("dice bag", 44, 102, 5, "c") end
		if phase != "place" then txt("+"..(b and b.coins or leftover_coins(run:unused())).."$", 85, 97, 6, "r") end
		for d in all(run:unused()) do
			if d != f.held then d:drw() end
		end
		hp_bar(2, 115, 44, p_shown, bars.p_trail, run.max_hp, 7, p_flash > 0)
		charge_bar(2, 123, 44, bars.p_charge.v)
		-- what you rolled, kept by the battle (the dice are back in the bag)
		if b then
			local s = b.stats
			print("a"..s.atk.." s"..s.spd.." d"..s.def, 48, 117, 6)
		end
		drw_group(inv)
		if aim then
			local s = inv[aim]
			rect(s.x - 7, s.y - 7, s.x + 6, s.y + 6, 8)
		end
		act_btn:drw()
		f:drw_frame()
		if phase == "done" then drw_result(_ENV) end
		hover_tip(f)
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
		local win = b:won()
		local c = win and 7 or 8
		rectfill(24, 46, 103, 72, 0)
		rect(24, 46, 103, 72, c)
		txt(win and "win!" or b:stalemate() and "no damage" or "defeated", 64, 51, c, "c", true)
		if gain.reward + gain.leftover > 0 then
			txt("+"..gain.reward.." +"..gain.leftover.." from the bag", 64, 62, 6, "c")
		end
	end
})
