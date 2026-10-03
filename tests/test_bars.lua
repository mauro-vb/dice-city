-- the charge bars must start over after each attack (a leftover tween once kept them full)
test("charge bars keep filling after the first hit", function()
	boot()
	new_run()
	run.stage_i = 1
	run.base = {atk = 0, spd = 1, def = 50}
	run:place(run:add_die({name = "t", faces = {1, 1, 1}, price = 0}), "atk")
	run:roll_all()
	scene:load(placement)
	placement.phase = "rolled"
	-- press fight like a player: start_fight must run inside the frame
	local b = placement.act_btn
	mouse(b.x, b.y, 1) step()
	mouse(b.x, b.y, 0)
	local seen = 0
	for _ = 1, 3000 do
		step()
		if placement.ev_i > seen then
			seen = placement.ev_i
			-- right after the enemy's first attack: its bar must start over
			if seen >= 1 then
				step(2 * frames_per_tick)
				local c = placement.bars.e_charge.v
				check(c > 0 and c < 1, "enemy bar stuck at "..c)
				return
			end
		end
	end
	check(false, "fight too short")
end)
