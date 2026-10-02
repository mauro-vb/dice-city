-- drives the screens like a player: mouse clicks and drags, plus one keys-only test

local function press(b)
	hold(b) step() release(b) step()
end

local function click(it)
	mouse(it.x, it.y, 1) step()
	mouse(it.x, it.y, 0) step()
end

local function drag(it, to)
	mouse(it.x, it.y, 0) step()
	mouse(it.x, it.y, 1) step()
	mouse(to.x, to.y, 1) step()
	mouse(to.x, to.y, 0) step()
end

local function start_run()
	boot()
	step(2)
	click(title.start_btn)
	check(scene.current == shop and run.stage_i == 0, "start -> opening shop")
end

-- buy the first offer (if asked), then fight
local function leave_shop(buy_one)
	check(scene.current == shop, "in shop")
	if buy_one then click(shop.shown[1]) end
	click(shop.fight_btn)
	check(scene.current == placement, "shop -> placement")
end

-- first die on atk (if needed), roll, fight, wait, continue
local function fight()
	local d = run.bag[1]
	if not d.slot then drag(d, placement.cols.atk) end
	check(d.slot == "atk", "dragged onto atk")
	click(placement.roll_btn)
	check(placement.rolled, "rolled")
	click(placement.fight_btn)
	check(scene.current == combat, "fight -> combat")
	for _ = 1, 2000 do
		if combat.cont_btn then break end
		step()
	end
	snap("combat")
	click(combat.cont_btn)
end

test("opening shop: next fight locked until you buy", function()
	start_run()
	check(not shop.fight_btn:is_on(), "locked")
	mouse(shop.shown[1].x, shop.shown[1].y) step()
	check(shop.f.cur == shop.shown[1], "hover shows the offer")
	snap("opening_shop")
	click(shop.shown[1])
	check(#run.bag == 1 and run.coins < 20 and shop.fight_btn:is_on(), "bought")
end)

test("drag between slots and back to the bag", function()
	start_run()
	leave_shop(true)
	local d = run.bag[1]
	drag(d, placement.cols.atk)
	check(d.slot == "atk" and #run.slots.atk == 1)
	drag(d, placement.cols.def)
	check(d.slot == "def" and #run.slots.atk == 0)
	snap("placement")
	mouse(10, 111) step()
	drag(d, {x = 60, y = 111})
	check(not d.slot, "back in the bag")
	drag(d, {x = 64, y = 6})
	check(not d.slot and not placement.f.held, "dropped on nothing: cancelled")
end)

test("keys only: pick up, move, drop", function()
	boot()
	step(2)
	press(5) -- start
	press(5) -- buy the first offer
	press(3) -- down to fight
	press(5)
	check(scene.current == placement, "keys -> placement")
	local d = run.bag[1]
	check(placement.f.cur == d, "cursor starts on the die")
	press(5) -- pick up
	check(placement.f.held == d)
	press(2) -- up to the atk column
	press(5) -- drop
	check(d.slot == "atk", "dropped on atk")
end)

test("opening shop -> stage 1 -> shop -> stage 2", function()
	start_run()
	leave_shop(true)
	run.base = {atk = 50, spd = 1, def = 50}
	fight()
	check(scene.current == shop, "win -> shop")
	snap("shop")
	leave_shop()
	check(run.stage_i == 2, "stage 2")
	check(not run.bag[1].value, "dice cleared")
end)

test("rolled dice can be rerolled once by clicking", function()
	start_run()
	leave_shop(true)
	local d = run.bag[1]
	drag(d, placement.cols.atk)
	click(placement.roll_btn)
	click(d)
	check(run.rerolls_left == 0, "rerolled")
	drag(d, placement.cols.def)
	check(d.slot == "atk", "can't move dice after rolling")
end)

test("a loss ends the run", function()
	start_run()
	leave_shop(true)
	run.hp = 1
	fight()
	check(scene.current == game_over and not run.won, "loss -> game over")
	step(31)
	click(game_over.title_btn)
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
