-- generic table/group helpers shared by scenes, entities, and src/particles/

function merge(t, added)
    local copy = {}
    for k, v in pairs(t) do copy[k] = v end
    for k, v in pairs(added) do copy[k] = v end
    return copy
end

-- usage: split2d"0,112,16,16,0,0|16,112,16,16,0,0" -> { {0,112,16,16,0,0}, {16,112,16,16,0,0} }
function split2d(s)
    local arr = split(s, "|", false)
    for k, v in pairs(arr) do
        arr[k] = split(v)
    end
    return arr
end

function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = flr(rnd(i) + 1)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

function rndrange(low, high)
    return low + rnd(high - low)
end

-- calls :upd() on every item in group -- entities, particles, anything game_object-based
function upd_group(group)
    for e in all(group) do
        if e.upd then
            e:upd()
        end
    end
end

function drw_group(group)
    for e in all(group) do
        if e.drw then
            e:drw()
        end
    end
end
