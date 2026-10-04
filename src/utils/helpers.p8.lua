-- generic table/group helpers shared by scenes, entities, and src/particles/

-- usage: split2d"0,112,16,16,0,0|16,112,16,16,0,0" -> { {0,112,16,16,0,0}, {16,112,16,16,0,0} }
function split2d(s)
    local arr = split(s, "|", false)
    for k, v in pairs(arr) do
        arr[k] = split(v)
    end
    return arr
end

function rndrange(low, high)
	return low + rnd(high - low)
end

-- calls :upd() on every item in group -- entities, particles, anything game_object-based
function upd_group(group)
    for e in all(group) do
        e:upd()
    end
end

function drw_group(group)
    for e in all(group) do
        e:drw()
    end
end

-- print with alignment and outline: al "c" centres on x, "r" puts the right
-- edge at x; ol adds a black p8scii outline (\^o, neighbours 5a = l/r/t/b)
-- usage: txt("win!", 64, 51, 7, "c", true)
-- width comes from print's return value (printed far off screen, also
-- under a camera offset), so p8scii control codes like the yellow cash
-- sign don't count as characters
function txt(s, x, y, c, al, ol)
	s = (ol and "\^o05a" or "")..s
	local w = print(s, 0, -999)
	x -= al == "c" and w \ 2 or al == "r" and w or 0
	print(s, x, y, c)
end

-- money: put it after the number ("12"..cash): the digits keep the line's
-- colour, only the $ turns yellow (p8scii \f = foreground colour)
cash = "\fa$"

-- data as strings (a string is 1 token): rows split by "|", fields by ",".
-- keys names the fields; the first field names the row, which also becomes a
-- global (d6, enemy1, potion). a field with ";" becomes a list (dice faces).
-- usage: defs("id,hp,atk", "enemy1,6,2|enemy2,8,3")
function defs(keys, s)
	keys = split(keys)
	for row in all(split(s, "|")) do
		local v, t = split(row), {}
		for i = 1, #v do
			local l = split(v[i] .. "", ";")
			t[keys[i]] = #l > 1 and l or v[i]
		end
		_ENV[v[1]] = t
	end
end

-- "d6,d3" -> {d6, d3}: a list of globals by name
function names(s)
	local t = split(s)
	for i = 1, #t do
		t[i] = _ENV[t[i]]
	end
	return t
end
