-- tweens: tw(obj, steps, done) plays steps one after another on obj; a step
-- is {f = frames, e = ease, field = target, ...} (more fields = in parallel,
-- no field = a wait). the start value is read on the step's first frame.
-- eases: nil linear, qin / qout / qio quad in / out / in-out, bout back out
-- usage: tw(d, {{f = 8, e = qout, x = 64, y = 30}, {f = 10}}, function() ... end)
tws = {}

function qin(t) return t * t end
function qout(t) return 1 - (1 - t) ^ 2 end
function qio(t) return t < .5 and 2 * t * t or 1 - 2 * (1 - t) ^ 2 end
function bout(t)
	t = 1 - t
	return 1 - 2.70158 * t ^ 3 + 1.70158 * t ^ 2
end

function tw(o, s, done)
	add(tws, {o = o, s = s, done = done, i = 1, n = 0})
end

-- once a frame (main's _update60)
function upd_tws()
	for w in all(tws) do
		local s, o = w.s[w.i], w.o
		if w.n == 0 then
			w.a = {}
			for k in pairs(s) do w.a[k] = o[k] end
		end
		w.n += 1
		local p = w.n / s.f
		if s.e then p = s.e(p) end
		for k, v in pairs(s) do
			if k != "f" and k != "e" then o[k] = w.a[k] + (v - w.a[k]) * p end
		end
		if w.n >= s.f then
			w.n, w.i = 0, w.i + 1
			if not w.s[w.i] then
				del(tws, w)
				if w.done then w.done() end
			end
		end
	end
end
