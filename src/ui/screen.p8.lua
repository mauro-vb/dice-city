-- a screen with some text and one centred text button (title, game over)
-- usage: init calls make(_ENV, label, press, ok); text(_ENV) draws the text
screen = scene:extend({
	make = function(_ENV, label, press, ok)
		timer, f = 0, focus:new()
		btn = f:item(button:new({label = label, x = 64, y = 84, w = 44, h = 12, on_press = press, enabled = ok}))
	end,

	upd = function(_ENV)
		timer += 1
		f:upd()
	end,

	drw = function(_ENV)
		cls(bg)
		text(_ENV)
		-- the button is just big text (p8scii: \^w\^t double size, \^o outline
		-- colour + all 8 sides): pink, white outline, dark grey when hovered
		txt("\^w\^t\^o"..(f.cur == btn and dark or 7).."ff"..btn.label, 64, 79, 14, "c")
		f:drw()
	end,
})
