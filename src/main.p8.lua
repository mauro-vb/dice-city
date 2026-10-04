global = _ENV

tween = ptween() -- src/utils/ptween.p8.lua
t = 0

function _init()
    color_settings()
    -- [music] the song from sound/music.p8 (patterns 0-5: intro 0-2, then
    -- 3-5 loop), on channels 0-2; channel 3 is always free for sound effects
    music(0)
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
