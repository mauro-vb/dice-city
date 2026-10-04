-- base class for game scenes/screens (title, gameplay, game over, ...)
--
-- usage:
--   title_scene = scene:extend({
--       upd = function(_ENV) if btnp(4) or btnp(5) then scene:load(game_scene) end end,
--       drw = function(_ENV) cls(0) print("press a button", 40, 64) end,
--   })
--   game_scene = scene:extend({ init = function(_ENV) entities = {} end })
--
--   scene:load(title_scene)     -- fades out, switches, fades in
--   scene.current:upd()         -- call every frame, in _update()
--   scene.current:drw()         -- call every frame, in _draw()

-- every scene change fades to black and back (src/main: 15 frames out, the
-- switch, 15 frames in). fades: 15 steps per colour slot, from its normal
-- screen colour (slot 1 shows navy, 129) down to black. this column is the
-- screen palette: _draw sets it every frame. table from
-- github.com/kevinthompson/tiny-flappy-bird-p8 (mit), made with
-- kometbomb.net/pico8/fadegen.html
fades = split"0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,129,129,129,129,129,129,129,129,0,0,0,0,0,0,0,2,2,2,130,130,130,130,130,128,128,128,128,128,0,0,3,3,3,131,131,131,131,129,129,129,129,129,0,0,0,4,4,132,132,132,132,132,132,130,128,128,128,128,0,0,5,5,133,133,133,133,130,130,128,128,128,128,128,0,0,6,6,134,13,13,13,141,5,5,5,133,130,128,128,0,7,6,6,6,134,134,134,134,5,5,5,133,130,128,0,8,8,136,136,136,136,132,132,132,130,128,128,128,128,0,9,9,9,4,4,4,4,132,132,132,128,128,128,128,0,10,10,138,138,138,4,4,4,132,132,133,128,128,128,0,11,139,139,139,139,3,3,3,3,129,129,129,0,0,0,12,12,12,140,140,140,140,131,131,131,1,129,129,129,0,13,13,141,141,5,5,5,133,133,130,129,129,128,128,0,14,14,14,134,134,141,141,2,2,133,130,130,128,128,0,15,143,143,134,134,134,134,5,5,5,133,133,128,128,0"

scene = game_object:extend({
    -- switch to new scene once the screen is black (no scene ever loads itself)
    load = function(_ENV, new_scene)
        -- [sfx 33: next] every scene change
        sfx(33)
        nxt, global.fade_t = new_scene, 0
    end
})
