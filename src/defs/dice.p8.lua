
-- 6 faces: basic
classic = {name="classic", faces={0,1,2,3,4,5}, price=10, colors={7,6}}   -- avg 2.5
stairs  = {name="stairs",  faces={1,1,2,2,3,3}, price=8,  colors={12,1}}  -- avg 2.0, no zeros
jackpot = {name="jackpot", faces={0,0,0,1,2,8}, price=7,  colors={10,9}}  -- avg 1.8
lotto   = {name="lotto",   faces={0,0,0,0,0,10},price=6,  colors={10,2}}  -- avg 1.7, one face only
gambler = {name="gambler", faces={0,0,0,4,4,4}, price=8,  colors={9,4}}   -- avg 2.0

-- 6 faces: strong
crit    = {name="crit",    faces={1,1,2,2,3,9}, price=12, colors={10,4}}  -- avg 3.0
anvil   = {name="anvil",   faces={3,3,3,3,3,3}, price=13, colors={11,1}}  -- avg 3.0
loaded  = {name="loaded",  faces={0,0,5,5,5,5}, price=14, colors={9,2}}   -- avg 3.3
hero    = {name="hero",    faces={2,3,3,4,4,5}, price=15, colors={7,13}}  -- avg 3.5
titan   = {name="titan",   faces={3,4,4,5,5,6}, price=20, colors={7,10}}  -- avg 4.5

-- 3 faces: basic
blank   = {name="blank",   faces={0,0,0},       price=3,  colors={6,1}}   -- avg 0, upgrades only
chip    = {name="chip",    faces={0,1,1},       price=5,  colors={6,5}}   -- avg 0.7
spike   = {name="spike",   faces={0,0,3},       price=6,  colors={8,2}}   -- avg 1.0
solid   = {name="solid",   faces={1,1,1},       price=7,  colors={11,3}}  -- avg 1.0
pair    = {name="pair",    faces={1,1,2},       price=8,  colors={15,4}}  -- avg 1.3

-- 3 faces: strong
fang    = {name="fang",    faces={0,0,6},       price=10, colors={8,14}}  -- avg 2.0
brick   = {name="brick",   faces={2,2,3},       price=12, colors={11,13}} -- avg 2.3
crown   = {name="crown",   faces={2,3,4},       price=15, colors={15,10}} -- avg 3.0
pillar  = {name="pillar",  faces={3,3,3},       price=16, colors={11,10}} -- avg 3.0

function die_type(def)
	local die = merge({name="classic", faces={1,2,3,4,5,6}, price=5, colors={7,6}}, def)
end
