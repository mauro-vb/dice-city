-- not called "end": that's a lua keyword
game_over = screen:extend({
	init = function(_ENV)
		make(_ENV, "title", function() scene:load(title) end, function() return timer > 30 end)
	end,

	-- on the title's splash art (still in upper memory, see title)
	text = function()
		memcpy(0x6000, 0x8000, 0x2000)
		txt(run.won and "you win!" or "game over", 64, 64, run.won and 7 or 8, "c", true)
		txt("stage "..run.stage_i, 64, 72, 7, "c", true)
	end,
})
