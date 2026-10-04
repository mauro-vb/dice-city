-- shop items that aren't dice (no faces); economy applies them
-- inv = goes into the inventory (stacks per slot) and is used from there
-- aim = used on a die you pick (scenes ask for the die first), in these
-- placement phases: a reroll after rolling, a rig before
-- col = an enchantment: used on a die before the roll, it becomes that die's
-- d.ench (one per die, a new one replaces it) and colours its body. its
-- name starts with the same colour as a p8scii code (\f + hex digit)
--   greedy  unused, it pays double its roll
--   grower  placed in a fight, its lowest face goes up 1 for good
--   wild    the one die you can still move after the roll
--   glass   rolls double; 1 in 4 breaks when the fight starts
defs("id,name,price,info,inv,aim,col", "potion,beer,3,heals 5 hp,1|bomb,bomb,6,10 damage (in a fight),1|token,reroll,3,reroll a die you rolled,1,rolled|double,double,4,copy a placed die (1 fight),1,place rolled|greedy,\fagreedy,4,unused: pays 2x roll,1,place,10|grower,\fbgrower,4,placed: low face +1,1,place,11|wild,\fewild,4,move it after the roll,1,place,14|glass,\fcglass,3,2x roll (1/4 breaks),1,place,12")
-- up = a bonus by tier (+, ++ like the dice): rigs go in the inventory and
-- add up to a random face of the die they're dropped on; level ups apply
-- when bought and add up to every base stat ("lv": "lvl up+" is too wide for
-- a shop card). own defs: an empty inv field would be "" (true)
defs("id,name,price,info,up,inv,aim", "rig,rig,3,+1 to a random face,1,1,place|rigp,rig+,4,+2 to a random face,2,1,place|rigpp,rig++,6,+3 to a random face,3,1,place|lvlup,lv up,6,+1 all base stats,1|lvlupp,lv up+,9,+2 all base stats,2")
-- by tier: gen_offers takes the first 6, 8 or 9 by stage (pick)
item_kinds, item_tiers = names"potion,bomb,token,double,rig,lvlup,rigp,lvlupp,rigpp", split"6,8,9"
-- one of these in every shop
ench_kinds = names"greedy,grower,wild,glass"
