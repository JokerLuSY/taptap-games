# 素材来源

## Ninja Adventure Asset Pack
- 作者：Pixel-boy、AAA
- 页面：https://pixel-boy.itch.io/ninja-adventure-asset-pack
- 许可：CC0 1.0 Universal（原文见 `art/cc0/ninja_adventure/LICENSE.txt`）
- 使用：地图图块 `art/cc0/ninja_adventure/tiles/`（原包 `Backgrounds/Tilesets/Tileset{Floor,Water,Nature,House,VillageAbandoned,Element,Relief}.png`、
  `Backgrounds/Animated/Water Ripples`、`FX/Particle/Fire.png`、`FX/Smoke/Smoke`，未改动，仅改名）

## 地图小人（原创）
- `art/units/fe/*.png` 为本项目原创像素图（GBA 火纹风，整只按阵营上色），源数据在 `tools/pixelart/fe_art.py`，
  用 `python -P -E tools/pixelart/fe_units.py art/units/fe` 重新生成。

## 战斗特写角色（原创）
- `art/combat/fe/<角色>/<动作>.png` 与 `scripts/combat_sets.gd` 由 `tools/pixelart/fe_combat.py` 生成（数据在 `fe_combat_art.py`），
  头、躯干、马身逐像素手画，四肢与武器按骨架姿势栅格化。重新生成：
  `python -P -E tools/pixelart/fe_combat.py art/combat/fe scripts/combat_sets.gd`
- 刀光特效 `art/cc0/ninja_adventure/fx/SlashCurved.png` 来自 Ninja Adventure（CC0，原包 `FX/Attack/SlashCurved`）
