-- place dice, roll, then the fight plays out live on this same screen
-- phase: place -> rolled -> intro (columns slide out, big enemy slides in) -> fight -> done

frames_per_tick = 10

placement = scene:extend({
	init = function(_ENV)
		global.parts = {}
		phase = "place"
		foe = cur_stage().enemy
		-- tweened values live in a fresh table per fight, so a tween still
		-- running from the last fight can't write into this one
		bars = {p_trail = run.hp, e_trail = foe.hp, p_charge = {v = 0}, e_charge = {v = 0}}
		-- intro: columns drop by off, the small art leaves to the left (small_x),
		-- the header moves left to centre its bars (hx), the big art comes in (foe_x)
		stage = {off = 0, small_x = 15, hx = 32, foe_x = -30}
		lunge = {y = 0}
		-- roll animation: roll_t counts frames since the roll; fight waits for roll_end
		roll_t, roll_end, global.shake = 0, 0, 0
		p_shown, e_shown, p_flash, e_flash = run.hp, foe.hp, 0, 0
		ev_i, frames = 0, 0
		b = false
		coins_shown = run.coins
		f = focus:new()
		cols = {}
		for n = 1, #stat_names do
			local k = stat_names[n]
			cols[k] = f:item(slot:new({key = k, x = 21 + (n - 1) * 43, y = 60, h = 47}))
		end
		f:item(selectable:new({
			x = 48, y = 100, w = 92, h = 17,
			accepts = function() return true end,
			on_drop = function(_, d) run:unplace(d) end,
		}))
		for d in all(run.bag) do
			d.pickable = true
			f:item(d)
		end
		-- one action button at the bag's height: roll -> fight -> next
		act_btn = f:item(button:new({
			x = 112, y = 100, h = 17,
			on_press = function()
				if phase == "done" then return scene:load(next_scene) end
				if phase == "rolled" then return start_fight(_ENV) end
				-- values first, then the show: columns left to right, bottom die
				-- first, bag dice last, each landing 10 frames after the one before
				local order = run:roll_all()
				-- the enemy rolls with you (only some have stats that roll)
				foe = roll_foe(foe)
				for i = 1, #order do
					order[i]:roll_anim(i - 1)
				end
				-- last landing at 30 + 10n, totals 10 frames later
				roll_t, roll_end = 0, 40 + 10 * #order
				phase = "rolled"
			end,
			enabled = function() return phase == "place" or phase == "rolled" and roll_t >= roll_end or phase == "done" and card.ready end,
		}))
		-- inventory: potions any time, bombs mid-fight, rerolls after rolling
		-- (press the reroll, then a die: aim = the slot being aimed)
		aim = false
		pick = function(d)
			-- a double adds a die: it joins the focus list too
			local k = use_item(aim, false, d)
			if k == double then f:item(run.bag[#run.bag]) end
			if k == token then d:roll_anim(0) end
			aim = false
		end
		inv = inv_slots(f, 120, function(i) use_at(_ENV, i) end, function(i)
			local s = run.items[i]
			if s and s.k.aim then return count(split(s.k.aim, " "), phase) > 0 end
			return phase != "intro" and phase != "done" and can_use(i, phase == "fight" and b)
		end)
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
			if d.slot and d.ench == grower then grow(d) end
			run:unplace(d)
			-- a double's copy and a broken glass die counted for the stats;
			-- they vanish in a puff
			if d.temp or d.broke then
				d:poof()
				del(run.bag, d)
				del(f.items, d)
			end
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
		if run.items[i].k.aim then
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
			local gap = min(16, 32 / max(1, #ds - 1))
			for i = 1, #ds do
				ds[i]:move_to(col.x, 75 - (i - 1) * gap)
			end
		end
		local u = run:unused()
		local gap = min(17, 74 / max(1, #u - 1))
		for i = 1, #u do
			u[i]:move_to(11 + (i - 1) * gap, 100)
		end
	end,

	upd = function(_ENV)

		for d in all(run.bag) do
			-- a wild die can still move once you've seen the rolls
			d.pickable = (phase == "place" or phase == "rolled" and d.ench == wild) and not aim
			d.on_press = aim and pick
		end
		act_btn.label = phase == "place" and "roll" or phase == "done" and "next" or "fight"
		f:upd()
		-- a press can switch scenes (next -> shop): stop, or this screen's layout
		-- would overwrite the shop's dice targets
		if scene.current != placement then return end
		layout(_ENV)
		-- ❎ skips the roll: every die lands next frame, totals show at once
		roll_t += 1
		if btnp(5) and roll_t < roll_end then
			for d in all(run.bag) do
				if d.air > 0 then d.air = 1 end
			end
			roll_t = roll_end
		end
		global.shake = max(0, shake - 1)
		upd_group(run.bag)
		upd_group(parts)
		if phase == "fight" then upd_fight(_ENV) end
		-- a win's coins count up into the total once the result card is down
		if card.ready and coins_shown < run.coins and t % 3 == 0 then coins_shown += 1 end
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
		-- freeze the charge bars: fresh tables, so the running charge tweens
		-- keep writing into the old ones
		bars.p_charge, bars.e_charge = {v = bars.p_charge.v}, {v = bars.e_charge.v}
		-- the result card waits a second, then drops in from above
		card = {y = -80}
		tween.new(card):add(60):add({k = "y", v = 0, f = 30, tr = "back", ease = "out"}):play(function() card.ready = true end)
	end,

	-- one event: snap the hp number, flash, let the trail follow, recharge
	hit = function(_ENV, ev)
		ev_i += 1
		local target = ev.who == "p" and "e" or "p"
		-- hit-stop: the next tick waits longer the harder the hit
		frames = -2 - ev.dmg \ 3
		if target == "e" then
			-- street fighter style sparks: one more per 4 damage, bigger with damage
			for i = 0, ev.dmg \ 4 do
				sparkp({x = stage.foe_x + rnd(16) - 8, y = 50 + rnd(16), size = min(4 + ev.dmg, 12), incrsize = 1, maxage = 6})
			end
		else
			-- the enemy lunges at you: quick step down, ease back. a fresh
			-- table each hit, so two lunges never tween the same field
			lunge = {y = 0}
			tween.new(lunge):add({k = "y", v = 8, f = 3, tr = "quad"}):add({k = "y", v = 0, f = 8, tr = "quad", ease = "out"}):play()
		end
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
		cls(bg)
		-- landing shake: the whole screen but the pointer and the result card
		local sx, sy = 0, 0
		if shake > 0 then sx, sy = rnd(3) - 1, rnd(3) - 1 end
		camera(sx, sy)
		local hx = stage.hx
		if stage.small_x > -15 then drw_foe(_ENV, foe.face_art, stage.small_x, 14) end
		print(foe.name, hx, 2, 7)
		hp_bar(hx, 9, 94, e_shown, bars.e_trail, foe.hp, 8, e_flash > 0)
		charge_bar(hx, 17, 94, bars.e_charge.v)
		-- a rolling stat shows its range until rolled: "a5-11 s8 d0"
		local stats = ""
		for k in all(stat_names) do
			local v = foe[k]
			stats ..= sub(k, 1, 1)..(type(v) == "table" and v[1].."-"..v[#v] or v).." "
		end
		print(stats, hx, 22, 6)
		if aim then txt("pick a die", 127, 22, 8, "r") end
		line(0, 29, 127, 29, dark)

		-- middle band: columns and their dice, dropping out during the intro
		clip(0, 30, 128, 60)
		camera(sx, sy - stage.off)
		for k, col in pairs(cols) do
			txt(k, col.x, 31, 6, "c")
			-- slot boxes only while placing; after the roll only dice and totals
			if phase == "place" then col:drw() end
			-- totals once the dice have landed, popping up 1 px on that frame
			txt(phase == "place" and run:stat_range(k) or b and b.stats[k] or roll_t < roll_end and "" or run:get_stat(k), col.x, roll_t == roll_end and 84 or 85, 7, "c")
			for d in all(run.slots[k]) do
				if d != f.held then d:drw() end
			end
		end
		camera(sx, sy)
		clip()
		if stage.foe_x > -28 then drw_foe(_ENV, foe.art, stage.foe_x, 59 + lunge.y) end

		rect(2, 91, 94, 108, dark) -- dice bag rect
		if #run:unused() == 0 then txt("dice bag", 48, 98, dark, "c") end
		-- stage and coins under the button, next to the inventory
		txt("stage "..run.stage_i, 126, 114, 7, "r")
		txt(coins_shown..cash, 126, 121, 7, "r")
		-- your rolled stats (kept by the battle) above your hp bar
		-- before that, the same line explains the bag: dice you don't place
		-- pay their roll as coins if you win (each landed one shows its +n)
		if b then
			local s = b.stats
			print("atk"..s.atk.." spd"..s.spd.." def"..s.def, 2, 110, 6)
		else
			txt(phase == "place" and "unused dice = cash" or "win: +"..leftover_coins(run:unused())..cash.."\f6 from the bag", 2, 110, 6)
		end
		for d in all(run:unused()) do
			if d != f.held then d:drw() end
			if not b and d.value and d.air == 0 then txt("+"..coin_value(d), d.x, d.y - 10, 10, "c", true) end
		end
		hp_bar(2, 116, 58, p_shown, bars.p_trail, run.max_hp, 7, p_flash > 0)
		charge_bar(2, 124, 58, bars.p_charge.v)
		drw_group(inv)
		if aim then
			local s = inv[aim]
			rect(s.x - 6, s.y - 6, s.x + 5, s.y + 5, 8)
		end
		act_btn:drw()
		drw_group(parts)
		camera()
		f:drw_frame()
		if phase == "done" then
			camera(0, -card.y)
			drw_result(_ENV)
			camera()
		end
		hover_tip(f)
		f:drw()
	end,

	-- enemy art: myspr region i (face_art in the header, art in the fight)
	-- centred on x, y with mspr; shakes when hit. green (11) is the sheet's
	-- background: only it is transparent while drawing, then back to the usual
	-- black + brown (palt bitmask: colour 0 = 0x8000 ... colour 15 = 1)
	drw_foe = function(_ENV, i, x, y)
		mspr(myspr[i], x + (e_flash > 0 and rnd(3) - 1 or 0), y)
	end,

	drw_result = function(_ENV)
		local win = b:won()
		local c = win and 7 or 8
		rectfill(24, 46, 103, 72, bg)
		rect(24, 46, 103, 72, c)
		txt(win and "win!" or b:stalemate() and "no damage" or "defeated", 64, 51, c, "c", true)
		if gain.reward + gain.leftover > 0 then
			txt("+"..gain.reward..cash.."\f6 win +"..gain.leftover..cash.."\f6 bag", 64, 62, 6, "c")
		end
	end
})
