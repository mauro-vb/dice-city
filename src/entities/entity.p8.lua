-- base entity: extend this for anything with a world position
--
-- usage:
--   coin = entity:extend({
--       drw = function(_ENV) spr(1, x, y) end,
--   })
--   add(entities, coin({ x = 40, y = 60 }))
--
-- if you want tile-grid movement with tweened pixel positions (logical x/y
-- separate from drawn drwx/drwy), see the `grid` cart for that pattern --
-- it's a small addition on top of this base.

entity = game_object:extend({
    x = 0,
    y = 0,
})
