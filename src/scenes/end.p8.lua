-- not called "end": that's a lua keyword
game_over = screen:extend({
	init = function(_ENV)
		make(_ENV, "title", function() scene:load(title) end, function() return timer > 30 end)
	end,

	text = function()
		txt(run.won and "you win!" or "game over", 64, 40, run.won and 7 or 8, "c", true)
		txt("stage "..run.stage_i, 64, 50, 6, "c")
	end,
})
