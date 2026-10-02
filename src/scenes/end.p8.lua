-- not called "end": that's a lua keyword
game_over = scene:extend({
	init = function(_ENV)
		timer = 0
		f = focus:new()
		title_btn = f:item(button:new({
			label = "title", x = 64, y = 84,
			on_press = function() scene:load(title) end,
			enabled = function() return timer > 30 end,
		}))
	end,

	upd = function(_ENV)
		timer += 1
		f:upd()
	end,

	drw = function(_ENV)
		cls(0)
		print(run.won and "you win!" or "game over", 44, 40, run.won and 11 or 8)
		print("stage "..run.stage_i, 48, 50, 6)
		title_btn:drw()
		f:drw()
	end
})
