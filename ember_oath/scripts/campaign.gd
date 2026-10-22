class_name Campaign
## 跨章节的战役进度：当前章节、我方队伍名单、金钱、战役旗标。
##
## 队伍名单 roster = {unit_id: 单位存档字典 + "status"}，status 为
##   active 在队 / away 暂时离队（剧情）/ retired 重伤撤退、转到幕后（剧情里还活着，不能再出击，见 Fates）/
##   dead 阵亡（永久死亡）。
## 每章开场按名单生成我方单位；章节胜利时把存活的我方单位写回名单。
## starts 记下每章开场时的快照，供「重开本关」和标题的章节选择回到那一章开头。

const CHAPTERS := [
	"res://scripts/chapter1.gd",
	"res://scripts/chapter2.gd",
	"res://scripts/chapter3.gd",
	"res://scripts/chapter4.gd",
	"res://scripts/chapter5.gd",
	"res://scripts/chapter6.gd",
	"res://scripts/chapter7.gd",
	"res://scripts/chapter8.gd",
	"res://scripts/chapter9.gd",
	"res://scripts/chapter10.gd",
	"res://scripts/chapter11.gd",
	"res://scripts/chapter12.gd",
	"res://scripts/chapter13.gd",
	"res://scripts/chapter14.gd",
	"res://scripts/chapter15.gd",
	"res://scripts/chapter16.gd",
	"res://scripts/chapter17.gd",
	"res://scripts/chapter18.gd",
	"res://scripts/chapter19.gd",
	"res://scripts/chapter20.gd",
	"res://scripts/chapter21.gd",
	"res://scripts/chapter22.gd",
	"res://scripts/chapter23.gd",
	"res://scripts/chapter24.gd",
	"res://scripts/chapter25.gd",
	"res://scripts/chapter26.gd",
	"res://scripts/chapter27.gd",
	"res://scripts/chapter28.gd",
	"res://scripts/chapter29.gd",
	"res://scripts/chapter30.gd",
]

static var chapter_index := 0
static var roster := {}
static var gold := 0
static var flags := {}
static var starts := {}             # {章节序号(字符串): 开场快照}
static var convoy: Array = []       # 道具库：[[物品 id, 剩余次数], ...]，跨章节保留


static func reset() -> void:
	chapter_index = 0
	roster = {}
	gold = 0
	flags = {}
	starts = {}
	convoy = []
	snapshot_start()


## 休闲模式：倒下的同伴只是撤退，下一章照常归队（主角倒下仍然败北）。开新游戏时选，整个战役不变
static func casual() -> bool:
	return bool(flags.get("casual", false))


static func chapter_count() -> int:
	return CHAPTERS.size()


static func is_finished() -> bool:
	return chapter_index >= CHAPTERS.size()


static func chapter_script(idx := -1) -> Script:
	var i := chapter_index if idx < 0 else idx
	return load(CHAPTERS[clampi(i, 0, CHAPTERS.size() - 1)])


static func index_of(script: Script) -> int:
	if script == null:
		return -1
	return CHAPTERS.find(script.resource_path)


# ==================== 名单 ====================

static func has_member(id: String) -> bool:
	return roster.has(id)


static func status_of(id: String) -> String:
	if not roster.has(id):
		return ""
	return str(roster[id].get("status", "active"))


static func set_status(id: String, status: String) -> void:
	if roster.has(id):
		roster[id]["status"] = status


static func active_ids() -> Array:
	var out: Array = []
	for id in roster:
		if status_of(id) == "active":
			out.append(id)
	return out


## 剧情里还活着（在队 / 暂离 / 转幕后）：台词里可以出现这个人
static func alive_in_story(id: String) -> bool:
	return status_of(id) in ["active", "away", "retired"]


## 能回队：剧情离队中（转幕后、阵亡的都回不来）
static func can_rejoin(id: String) -> bool:
	return status_of(id) == "away"


## 离队的人回队。离队期间不长经验；回队时若低于在队成员平均等级 − 2（上级职业按 +20 级算），
## 按成长率补到那一级。返回补了几级。
static func rejoin(id: String) -> int:
	if not roster.has(id):
		return 0
	var n := catch_up(id)
	roster[id]["status"] = "active"
	return n


## 只补等级、不改状态（中立出场、等被救的离队同伴先补好）
static func catch_up(id: String) -> int:
	if not roster.has(id):
		return 0
	var others: Array = active_ids()
	others.erase(id)
	if others.is_empty():
		return 0
	var total := 0
	for o in others:
		total += effective_level(roster[o])
	var target := int(floor(float(total) / others.size())) - 2
	var d: Dictionary = roster[id]
	var n := 0
	while effective_level(d) < target and int(d.get("level", 1)) < 20:
		_level_up_data(d)
		n += 1
	return n


## 离队很久的人回队：能力至少抬到 floor（章节给的默认数值）。用于第 4 章就离队、第 23 章才回来的巴尔托一行——
## 巴尔托是上级职业，按实际等级算已经「够高」，catch_up 一级都不补，回来还是第 4 章的数值
static func raise_stats_to(id: String, floor: Dictionary) -> void:
	if not roster.has(id) or floor.is_empty():
		return
	var d: Dictionary = roster[id]
	if str(d.get("class", "")) != str(floor.get("class", d.get("class", ""))):
		return
	for k in ["pwr", "skl", "spd", "dfn", "res", "mov"]:
		if floor.has(k):
			d[k] = maxi(int(d.get(k, 0)), int(floor[k]))
	if floor.has("hp"):
		d["max_hp"] = maxi(int(d.get("max_hp", 1)), int(floor["hp"]))
		d["hp"] = d["max_hp"]
	if floor.has("level"):
		d["level"] = maxi(int(d.get("level", 1)), int(floor["level"]))


## 剧情需要：把名单里某人至少补到 lv 级（例如第 8 章艾德里克离开第 3 章后自己也在成长）
static func raise_to(id: String, lv: int) -> int:
	if not roster.has(id):
		return 0
	var d: Dictionary = roster[id]
	var n := 0
	while int(d.get("level", 1)) < mini(lv, 20):
		_level_up_data(d)
		n += 1
	return n


## 实际强度用的等级：上级职业 +20
static func effective_level(d: Dictionary) -> int:
	return int(d.get("level", 1)) + GameData.level_bonus(str(d.get("class", "")))


## 存档字典直接升一级（按成长率）
static func _level_up_data(d: Dictionary) -> void:
	d["level"] = int(d.get("level", 1)) + 1
	d["xp"] = 0
	var g = d.get("growths", {})
	if g is Dictionary:
		for k in g:
			if randf() * 100.0 < float(g[k]):
				if k == "hp":
					d["max_hp"] = int(d.get("max_hp", 20)) + 1
				else:
					d[k] = int(d.get(k, 0)) + 1
	d["hp"] = int(d.get("max_hp", 20))


## 章节胜利：存活的我方写回名单（满血、未行动），阵亡的标记 dead
static func store_party(units: Array) -> void:
	for u in units:
		if not u.is_player():
			continue
		var data: Dictionary = u.to_save()
		var keep := str(roster.get(u.unit_id, {}).get("status", "active"))
		if not u.is_alive() and not casual():
			data["status"] = "retired" if u.get_meta("retreated", false) else "dead"
		else:
			data["hp"] = data["max_hp"]
			data["has_acted"] = false
			data["alive"] = true
			data["status"] = "away" if keep == "away" else "active"
		roster[u.unit_id] = data


## 章节胜利后推进到下一章并记下开场快照
static func advance(battle_gold: int) -> void:
	gold = battle_gold
	chapter_index += 1
	snapshot_start()


static func snapshot_start() -> void:
	starts[str(chapter_index)] = {
		"roster": roster.duplicate(true),
		"gold": gold,
		"flags": flags.duplicate(true),
		"convoy": convoy.duplicate(true),
	}


## 回到某章开场时的状态（重开本关、章节选择）
static func restore_start(idx: int) -> bool:
	var snap = starts.get(str(idx))
	if not snap is Dictionary:
		return false
	chapter_index = idx
	roster = (snap.get("roster", {}) as Dictionary).duplicate(true)
	gold = int(snap.get("gold", 0))
	flags = (snap.get("flags", {}) as Dictionary).duplicate(true)
	var cv = snap.get("convoy", [])
	convoy = cv.duplicate(true) if cv is Array else []
	# 之后的章节快照作废：从这一章重新打起
	for k in starts.keys():
		if int(k) > idx:
			starts.erase(k)
	return true


static func reached() -> Array:
	var out: Array = []
	for k in starts:
		var i := int(k)
		if i < CHAPTERS.size():
			out.append(i)
	out.sort()
	return out


# ==================== 存档 ====================

static func to_dict() -> Dictionary:
	return {
		"chapter_index": chapter_index,
		"roster": roster.duplicate(true),
		"gold": gold,
		"flags": flags.duplicate(true),
		"starts": starts.duplicate(true),
		"convoy": convoy.duplicate(true),
	}


static func from_dict(d: Dictionary) -> void:
	chapter_index = int(d.get("chapter_index", 0))
	var r = d.get("roster", {})
	roster = r.duplicate(true) if r is Dictionary else {}
	gold = int(d.get("gold", 0))
	var f = d.get("flags", {})
	flags = f.duplicate(true) if f is Dictionary else {}
	var cv = d.get("convoy", [])
	convoy = cv.duplicate(true) if cv is Array else []
	var s = d.get("starts", {})
	starts = s.duplicate(true) if s is Dictionary else {}
	if starts.is_empty():
		snapshot_start()


## 读入存档载荷。旧版（只有第一章、没有 campaign 字段）按第一章处理。
static func load_payload(payload: Dictionary) -> void:
	var c = payload.get("campaign", null)
	if c is Dictionary:
		from_dict(c)
		return
	reset()
