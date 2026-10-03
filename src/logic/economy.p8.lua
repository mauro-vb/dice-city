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

-- potion only helps when you're hurt
function can_buy(k)
	return run.coins >= k.price and (k != potion or run.hp < run.max_hp)
end

-- returns the new die for dice, true for items, false if you can't
function buy(k)
	if not can_buy(k) then return false end
	run:spend(k.price)
	if k == potion then
		run:heal(5)
		return true
	end
	if k == token then
		run.extra_rerolls += 1
		return true
	end
	return run:add_die(k)
end
