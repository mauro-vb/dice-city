global = _ENV

t = 0

function _init()
    color_settings()
    -- [music] the song from sound/music.p8 (patterns 0-5: intro 0-2, then
    -- 3-5 loop), on channels 0-2; channel 3 is always free for sound effects
    music(0)
    -- start at black: the title switches in on the first frame, then fades in
    scene:load(title)
    fade_t = 14
end

function _update60()
	t += 1
    pmb, mb = mb, stat(34) & 1
    upd_tws()
    -- scene fade (src/oop/scene): 0-14 out, the old scene frozen; 15 switch;
    -- 15-29 in; 30 idle
    fade_t = min(fade_t + 1, 30)
    if fade_t == 15 then
        scene.current = scene.nxt
        scene.current:init()
    end
    if fade_t > 14 then scene.current:upd() end
end

function _draw()
    scene.current:drw()
    local l = min(14, 15 - abs(fade_t - 15))
    for c = 0, 15 do
        pal(c, fades[c * 15 + l + 1], 1)
    end
end
