extends Node
## GameState: 当前关卡、已获证据、提示计时、UI 文案

signal evidence_collected(level_id: int, evidence_id: String)
signal level_started(level_id: int)
signal hint_flash_requested
signal hint_board_requested

const TOTAL_LEVELS := 12
const HINT_IDLE_SEC := 90.0    ## 无操作 90 秒: 热点描边闪一次
const HINT_BOARD_SEC := 60.0   ## 再无进展 60 秒: 线索板自动打开并高亮

var current_level: int = 1
var collected: Dictionary = {}  ## "1" -> ["note_01", ...]
var ending_seen: bool = false
var ui_strings: Dictionary = {}

var _idle_timer: Timer
var _board_timer: Timer


func _ready() -> void:
	ui_strings = load_json("res://data/strings/ui_zh.json")
	_idle_timer = Timer.new()
	_idle_timer.one_shot = true
	_idle_timer.wait_time = HINT_IDLE_SEC
	_idle_timer.timeout.connect(_on_idle_timeout)
	add_child(_idle_timer)
	_board_timer = Timer.new()
	_board_timer.one_shot = true
	_board_timer.wait_time = HINT_BOARD_SEC
	_board_timer.timeout.connect(_on_board_timeout)
	add_child(_board_timer)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		reset_idle_timer()
	elif event is InputEventScreenTouch and event.pressed:
		reset_idle_timer()
	elif event is InputEventKey and event.pressed:
		reset_idle_timer()


static func load_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("无法读取 JSON: " + path)
		return null
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return data


func ui_text(key: String) -> String:
	return str(ui_strings.get(key, key))


func start_new_game() -> void:
	current_level = 1
	collected = {}
	SaveManager.save_game()
	level_started.emit(current_level)


func continue_game() -> void:
	var data := SaveManager.load_game()
	current_level = int(data.get("level", 1))
	collected = data.get("collected", {})
	ending_seen = bool(data.get("ending_seen", false))


func set_level(n: int) -> void:
	current_level = n
	SaveManager.save_game()
	level_started.emit(n)


func collect(level_id: int, ev_id: String) -> bool:
	var key := str(level_id)
	if not collected.has(key):
		collected[key] = []
	if ev_id in collected[key]:
		return false
	collected[key].append(ev_id)
	evidence_collected.emit(level_id, ev_id)
	notify_progress()
	SaveManager.save_game()
	return true


func is_collected(level_id: int, ev_id: String) -> bool:
	return collected.get(str(level_id), []).has(ev_id)


func collected_of(level_id: int) -> Array:
	return collected.get(str(level_id), [])


func mark_ending_seen() -> void:
	ending_seen = true
	SaveManager.save_game()


## 任意输入: 重置 90 秒无操作计时
func reset_idle_timer() -> void:
	_idle_timer.start()


## 有实质进展(获得证据): 重置全部提示计时
func notify_progress() -> void:
	_idle_timer.start()
	_board_timer.stop()


func stop_hint_timers() -> void:
	_idle_timer.stop()
	_board_timer.stop()


func _on_idle_timeout() -> void:
	hint_flash_requested.emit()
	_board_timer.start()


func _on_board_timeout() -> void:
	hint_board_requested.emit()
	_idle_timer.start()
