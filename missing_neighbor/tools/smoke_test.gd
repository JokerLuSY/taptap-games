extends Node
## 冒烟测试: 校验关卡 JSON + 驱动真实场景截图
## 用法(窗口模式运行, 覆盖主场景, Autoload 正常注册):
##   godot --path missing_neighbor res://tools/smoke_runner.tscn
## 截图输出到 missing_neighbor/tools/shots/

var _shot_dir := "res://tools/shots/"
var _failures: Array = []
var _flag_failed := false
var _flag_solved := false
var _flag_flash := false


func _on_test_flash() -> void:
	_flag_flash = true


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shot_dir))
	_validate_levels()
	_validate_save_system()
	await _drive_scenes()
	SaveManager.clear_save()
	print("========================================")
	if _failures.is_empty():
		print("SMOKE TEST: ALL PASS")
	else:
		print("SMOKE TEST: %d FAILURES" % _failures.size())
		for f in _failures:
			print("  FAIL: " + f)
	get_tree().quit()


# ---------------- 数据校验 ----------------

func _validate_levels() -> void:
	for i in range(1, 13):
		var path := "res://data/levels/level_%02d.json" % i
		if not FileAccess.file_exists(path):
			_failures.append("缺少关卡文件: " + path)
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) != TYPE_DICTIONARY:
			_failures.append("level_%02d JSON 解析失败" % i)
			continue
		for field in ["id", "title", "bg", "intro", "hotspots", "evidences", "board"]:
			if not data.has(field):
				_failures.append("level_%02d 缺字段: %s" % [i, field])
		if not FileAccess.file_exists(data.get("bg", "")):
			_failures.append("level_%02d 背景图缺失: %s" % [i, data.get("bg", "?")])
		var ev_ids: Array = []
		for ev in data.get("evidences", []):
			ev_ids.append(ev.get("id", ""))
			if not FileAccess.file_exists(ev.get("icon", "")):
				_failures.append("level_%02d 图标缺失: %s" % [i, ev.get("icon", "?")])
		var required_count := 0
		for h in data.get("hotspots", []):
			if not ev_ids.has(h.get("evidence_id", "")):
				_failures.append("level_%02d 热点 %s 指向不存在的证据" % [i, h.get("id", "?")])
			if h.get("required", false):
				required_count += 1
		if required_count != 1:
			_failures.append("level_%02d 必得证据数量=%d (应为1)" % [i, required_count])
		var board: Dictionary = data.get("board", {})
		var slots: Array = board.get("slots", [])
		var solution: Array = board.get("solution", [])
		if slots.size() != solution.size():
			_failures.append("level_%02d slots 与 solution 数量不一致" % i)
		for sol in solution:
			for ev_id in sol:
				if not ev_ids.has(ev_id):
					_failures.append("level_%02d solution 引用不存在的证据: %s" % [i, ev_id])
		for field in ["success_line", "fail_line"]:
			if not board.has(field):
				_failures.append("level_%02d board 缺字段: %s" % [i, field])
	print("关卡 JSON 校验完成")


func _validate_save_system() -> void:
	GameState.start_new_game()
	GameState.collect(1, "test_evidence")
	SaveManager.save_game()
	var data := SaveManager.load_game()
	if int(data.get("level", -1)) != 1:
		_failures.append("存档 level 字段错误")
	var c: Dictionary = data.get("collected", {})
	if not c.get("1", []).has("test_evidence"):
		_failures.append("存档 collected 字段错误")
	SaveManager.clear_save()
	if SaveManager.has_save():
		_failures.append("清除存档失败")
	print("存档系统校验完成")


# ---------------- 场景驱动与截图 ----------------

func _drive_scenes() -> void:
	# 主菜单
	var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	await _frames(8)
	_shot("01_menu.png")
	menu.queue_free()
	await _frames(2)

	# 游戏场景: 关 1
	GameState.start_new_game()
	var game: Control = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child(game)
	await _frames(10)
	_shot("02_level1.png")

	var lv: Control = _find_child_by_name(game, "LevelView")
	if lv == null:
		_failures.append("找不到 LevelView")
		return

	# 点击第一个热点(必得证据) -> 获得弹窗
	lv._on_hotspot_pressed(lv._hotspots[0])
	await _frames(6)
	_shot("03_obtain.png")

	# 关掉弹窗 -> 自动打开线索板
	lv._close_obtain()
	await _frames(90)
	_shot("04_board.png")

	# 背包
	lv._board.visible = false
	lv._open_inventory()
	await _frames(6)
	_shot("05_inventory.png")
	lv._inventory.visible = false
	lv._board.visible = true
	await _frames(4)

	# ---- Milestone B: 线索板配对 ----
	var board: Control = lv._board
	_flag_failed = false
	_flag_solved = false
	board.failed.connect(func() -> void: _flag_failed = true)
	board.solved.connect(func() -> void: _flag_solved = true)
	# 错误配对(装饰证据 -> 槽位): 应触发 failed
	board._try_place("plate_01", 0)
	await _frames(4)
	if not _flag_failed:
		_failures.append("错误配对未触发 failed 信号")
	if lv._solved:
		_failures.append("错误配对后不应 solved")
	# 正确配对: 用真实输入事件模拟拖拽 note_01 -> 槽位 0
	var btn: Button = board._shelf_buttons.get("note_01")
	if btn == null:
		_failures.append("货架上找不到 note_01 按钮")
	else:
		var from: Vector2 = btn.get_global_rect().get_center()
		var zone: PanelContainer = board._slots[0].zone
		var to: Vector2 = zone.get_global_rect().get_center()
		print("DIAG btn_rect=", btn.get_global_rect(), " zone_rect=", zone.get_global_rect(), " window=", DisplayServer.window_get_size())
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = from
		Input.parse_input_event(press)
		await _frames(3)
		if board._drag_preview == null:
			print("DIAG viewport pick missed, emit gui_input directly")
			btn.gui_input.emit(press)
			await _frames(3)
		if board._drag_preview == null:
			_failures.append("拖拽未开始: press 未命中货架按钮")
		for t in 5:
			var motion := InputEventMouseMotion.new()
			motion.position = from.lerp(to, (t + 1) / 5.0)
			board._input(motion)
			await _frames(2)
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		release.position = to
		board._input(release)
		await _frames(40)
		if not _flag_solved:
			board._try_place("note_01", 0)
			await _frames(40)
			if _flag_solved:
				_failures.append("拖拽路径失败(直接调用判定成功)")
			else:
				_failures.append("正确配对判定本身失败")
		if not lv._solved:
			_failures.append("关卡未标记 solved")
		_shot("06_board_solved.png")
	await _frames(160)  # 等待过关旁白与 level_finished
	_shot("07_success.png")
	print("场景驱动完成")

	# ---- Milestone C: 垂直切片 5/10/12 ----
	lv.level_finished.disconnect(game._on_level_finished)
	for level_id in [5, 10, 12]:
		lv.load_level(level_id)
		await _frames(8)
		var req: Hotspot = null
		for hs in lv._hotspots:
			if hs.required:
				req = hs
		if req == null:
			_failures.append("level %d 没有必得热点" % level_id)
			continue
		lv._on_hotspot_pressed(req)
		await _frames(4)
		lv._close_obtain()
		await _frames(90)
		lv._board._try_place(req.evidence_id, 0)
		await _frames(50)
		if not lv._solved:
			_failures.append("level %d 切片未能通关" % level_id)
		_shot("08_level%02d.png" % level_id)

	# ---- Milestone C: 存档续玩 ----
	GameState.set_level(10)
	SaveManager.save_game()
	GameState.current_level = 1
	GameState.collected = {}
	GameState.continue_game()
	if GameState.current_level != 10:
		_failures.append("读档后关卡应为 10, 实际 %d" % GameState.current_level)
	if not GameState.is_collected(12, "id_card"):
		_failures.append("读档后证据丢失")

	# ---- Milestone D: 提示系统(缩短计时器验证) ----
	GameState._idle_timer.wait_time = 0.2
	GameState._board_timer.wait_time = 0.2
	_flag_flash = false
	if not GameState.hint_flash_requested.is_connected(_on_test_flash):
		GameState.hint_flash_requested.connect(_on_test_flash)
	lv.load_level(2)
	await _frames(8)
	lv._hide_narration()
	await _frames(40)  # 约 0.66s 无操作: 应已触发描边闪烁
	if not _flag_flash:
		_failures.append("无操作未触发热点描边闪烁")
	await _frames(40)  # 再 0.66s: 应自动打开线索板并高亮
	if not lv._board.visible:
		_failures.append("提示系统未自动打开线索板")
	_shot("09_hint_board.png")
	GameState._idle_timer.wait_time = GameState.HINT_IDLE_SEC
	GameState._board_timer.wait_time = GameState.HINT_BOARD_SEC
	GameState.stop_hint_timers()

	# ---- Milestone E: 结局演出与双选项 ----
	game.queue_free()
	await _frames(4)
	var ending: Control = load("res://scenes/ending.tscn").instantiate()
	get_tree().root.add_child(ending)
	await _frames(8)
	for i in 12:
		ending._advance()
		await _frames(2)
	if not ending._choices.visible:
		_failures.append("结局未出现二选一")
	_shot("10_ending_choice.png")
	ending._on_choice(true)
	await _frames(4)
	for i in 6:
		ending._advance()
		await _frames(2)
	if not ending._back_btn.visible:
		_failures.append("A 结局未出现返回按钮")
	if not GameState.ending_seen:
		_failures.append("ending_seen 未标记")
	_shot("11_ending_a.png")
	ending.queue_free()
	await _frames(4)
	# B 选项: NG 字卡
	var ending_b: Control = load("res://scenes/ending.tscn").instantiate()
	get_tree().root.add_child(ending_b)
	await _frames(8)
	for i in 12:
		ending_b._advance()
		await _frames(2)
	ending_b._on_choice(false)
	await _frames(4)
	for i in 6:
		ending_b._advance()
		await _frames(2)
	if not "NG" in ending_b._label.text:
		_failures.append("B 结局未显示 NG 字卡")
	if not ending_b._back_btn.visible:
		_failures.append("B 结局未出现返回按钮")
	_shot("12_ending_b.png")
	ending_b.queue_free()


func _find_child_by_name(node: Node, n: String) -> Node:
	if node.name == n:
		return node
	for c in node.get_children():
		var r := _find_child_by_name(c, n)
		if r != null:
			return r
	return null


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(file_name: String) -> void:
	var img := get_tree().root.get_texture().get_image()
	var path := ProjectSettings.globalize_path(_shot_dir + file_name)
	img.save_png(path)
	print("截图: " + path)
