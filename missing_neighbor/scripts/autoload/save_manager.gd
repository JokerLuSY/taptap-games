extends Node
## SaveManager: 读写 user://save.json (关卡进度、已获证据、结局是否看过)

const SAVE_PATH := "user://save.json"


func save_game() -> void:
	var data := {
		"level": GameState.current_level,
		"collected": GameState.collected,
		"ending_seen": GameState.ending_seen,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("无法写入存档: " + SAVE_PATH)
		return
	f.store_string(JSON.stringify(data, "  "))
	f.close()


func load_game() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return {}


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func clear_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
