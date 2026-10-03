-- ptween v1.1
-- chainable tween library for pico-8
-- trimmed to what the game uses (more transitions, pausing and per-step
-- objects / call_backs are in git)
ptween = function()
	local Trans = {
	    linear = function(t) return t end,
	    quad = function(t) return t * t end,
	    back = function(t)
	        local s = 1.70158; return (s + 1) * t ^ 3 - s * t ^ 2
	    end
	}

	local Ease = {
	    _in = function(f) return f end,
	    out = function(f)
	        return function(t)
	            return 1 - f(1 - t)
	        end
	    end,
	    inout = function(f)
	        return function(t)
	            if t < .5 then
	                return f(t * 2) * .5
	            end
	            return 1 - f((1 - t) * 2) * .5
	        end
	    end
	}
    local routines = {}

    -- call each frame
    local function upd()
        for r in all(routines) do
            if costatus(r) == "dead" then
                del(routines, r)
            else
                coresume(r)
            end
        end
    end

    -- one tween as a coroutine body
    -- initial value is captured when the coroutine starts, not when :add() is called
    local function make(obj, k, v, f, trans, ease)
        local tr = (Ease[ease] or Ease._in)(Trans[trans] or Trans.linear)
        return function()
            local iv = obj[k] or 0
            for i = 1, f do
                obj[k] = lerp(iv, v, tr(i / f))
                yield()
            end
        end
    end

    -- create a new tween chain on table obj
    --
    -- usage:
    --   tw:add({ k="x", v=100, f=30, tr="quad", ease="out" })
    --   tw:add(15)                                 wait n frames
    --   tw:add({ parallel=true, {k=..}, {k=..} })  parallel group
    --   tw:play(final_call_back)
    local function new_tw(obj)
        local steps = {}
        local tw = {}

        function tw:add(step)
            if type(step) == "number" then
                add(steps, { make({}, "x", 0, step) })
            elseif step.parallel then
                local group = {}
                for s in all(step) do
                    add(group, make(obj, s.k, s.v, s.f, s.tr, s.ease))
                end
                add(steps, group)
            else
                add(steps, { make(obj, step.k, step.v, step.f, step.tr, step.ease) })
            end
            return self
        end

        -- start playing; fires final_call_back when all steps complete
        function tw:play(final_call_back)
            add(routines, cocreate(function()
                for step in all(steps) do
                    local cos = {}
                    for a in all(step) do
                        add(cos, cocreate(a))
                    end
                    local any = true
                    while any do
                        any = false
                        for co in all(cos) do
                            if costatus(co) != "dead" then
                                coresume(co)
                                any = true
                            end
                        end
                        if any then yield() end
                    end
                end
                if final_call_back then final_call_back() end
            end))
            return self
        end

        return tw
    end

    return {
        new   = new_tw,
        upd   = upd,
    }
end
