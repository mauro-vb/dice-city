title = screen:extend({
	init = function(_ENV)
		make(_ENV, "start", function()
			new_run()
			scene:load(shop)
		end)
	end,

	text = function()
		txt("autoroll", 64, 50, 7, "c", true)
	end,
})
