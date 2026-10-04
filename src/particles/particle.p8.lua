-- lightweight particle system (game_object-based), ported from an earlier
-- project and trimmed to what the game uses (the full version is in git).
-- shapes live next to it: particle_circle.p8.lua (circlep, sparkp). "particle.p8.lua"
-- sorts first in this folder ("." < "_"), so the base class is defined first.
--
-- usage:
--   upd_group(parts) / drw_group(parts) every frame (src/utils/helpers)
--   circlep({ x = 64, y = 64, c = 8, size = 3, sy = -0.5, maxage = 20 })
--
-- particle fields (all optional):
--   x, y, c, size     starting position, color, size
--   sx, sy            speed per frame (added to x/y each frame)
--   drag              multiplies sx/sy each frame (< 1 slows down, > 1 speeds up)
--   grav              added to sy each frame
--   incrsize          added to size each frame
--   wait              frames before the particle starts (hidden until then)
--   maxage            frames alive; also deleted when size < 1

parts = parts or {}

function dopart(_ENV)
    if wait then
        wait -= 1
        if (wait <= 0) wait = nil
        return
    end
    age += 1
    x += sx
    y += sy
    sx *= drag
    sy = sy * drag + grav
    size += incrsize
    if age >= maxage or size < 1 then
        del(parts, _ENV)
    end
end

particle = game_object:extend({
    age = 0,
    maxage = 0,
    x = 63,
    y = 63,
    size = 1,
    sx = 0,
    sy = 0,
    drag = 1,
    grav = 0,
    incrsize = 0,
    upd = dopart,
    init = function(_ENV)
        add(parts, _ENV)
    end,
    drw = function(_ENV)
        if (wait) return
        pdrw(_ENV)
    end
})

-- n dots from a die's bottom, up and out (any angle in the top half), speed
-- up to v, falling with gravity g; colours from cols. dust and sparks on landing.
-- lighter gravity lingers longer: 10 to 2 / g frames (sparks .1: 10-20)
function spray(d, n, cols, v, g)
    for i = 1, n do
        local a, s = rnd(.5), v / 2 + rnd(v / 2)
        circlep({
            x = d.x, y = d.y + 7,
            c = rnd(cols),
            sx = cos(a) * s, sy = sin(a) * s,
            grav = g, drag = .9,
            maxage = 10 + rnd(2 / g - 10),
        })
    end
end
