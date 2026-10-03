-- offers can repeat
function gen_offers(st)
	local offers = {}
	for i = 1, st.offers do
		add(offers, rnd(st.pool))
	end
	return concat(offers, st.always)
end

-- unused dice were rolled with the rest: their values become coins
function leftover_coins(dice)
	local sum = 0
	for d in all(dice) do
		sum += d.value or 0
	end
	return sum
end

-- inventory items need a stack of their kind with room, or a free slot
function can_buy(k)
	return run.coins >= k.price and (not k.inv or stack_for(k) or #run.items < inv_size)
end

-- returns the new die for dice, true for items, false if you can't
function buy(k)
	if not can_buy(k) then return false end
	run:spend(k.price)
	if k.inv then
		local s = stack_for(k)
		if s then s.n += 1 else add(run.items, {k = k, n = 1}) end
		return true
	end
	return run:add_die(k)
end

-- inventory: inv_size slots, each a stack {k = item, n = count} of one kind
-- (up to stack_max). b = the battle when used mid-fight, else false.
-- potion: heals 5 when hurt (the fight's hp in a fight). bomb: 4 damage to
-- the enemy, ignoring def, only in a fight. token: rerolls die d (scenes
-- decide when: after rolling)
inv_size, stack_max = 3, 5

function stack_for(k)
	for s in all(run.items) do
		if s.k == k and s.n < stack_max then return s end
	end
end

function can_use(i, b)
	local s = run.items[i]
	if not s then return false end
	if s.k == potion then return (b and b.p_hp or run.hp) < run.max_hp end
	if s.k == token then return not b end
	return b and b.e_hp > 0
end

-- uses one item from stack i (d = the die for a reroll); returns its kind, or false
function use_item(i, b, d)
	if not can_use(i, b) then return false end
	local s = run.items[i]
	s.n -= 1
	if s.n == 0 then deli(run.items, i) end
	if s.k == bomb then
		b:blast(4)
	elseif s.k == token then
		roll_die(d)
	elseif b then
		b:heal(5)
	else
		run:heal(5)
	end
	return s.k
end
