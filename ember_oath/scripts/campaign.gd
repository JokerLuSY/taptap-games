class_name Campaign
## 跨章节的战役进度：当前章节、我方队伍名单、金钱、战役旗标。
##
## 队伍名单 roster = {unit_id: 单位存档字典 + "status"}，status 为
##   active 在队 / away 暂时离队（剧情）/ dead 阵亡（永久死亡）。
## 每章开场按名单生成我方单位；章节胜利时把存活的我方单位写回名单。
## starts 记下每章开场时的快照，供「重开本关」和标题的章节选择回到那一章开头。

const CHAPTERS := [
	"res://scripts/chapter1.gd",
	"res://scripts/chapter2.gd",
	"res://scripts/chapter3.gd",
	"res://scripts/chapter4.gd",
	"res://scripts/chapter5.gd",
]

static var chapter_index := 0
static var roster := {}
static var gold := 0
static var flags := {}
static var starts := {}             # {章节序号(字符串): 开场快照}


static func reset() -> void:
	chapter_index = 0
	roster = {}
	gold = 0
	flags = {}
	starts = {}
	snapshot_start()


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


## 章节胜利：存活的我方写回名单（满血、未行动），阵亡的标记 dead
static func store_party(units: Array) -> void:
	for u in units:
		if not u.is_player():
			continue
		var data: Dictionary = u.to_save()
		var keep := str(roster.get(u.unit_id, {}).get("status", "active"))
		if not u.is_alive():
			data["status"] = "dead"
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
	}


static func from_dict(d: Dictionary) -> void:
	chapter_index = int(d.get("chapter_index", 0))
	var r = d.get("roster", {})
	roster = r.duplicate(true) if r is Dictionary else {}
	gold = int(d.get("gold", 0))
	var f = d.get("flags", {})
	flags = f.duplicate(true) if f is Dictionary else {}
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
