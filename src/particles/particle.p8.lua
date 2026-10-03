-- lightweight particle system (game_object-based), ported from an earlier
-- project and trimmed to what the game uses (the full version is in git).
-- shapes live next to it: particle_circle.p8.lua (circlep). "particle.p8.lua"
-- sorts first in this folder ("." < "_"), so the base class is defined first.
--
-- usage:
--   upd_group(parts) / drw_group(parts) every frame (src/utils/helpers)
--   circlep({ x = 64, y = 64, c = 8, size = 3, sy = -0.5, maxage = 20, onend = "fade" })
--
-- particle fields (all optional):
--   x, y, c, size     starting position, color, size
--   sx, sy            speed per frame (added to x/y each frame)
--   drag              multiplies sx/sy each frame (< 1 slows down, > 1 speeds up)
--   grav              added to sy each frame
--   incrsize          added to size each frame
--   wait              frames before the particle starts (hidden until then)
--   maxage            frames alive before onend fires
--   onend             "fade" (shrink out) or nil (delete); also deleted when size < 1

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
        if onend == "fade" then
            maxage += 32000
            incrsize = -0.1 - rnd(0.3)
        else
            del(parts, _ENV)
        end
        onend = nil
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

-- ---------------------------------------------------------------------
-- example usage: a small radial burst, e.g. call burst(x, y, 8) on a
-- hit/pickup/explosion
-- ---------------------------------------------------------------------
function burst(x, y, col, n)
    for i = 1, n do
        local a = rnd(1) -- random angle, 0..1 pico-8 "turns"
        circlep({
            x = x, y = y,
            c = type(col) == "table" and rnd(col) or col,
            size = 1 + rnd(2),
            sx = cos(a) * rnd(1),
            sy = sin(a) * rnd(1),
            maxage = 10 + rnd(10),
            onend = "fade",
         })
    end
end

-- n dots from a die's bottom, up and out (any angle in the top half), speed
-- up to v, falling with gravity g; colours from cols. dust and sparks on landing
function spray(d, n, cols, v, g)
    for i = 1, n do
        local a, s = rnd(.5), rndrange(v / 2, v)
        circlep({
            x = d.x, y = d.y + 7,
            c = rnd(cols),
            sx = cos(a) * s, sy = sin(a) * s,
            grav = g, drag = .9,
            maxage = rndrange(10, 20),
        })
    end
end
