global = _ENV

tween = ptween() -- src/utils/ptween.p8.lua
t = 0

function _init()
    color_settings()
    scene:load(title)
end

function _update60()
	t += 1
    pmb, mb = mb, stat(34) & 1
    tween.upd()
    scene.current:upd()
end

function _draw()
    scene.current:drw()
end
