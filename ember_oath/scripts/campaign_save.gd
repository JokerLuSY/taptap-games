extends Node
## 单存档位 user://save.cfg（ConfigFile + JSON 载荷）。
##
## 载荷里 campaign 是跨章节的战役进度（当前章节、队伍名单、金钱、战役旗标、各章开场快照，见 Campaign）。
## 两种存档点：
## - 章节检查点：每个我方回合开始、回合剧情放完进入 IDLE 时写入，带本章全部单位状态和章节旗标。
##   「继续游戏」回到该回合开始，不重播本回合已经放过的剧情。
## - 章节开场：章节胜利后写入下一章的开场（units 为空），「继续游戏」从下一章开头打起。
## 新游戏：标题上若已有存档，必须确认后才删除存档并从头开始。
## - 中断存档：切到后台 / 退出时写入（suspend = true），带上本回合开始的快照 turn_start，
##   这样「继续游戏」回到切出去的那一刻，「重来本回合」仍回到回合开始。
## 写入是原子的：先写 save.cfg.tmp，旧档挪成 save.cfg.bak，再把 tmp 改名过去；读不到主档就读备份。


const PATH := "user://save.cfg"
const FILE := "save.cfg"
const TMP := "save.cfg.tmp"
const BAK := "save.cfg.bak"
const CHAPTER_ID := "ch1"

var pending_load := false
## 下一次 read() 返回本回合开始的快照（重来本回合）
var _want_turn_start := false
## 最近一次回合开始检查点（内存里留一份，中断存档时附上）
var _turn_start := {}


func has_save() -> bool:
	return FileAccess.file_exists(PATH) or FileAccess.file_exists("user://" + BAK)


## 主档坏了 / 不在就读备份
func _load_cfg() -> ConfigFile:
	for f in [FILE, BAK]:
		var cfg := ConfigFile.new()
		if cfg.load("user://" + f) == OK and str(cfg.get_value("save", "payload", "")) != "":
			return cfg
	return null


func is_cleared() -> bool:
	var cfg := _load_cfg()
	return cfg != null and bool(cfg.get_value("save", "cleared", false))


func clear() -> void:
	pending_load = false
	_want_turn_start = false
	_turn_start = {}
	var dir := DirAccess.open("user://")
	if dir != null:
		for f in [FILE, TMP, BAK]:
			if dir.file_exists(f):
				dir.remove(f)


func request_continue() -> void:
	pending_load = true


## 重来本回合：读档时取回合开始的快照
func request_restart_turn() -> void:
	pending_load = true
	_want_turn_start = true


func take_pending_load() -> bool:
	var want := pending_load and has_save()
	pending_load = false
	if not want:
		_want_turn_start = false
	return want


func _read_raw() -> Dictionary:
	var cfg := _load_cfg()
	if cfg == null:
		return {}
	var parsed = JSON.parse_string(str(cfg.get_value("save", "payload", "")))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func read() -> Dictionary:
	var data := _read_raw()
	if _want_turn_start:
		_want_turn_start = false
		var ts := _turn_start_of(data)
		if not ts.is_empty():
			return ts
	return data


## 这份存档对应的回合开始快照：本身就是回合开始的就是它自己
func _turn_start_of(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	if not bool(data.get("suspend", false)):
		return data if not (data.get("units", []) as Array).is_empty() else {}
	var ts = data.get("turn_start", {})
	return ts if ts is Dictionary else {}


## 本章能不能「重来本回合」（有这一章的回合开始检查点）
func can_restart_turn(chapter_id: String) -> bool:
	var ts := _turn_start if not _turn_start.is_empty() else _turn_start_of(_read_raw())
	return not ts.is_empty() and str(ts.get("chapter_id", "")) == chapter_id


## suspend = true：中断存档（回合中途），不覆盖回合开始快照
func write_checkpoint(battle, suspend := false) -> void:
	if battle == null or battle.units.is_empty():
		return
	var units_data: Array = []
	for u in battle.units:
		units_data.append(u.to_save())
	var payload := {
		"chapter_id": str(battle.chapter.chapter_id()),
		"turn": int(battle.turn),
		"gold": int(battle.gold),
		"cleared": false,
		"support_points": battle.support_points.duplicate(true),
		"flags": battle.chapter.export_flags(),
		"units": units_data,
		"campaign": Campaign.to_dict(),
	}
	if suspend:
		var ts := _turn_start if not _turn_start.is_empty() else _turn_start_of(_read_raw())
		if str(ts.get("chapter_id", "")) != payload["chapter_id"]:
			ts = {}
		payload["suspend"] = true
		payload["turn_start"] = ts
	else:
		_turn_start = payload.duplicate(true)
	_write(payload)


## 章节开场存档：章节胜利后（或重开本关）写入，继续游戏从这一章开头打起
func write_chapter_start() -> void:
	_turn_start = {}
	var payload := {
		"chapter_id": chapter_id_of(Campaign.chapter_index),
		"turn": 1,
		"gold": Campaign.gold,
		"cleared": Campaign.is_finished(),
		"support_points": {},
		"flags": {},
		"units": [],
		"campaign": Campaign.to_dict(),
	}
	_write(payload)


static func chapter_id_of(idx: int) -> String:
	if idx >= Campaign.chapter_count():
		return "done"
	return "ch%d" % (idx + 1)


func mark_cleared() -> void:
	var data := read()
	if data.is_empty():
		return
	data["cleared"] = true
	_write(data)


func _write(payload: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "chapter_id", str(payload.get("chapter_id", CHAPTER_ID)))
	cfg.set_value("save", "turn", int(payload.get("turn", 1)))
	cfg.set_value("save", "cleared", bool(payload.get("cleared", false)))
	cfg.set_value("save", "payload", JSON.stringify(payload))
	var dir := DirAccess.open("user://")
	if dir == null:
		cfg.save(PATH)
		return
	# 先完整写出临时文件；写一半被杀进程时旧档还在
	if cfg.save("user://" + TMP) != OK:
		return
	if dir.file_exists(FILE):
		if dir.file_exists(BAK):
			dir.remove(BAK)
		dir.rename(FILE, BAK)
	if dir.rename(TMP, FILE) != OK:
		cfg.save(PATH)
