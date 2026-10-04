-- the charge bars must start over after each attack (a leftover tween once kept them full)
test("charge bars keep filling after the first hit", function()
	boot()
	step()
	new_run()
	run.stage_i = 1
	run.base = {atk = 0, spd = 1, def = 50}
	run:place(run:add_die({name = "t", faces = {1, 1, 1}, price = 0}), "atk")
	run:roll_all()
	-- the scene switches in after the fade out (15 frames)
	scene:load(placement)
	step(15)
	placement.phase = "rolled"
	-- press fight like a player: start_fight must run inside the frame
	local b = placement.act_btn
	mouse(b.x, b.y, 1) step()
	mouse(b.x, b.y, 0)
	for _ = 1, 3000 do
		step()
		-- right after the enemy's first attack (your hp bar flashes): its bar
		-- must start over
		if placement.p_flash > 0 then
			step(2 * 10)
			local c = placement.bars.e_charge.v
			check(c > 0 and c < 1, "enemy bar stuck at "..c)
			return
		end
	end
	check(false, "fight too short")
end)
