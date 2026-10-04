-- a screen with some text and one centred text button (title, game over)
-- usage: init calls make(_ENV, label, press, ok); text(_ENV) draws the text
screen = scene:extend({
	make = function(_ENV, label, press, ok)
		timer, f = 0, focus:new()
		btn = f:item(button:new({label = label, x = 64, y = 84, w = 24, h = 9, on_press = press, enabled = ok}))
	end,

	upd = function(_ENV)
		timer += 1
		f:upd()
	end,

	drw = function(_ENV)
		cls(bg)
		text(_ENV)
		-- the button is just text (p8scii \^o: outline colour + all 8 sides):
		-- pink, black outline, white when hovered
		txt("\^o"..(f.cur == btn and 7 or 0).."ff"..btn.label, 64, 82, 14, "c")
		f:drw()
	end,
})
