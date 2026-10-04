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

-- a grower going into a fight raises its lowest face: the last one of that
-- value, so the faces stay in order (1;2;3 -> 2;2;3 -> 2;3;3). this fight
-- is already rolled, and losing ends the run, so it's the same as growing
-- after a win
function grow(d)
	local lo, j = d:range()
	for i = 1, #d.faces do
		if d.faces[i] == lo then j = i end
	end
	d.faces[j] += 1
end
