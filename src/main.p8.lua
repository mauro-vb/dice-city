global = _ENV

tween = ptween() -- src/utils/ptween.p8.lua
t = 0

function _init()
    color_settings()
    scene:load(title)
end

function _update60()
	t += 1
    cursor:upd()
    tween.upd()
    scene.current:upd()
end

function _draw()
    scene.current:drw()
    -- circfill(cursor.x, cursor.y, 2) -- draw a mouse cursor here if your game uses one
end
