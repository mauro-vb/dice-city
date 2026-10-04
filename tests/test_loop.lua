-- drives the screens like a player: mouse clicks and drags, plus one keys-only test
-- dice glide with 8-frame tweens, so wait (settle) before clicking or dragging them

local function press(b)
	hold(b) step() release(b) step()
end

local function settle()
	step(10)
end

-- ❎ skips the roll animation (fight stays locked until it's over)
local function skip()
	press(5)
	settle()
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
	settle()
end

local function start_run()
	boot()
	step(2)
	click(title.btn)
	check(scene.current == shop and run.stage_i == 0, "start -> opening shop")
end

-- buy the first offer (if asked), then fight
local function leave_shop(buy_one)
	check(scene.current == shop, "in shop")
	if buy_one then click(shop.cards[1]) end
	click(shop.fight_btn)
	check(scene.current == placement, "shop -> placement")
	settle()
end

-- the first die on atk (if not there), roll and press fight
local function start_fight()
	local d = run.bag[1]
	if not d.slot then drag(d, placement.cols.atk) end
	click(placement.act_btn)
	skip()
	click(placement.act_btn)
	return d
end

-- wait for the fight to end and the result card to land, then press next
local function finish()
	for _ = 1, 6000 do
		if placement.phase == "done" and placement.card.ready then break end
		step()
	end
	click(placement.act_btn)
	settle()
end

local function fight()
	start_fight()
	finish()
end

test("opening shop: fight locked until you buy", function()
	start_run()
	check(not shop.fight_btn:is_on(), "locked")
	mouse(shop.cards[1].x, shop.cards[1].y) step()
	check(shop.f.cur == shop.cards[1], "hover shows the offer")
	step(10)
	check(shop.f.hover_t < 30, "no tooltip yet")
	step(25)
	check(shop.f.hover_t >= 30, "tooltip after half a second")
	snap("opening_shop")
	click(shop.cards[1])
	check(#run.bag == 1 and run.coins < 20 and shop.fight_btn:is_on(), "bought")
end)

test("shop reroll: new offers, price goes up", function()
	start_run()
	local before = shop.offers
	click(shop.reroll_btn)
	check(shop.offers != before and #shop.offers == 4, "new offers")
	check(run.coins == 19 and shop.reroll_cost == 2, "paid 1, next costs 2")
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
	drag(d, {x = 60, y = 104})
	check(not d.slot, "back in the bag")
	drag(d, {x = 64, y = 6})
	check(not d.slot and not placement.f.held, "dropped on nothing: cancelled")
end)

test("keys only: pick up, move, drop, glide", function()
	boot()
	step(2)
	press(5) -- start
	press(5) -- buy the first offer
	press(3) -- down to the first inventory slot
	press(1) press(1) -- along the slots
	press(1) -- right to fight
	press(5)
	check(scene.current == placement, "keys -> placement")
	settle()
	local d = run.bag[1]
	check(placement.f.cur == d, "cursor starts on the die")
	press(5) -- pick up
	check(placement.f.held == d)
	press(2) -- up to the atk column
	press(5) -- drop
	check(d.slot == "atk", "dropped on atk")
	check(d.y != 75, "still gliding")
	settle()
	check(d.x == placement.cols.atk.x and d.y == 75, "glided into the column")
end)

test("opening shop -> stage 1 -> shop -> stage 2", function()
	start_run()
	leave_shop(true)
	run.base = {atk = 50, spd = 1, def = 50}
	local d = start_fight()
	check(placement.phase == "intro", "intro: columns out, enemy in")
	check(count(placement.f.items, placement.cols.atk) == 0, "columns can't be hovered")
	check(not d.slot and #run.slots.atk == 0, "dice back in the bag on fight")
	check(placement.b.stats.atk > 50 or d.value == 0, "battle kept the placed stats")
	step(40)
	snap("fight")
	finish()
	check(scene.current == shop, "win -> shop")
	snap("shop")
	for d in all(run.bag) do
		check(d.ty == 84, "shop dice go to the your-dice row")
	end
	leave_shop()
	check(run.stage_i == 2, "stage 2")
	check(not run.bag[1].value, "dice cleared")
	check(not run.bag[1].slot and #run.slots.atk == 0, "dice back in the bag")
end)

test("roll shows bag coins; reroll item: press it, then a die", function()
	start_run()
	click(shop.cards[1])
	click(shop.cards[1])
	leave_shop()
	run.items = {{k = token, n = 1}}
	local a, b = run.bag[1], run.bag[2]
	drag(a, placement.cols.atk)
	click(placement.act_btn)
	check(b.value and leftover_coins(run:unused()) == b.value, "bag die rolled")
	click(placement.inv[1])
	check(placement.aim == 1, "aiming")
	click(b)
	check(not placement.aim and #run.items == 0, "used on the bag die")
	drag(a, placement.cols.def)
	check(a.slot == "atk", "can't move dice after rolling")
end)

test("a loss ends the run", function()
	start_run()
	leave_shop(true)
	run.hp = 1
	fight()
	check(scene.current == game_over and not run.won, "loss -> game over")
	step(31)
	click(game_over.btn)
	check(scene.current == title, "game over -> title")
end)

test("a full run beats the boss", function()
	start_run()
	leave_shop(true)
	run.base = {atk = 50, spd = 1, def = 50}
	-- every stage before the boss
	for i = 1, #stages - 1 do
		fight()
		leave_shop()
	end
	check(cur_stage().boss)
	fight()
	check(scene.current == game_over and run.won, "boss -> win")
	snap("win")
end)

test("drink a potion mid-fight by clicking its slot", function()
	start_run()
	leave_shop(true)
	run.hp = 10
	run.items = {{k = potion, n = 2}}
	run.base = {atk = 0, spd = 1, def = 50}
	drag(run.bag[1], placement.cols.atk)
	click(placement.act_btn)
	skip()
	click(placement.act_btn)
	for _ = 1, 100 do
		if placement.phase == "fight" then break end
		step()
	end
	local before = placement.b.p_hp
	click(placement.inv[1])
	check(placement.b.p_hp == before + 5 and run.items[1].n == 1, "healed mid-fight, one left")
	snap("potion")
end)

test("sell a die by dropping it on the sell box", function()
	start_run()
	click(shop.cards[1])
	settle()
	local d, coins = run.bag[1], run.coins
	drag(d, shop.sell_box)
	check(#run.bag == 0 and run.coins == coins + sell_price(d), "sold")
end)

test("double: press it, then a placed die; the copy is gone when the fight starts", function()
	start_run()
	leave_shop(true)
	run.items = {{k = double, n = 1}}
	local d = run.bag[1]
	drag(d, placement.cols.atk)
	click(placement.act_btn)
	click(placement.inv[1])
	click(d)
	check(#run.slots.atk == 2 and run.bag[2].temp, "copy in the column")
	settle()
	snap("double")
	skip()
	click(placement.act_btn)
	check(#run.bag == 1 and placement.b.stats.atk == 1 + d.value * 2, "copy counted, then removed")
end)

test("glass: enchant a placed die, it breaks when the fight starts", function()
	start_run()
	leave_shop(true)
	run.items = {{k = glass, n = 1}}
	local d = run.bag[1]
	drag(d, placement.cols.atk)
	click(placement.inv[1])
	click(d)
	check(d.ench == glass and #run.items == 0, "enchanted")
	click(placement.act_btn)
	skip()
	d.broke = true
	click(placement.act_btn)
	check(#run.bag == 0 and placement.b.stats.atk == 1 + d.value, "counted, then broke")
	check(d.value == d.faces[d.face_i] * 2, "doubled")
end)
