global = _ENV

t = 0

-- [music] segments of the song in cart.p8's __music__, as {first, last}
-- pattern; each loops (loop-start flag on first, loop-end on last) until
-- another one is wanted. channels 0-2 are music, 3 is always free for sfx
segs = {menu = {0, 2}, fight1 = {8, 13}}

-- a scene asks for a segment; it starts once the playing pattern has
-- finished, so the change lands on the beat
function want_music(name) want = name end

function music_upd()
    local pat = stat(54)
    if want != playing then
        -- done: the playing pattern just ended (the next one started)
        if not segs[playing] or pat != ppat then
            music(segs[want][1])
            playing, pat = want, -1
        end
    end
    ppat = pat
end

function _init()
    color_settings()
    music(0)
    want, playing = "menu", "menu"
    -- start at black: the title switches in on the first frame, then fades in
    scene:load(title)
    fade_t = 14
end

function _update60()
	t += 1
    music_upd()
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
