-- ptween v1.1
-- chainable tween library for pico-8
ptween = function()
	-- transitions (comment out unused ones to save tokens)
	local Trans = {
	    linear = function(t) return t end,
	    quad = function(t) return t * t end,
	    cubic = function(t) return t * t * t end,
	    quart = function(t) return t * t * t * t end,
	    sine = function(t) return 1 - cos(t * 0.25) end,
	    expo = function(t) return t == 0 and 0 or (1 << (10 * (t - 1))) / 1024 end,
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

    -- call each frame; pass paused=true to freeze pausable tweens
    local function upd(paused)
        for r in all(routines) do
            if costatus(r.co) == "dead" then
                r.call_back()
                del(routines, r)
            elseif not (paused and r.pausable) then
                coresume(r.co)
            end
        end
    end

    -- build a single tween descriptor
    -- initial value is captured when the coroutine starts, not when :add() is called
    local function make(obj, k, v, f, trans, ease, call_back, pausable)
        trans = Trans[trans] or Trans.linear
        ease = Ease[ease] or Ease._in
        local tr = ease(trans)
        local function anim()
            local iv = obj and obj[k] or 0
            for i = 1, f do
                if obj then obj[k] = lerp(iv, v, tr(i / f)) end
                yield()
            end
        end
        return { anim = anim, call_back = call_back or _noop, pausable = pausable }
    end

    -- create a new tween chain object
    --
    -- usage:
    --   tw:add({ obj=x, k="x", v=100, f=30, tr=pt.trans.smooth, call_back=fn })
    --   tw:add(15)                        wait n frames
    --   tw:add({ {obj=..}, {obj=..} })    parallel group
    --   tw:pause():play(final_call_back)
    local function new_tw(obj)
        local steps = {}
        local pausable = false
        local tw = {}

        function tw:add(step)
            if type(step) == "number" then
                add(steps, { make({}, "x", 0, step) })
                return self
            end

            if step.parallel then
                local group = {}
                for s in all(step) do
                    if obj != nil and s.obj == nil then s.obj = obj end
                    add(group, make(s.obj, s.k, s.v, s.f, s.tr, s.ease, s.call_back, pausable))
                end
                add(steps, group)
                return self
            end

            -- single descriptor
            if obj != nil and step.obj == nil then step.obj = obj end
            add(steps, { make(step.obj, step.k, step.v, step.f, step.tr, step.ease, step.call_back, pausable) })
            return self
        end

        -- mark all steps in this chain as pausable
        function tw:pause(v)
            pausable = v != false
            return self
        end

        -- start playing; fires final_call_back when all steps complete
        function tw:play(final_call_back)
            final_call_back = final_call_back or _noop
            local function chain()
                for step in all(steps) do
                    local cos = {}
                    for t in all(step) do
                        add(cos, { co = cocreate(t.anim), call_back = t.call_back })
                    end
                    local any = true
                    while any do
                        any = false
                        for item in all(cos) do
                            if costatus(item.co) != "dead" then
                                coresume(item.co)
                                any = true
                            end
                        end
                        if any then yield() end
                    end
                    for item in all(cos) do item.call_back() end
                end
                final_call_back()
            end
            add(routines, { co = cocreate(chain), call_back = _noop, pausable = pausable })
            return self
        end

        return tw
    end

    return {
        new   = new_tw,
        upd   = upd,
    }
end
