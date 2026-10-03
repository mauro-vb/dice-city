-- a screen with some text and one centred button (title, game over)
-- usage: init calls make(_ENV, label, press, ok); text(_ENV) draws the text
screen = scene:extend({
	make = function(_ENV, label, press, ok)
		timer, f = 0, focus:new()
		btn = f:item(button:new({label = label, x = 64, y = 84, on_press = press, enabled = ok}))
	end,

	upd = function(_ENV)
		timer += 1
		f:upd()
	end,

	drw = function(_ENV)
		cls(bg)
		text(_ENV)
		btn:drw()
		f:drw_frame()
		f:drw()
	end,
})
