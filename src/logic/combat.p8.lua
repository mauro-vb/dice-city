--player method
function simulate_combat(_ENV, enemy)
	local events = {}
	local i = 0
	local atk_progress = 0
	local e_atk_progress = 0
	local increase_k = 5
	local spd = get_stat(_ENV, "spd")
	local atk = get_stat(_ENV, "atk")
	local def = get_stat(_ENV, "def")
	while hp > 0 and enemy.hp > 0 do
		p_atk_progress += spd + increase_k
		e_atk_progress += enemy.spd + increase_k

		i += 1
	end
end
