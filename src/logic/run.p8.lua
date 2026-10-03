-- pico-8 seeds rnd randomly at launch, so runs differ; pass a seed to repeat one
-- (tests do)
function new_run(seed)
	if seed then srand(seed) end
	global.run = player:new()
end

function cur_stage()
	return stages[run.stage_i]
end

-- applies a finished battle; returns the coins gained and the next scene
function finish_fight(b)
	local st = cur_stage()
	local gain = {reward = 0, leftover = 0}
	run.hp = b.p_hp
	if not b:won() or st.boss then
		run.won = b:won()
		return gain, game_over
	end
	gain.reward = st.reward
	gain.leftover = b.coins
	run:earn(gain.reward + gain.leftover)
	return gain, shop
end

-- dice are back in the bag since the fight started; clear their values
function next_stage()
	run.stage_i += 1
	for d in all(run.bag) do
		d:clear()
	end
end
