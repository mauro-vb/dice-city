-- focus: hover follows the mouse even when items move under a still mouse,
-- and nothing behind an open tooltip gets hovered

local function setup()
	boot()
	local f = focus:new()
	local a = f:item(selectable:new({x = 10, y = 10, on_press = _noop}))
	local b = f:item(selectable:new({x = 50, y = 50, on_press = _noop}))
	mouse(10, 10) cursor:upd() f:upd()
	return f, a, b
end

test("still mouse: hover follows the item now under it", function()
	local f, a, b = setup()
	check(f.cur == a)
	a.x, b.x, b.y = 90, 10, 10
	cursor:upd() f:upd()
	check(f.cur == b, "hover moved to b")
end)

test("no hovering through an open tooltip", function()
	local f, a, b = setup()
	tip_area = {40, 40, 60, 60}
	mouse(50, 50) cursor:upd() f:upd()
	check(f.cur == a, "b is behind the tooltip")
	tip_area = false
	cursor:upd() f:upd()
	check(f.cur == b)
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
