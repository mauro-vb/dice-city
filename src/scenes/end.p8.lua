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
		txt(run.won and "you win!" or "game over", 64, 40, run.won and 7 or 8, "c", true)
		txt("stage "..run.stage_i, 64, 50, 6, "c")
		title_btn:drw()
		f:drw_frame()
		f:drw()
	end
})
