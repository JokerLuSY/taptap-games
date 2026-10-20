# 素材来源

## Ninja Adventure Asset Pack
- 作者：Pixel-boy、AAA
- 页面：https://pixel-boy.itch.io/ninja-adventure-asset-pack
- 许可：CC0 1.0 Universal（原文见 `art/cc0/ninja_adventure/LICENSE.txt`）
- 使用：地图图块 `art/cc0/ninja_adventure/tiles/`（原包 `Backgrounds/Tilesets/Tileset{Floor,Water,Nature,House,VillageAbandoned,Element,Relief,Dungeon}.png`、`tileset_camp.png`（改名 TilesetCamp.png）、`Interior/TilesetInteriorFloor.png`、`Items/Treasure/BigTreasureChest.png`（改名 Chest.png）、
  `Backgrounds/Animated/Water Ripples`、`FX/Particle/Fire.png`、`FX/Smoke/Smoke`，未改动，仅改名）

## 地图小人（原创）
- `art/units/fe/*.png` 为本项目原创像素图（GBA 火纹风，整只按阵营上色），源数据在 `tools/pixelart/fe_art.py`，
  用 `python -P -E tools/pixelart/fe_units.py art/units/fe` 重新生成。
- 第 2–5 章新角色（哈洛、妮娜、凯因、艾德里克、诺雅、圣焰教会步兵、圣焰骑士、塞拉斯、黑烬佣兵、霍克、巴雷特）的数据在
  `tools/pixelart/fe_art_ch2.py`，同一条命令一起生成；新增固定色 w / v（白布：教会制服、修女头巾），不随阵营变。
- 第二篇新增（加雷斯、灰烬傀儡、天马骑士、囚车）的数据在 `tools/pixelart/fe_art_ch8.py`；每只小人都出蓝 / 红 / 绿（中立）三张。

## 战斗特写角色（原创）
- `art/combat/fe/<角色>/<动作>.png` 与 `scripts/combat_sets.gd` 由 `tools/pixelart/fe_combat.py` 生成（数据在 `fe_combat_art.py`），
  头、躯干、马身逐像素手画，四肢与武器按骨架姿势栅格化。重新生成：
  `python -P -E tools/pixelart/fe_combat.py art/combat/fe scripts/combat_sets.gd`
- 第 2–5 章新角色的战斗特写数据在 `tools/pixelart/fe_combat_art_ch2.py`（同一条命令一起生成），复用第一章的骨架姿势，
  新增部件：披风层（艾德里克、塞拉斯）、盾牌层（巴雷特）、治疗杖武器（诺雅）、细剑 / 阔刃剑刃宽。
- 第二篇新增（加雷斯、灰烬傀儡、天马骑士）的数据在 `tools/pixelart/fe_combat_art_ch8.py`；天马 = 骑马骨架 + 翅膀层。
- 战斗背景（原创）：`art/combat/bg/` 里雪地 / 城镇 / 城堡内 / 山岭 / 河岸五套（sky / mountains / mid / ground_strip 四层）
  由 `python -P -E tools/pixelart/combat_bg.py art/combat/bg` 生成（320×180 逐像素绘制，最近邻放大 4 倍）；草地 / 森林 / 焦土三套是原有正稿
- 检查：`godot --path . res://tools/combat_gallery.tscn` 输出对阵截图和每套条带的全部动作总表 `tools/shots/sheet_<条带>.png`
- 刀光特效 `art/cc0/ninja_adventure/fx/SlashCurved.png` 来自 Ninja Adventure（CC0，原包 `FX/Attack/SlashCurved`）

## 原创像素对话立绘

- `art/portraits/px/*.png` 由 `tools/pixelart/fe_portraits.py`（脸模板 `fe_faces.py`）逐人手绘坐标生成（原创，随项目授权）。

## APP 图标（原创）
- `icon.png` 与 `art/icon/*.png`（安卓传统 / 自适应前景、背景、单色启动图标）由 `python -P -E tools/pixelart/app_icon.py --final .` 生成：64×64 逐像素绘制的「炎刃纹章」（火焰、盾形纹章、剑），最近邻放大。

## 标题主视觉（原创）
- `art/title/key_art.png` 由 `python -P -E tools/pixelart/title_art.py .` 生成：140×180 逐像素绘制的夜空、圣都剪影、燃烧的灰岩村，前景是缇娅的战斗特写待机帧，取中间 94×120 ×3 放大。替换了早期 AI 生成的标题插画（已删除）。

## 游戏内授权声明
- 标题画面右下角【授权声明】：本作原创声明、Ninja Adventure（CC0）、Godot 引擎 MIT 许可与引擎内第三方组件的版权和许可全文（运行时从 `Engine.get_license_text()` / `get_copyright_info()` / `get_license_info()` 读取）。
