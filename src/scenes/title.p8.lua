-- starter scene -- rename this (and the reference in src/main.p8.lua) to
-- whatever your first real scene should be called

title = scene:extend({
    init = function(_ENV)
    	mydie=die:new({kind=stairs})--test
        entities = {mydie}
        -- parts = {} -- uncomment if you're using src/particles/
    end,

    upd = function(_ENV)
    	mydie.x = cursor.x
     	mydie.y = cursor.y
        upd_group(entities)
        -- upd_group(parts)
    end,

    drw = function(_ENV)
        cls(0)
        drw_group(entities)
        -- drw_group(parts)
    end
})
