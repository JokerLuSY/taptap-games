extends Node
## 单存档位 user://save.cfg（ConfigFile + JSON 载荷）。
##
## 续关模型：每个我方回合开始、开场/回合剧情结束并进入 IDLE 时自动写检查点
## （章节 id、回合、金钱、单位状态、章节旗标、支援点）。中途退出后「继续游戏」
## 回到该回合开始，不重播本回合已经放过的剧情。
## 章节胜利只把 meta/cleared 标为 true，不改写单位快照（目前没有第二章，
## 继续游戏会从获胜那一回合的开始重打）。
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
		"chapter_id": CHAPTER_ID,
		"turn": int(battle.turn),
		"gold": int(battle.gold),
		"cleared": false,
		"support_points": battle.support_points.duplicate(true),
		"flags": battle.chapter.export_flags(),
		"units": units_data,
	}
	_write(payload)


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
