-- tiny class/inheritance system
--
-- usage:
--   enemy  = class:extend({ hp = 10, init = function(_ENV) end })
--   goomba = enemy:extend({ speed = 1 })
--   local g = goomba({ x = 10 })   -- same as goomba:new({ x = 10 })
--
-- extend() builds a new table whose __index falls back to the parent,
-- so unset fields/methods resolve up the chain automatically.

_noop = function() end

class = setmetatable({
    -- extend a class
    extend = function(_ENV, tbl)
        tbl = tbl or {}
        tbl.__index = tbl
        setmetatable(tbl, {
            -- new class defers to this class for missing keys
            __index = _ENV,

            -- allow class to be called as an initializer function
            -- ex: goomba({ x = 2 }) is the same as goomba:new({ x = 2 })
            -- this saves tokens when there are more than ~12 new calls
            __call = function(_ENV, tbl)
                return _ENV:new(tbl)
            end
        })

        return tbl
    end,

    -- instantiate object
    new = function(_ENV, tbl)
        tbl = tbl or {}
        setmetatable(tbl, _ENV)
        tbl.class = _ENV
        tbl:init()
        return tbl
    end,

    -- default initializer
    init = _noop
}, { __index = _ENV })

-- class is used as a metatable
-- so its index points to itself
class.__index = class
