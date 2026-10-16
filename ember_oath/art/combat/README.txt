# combat art

Pixel strips (earliest-style, tia_sword and bandit_axe only):
- art/combat/{id}.png — normal 4-frame horizontal strip
- art/combat/{id}_crit.png — crit strip, frame order 1,2,2,3
Feet come from CombatScene.FRAME_FEET and land on FEET_Y (520). Sprites scale to
SPRITE_TARGET_H (154) with nearest filtering. Other classes stay procedural.

Layered backdrops live in combat/bg/. Each set is four 1280×720 layers
(sky, mountains, mid, ground_strip), drawn with LINEAR filtering.
Feet stay on CombatScene.FEET_Y (520). Unlisted terrain chars use the color-block fallback.

- grass (`.` `H` `W`): sky_grass.png, mountains_grass.png, mid_grass.png, ground_strip_grass.png
- forest (`F`): sky_forest.png, mountains_forest.png, mid_forest.png, ground_strip_forest.png
- scorch (`f` `B`, chapter-2 scorched ground): sky_scorch.png, mountains_scorch.png, mid_scorch.png, ground_strip_scorch.png
