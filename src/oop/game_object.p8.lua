-- base class for anything with an update/draw lifecycle
--
-- usage:
--   bullet = game_object:extend({
--       upd = function(_ENV) y -= 2 end,
--       drw = function(_ENV) pset(x, y, 8) end,
--   })
--   local b = bullet({ x = 64, y = 64 })
--   b:upd()
--   -- or drive many at once: upd_group(group) / drw_group(group), see src/helpers.p8.lua

game_object = class:extend({
    upd = _noop,
    drw = _noop,
})
