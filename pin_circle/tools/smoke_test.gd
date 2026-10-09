extends Node
## 《见缝插针》冒烟测试
## 用法: godot --path pin_circle res://tools/smoke_runner.tscn

var _shot_dir := "res://tools/shots/"
var _failures: Array = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shot_dir))

	var main: Control = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await _frames(8)
	if main.state != main.State.TITLE:
		_failures.append("初始状态应为 TITLE")
	print("DEBUG title stuck_angles=", main._wheel.stuck_angles, " state=", main.state)
	_shot("01_title.png")

	# 开始游戏(用真实输入事件, 覆盖 _input 路径)
	_tap()
	await _frames(4)
	if main.state != main.State.PLAYING:
		_failures.append("真实点击后应进入 PLAYING (_input 路径)")
	if main.remaining != 5:
		_failures.append("第 1 关应有 5 针, 实际 %d" % main.remaining)

	# 插 2 针后截图
	await _shoot_n(main, 2)
	_shot("02_playing.png")
	if main._wheel.stuck_angles.size() != 2:
		_failures.append("应插入 2 针, 实际 %d" % main._wheel.stuck_angles.size())

	# 插完剩余 -> 过关
	await _shoot_n(main, 3)
	await _frames(10)
	if main.state != main.State.CLEAR and main.state != main.State.PLAYING:
		_failures.append("插完后应进入 CLEAR/下一关, 实际状态 %d" % main.state)
	_shot("03_clear.png")
	await get_tree().create_timer(1.4).timeout
	if main.level != 2:
		_failures.append("应进入第 2 关, 实际第 %d 关" % main.level)
	if main.best < 1:
		_failures.append("过关后最佳成绩未更新")

	# 碰撞失败: 停转后在触点角度塞一根针, 再射(避免飞行时间内轮盘转走)
	main._wheel.spinning = false
	var contact := wrapf(90.0 - main._wheel.rotation_degrees, 0.0, 360.0)
	main._wheel.stuck_angles.append(contact)
	main._shoot()
	await get_tree().create_timer(1.2).timeout
	if main.state != main.State.OVER:
		_failures.append("碰撞后应进入 GAME_OVER")
	_shot("04_gameover.png")

	# 重试(真实输入事件)
	_tap()
	await _frames(4)
	if main.state != main.State.PLAYING:
		_failures.append("失败后真实点击应重试")

	# ---- 回归: 死亡动画期间点击的竞态 ----
	# 再次制造碰撞
	main._wheel.spinning = false
	var contact2 := wrapf(90.0 - main._wheel.rotation_degrees, 0.0, 360.0)
	main._wheel.stuck_angles.append(contact2)
	main._shoot()
	await get_tree().create_timer(0.2).timeout  # 死亡动画中, 弹窗未出
	if main.state != main.State.OVER:
		_failures.append("碰撞后应立即进入 OVER")
	_tap()  # 过早点击: 应被忽略, 不应触发重试
	await _frames(4)
	if main.state != main.State.OVER:
		_failures.append("死亡动画期间的点击不应触发重试(竞态回归)")
	await get_tree().create_timer(0.8).timeout  # 等弹窗出现
	if not main._over_overlay.visible:
		_failures.append("失败弹窗未出现")
	_tap()  # 现在点击才应重试
	await _frames(4)
	if main.state != main.State.PLAYING:
		_failures.append("弹窗出现后点击应重试成功")
	if main._over_overlay.visible:
		_failures.append("重试后失败弹窗应关闭")
	# 重试后应能继续射针
	var before: int = main._wheel.stuck_angles.size()
	main._shoot()
	await get_tree().create_timer(0.4).timeout
	if main._wheel.stuck_angles.size() != before + 1:
		_failures.append("重试后无法继续射针")

	# 存档
	if not FileAccess.file_exists("user://pin_save.json"):
		_failures.append("存档文件未生成")

	print("========================================")
	if _failures.is_empty():
		print("SMOKE TEST: ALL PASS")
	else:
		print("SMOKE TEST: %d FAILURES" % _failures.size())
		for f in _failures:
			print("  FAIL: " + f)
	get_tree().quit()


func _tap() -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(540, 1200)
	Input.parse_input_event(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(540, 1200)
	Input.parse_input_event(release)


func _shoot_n(main: Control, n: int) -> void:
	for i in n:
		main._shoot()
		await get_tree().create_timer(0.35).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(file_name: String) -> void:
	var img := get_tree().root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(_shot_dir + file_name))
	print("截图: " + file_name)
