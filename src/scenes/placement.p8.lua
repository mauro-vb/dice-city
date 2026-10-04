-- place dice, roll, then the fight plays out live on this same screen
-- phase: place -> rolled -> intro (columns slide out, big enemy slides in) -> fight -> done


placement = scene:extend({
	-- >> during the fight: 3x speed (resets each fight)
	fast = false,
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
		-- speech bubble by the enemy art: say = the line, say_t = frames left
		say, say_t = false, 0
		-- the stage's story screen first: story = its text until a click, story_t
		-- = frames shown (the boxes appear one by one)
		story, story_t = cur_stage().story, 0
		if not story then global.want_music("fight1") end
		-- roll animation: roll_t counts frames since the roll; fight waits for roll_end
		roll_t, roll_end, global.shake = 0, 0, 0
		p_shown, e_shown, p_flash, e_flash = run.hp, foe.hp, 0, 0
		frames = 0
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
			accepts = function(_, d) return d.class == die end,
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
				if phase == "fight" then fast = not fast return end
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
				-- [sfx 32 / 43 / 44: dice roll]
				-- one roll sound per die (up to 3) on channels 3, 2, 1 at once (the
				-- 2nd and 3rd briefly take over music channels), each from a
				-- different note so they don't sound as one. an sfx plays on one
				-- channel at a time, so 43 and 44 are copies of 32 (cart.p8 only)
				for i = 1, min(#order, 3) do
					sfx(i < 2 and 32 or 41 + i, 4 - i, i * 3 - 3)
				end
				-- last landing at 30 + 10n, totals 10 frames later
				roll_t, roll_end = 0, 40 + 10 * #order
				phase = "rolled"
			end,
			enabled = function() return phase == "place" or phase == "fight" or phase == "rolled" and roll_t >= roll_end or phase == "done" and card.ready end,
		}))
		-- inventory: potions any time, bombs mid-fight. aim items (reroll, rig,
		-- double, enchantments) are carried to a die and used on it when dropped
		use_on = function(d, s)
			-- focus:drop left the slot where it was dropped: back in its row
			-- (inv_slots' spacing)
			s.x, s.y = 58 + s.i * 11, 121
			-- a double adds a die: it joins the focus list too
			local k = use_item(s.i, false, d)
			if k == double then f:item(run.bag[#run.bag]) end
			if k == token then
				d:roll_anim(0)
				-- [sfx 32: dice roll] a reroll item
				sfx(32, 3)
			end
		end
		inv = inv_slots(f, 121, function(i) use_at(_ENV, i) end, function(i)
			local s = run.items[i]
			if s and s.k.aim then return count(split(s.k.aim, " "), phase) > 0 end
			return phase != "intro" and phase != "done" and can_use(i, phase == "fight" and b)
		end)
		layout(_ENV)
	end,

	-- the battle runs live once the intro tween ends
	start_fight = function(_ENV)
		phase = "intro"
		-- [sfx 36: enemy appearance] the fight intro starts
		sfx(36)
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
		tw(stage, {{f = 18, e = qin, off = 64}})
		tw(stage, {{f = 12, e = qin, small_x = -16}})
		tw(stage, {{f = 16, e = qio, hx = 17}})
		tw(stage, {{f = 24, e = bout, foe_x = 64}}, function()
			phase = "fight"
			fast = false
			-- arrived: its walk-in line
			say, say_t = foe.walk_in, 150
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
		tw(c, {{f = b:ticks_to(who) * 10, v = 1}})
	end,

	-- use the item in slot i: a bomb hits the enemy like an attack would,
	-- a potion fills your bar (the fight's hp mid-fight, the run's before)
	use_at = function(_ENV, i)
		local k = use_item(i, phase == "fight" and b)
		if k == bomb then
			-- [sfx 39: bomb]
			sfx(39)
			sparks(_ENV, 10, 12)
			return hurt_bar(_ENV, "e", b.e_hp)
		end
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
		if story then
			story_t += 1
			if mb > pmb then story = false global.want_music("fight1") end
			return
		end
		for d in all(run.bag) do
			-- a wild die can still move once you've seen the rolls
			d.pickable = phase == "place" or phase == "rolled" and d.ench == wild
			d.accepts, d.on_drop = function(_, s) return s.class == item_slot end, use_on
		end
		for s in all(inv) do
			local it = run.items[s.i]
			s.pickable = it and it.k.aim
		end
		act_btn.label = phase == "place" and "roll" or phase == "done" and "next" or phase == "fight" and (fast and "x3" or ">>") or "fight"
		f:upd()
		-- a press can switch scenes (next -> shop): stop, or this screen's layout
		-- would overwrite the shop's dice targets
		if scene.current != placement then return end
		layout(_ENV)
		roll_t += 1
		global.shake = max(0, shake - 1)
		upd_group(run.bag)
		upd_group(parts)
		-- x3: the fight, its tweens and particles run 3 steps a frame (input
		-- stays once a frame, so a click never counts 3 times)
		for i = 1, fast and 3 or 1 do
			if phase == "fight" then
				if i > 1 then
					upd_tws()
					upd_group(parts)
				end
				upd_fight(_ENV)
			end
		end
		-- a win's coins count up into the total once the result card is down
		if card.ready and coins_shown < run.coins and t % 3 == 0 then coins_shown += 1 end
		p_flash = max(0, p_flash - 1)
		say_t -= 1
		e_flash = max(0, e_flash - 1)
	end,

	-- steps the battle one tick every 10 frames
	upd_fight = function(_ENV)
		if b:over() then return end_fight(_ENV) end
		frames += 1
		if frames < 10 then return end
		frames = 0
		for ev in all(b:step()) do
			hit(_ENV, ev)
		end
	end,

	end_fight = function(_ENV)
		phase = "done"
		gain, next_scene = finish_fight(b)
		-- [sfx 37: defeat] the fight is lost
		if not b:won() then
			global.stop_music()
			sfx(37)
		end
		-- freeze the charge bars: fresh tables, so the running charge tweens
		-- keep writing into the old ones
		bars.p_charge, bars.e_charge = {v = bars.p_charge.v}, {v = bars.e_charge.v}
		-- its line on how it went, until the result card lands: the card waits
		-- 1.5 seconds, then drops in from above
		say, say_t = b:won() and foe.beaten or foe.beat_you, 120
		card = {y = -80}
		tw(card, {{f = 90}, {f = 30, e = bout, y = 0}}, function() card.ready = true end)
	end,

	-- one event: snap the hp number, flash, let the trail follow, recharge
	hit = function(_ENV, ev)
		local target = ev.who == "p" and "e" or "p"
		-- [sfx 40: punch] every hit, either side (40 has no notes yet)
		sfx(40)
		-- hit-stop: the next tick waits longer the harder the hit
		frames = -2 - ev.dmg \ 3
		if target == "e" then
			-- one more spark per 4 damage (3 at most: god mode hits for 9999),
			-- bigger with damage
			sparks(_ENV, 1 + min(ev.dmg \ 4, 2), min(4 + ev.dmg, 12))
		else
			-- the enemy lunges at you: quick step down, ease back. a fresh
			-- table each hit, so two lunges never tween the same field
			lunge = {y = 0}
			tw(lunge, {{f = 3, e = qin, y = 8}, {f = 8, e = qout, y = 0}})
		end
		hurt_bar(_ENV, target, ev[target.."_hp"])
		charge_next(_ENV, ev.who)
	end,

	-- n street fighter style sparks of size s on the big enemy art (hits: 1-3,
	-- a bomb: 10)
	sparks = function(_ENV, n, s)
		for i = 1, n do
			sparkp({x = stage.foe_x + rnd(16) - 8, y = 50 + rnd(16), size = s, incrsize = 1, maxage = 6})
		end
	end,

	-- a side ("p" / "e") took damage: snap its number, flash, let the trail follow
	hurt_bar = function(_ENV, side, hp)
		_ENV[side.."_shown"], _ENV[side.."_flash"] = hp, 10
		tw(bars, {{f = 8}, {f = 20, e = qout, [side.."_trail"] = hp}})
	end,

	drw = function(_ENV)
		cls(bg)
		if story then return drw_story(_ENV) end
		-- landing shake: the whole screen but the pointer and the result card
		local sx, sy = 0, 0
		if shake > 0 then sx, sy = rnd(3) - 1, rnd(3) - 1 end
		camera(sx, sy)
		local hx = stage.hx
		if stage.small_x > -15 then drw_foe(_ENV, foe.face_art, stage.small_x, 14) end
		print(foe.name, hx, 2, 7)
		hp_bar(hx, 9, 94, e_shown, bars.e_trail, foe.hp, 8, e_flash > 0)
		charge_bar(hx, 17, 94, bars.e_charge.v)
		-- a rolling stat shows its range until rolled: "atk5-11 spd8 def1"
		local stats = ""
		for k in all(stat_names) do
			local v = foe[k]
			stats ..= k..(type(v) == "table" and v[1].."-"..v[#v] or v).." "
		end
		print(stats, hx, 22, 6)
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
		if say_t > 0 then drw_say(_ENV) end

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
	-- story screen: comic caption boxes on black, one every 30 frames, each a
	-- bit further right and down: yellow, black inner border, grey drop shadow
	drw_story = function(_ENV)
		local bs = split(story, "/", false)
		for i = 1, min(#bs, story_t \ 30 + 1) do
			local ls, w = split(bs[i], "\n", false), 0
			for l in all(ls) do
				w = max(w, #l * 4)
			end
			local x, y, h = 6 + (i - 1) * 18, 10 + (i - 1) * 40, #ls * 6 + 7
			rectfill(x + 2, y + 2, x + w + 9, y + h + 1, dark)
			rectfill(x, y, x + w + 7, y + h - 1, 10)
			rect(x + 1, y + 1, x + w + 6, y + h - 2, 0)
			print(bs[i], x + 4, y + 4, 0)
		end
		txt("click to go on", 64, 118, dark, "c")
		mspr(myspr[15], stat(32), stat(33))
	end,

	-- speech bubble right of the big enemy art (shifted left to fit the
	-- screen), its tail pointing down-left at the art; \n in say = new line
	drw_say = function(_ENV)
		local ls, w = split(say, "\n", false), 0
		for l in all(ls) do
			w = max(w, #l * 4)
		end
		local h = #ls * 6 + 3
		local x, y = min(stage.foe_x + 14, 122 - w), 32
		rrectfill(x, y, w + 5, h, 2, 7)
		line(x + 3, y + h, x, y + h + 3, 7)
		line(x + 4, y + h, x + 1, y + h + 3, 7)
		print(say, x + 3, y + 2, 0)
	end,

	drw_foe = function(_ENV, i, x, y)
		mspr(myspr[i], x + (e_flash > 0 and rnd(3) - 1 or 0), y)
	end,

	drw_result = function(_ENV)
		local win = b:won()
		local c = win and 7 or 8
		rectfill(24, 46, 103, 72, bg)
		rect(24, 46, 103, 72, c)
		txt(win and "win!" or b:stalemate() and "no one can win" or "defeated", 64, 51, c, "c", true)
		if gain.reward + gain.leftover > 0 then
			txt("+"..gain.reward..cash.."\f6 win +"..gain.leftover..cash.."\f6 bag", 64, 62, 6, "c")
		end
	end
})
