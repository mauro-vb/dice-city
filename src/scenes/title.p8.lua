title = scene:extend({
	init = function(_ENV)
		f = focus:new()
		start_btn = f:item(button:new({
			label = "start", x = 64, y = 84,
			on_press = function()
				new_run()
				scene:load(shop)
			end,
		}))
	end,

	upd = function(_ENV)
		f:upd()
	end,

	drw = function(_ENV)
		cls(0)
		print("autoroll", 48, 50, 7)
		start_btn:drw()
		f:drw()
	end
})
