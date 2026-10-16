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
	await get_tree().create_timer(180.0).timeout
	print("WATCHDOG: 超时强制退出")
	print("SMOKE TEST: TIMEOUT, %d FAILURES" % _failures.size())
	for f_ in _failures:
		print("  FAIL: " + f_)
	get_tree().quit(1)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shot_dir))
	_check_infra()
	await _check_title_and_narration()
	await _check_en_topbar()
	GameLocale.set_code("zh_CN")
	battle = load("res://scenes/battle.tscn").instantiate()
	get_tree().root.add_child(battle)
	battle.set_process_unhandled_input(false)
	await _frames(6)
	_check(battle.dialogue.offset_left == SafeArea.MARGIN_X, "对话框左边距应为安全区")
	_check(battle.dialogue.offset_right == -SafeArea.MARGIN_X, "对话框右边距应为安全区")
	_check(battle.dialogue.offset_bottom == -SafeArea.MARGIN_Y, "对话框底边距应为安全区")
	var end_turn := battle.ui.find_child("EndTurnButton", true, false) as Button
	_check(end_turn != null, "应有回合结束按钮")
	if end_turn != null:
		var right := end_turn.position.x + end_turn.size.x
		_check(right <= 1280.0 - SafeArea.EDGE_ACTION + 0.01, "回合结束应避开右缘 80px，右缘 %s" % right)
		_check(end_turn.size.y >= SafeArea.MIN_HIT, "回合结束热区高度应 ≥ 48，实际 %s" % end_turn.size.y)
		_check(end_turn.text == "回合结束", "回合结束按钮应为中文，实际 " + end_turn.text)
	var chapter_label := battle.ui.find_child("ChapterLabel", true, false) as Label
	_check(chapter_label != null and chapter_label.position.x >= SafeArea.MARGIN_X, "章节名应避开左缘 64px")
	var turn_label := battle.ui.find_child("TurnLabel", true, false) as Label
	_check(turn_label != null, "应有回合标签")
	if chapter_label != null and turn_label != null:
		var chapter_right := chapter_label.position.x + maxf(chapter_label.size.x, chapter_label.get_minimum_size().x)
		_check(chapter_right <= turn_label.position.x + 0.01, "中文章节右缘应不超过回合左缘，右缘 %s 左缘 %s" % [chapter_right, turn_label.position.x])
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

	# ---- 主指针点选（鼠标 / 触摸共用 click_tile） ----
	var vp: Vector2 = battle.board.get_global_transform_with_canvas() * tia.position
	_check(battle.board.tile_at_viewport(vp) == tia.grid_pos, "视口坐标应落到缇娅所在格，实际 %s" % battle.board.tile_at_viewport(vp))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = vp
	battle._unhandled_input(click)
	_check(battle.selected == tia, "鼠标主指针应按在缇娅格上并选中她")
	battle.cancel()
	await _frames(2)
	ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", false)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = vp
	battle._unhandled_input(touch)
	_check(battle.selected == tia, "关闭鼠标模拟后，单指触摸应同样选中缇娅")
	battle.cancel()
	ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", true)
	await _frames(2)
	_check(battle.state == battle.S.IDLE, "取消后应回到 IDLE")

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
	var menu_btn := battle.menu_box.get_child(0) as Button
	_check(menu_btn != null and menu_btn.text == "攻击", "行动菜单首项应为攻击，实际 %s" % (menu_btn.text if menu_btn != null else "null"))
	_check(menu_btn != null and menu_btn.custom_minimum_size.y >= SafeArea.MIN_HIT, "行动菜单热区应 ≥ 48")
	_shot("03_action_menu.png")
	battle._on_menu_attack()
	await _frames(2)
	_check(battle.state == battle.S.TARGET_SEL, "应进入目标选择, 实际 %d" % battle.state)
	battle.click_tile(bandit.grid_pos)
	await _frames(2)
	_check(battle.forecast_panel.visible, "应显示战斗预测面板")
	var confirm := _find_button(battle.forecast_panel, "确认攻击")
	_check(confirm != null and confirm.custom_minimum_size.y >= SafeArea.MIN_HIT, "确认攻击热区应 ≥ 48")
	_shot("04_forecast.png")
	Combat.force_crit = true  # 截一张暴击演出
	battle._on_forecast_ok()
	await get_tree().create_timer(1.05).timeout
	_shot("04b_combat_scene.png")  # 暴击特写演出中
	_check(battle.combat_scene._att_node.get_node_or_null("CombatPose") != null, "缇娅特写应挂上像素帧")
	_check(battle.combat_scene._def_node.get_node_or_null("CombatPose") != null, "山贼特写应挂上像素帧")
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

	# ---- 支援自然涨点（相邻回合 +1）----
	_mark("支援自然涨点")
	battle.support_points["tia|balto"] = 0
	tia.grid_pos = Vector2i(4, 3)
	tia.position = tia.tile_center()
	balto.grid_pos = Vector2i(4, 4)  # 相邻
	balto.position = balto.tile_center()
	battle._gain_support_points()
	_check(battle.support_points.get("tia|balto", 0) == 1, "相邻时应涨到 1 点, 实际 %d" % battle.support_points.get("tia|balto", 0))
	battle._gain_support_points()
	_check(battle.support_points.get("tia|balto", 0) == 2, "再相邻应涨到 2 点, 实际 %d" % battle.support_points.get("tia|balto", 0))
	# 不相邻不涨
	balto.grid_pos = Vector2i(6, 3)
	balto.position = balto.tile_center()
	battle._gain_support_points()
	_check(battle.support_points.get("tia|balto", 0) == 2, "不相邻时点数应保持 2, 实际 %d" % battle.support_points.get("tia|balto", 0))

	# ---- 支援系统（灌满后解锁对话）----
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
	# 横幅「敌方增援！」会在进入 IDLE 前被「第 3 回合 · 我方回合」覆盖，需在过渡中捕获
	var saw_reinforce_banner := false
	var t_rf := 0.0
	while not (battle.state == battle.S.IDLE and battle.turn == 3) and t_rf < 40.0:
		if battle.banner_label != null and "敌方增援" in battle.banner_label.text:
			saw_reinforce_banner = true
		if battle.state == battle.S.STORY:
			battle.dialogue.skip_all()
		if battle.combat_scene.active:
			battle.combat_scene.skip()
		await get_tree().create_timer(0.1).timeout
		t_rf += 0.1
	ok = battle.state == battle.S.IDLE and battle.turn == 3
	_check(ok, "应进入第 3 回合, state=%d turn=%d" % [battle.state, battle.turn])
	# 若轮询错过淡入瞬间，退而检查 banner 残留文案或已触发标志
	if not saw_reinforce_banner and battle.banner_label != null and "敌方增援" in battle.banner_label.text:
		saw_reinforce_banner = true
	_check(saw_reinforce_banner or battle.chapter.f_reinforce, "应出现含「敌方增援」的横幅（或至少触发增援事件）")
	_check(saw_reinforce_banner, "过渡中应捕获到横幅文案含「敌方增援」, banner='%s'" % (battle.banner_label.text if battle.banner_label else ""))
	_check(battle.get_unit("bandit_r1") != null, "第 3 回合应有增援 bandit_r1")
	_check(battle.get_unit("bandit_r2") != null, "第 3 回合应有增援 bandit_r2")
	_check(battle.chapter.f_reinforce, "第 3 回合增援标志 f_reinforce 应为 true")
	var r1 = battle.get_unit("bandit_r1")
	var r2 = battle.get_unit("bandit_r2")
	if r1 != null:
		_check(r1.is_alive() and not r1.is_player(), "bandit_r1 应为存活敌方")
	if r2 != null:
		_check(r2.is_alive() and not r2.is_player(), "bandit_r2 应为存活敌方")
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
	_check("灰岩村" in battle.end_sub.text, "缇娅败北副标题应含灰岩村, 实际: " + battle.end_sub.text)
	_check(_phase_banner_hidden(), "缇娅败北结算时相位横幅应不可见, vis=%s a=%s text=%s" % _banner_state())
	_shot("09_gameover.png")

	# ---- 战败: 新开一局, 巴尔托阵亡 ----
	_mark("巴尔托阵亡败北")
	battle.queue_free()
	await _frames(3)
	await _spawn_battle()
	var balto2 = battle.get_unit("balto")
	var tia3 = battle.get_unit("tia")
	balto2.take_damage(999)
	_check(not balto2.is_alive() and tia3.is_alive(), "巴尔托应阵亡且缇娅仍存活")
	battle.check_end_conditions()
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 15.0)
	_check(ok, "巴尔托阵亡后应显示结算界面")
	_check(battle.state == battle.S.OVER, "巴尔托阵亡应进入 OVER")
	_check("败" in battle.end_title.text, "结算标题应为「战败」, 实际: " + battle.end_title.text)
	_check("灰岩村" in battle.end_sub.text, "巴尔托败北副标题应含灰岩村, 实际: " + battle.end_sub.text)
	_check(_phase_banner_hidden(), "巴尔托败北结算时相位横幅应不可见, vis=%s a=%s text=%s" % _banner_state())
	_shot("10_gameover_balto.png")

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


func _check_infra() -> void:
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 1280, "逻辑宽度应为 1280")
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 720, "逻辑高度应为 720")
	_check(int(ProjectSettings.get_setting("display/window/handheld/orientation")) == 4, "应强制 sensor_landscape（横屏）")
	_check(str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile")) == "gl_compatibility", "Android 渲染应走 gl_compatibility")
	_check(bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch")), "应开启触控模拟鼠标")
	_check(SafeArea.MARGIN_X >= 64 and SafeArea.MARGIN_Y >= 48, "安全区左右应 ≥ 64、上下应 ≥ 48")
	_check(SafeArea.EDGE_ACTION >= 80 and SafeArea.MIN_HIT >= 48, "主操作内缩应 ≥ 80、热区应 ≥ 48")
	var combat_art: Array = [
		"res://art/combat/tia_sword.png",
		"res://art/combat/bandit_axe.png",
		"res://art/combat/bg/sky_grass.png",
		"res://art/combat/bg/mountains_grass.png",
		"res://art/combat/bg/mid_grass.png",
		"res://art/combat/bg/ground_strip_grass.png",
	]
	for i in 4:
		combat_art.append("res://art/combat/tia_sword_frames/%02d.png" % i)
		combat_art.append("res://art/combat/bandit_axe_frames/%02d.png" % i)
	for path in combat_art:
		_check(FileAccess.file_exists(path), "战斗资源应存在: " + path)
	var area := SafeArea.rect()
	_check(area.position == Vector2(64, 48), "安全区原点应为 (64, 48)，实际 %s" % area.position)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(12, 34)
	_check(PointerInput.is_primary_press(click), "鼠标左键按下应是主指针")
	_check(PointerInput.viewport_position(click) == Vector2(12, 34), "主指针应使用事件坐标")
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	_check(PointerInput.is_secondary_press(right), "鼠标右键应是取消指针")
	var motion := InputEventMouseMotion.new()
	_check(PointerInput.is_pointer_move(motion), "鼠标移动应是指针移动")
	var finger := InputEventScreenTouch.new()
	finger.index = 0
	finger.pressed = true
	finger.position = Vector2(5, 6)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(7, 8)
	ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", true)
	_check(not PointerInput.is_primary_press(finger), "触控模拟鼠标开启时，不应再单独消费触摸按下")
	_check(not PointerInput.is_pointer_move(drag), "触控模拟鼠标开启时，不应再单独消费触摸拖动")
	ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", false)
	_check(PointerInput.is_primary_press(finger), "关闭模拟后，单指按下应是主指针")
	_check(PointerInput.is_pointer_move(drag), "关闭模拟后，单指拖动应是指针移动")
	_check(PointerInput.viewport_position(finger) == Vector2(5, 6), "触摸坐标应取事件位置")
	var finger2 := InputEventScreenTouch.new()
	finger2.index = 1
	finger2.pressed = true
	_check(PointerInput.is_secondary_press(finger2), "第二指按下应视为取消")
	ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", true)
	TranslationServer.set_locale("zh_CN")
	_check(tr("敌方增援！") == "敌方增援！", "中文横幅应保持敌方增援，实际 " + tr("敌方增援！"))
	TranslationServer.set_locale("en")
	_check(tr("敌方增援！") == "Enemy Reinforcements!", "英文横幅翻译错误: " + tr("敌方增援！"))
	_check(tr("战  败") == "Defeat", "英文战败文案错误: " + tr("战  败"))
	_check(tr("手腕太僵了。剑不是靠蛮力挥的，缇娅。") == "Your wrist is too stiff. A sword isn't swung by brute force, Tia.", "抽样台词未译出")
	var en_keys: Array = [
		"攻击", "待机", "访问", "对话", "支援", "说得", "道具",
		"回合结束", "我方回合", "敌方回合", "危险范围 (T)",
		"第一章 · 边境的少女", "战  败", "第一章 · 完", "重试本章", "回到标题",
		"敌方增援！", "点击我方单位行动 · 点击敌人查看其威胁范围",
		"确认攻击", "取消", "必 杀 !", "攻击 %d", "命中 %d   必杀 %d",
		"我方", "敌方", "铁剑", "银枪", "伤药", "剑士", "圣骑士", "弓箭手", "平原", "森林",
		"%s 成为同伴了！", "缇娅 获得 伤药",
		"%s 与 %s 的羁绊加深了……（相邻时可用【支援】）",
		"缇娅 与 巴尔托 的支援提升到 C！（相邻时 命中/回避 +5）",
		"（能力没有提升……）", "%s 升级了！  Lv %d",
		"自「焚世之灾」过去，已逾八百年。",
		"在圣焰教会治理下的和平年代，火焰成为人们敬畏与禁忌的象征。",
		"知道啦知道啦，这话你说了八百遍了。",
		"……红头发？他们在说什么？",
		"……别分心！先解决眼前的敌人！",
		"对……不起……巴尔托……",
		"缇娅倒下了。灰岩村的命运，到此为止……",
		"听好，战场上先看清四周再动手。点击缇娅，就能看到她能走到的范围。",
		"（屋内）缇娅小姐！救命！有山贼在砸我家的门！",
	]
	for k in en_keys:
		var got := tr(k)
		_check(got.strip_edges() != "" and got != k and not _has_cjk(got), "英文 locale 下关键文案应有非空英译: %s -> %s" % [k, got])
	var narr_en := tr("在圣焰教会治理下的和平年代，火焰成为人们敬畏与禁忌的象征。").replace("\\n", "\n")
	_check("\n" in narr_en, "英文开场旁白应保留换行，实际 " + narr_en)
	TranslationServer.set_locale("zh_CN")


func _check_en_topbar() -> void:
	GameLocale.set_code("en")
	var probe = load("res://scenes/battle.tscn").instantiate()
	add_child(probe)
	probe.set_process_unhandled_input(false)
	await _frames(2)
	var chapter_label := probe.ui.find_child("ChapterLabel", true, false) as Label
	var turn_label := probe.ui.find_child("TurnLabel", true, false) as Label
	var gold_label := probe.ui.find_child("GoldLabel", true, false) as Label
	var threat := probe.ui.find_child("ThreatButton", true, false) as Button
	_check(chapter_label != null and turn_label != null, "英文顶栏应有章节与回合标签")
	if chapter_label != null and turn_label != null:
		var chapter_right := chapter_label.position.x + maxf(chapter_label.size.x, chapter_label.get_minimum_size().x)
		var turn_left := turn_label.position.x
		var turn_right := turn_left + maxf(turn_label.size.x, turn_label.get_minimum_size().x)
		_check(chapter_label.text == "Chapter 1 · The Girl of the Border", "英文章节名不符，实际 " + chapter_label.text)
		_check(turn_label.text.begins_with("Turn "), "英文回合标应已刷新，实际 " + turn_label.text)
		_check(chapter_right <= turn_left + 0.01, "英文章节右缘应不超过回合左缘，右缘 %s 左缘 %s" % [chapter_right, turn_left])
		_check(turn_left - chapter_right >= 8.0, "英文章节与回合应留出空隙，间距 %s" % (turn_left - chapter_right))
		if gold_label != null:
			var gold_left := gold_label.position.x
			_check(turn_right <= gold_left + 0.01, "英文回合右缘应不超过金钱左缘，右缘 %s 左缘 %s" % [turn_right, gold_left])
	if threat != null:
		_check(is_equal_approx(threat.size.x, 210.0), "危险范围按钮宽应保持 210，实际 %s" % threat.size.x)
		if gold_label != null:
			var gold_right := gold_label.position.x + maxf(gold_label.size.x, gold_label.get_minimum_size().x)
			_check(gold_right <= threat.position.x + 0.01, "英文金钱标不应压到危险范围，右缘 %s 按钮 %s" % [gold_right, threat.position.x])
	probe.queue_free()
	await _frames(2)
	GameLocale.set_code("zh_CN")


func _check_title_and_narration() -> void:
	GameLocale.set_code("zh_CN")
	var title = load("res://scenes/title.tscn").instantiate()
	add_child(title)
	await _frames(2)
	var start := title.get_node("StartButton") as Button
	var lang := title.get_node("LangButton") as Button
	_check(start.text == "开始游戏", "标题开始按钮默认中文，实际 " + start.text)
	_check(lang.text == "English", "中文界面的语言按钮应写 English，实际 " + lang.text)
	var lang_right := lang.position.x + lang.size.x
	_check(lang_right <= 1280.0 - SafeArea.EDGE_ACTION + 0.01, "语言按钮应避开右缘 80px，右缘 %s" % lang_right)
	_check(lang.position.y >= SafeArea.MARGIN_Y and lang.size.y >= SafeArea.MIN_HIT, "语言按钮应落在安全区且热区 ≥ 48")
	_check(start.size.y >= SafeArea.MIN_HIT, "开始按钮热区应 ≥ 48")
	GameLocale.toggle()
	_check(start.text == "Start", "切换英文后开始按钮应为 Start，实际 " + start.text)
	_check(lang.text == "中文", "英文界面的语言按钮应写 中文，实际 " + lang.text)
	_check(tr("开始游戏") == "Start", "切换后 tr(开始游戏) 应为 Start")
	GameLocale.toggle()
	_check(start.text == "开始游戏", "切回中文后开始按钮应恢复")
	title.queue_free()
	await _frames(2)
	var narration = load("res://scenes/narration.tscn").instantiate()
	add_child(narration)
	await _frames(2)
	var skip := narration.get_node("SkipButton") as Button
	_check(skip.text == "跳过 >>", "跳过按钮默认中文，实际 " + skip.text)
	var skip_right := skip.position.x + skip.size.x
	_check(skip_right <= 1280.0 - SafeArea.EDGE_ACTION + 0.01, "跳过按钮应避开右缘 80px，右缘 %s" % skip_right)
	_check(narration._label.text == "卡尔迪亚大陆历 812 年。", "开场旁白抽样应保持中文，实际 " + narration._label.text)
	var narr_zh := tr("在圣焰教会治理下的和平年代，火焰成为人们敬畏与禁忌的象征。").replace("\\n", "\n")
	_check("\n" in narr_zh and narr_zh.begins_with("在圣焰教会"), "中文开场旁白应保留换行，实际 " + narr_zh)
	# 旁白推进走主指针：淡入未完成时只补全，不切到下一句
	narration._label.modulate.a = 0.2
	var adv := InputEventMouseButton.new()
	adv.button_index = MOUSE_BUTTON_LEFT
	adv.pressed = true
	narration._input(adv)
	_check(narration._idx == 0 and narration._label.modulate.a == 1.0, "主指针应先补全淡入，而不是直接跳过")
	narration.queue_free()
	await _frames(2)


func _phase_banner_hidden() -> bool:
	if battle == null or battle.banner_label == null:
		return true
	return (not battle.banner_label.visible) or battle.banner_label.modulate.a < 0.01


func _banner_state() -> Array:
	if battle == null or battle.banner_label == null:
		return [false, 0.0, ""]
	return [battle.banner_label.visible, battle.banner_label.modulate.a, battle.banner_label.text]


func _has_cjk(s: String) -> bool:
	for i in s.length():
		var c := s.unicode_at(i)
		if c >= 0x4E00 and c <= 0x9FFF:
			return true
	return false


func _find_button(root: Node, text: String) -> Button:
	if root is Button and (root as Button).text == text:
		return root
	for c in root.get_children():
		var found := _find_button(c, text)
		if found != null:
			return found
	return null


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
