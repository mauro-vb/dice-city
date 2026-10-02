function gen_offers(st)
	local pool = shuffle(concat(st.pool, {}))
	local offers = {}
	for i = 1, min(st.offers, #pool) do
		add(offers, pool[i])
	end
	return concat(offers, st.always)
end

-- rolls every die and adds up the values
function leftover_coins(dice)
	local sum = 0
	for d in all(dice) do
		sum += roll_die(d)
	end
	return sum
end

function buy(kind)
	if not run:spend(kind.price) then return false end
	run:add_die(kind)
	return true
end
