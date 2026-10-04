-- dice: plain d3, d6 and d8, each with a + (every face +1) and a ++ (+2)
-- version. drawn with pips, 0 is a sad face (faces without a pip layout
-- print); 8 faces draw as a circle with numbers. special rules come from
-- enchantments (src/defs/shop_items.p8.lua), not from the dice.
-- every kind is offered equally often: price is what makes a die rare.
-- prices (see tools/balance.py): 2 coins per point of average above 1.5,
-- since an unused die pays its roll back every won fight
defs("id,name,faces,price", "d3,d3,1;2;3,1|d3p,d3+,2;3;4,3|d3pp,d3++,3;4;5,5|d6,d6,1;2;3;4;5;6,4|d6p,d6+,2;3;4;5;6;7,6|d6pp,d6++,3;4;5;6;7;8,8|d8,d8,1;2;3;4;5;6;7;8,6|d8p,d8+,2;3;4;5;6;7;8;9,8|d8pp,d8++,3;4;5;6;7;8;9;10,10")
-- by tier: gen_offers takes the first 3, 6 or 9 by stage (pick)
dice_kinds, dice_tiers = names"d3,d6,d8,d3p,d6p,d8p,d3pp,d6pp,d8pp", split"3,6,9"
