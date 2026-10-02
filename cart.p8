pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- autoroll
-- by mauro-vb

#include src/oop/class.p8.lua
#include src/oop/game_object.p8.lua
#include src/oop/scene.p8.lua
#include src/ui/button.p8.lua
#include src/ui/focus.p8.lua
#include src/ui/menu.p8.lua
#include src/ui/selectable.p8.lua
#include src/utils/color_settings.p8.lua
#include src/utils/cursor.p8.lua
#include src/utils/helpers.p8.lua
#include src/utils/input.p8.lua
#include src/utils/math.p8.lua
#include src/utils/ptween.p8.lua
#include src/utils/sprite.p8.lua
#include data/myspr.txt
#include src/particles/particle.p8.lua
#include src/particles/particle_ball.p8.lua
#include src/particles/particle_circle.p8.lua
#include src/particles/particle_oval.p8.lua
#include src/particles/particle_rect.p8.lua
#include src/particles/particle_ring.p8.lua
#include src/particles/particle_spark.p8.lua
#include src/particles/particle_sprite.p8.lua
#include src/particles/particle_text.p8.lua
#include src/entities/die.p8.lua
#include src/entities/enemy.p8.lua
#include src/entities/player.p8.lua
#include src/entities/slot.p8.lua
#include src/scenes/combat.p8.lua
#include src/scenes/end.p8.lua
#include src/scenes/placement.p8.lua
#include src/scenes/shop.p8.lua
#include src/scenes/title.p8.lua
#include src/defs/dice.p8.lua
#include src/defs/enemies.p8.lua
#include src/defs/shop_items.p8.lua
#include src/defs/stages.p8.lua
#include src/logic/combat.p8.lua
#include src/logic/economy.p8.lua
#include src/logic/roll.p8.lua
#include src/logic/run.p8.lua
#include src/main.p8.lua

