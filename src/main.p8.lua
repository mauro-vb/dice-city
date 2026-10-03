global = _ENV

tween = ptween() -- src/utils/ptween.p8.lua
tween_pause = false
t = 0

function _init()
    color_settings()
    scene:load(title)
end

function _update60()
	t += 1
    cursor:upd()
    tween.upd(tween_pause)
    scene.current:upd()
end

function _draw()
    scene.current:drw()
    -- circfill(cursor.x, cursor.y, 2) -- draw a mouse cursor here if your game uses one
end
