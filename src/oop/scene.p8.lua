-- base class for game scenes/screens (title, gameplay, game over, ...)
--
-- usage:
--   title_scene = scene:extend({
--       upd = function(_ENV) if btnp(4) or btnp(5) then scene:load(game_scene) end end,
--       drw = function(_ENV) cls(0) print("press a button", 40, 64) end,
--   })
--   game_scene = scene:extend({ init = function(_ENV) entities = {} end })
--
--   scene:load(title_scene)     -- call once, in _init()
--   scene.current:upd()         -- call every frame, in _update()
--   scene.current:drw()         -- call every frame, in _draw()

scene = game_object:extend({
    -- switch to new scene (no scene ever loads itself)
    load = function(_ENV, new_scene)
        sfx(33) -- next
        current = new_scene
        current:init()
    end
})
