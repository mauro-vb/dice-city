-- dice: drawn with pips, 0 shows as an x (faces without a pip layout print);
-- 8 faces draw as a circle with numbers. col = body colour before rolling.
-- every kind is offered equally often: price is what makes a die rare.
-- prices (see tools/balance.py): 2 coins per point of average above 1.5,
-- since an unused die pays its roll back every won fight; +1 for a high max
-- face (breaks a def), -1 for a swingy die (loses races)
defs("id,name,faces,price,col", "d3,d3,1;2;3,1,6|d6,d6,1;2;3;4;5;6,4,6|d6g,gambler,0;0;0;6;6;6,3,6|d3p,d3+,3;4;5,5,6|d8,d8,1;2;3;4;5;6;7;8,6,15|d3pp,d3++,4;5;6,7,15")
dice_kinds = names"d3,d6,d6g,d3p,d8,d3pp"
