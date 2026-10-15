extends Node
## 《余烬之誓》第一章冒烟测试
## 用法: godot --path ember_oath res://tools/smoke_runner.tscn   (窗口模式可截图, --headless 仅验证逻辑)

var _shot_dir := "res://tools/shots/"
var _failures: Array = []
var battle


func _ready() -> void:
	_run.call_deferred()
	_watchdog()


## 看门狗：任何脚本错误导致 _run 中断时也能退出，避免挂死
func _watchdog() -> void:
	await get_tree().create_timer(150.0).timeout
	print("WATCHDOG: 超时强制退出")
	print("SMOKE TEST: TIMEOUT, %d FAILURES" % _failures.size())
	for f_ in _failures:
		print("  FAIL: " + f_)
	get_tree().quit(1)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shot_dir))
	battle = load("res://scenes/battle.tscn").instantiate()
	get_tree().root.add_child(battle)
	battle.set_process_unhandled_input(false)
	await _frames(6)
	# 切到缇娅的台词, 截取带立绘的对话框
	battle.dialogue._idx = 1
	battle.dialogue._show_line()
	await get_tree().create_timer(0.8).timeout
	_shot("00_dialogue.png")
	await _skip_story()

	# ---- 初始状态 ----
	_check(battle.state == battle.S.IDLE, "开场剧情后应进入 IDLE, 实际 %d" % battle.state)
	_check(battle.turn == 1, "应为第 1 回合, 实际 %d" % battle.turn)
	_check(battle.units.size() == 11, "初始应有 11 个单位, 实际 %d" % battle.units.size())
	_shot("01_map.png")

	var tia = battle.get_unit("tia")
	var balto = battle.get_unit("balto")
	var bandit = battle.get_unit("bandit1")

	# ---- 移动范围 ----
	battle.click_tile(tia.grid_pos)
	await _frames(2)
	_check(battle.selected == tia, "点击缇娅应选中她")
	_check(battle.move_dict.has(Vector2i(5, 5)), "缇娅应能走到桥 (5,5)")
	_check(not battle.move_dict.has(Vector2i(0, 5)), "缇娅不应能踏进河流 (0,5)")
	_shot("02_move_range.png")
	battle.cancel()
	await _frames(2)
	_check(battle.state == battle.S.IDLE, "取消后应回到 IDLE, 实际 %d" % battle.state)

	# ---- 战斗: 把一个山贼传送到缇娅旁边并压残 ----
	bandit.grid_pos = Vector2i(4, 4)
	bandit.position = bandit.tile_center()
	bandit.hp = 5
	var f: Dictionary = Combat.forecast(tia, bandit, 0, battle.board)
	_check(f["a_dmg"] == 9, "缇娅对山贼伤害应为 9(5+5+剑克斧1-防2), 实际 %d" % f["a_dmg"])
	_check(f["a_times"] == 2, "缇娅应追击(速7 vs 速3)")
	_check(f["a_crit"] == 8, "缇娅必杀率应为 8(技6/2+铁剑5), 实际 %d" % f["a_crit"])
	# 暴击结算: 强制暴击, 伤害应 ×3
	Combat.force_crit = true
	var crit_events := Combat.resolve(tia, bandit, 0, battle.board)
	Combat.force_crit = false
	_check(crit_events[0]["crit"] == true, "强制暴击时事件应标记 crit")
	_check(crit_events[0]["dmg"] == 27, "暴击伤害应为 9×3=27, 实际 %d" % crit_events[0]["dmg"])
	battle.click_tile(tia.grid_pos)
	await _frames(2)
	battle.click_tile(tia.grid_pos)  # 原地 -> 行动菜单
	await _frames(6)
	_check(battle.state == battle.S.ACTION_MENU, "应打开行动菜单, 实际 %d" % battle.state)
	_shot("03_action_menu.png")
	battle._on_menu_attack()
	await _frames(2)
	_check(battle.state == battle.S.TARGET_SEL, "应进入目标选择, 实际 %d" % battle.state)
	battle.click_tile(bandit.grid_pos)
	await _frames(2)
	_check(battle.forecast_panel.visible, "应显示战斗预测面板")
	_shot("04_forecast.png")
	Combat.force_crit = true  # 截一张暴击演出
	battle._on_forecast_ok()
	await get_tree().create_timer(1.05).timeout
	_shot("04b_combat_scene.png")  # 暴击特写演出中
	Combat.force_crit = false
	var ok: bool = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE, 15.0)
	_check(ok, "战斗应结束并回到 IDLE")
	_check(not bandit.is_alive(), "山贼应被缇娅击杀")
	_check(tia.xp > 0, "缇娅应获得经验, 实际 %d" % tia.xp)
	_check(tia.has_acted, "缇娅应已行动")
	_shot("05_after_combat.png")

	# ---- 危险范围开关 ----
	battle.toggle_danger()
	await _frames(2)
	_check(battle.board.danger_tiles.size() > 0, "危险范围应非空")
	battle.toggle_danger()

	# ---- 高度系统 ----
	_check(battle.board.level_at(Vector2i(0, 0)) == 2, "北缘森林应为高地 Lv2")
	_check(battle.board.level_at(Vector2i(5, 5)) == 1, "桥面应为 Lv1")
	# 攀爬消耗: 巴尔托(移7)从 (1,1) 攀上 (1,0) 森林高地 = 2(森林) + 2(爬升) = 4, 剩 3
	balto.grid_pos = Vector2i(1, 1)
	balto.position = balto.tile_center()
	var mr: Dictionary = battle.board.move_range(balto)
	_check(mr.get(Vector2i(1, 0), -99) == 3, "攀爬森林高地后剩余移动力应为 3, 实际 %d" % mr.get(Vector2i(1, 0), -99))
	# 居高临下: 缇娅站 (1,0) Lv2 打 (1,1) Lv1, 伤害 9+1=10
	var bandit2 = battle.get_unit("bandit2")
	bandit2.grid_pos = Vector2i(1, 1)
	bandit2.position = bandit2.tile_center()
	tia.grid_pos = Vector2i(1, 0)
	tia.position = tia.tile_center()
	var f2: Dictionary = Combat.forecast(tia, bandit2, 0, battle.board)
	_check(f2["a_dmg"] == 10, "居高临下伤害应为 10, 实际 %d" % f2["a_dmg"])
	# 高地弓箭手射程 +1
	var archer = battle.get_unit("archer1")
	archer.grid_pos = Vector2i(1, 0)
	archer.position = archer.tile_center()
	_check(battle.board.can_hit_from(archer, 3, 0), "高地弓箭手应能射 3 格")
	archer.grid_pos = Vector2i(1, 1)
	archer.position = archer.tile_center()
	_check(not battle.board.can_hit_from(archer, 3, 0), "平地弓箭手不应能射 3 格")
	# 恢复各单位位置
	tia.grid_pos = Vector2i(4, 3)
	tia.position = tia.tile_center()
	balto.grid_pos = Vector2i(6, 3)
	balto.position = balto.tile_center()
	bandit2.grid_pos = Vector2i(7, 7)
	bandit2.position = bandit2.tile_center()
	archer.grid_pos = Vector2i(6, 8)
	archer.position = archer.tile_center()

	# ---- 支援系统 ----
	_mark("支援系统")
	battle.support_points["tia|balto"] = 6  # 直接灌满点数
	balto.grid_pos = Vector2i(4, 4)
	balto.position = balto.tile_center()
	tia.has_acted = false
	battle.click_tile(tia.grid_pos)
	await _frames(2)
	battle.click_tile(tia.grid_pos)
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.ACTION_MENU, 5.0)
	_check(ok, "缇娅原地应打开行动菜单")
	_check(battle.chapter.get_support_partner(tia) == balto, "缇娅应能对巴尔托使用支援")
	battle._on_menu_support()
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE, 10.0)
	_check(ok, "支援对话后应回到 IDLE")
	_check(tia.support_with.has("balto"), "缇娅应已解锁对巴尔托的支援")
	_check(balto.support_with.has("tia"), "巴尔托应已解锁对缇娅的支援")
	# 支援加成: 缇娅相邻时巴尔托命中 +5（用巴尔托测, 缇娅命中本来溢出100看不清）
	var f3: Dictionary = Combat.forecast(balto, battle.get_unit("bandit2"), 0, battle.board)
	tia.grid_pos = Vector2i(1, 4)
	tia.position = tia.tile_center()
	var f3b: Dictionary = Combat.forecast(balto, battle.get_unit("bandit2"), 0, battle.board)
	_check(f3["a_hit"] == f3b["a_hit"] + 5, "缇娅相邻时巴尔托命中应 +5, %d vs %d" % [f3["a_hit"], f3b["a_hit"]])

	# ---- 说得系统 ----
	_mark("说得系统")
	var bandit6 = battle.get_unit("bandit6")
	bandit6.grid_pos = Vector2i(5, 4)
	bandit6.position = bandit6.tile_center()
	tia.grid_pos = Vector2i(4, 4)
	tia.position = tia.tile_center()
	balto.grid_pos = Vector2i(6, 3)
	balto.position = balto.tile_center()
	tia.has_acted = false
	battle.click_tile(tia.grid_pos)
	await _frames(2)
	battle.click_tile(tia.grid_pos)
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.ACTION_MENU, 5.0)
	_check(ok, "缇娅应再次打开行动菜单")
	_check(battle.chapter.get_recruit_target(tia) == bandit6, "缇娅应能说得山贼小弟")
	battle._on_menu_recruit()
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE, 10.0)
	_check(ok, "说得后应回到 IDLE")
	_check(bandit6.is_player(), "山贼小弟应变成我方")
	# 说得对象挪到安全角落
	bandit6.grid_pos = Vector2i(0, 1)
	bandit6.position = bandit6.tile_center()
	bandit6.has_acted = true
	tia.grid_pos = Vector2i(4, 3)
	tia.position = tia.tile_center()
	tia.has_acted = true

	# ---- 巴尔托移动并待机 -> 自动敌方回合 -> 第 2 回合 ----
	_mark("巴尔托待机+敌方回合")
	battle.click_tile(balto.grid_pos)
	await _frames(2)
	_check(battle.selected == balto, "应选中巴尔托")
	battle.click_tile(Vector2i(5, 4))
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.ACTION_MENU, 5.0)
	_check(ok, "巴尔托移动后应打开行动菜单")
	battle._on_menu_wait()
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE and battle.turn == 2, 40.0)
	_check(ok, "敌方回合后应回到我方第 2 回合, state=%d turn=%d" % [battle.state, battle.turn])
	_check(tia.is_alive() and balto.is_alive(), "第 1 轮敌方回合后我方应全员存活")
	_shot("06_turn2.png")

	# ---- 访问民居（东屋给伤药） ----
	tia.grid_pos = Vector2i(8, 1)
	tia.position = tia.tile_center()
	tia.has_acted = false
	var items_before: int = tia.items.size()
	battle.click_tile(tia.grid_pos)
	await _frames(2)
	battle.click_tile(Vector2i(9, 1))
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.ACTION_MENU, 5.0)
	_check(ok, "走到东屋应打开行动菜单")
	battle._on_menu_visit()
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE, 10.0)
	_check(ok, "访问后应回到 IDLE")
	_check(tia.items.size() == items_before + 1, "访问东屋应获得伤药")

	# ---- 缇娅 ↔ 巴尔托 对话 ----
	balto.grid_pos = Vector2i(9, 2)
	balto.position = balto.tile_center()
	balto.has_acted = false
	battle.click_tile(balto.grid_pos)
	await _frames(2)
	battle.click_tile(balto.grid_pos)  # 原地 -> 菜单
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.ACTION_MENU, 5.0)
	_check(ok, "巴尔托原地应打开行动菜单")
	battle._on_menu_talk()
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE, 10.0)
	_check(ok, "对话后应回到 IDLE")
	_check(battle.chapter.f_talk, "对话事件应已触发")

	# 被说得的山贼小弟也要行动（待机）, 否则无法自动结束回合
	_mark("山贼小弟待机")
	battle.click_tile(bandit6.grid_pos)
	await _frames(2)
	battle.click_tile(bandit6.grid_pos)
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.ACTION_MENU, 5.0)
	_check(ok, "山贼小弟应能被我方操作")
	battle._on_menu_wait()

	# ---- 第 3 回合：敌方增援 ----
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE and battle.turn == 3, 40.0)
	_check(ok, "应进入第 3 回合, state=%d turn=%d" % [battle.state, battle.turn])
	_check(battle.get_unit("bandit_r1") != null, "第 3 回合应有增援 bandit_r1")
	_shot("07_reinforce.png")

	# ---- 胜利: 只留一个残血山贼, 让巴尔托击杀 ----
	for e in battle.units:
		if not e.is_player() and e.is_alive():
			if e.unit_id == "bandit5":
				e.hp = 1
				e.grid_pos = Vector2i(9, 3)
				e.position = e.tile_center()
			else:
				e.take_damage(999)
	balto.grid_pos = Vector2i(9, 2)
	balto.position = balto.tile_center()
	battle.click_tile(balto.grid_pos)
	await _frames(2)
	battle.click_tile(balto.grid_pos)
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.ACTION_MENU, 5.0)
	_check(ok, "巴尔托应打开行动菜单")
	battle._on_menu_attack()
	await _frames(2)
	_check(battle.state == battle.S.WEAPON_SEL, "巴尔托双武器应进入武器选择, 实际 %d" % battle.state)
	battle._on_weapon_chosen(0)  # 银枪
	await _frames(2)
	_check(battle.state == battle.S.TARGET_SEL, "应进入目标选择, 实际 %d" % battle.state)
	var target = battle.get_unit("bandit5")
	battle.click_tile(target.grid_pos)
	await _frames(2)
	_check(battle.forecast_panel.visible, "应显示战斗预测面板")
	battle._on_forecast_ok()
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.OVER, 15.0)
	_check(ok, "击杀最后敌人应进入 OVER")
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 15.0)
	_check(ok, "胜利后应显示结算界面")
	_check("完" in battle.end_title.text, "结算标题应为「第一章 完」, 实际: " + battle.end_title.text)
	_shot("08_victory.png")

	# ---- 战败: 新开一局, 缇娅阵亡 ----
	battle.queue_free()
	await _frames(3)
	await _spawn_battle()
	var tia2 = battle.get_unit("tia")
	tia2.take_damage(999)
	battle.check_end_conditions()  # 异步, 内部会播放战败剧情
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 15.0)
	_check(ok, "缇娅阵亡后应显示结算界面")
	_check(battle.state == battle.S.OVER, "缇娅阵亡应进入 OVER")
	_check("败" in battle.end_title.text, "结算标题应为「战败」, 实际: " + battle.end_title.text)
	_shot("09_gameover.png")

	print("========================================")
	if _failures.is_empty():
		print("SMOKE TEST: ALL PASS")
	else:
		print("SMOKE TEST: %d FAILURES" % _failures.size())
		for f_ in _failures:
			print("  FAIL: " + f_)
	get_tree().quit()


func _spawn_battle() -> void:
	battle = load("res://scenes/battle.tscn").instantiate()
	get_tree().root.add_child(battle)
	# 测试全程直接调用内部方法, 屏蔽真实鼠标输入, 防止用户动鼠标干扰
	battle.set_process_unhandled_input(false)
	await _frames(6)
	await _skip_story()


func _skip_story() -> void:
	var t := 0.0
	while battle.state == battle.S.STORY and t < 20.0:
		battle.dialogue.skip_all()
		await get_tree().create_timer(0.15).timeout
		t += 0.15
	await _frames(2)


func _wait_cond(cond: Callable, timeout: float) -> bool:
	var t := 0.0
	while not cond.call():
		if battle.state == battle.S.STORY:
			battle.dialogue.skip_all()
		if battle.combat_scene.active:
			battle.combat_scene.skip()
		await get_tree().create_timer(0.1).timeout
		t += 0.1
		if t > timeout:
			return false
	return true


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures.append(msg)


func _mark(msg: String) -> void:
	print("[SMOKE] ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var img := get_tree().root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(_shot_dir + file_name))
	print("截图: " + file_name)
