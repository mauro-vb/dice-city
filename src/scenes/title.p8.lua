title = screen:extend({
	init = function(_ENV)
		global.want_music("menu")
		reload(0x8000, 0, 0x2000, "splash.p8")
		make(_ENV, "start", function()
			new_run()
			scene:load(shop)
		end)
	end,

	text = function()
		memcpy(0x6000, 0x8000, 0x2000)
	end,
})
