-- focus: hover follows the mouse even when items move under a still mouse;
-- tooltips of things low on the screen open above them

local function setup()
	boot()
	local f = focus:new()
	local a = f:item(selectable:new({x = 10, y = 10, w = 8, h = 8, on_press = _noop}))
	local b = f:item(selectable:new({x = 50, y = 50, w = 8, h = 8, on_press = _noop}))
	-- focus reads mb / pmb, which main's _update60 sets; f:upd() is called alone here
	mb, pmb = 0, 0
	mouse(10, 10) f:upd()
	return f, a, b
end

test("still mouse: hover follows the item now under it", function()
	local f, a, b = setup()
	check(f.cur == a)
	a.x, b.x, b.y = 90, 10, 10
	f:upd()
	check(f.cur == b, "hover moved to b")
end)

test("tooltips: above things low on the screen, beside the rest", function()
	boot()
	local low, high = {x = 40, y = 100, w = 16, h = 16}, {x = 40, y = 50, w = 16, h = 16}
	local x, y = tip_box(low, 30, 20)
	check(y + 20 <= 92, "above the bag die")
	x, y = tip_box(high, 30, 20)
	check(x >= 48, "beside it")
end)

test("no frame on things you can't use right now", function()
	local f, a, b = setup()
	local drawn = false
	local real_rect = rect
	rect = function() drawn = true end
	a.enabled = false
	f:drw_frame()
	check(not drawn, "disabled: no frame")
	a.enabled = true
	f:drw_frame()
	rect = real_rect
	check(drawn, "enabled: frame")
end)
