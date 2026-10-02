function new_run()
	global.run = player:new()
end

function cur_stage()
	return stages[run.stage_i]
end

function foe_label()
	return cur_stage().boss and "boss" or "enemy "..run.stage_i
end

-- applies a fight result; returns the coins gained and the next scene
function finish_fight(result)
	local st = cur_stage()
	local gain = {reward = 0, leftover = 0}
	run.hp = result.hp_left
	if not result.win or st.boss then
		run.won = result.win
		return gain, game_over
	end
	gain.reward = st.reward
	gain.leftover = leftover_coins(run:unused())
	run:earn(gain.reward + gain.leftover)
	return gain, shop
end

function next_stage()
	run.stage_i += 1
	for d in all(run.bag) do
		d:clear()
	end
	run.rerolls_left = run.rerolls
end
