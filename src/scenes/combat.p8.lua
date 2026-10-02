combat = scene:extend({
	init = function(_ENV)
		foe = cur_stage().enemy
		p_hp, e_hp = run.hp, foe.hp
		result = run:fight(foe)
		gain, next_scene = finish_fight(result)
		ev_i = 0
		timer = 0
		last = ""
		f = focus:new()
		cont_btn = false
	end,

	done = function(_ENV)
		return ev_i >= #result.events
	end,

	upd = function(_ENV)
		f:upd()
		if done(_ENV) then
			if not cont_btn then
				cont_btn = f:item(button:new({
					label = "continue", x = 64, y = 110, w = 40,
					on_press = function() scene:load(next_scene) end,
				}))
			end
			return
		end
		timer += 1
		if timer < 15 then return end
		timer = 0
		ev_i += 1
		local ev = result.events[ev_i]
		p_hp, e_hp = ev.p_hp, ev.e_hp
		last = (ev.who == "p" and "you hit " or foe_label().." hits ")..ev.dmg
	end,

	drw = function(_ENV)
		cls(0)
		print("you "..p_hp.."/"..run.max_hp, 4, 20, 7)
		print(foe_label().." "..e_hp.."/"..foe.hp, 70, 20, foe.col)
		print(last, 4, 40, 6)
		if done(_ENV) then
			print(result.win and "win!" or "lose", 4, 56, result.win and 11 or 8)
			if gain.reward > 0 then
				print("+"..gain.reward.." reward  +"..gain.leftover.." leftover", 4, 66, 10)
			end
		end
		if cont_btn then cont_btn:drw() end
		f:drw()
	end
})
