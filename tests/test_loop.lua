-- drives the screens with keys only: 2 = up, 5 = x

local function press(b)
	hold(b) step() release(b) step()
end

-- in the shop: buy the first affordable offer (if asked), then next fight
local function leave_shop(buy_one)
	check(scene.current == shop, "in shop")
	if buy_one then press(5) end
	press(2) -- wraps up to next fight
	press(5)
	check(scene.current == placement, "shop -> placement")
end

local function start_run()
	boot()
	step(2)
	press(5)
	check(scene.current == shop and run.stage_i == 0, "start -> opening shop")
	snap("opening_shop")
end

-- place the first die (if needed), roll, fight, wait for the result
local function fight()
	if not run.bag[1].slot then press(5) end
	press(2) -- wraps up to roll
	press(5) -- roll
	check(placement.rolled, "rolled")
	press(5) -- cursor skipped to fight
	check(scene.current == combat, "fight -> combat")
	for _ = 1, 2000 do
		if #combat.m.items > 0 then break end
		step()
	end
	snap("combat")
	press(5) -- continue
end

test("can't leave the opening shop without a die", function()
	start_run()
	local m = shop.m
	local next_fight = m.items[#m.items]
	check(not m:on(next_fight), "next fight locked")
	press(5) -- buy
	check(#run.bag == 1 and shop.m:on(shop.m.items[#shop.m.items]), "unlocked after buying")
end)

test("opening shop -> stage 1 -> shop -> stage 2", function()
	start_run()
	leave_shop(true)
	check(#run.bag == 1 and run.coins < 20 and run.stage_i == 1)
	run.base = {atk = 50, spd = 1, def = 50}
	snap("placement")
	fight()
	check(scene.current == shop, "win -> shop")
	snap("shop")
	leave_shop()
	check(run.stage_i == 2, "stage 2")
	check(not run.bag[1].value, "dice cleared")
end)

test("a loss ends the run", function()
	start_run()
	leave_shop(true)
	run.hp = 1
	fight()
	check(scene.current == game_over and not run.won, "loss -> game over")
	step(31)
	press(5)
	check(scene.current == title, "game over -> title")
end)

test("a full run beats the boss", function()
	start_run()
	leave_shop(true)
	run.base = {atk = 50, spd = 1, def = 50}
	for i = 1, 5 do
		fight()
		leave_shop()
	end
	check(cur_stage().boss)
	fight()
	check(scene.current == game_over and run.won, "boss -> win")
	snap("win")
end)
