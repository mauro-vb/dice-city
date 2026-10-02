global = _ENV

tween = ptween() -- src/utils/ptween.p8.lua
tween_pause = false

function _init()
    color_settings()
    scene:load(main_scene)
end

function _update()
    cursor:upd()
    tween.upd(tween_pause)
    scene.current:upd()
end

function _draw()
    scene.current:drw()
    -- spr(32, cursor.x, cursor.y) -- draw a mouse cursor here if your game uses one
end
