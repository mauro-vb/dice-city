-- dice: plain d4, d6 and d8, each with a + (every face +1) and a ++ (+2)
-- version. drawn with pips, 0 is a sad face (faces without a pip layout
-- print, so a d4's 4 is a number); 4 faces draw as a triangle, 8 as a
-- circle with numbers. special rules come from enchantments
-- (src/defs/shop_items.p8.lua), not from the dice.
-- every kind is offered equally often: price is what makes a die rare.
-- prices: d4 2, d6 3, d8 4, then 2 coins more per + (see tools/balance.py)
defs("id,name,faces,price", "d4,d4,1;2;3;4,2|d4p,d4+,2;3;4;5,4|d4pp,d4++,3;4;5;6,6|d6,d6,1;2;3;4;5;6,3|d6p,d6+,2;3;4;5;6;7,5|d6pp,d6++,3;4;5;6;7;8,7|d8,d8,1;2;3;4;5;6;7;8,4|d8p,d8+,2;3;4;5;6;7;8;9,6|d8pp,d8++,3;4;5;6;7;8;9;10,8")
-- by tier: gen_offers takes the first 3, 6 or 9 by stage (pick)
dice_kinds, dice_tiers = names"d4,d6,d8,d4p,d6p,d8p,d4pp,d6pp,d8pp", split"3,6,9"
