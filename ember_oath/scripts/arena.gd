class_name Arena
## 竞技场（火纹式）：大战前的出击准备里开放。选一个人、付押金，和一个同等级的对手单挑。
## 一回合一次交锋（战斗特写照常播放），直到一方倒下；6 回合还没分出胜负算平局退押金。
## 赢了拿回 1.5 倍押金 + 经验；输了不会死（HP 剩 1），押金没收。打完 HP 回满（还没开战）。

## 开放竞技场的章节（大战之前 / 城镇章节）
const CHAPTERS := [7, 11, 12, 13, 16, 21, 22, 26, 29, 30]
const MAX_ROUNDS := 6
## 每次出击准备最多挑战几场（防止无限刷钱刷经验）
const MAX_FIGHTS := 3
## 赢一场的经验：等于同等级击破（10 + 15）
const WIN_XP := 25

## 对手职业：近身 / 远程各一组，按出战者能打到的距离挑
const MELEE := [["剑士", "sword"], ["佣兵", "sword"], ["战士", "axe"], ["枪兵", "lance"], ["山贼", "axe"]]
const RANGED := [["弓箭手", "bow"], ["魔道士", "anima"]]
const WEAPON_BY_TIER := {
	"sword": ["iron_sword", "steel_sword", "silver_sword"],
	"axe": ["iron_axe", "steel_axe", "silver_axe"],
	"lance": ["iron_lance", "steel_lance", "silver_lance"],
	"bow": ["iron_bow", "steel_bow", "silver_bow"],
	"anima": ["fire", "thunder", "elfire"],
}


static func open_in(ch: int) -> bool:
	return ch in CHAPTERS


## 押金：100 + 实际等级 × 25（上级职业按 +20 级算）
static func wager(u: Unit) -> int:
	return 100 + effective_level(u) * 25


static func effective_level(u: Unit) -> int:
	return u.level + GameData.level_bonus(u.class_label)


## 出战者用哪把武器、站多远：能近身就打近身，只能远程就隔一格
static func pick_weapon(u: Unit) -> Array:
	# 魔法隔一格打：配远程对手（原来火焰也被拉去近身，对手照抄施法者的低守备，打不过）
	for wi in u.weapons.size():
		var mw: Dictionary = u.weapon(wi)
		if mw.get("magic", false) and u.can_use(wi) and 2 in mw["rng"]:
			return [wi, 2]
	for wi in u.weapons.size():
		var w: Dictionary = u.weapon(wi)
		if w["type"] == "staff" or not u.can_use(wi):
			continue
		if 1 in w["rng"]:
			return [wi, 1]
	for wi in u.weapons.size():
		var w: Dictionary = u.weapon(wi)
		if w["type"] != "staff" and u.can_use(wi):
			return [wi, int(w["rng"][0])]
	return [-1, 1]


## 生成对手：和出战者同等级，能力在出战者上下浮动，职业按距离挑
static func make_foe(u: Unit, dist: int) -> Unit:
	var pool: Array = MELEE if dist == 1 else RANGED
	var pick: Array = pool[randi() % pool.size()]
	var eff := effective_level(u)
	var tier := 0 if eff < 12 else (1 if eff < 25 else 2)
	var wpn: String = WEAPON_BY_TIER[pick[1]][tier]
	var def := {
		"id": "arena_foe", "name": "竞技场斗士", "class": pick[0], "faction": "enemy", "level": u.level,
		"hp": maxi(16, u.max_hp + randi_range(-2, 2)),
		"pwr": maxi(3, u.pwr + randi_range(-1, 1)), "skl": maxi(3, u.skl + randi_range(-1, 1)),
		"spd": maxi(3, u.spd + randi_range(-1, 1)), "dfn": maxi(1, u.dfn + randi_range(-1, 1)),
		"res": maxi(1, u.res + randi_range(-1, 1)), "mov": 5,
		"weapons": [wpn], "wexp": {pick[1]: 251},
		"color": Color(0.55, 0.5, 0.45), "hair": "short", "armor": Color(0.5, 0.45, 0.4),
	}
	var f := Unit.new()
	f.setup(def)
	return f
