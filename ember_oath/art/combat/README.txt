# combat art (300px sheets)

Path: art/combat/{id}.png — normal 4-frame horizontal strip
      art/combat/{id}_crit.png — crit 4-frame horizontal strip

All sheets are height 300px, transparent RGBA. The canvas bottom edge is the foot line
and is placed on CombatScene.FEET_Y (520) at SHEET_SCALE 1.0.

Layered backdrops live in combat/bg/. Each set is four 1280×720 layers
(sky, mountains, mid, ground_strip), drawn with LINEAR filtering.
Feet stay on CombatScene.FEET_Y (520). Unlisted terrain chars use the color-block fallback.

- grass (`.` `H` `W`): sky_grass.png, mountains_grass.png, mid_grass.png, ground_strip_grass.png
- forest (`F`): sky_forest.png, mountains_forest.png, mid_forest.png, ground_strip_forest.png
- scorch (`f` `B`, chapter-2 scorched ground): sky_scorch.png, mountains_scorch.png, mid_scorch.png, ground_strip_scorch.png
