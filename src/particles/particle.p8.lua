-- lightweight particle system (game_object-based), ported from an earlier
-- project. self-contained -- doesn't need src/utils/ptween.p8.lua, it drives
-- its own movement/size/color via the per-particle fields below.
--
-- this file is just the base: age/lifecycle/movement (dopart) and the
-- `particle` class itself. actual shapes live alongside it in this same
-- src/particles/ directory -- particle_circle.p8.lua, particle_rect.p8.lua,
-- particle_oval.p8.lua, particle_spark.p8.lua, particle_ring.p8.lua,
-- particle_text.p8.lua, particle_sprite.p8.lua -- each just a small pdrw.
-- drop a new particle_whatever.p8.lua in this folder to add a shape --
-- build.py picks it up automatically. "particle.p8.lua" always sorts first
-- in this folder (a "." sorts before a "_"), so the base class is always
-- defined before any particle_*.p8.lua that extends it.
--
-- usage:
--   parts = parts or {} -- created below; keep one per scene, or share globally
--
--   -- call every frame, alongside your own entities:
--   upd_group(parts)   -- src/helpers.p8.lua
--   drw_group(parts)
--
--   circlep({ x = 64, y = 64, c = 8, size = 3, sy = -0.5, maxage = 20, onend = "fade" })
--   -- see the other particle_*.p8.lua files in this folder for more shapes
--
-- key particle fields (all optional, set per-instance, shared by every shape):
--   x, y, c, size          starting position, color, size
--   sx, sy                 linear speed per frame (added to x/y each frame)
--   tox, toy, tospd         ease toward a target position instead of linear
--   tosize, incrsize        ease toward a target size, or grow/shrink by a flat amount
--   ctab, ctabv             color table to animate through over the particle's life
--   rotspd, cdist, cx, cy   orbit around (cx, cy) at cdist, rotating by rotspd/frame
--   wait                    delay n frames before the particle "starts" (snaps to parentp if set)
--   maxage                  frames alive before onend fires
--   onend                   "fade" (shrink out), "return" (ease back to start pos), or nil (delete)
--   drag                    multiplies sx/sy each frame (e.g. 0.9 to decelerate)
--
-- see the burst() example commented out at the bottom of this file

parts = parts or {}

function dopart(_ENV)
    -- age and wait
    if wait then
        wait -= 1
        if wait <= 0 then
            wait = nil
            if parentp then
                x = parentp.x; y = parentp.y
                if offsetx then
                    x += offsetx
                end
                if offsety then
                    y += offsety
                end
            end
        end
    else
        age = age or 0
        c = c or ctab and ctab[1]
        if age == 0 then
            ox = x
            oy = y
            size = size or 1
            ctabv = ctabv or 0
            tospd = tospd or 1
        elseif freezeat == age then
            global.freeze_frames = freezeframes -- optional hit-stop hook; ignore if unused
        end
        age += 1
        if age <= 0 then return end
        --particle code
        --animate color
        if ctab then
            local ci = (age + ctabv) / maxage
            ci = mid(1, flr(1 + ci * #ctab), #ctab)
            c = ctab[ci]
        end

        --movement
        -- to pos
        if tox then
            x += (tox - x) / (4 / tospd)
        end
        if toy then
            y += (toy - y) / (4 / tospd)
        end
        -- rotation
        if rotspd then
            rota = rota or 0
            cdist = cdist or 8
            rota += rotspd
            x = cx + sin(rota) * cdist
            y = cy + cos(rota) * cdist
        end
        -- linear
        if sx then
            if cx then
                cx += sx
            else
                x += sx
            end
            if tox then
                tox += sx
            end
            if drag then
                sx *= drag
            end
        end
        if sy then
            if cy then
                cy += sy
            else
                y += sy
            end
            if toy then
                toy += sy
            end
            if drag then
                sy *= drag
            end
        end

        --size
        if tosize then
            size += (tosize - size) / (5 / tospd)
        end
        if incrsize then
            size += incrsize
        end
        if age >= maxage or size < 1 then
            if onendf then onendf() end
            if onend == "return" then
                maxage += 32000
                tox = ox
                toy = oy
                tosize = nil
                incrsize = -0.3
            elseif onend == "fade" then
                maxage += 32000
                tosize = nil
                incrsize = -0.1 - rnd(0.3)
            else
                del(parts, _ENV)
            end
            ctab = nil
            onend = nil
        end
    end
end

particle = game_object:extend({
    age = 0,
    maxage = 0,
    x = 63,
    y = 63,
    size = 1,
    ctabv = nil,
    spd = 1,
    upd = dopart,
    init = function(_ENV)
        ox = x
        oy = y

        add(parts, _ENV)
        if pinit then pinit(_ENV) end
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
-- function burst(x, y, col, n)
--     n = n or 12
--     for i = 1, n do
--         local a = rnd(1) -- random angle, 0..1 pico-8 "turns"
--         circlep({
--             x = x, y = y,
--             c = col or 8,
--             size = 1 + rnd(2),
--             sx = cos(a) * rnd(1),
--             sy = sin(a) * rnd(1),
--             maxage = 10 + rnd(10),
--             onend = "fade",
--         })
--     end
-- end
