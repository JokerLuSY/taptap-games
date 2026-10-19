extends Node
## 单存档位 user://save.cfg（ConfigFile + JSON 载荷）。
##
## 载荷里 campaign 是跨章节的战役进度（当前章节、队伍名单、金钱、战役旗标、各章开场快照，见 Campaign）。
## 两种存档点：
## - 章节检查点：每个我方回合开始、回合剧情放完进入 IDLE 时写入，带本章全部单位状态和章节旗标。
##   「继续游戏」回到该回合开始，不重播本回合已经放过的剧情。
## - 章节开场：章节胜利后写入下一章的开场（units 为空），「继续游戏」从下一章开头打起。
## 新游戏：标题上若已有存档，必须确认后才删除存档并从头开始。


const PATH := "user://save.cfg"
const CHAPTER_ID := "ch1"

var pending_load := false


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func is_cleared() -> bool:
	if not has_save():
		return false
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return false
	return bool(cfg.get_value("save", "cleared", false))


func clear() -> void:
	pending_load = false
	if not has_save():
		return
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.remove("save.cfg")


func request_continue() -> void:
	pending_load = true


func take_pending_load() -> bool:
	var want := pending_load and has_save()
	pending_load = false
	return want


func read() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return {}
	var parsed = JSON.parse_string(str(cfg.get_value("save", "payload", "")))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func write_checkpoint(battle) -> void:
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
	_write(payload)


## 章节开场存档：章节胜利后（或重开本关）写入，继续游戏从这一章开头打起
func write_chapter_start() -> void:
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
	cfg.load(PATH)
	cfg.set_value("save", "chapter_id", str(payload.get("chapter_id", CHAPTER_ID)))
	cfg.set_value("save", "turn", int(payload.get("turn", 1)))
	cfg.set_value("save", "cleared", bool(payload.get("cleared", false)))
	cfg.set_value("save", "payload", JSON.stringify(payload))
	cfg.save(PATH)
