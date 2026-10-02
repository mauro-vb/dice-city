-- not called "end": that's a lua keyword
game_over = scene:extend({
	init = function(_ENV)
		timer = 0
		m = menu:new({x = 50, y = 80})
		m:item("title", function() scene:load(title) end, function() return timer > 30 end)
	end,

	upd = function(_ENV)
		timer += 1
		m:upd()
	end,

	drw = function(_ENV)
		cls(0)
		print(run.won and "you win!" or "game over", 44, 40, run.won and 11 or 8)
		print("stage "..run.stage_i, 48, 50, 6)
		m:drw()
	end
})
