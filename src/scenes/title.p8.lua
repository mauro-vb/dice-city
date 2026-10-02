title = scene:extend({
	init = function(_ENV)
		m = menu:new({x = 50, y = 80})
		m:item("start", function()
			new_run()
			scene:load(shop)
		end)
	end,

	upd = function(_ENV)
		m:upd()
	end,

	drw = function(_ENV)
		cls(0)
		print("autoroll", 48, 50, 7)
		m:drw()
	end
})
