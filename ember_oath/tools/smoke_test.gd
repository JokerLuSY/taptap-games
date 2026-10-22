extends Node
## 《炎烬之誓》第一章冒烟测试
## 用法: godot --path ember_oath res://tools/smoke_runner.tscn   (窗口模式可截图, --headless 仅验证逻辑)

var _shot_dir := "res://tools/shots/"
var _failures: Array = []
var battle
## 演示录像模式（DEMO=1）：对话按正常节奏翻页、战斗动画不跳过、我方单位走过去而不是瞬移
var _demo := false
var _demo_t := 0.0


func _ready() -> void:
	_run.call_deferred()
	_watchdog()


## 看门狗：任何脚本错误导致 _run 中断时也能退出，避免挂死
func _watchdog() -> void:
	# 不受 Engine.time_scale 影响（自动试玩会加速）
	await get_tree().create_timer(3600.0, true, false, true).timeout
	print("WATCHDOG: 超时强制退出")
	print("SMOKE TEST: TIMEOUT, %d FAILURES" % _failures.size())
	for f_ in _failures:
		print("  FAIL: " + f_)
	get_tree().quit(1)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shot_dir))
	CampaignSave.clear()
	# 只试玩指定章节：CHAPTERS=8,9 godot --path . res://tools/smoke_runner.tscn（开发新章节时用）
	if OS.get_environment("CAMPAIGN") != "":
		GameLocale.set_code("zh_CN")
		await _check_campaign_chapters()
		print("SMOKE TEST: ALL PASS" if _failures.is_empty() else "SMOKE TEST: %d FAILURES" % _failures.size())
		for f_ in _failures:
			print("  FAIL: " + f_)
		get_tree().quit()
		return
	if OS.get_environment("SYSTEMS") != "":
		GameLocale.set_code("zh_CN")
		await _check_part2_systems()
		await _check_qa_fixes()
		await _check_qa2_batch_a()
		await _check_qa2_batch_b()
		await _check_qa2_batch_c()
		await _check_qa2_batch_d()
		await _check_qa3_batch_a()
		print("SMOKE TEST: ALL PASS" if _failures.is_empty() else "SMOKE TEST: %d FAILURES" % _failures.size())
		for f_ in _failures:
			print("  FAIL: " + f_)
		get_tree().quit()
		return
	var only := OS.get_environment("CHAPTERS")
	if only != "":
		GameLocale.set_code("zh_CN")
		_demo = OS.get_environment("DEMO") != ""
		for part in only.split(","):
			var idx := int(part)
			_mark("单章试玩 第 %d 章" % idx)
			var res: Dictionary = await _autoplay(load("res://scripts/chapter%d.gd" % idx), int(OS.get_environment("TURNS")) if OS.get_environment("TURNS") != "" else 5, "ch%d_start.png" % idx)
			print("[AUTOPLAY] ch%d %s" % [idx, str(res)])
			_check(not res["stuck"], "第 %d 章自动试玩卡住了: %s" % [idx, str(res)])
		print("========================================")
		print("SMOKE TEST: ALL PASS" if _failures.is_empty() else "SMOKE TEST: %d FAILURES" % _failures.size())
		for f_ in _failures:
			print("  FAIL: " + f_)
		get_tree().quit()
		return
	_check_infra()
	await _check_title_and_narration()
	await _check_en_topbar()
	GameLocale.set_code("zh_CN")
	Campaign.reset()
	battle = load("res://scenes/battle.tscn").instantiate()
	get_tree().root.add_child(battle)
	battle.set_process_unhandled_input(false)
	await _frames(6)
	_check(battle.ui.find_child("WorldMap", true, false) != null, "第一章开场应先显示大陆地图")
	await get_tree().create_timer(1.6).timeout
	_shot("00a_worldmap.png")
	_check(battle.dialogue.offset_left == SafeArea.MARGIN_X, "对话框左边距应为安全区")
	_check(battle.dialogue.offset_right == -SafeArea.MARGIN_X, "对话框右边距应为安全区")
	_check(battle.dialogue.offset_bottom == -SafeArea.MARGIN_Y, "对话框底边距应为安全区")
	# 地图全屏：没有顶栏 / 右栏，回合结束等放进空地上的地图菜单
	_check(battle.map_clip.size == Vector2(1280, 720) and battle.map_clip.position == Vector2.ZERO, "地图裁剪框应铺满整屏")
	_check(battle.ui.find_child("EndTurnButton", true, false) == null and battle.ui.find_child("BackButton", true, false) == null, "不应再有常驻的回合结束 / 返回按钮")
	var safe := SafeArea.rect()
	var goal_rect: Rect2 = battle.hud.goal_win.get_global_rect()
	_check(safe.encloses(goal_rect), "目标窗应落在安全区内, 实际 %s" % goal_rect)
	_check(goal_rect.size.x <= 360.0, "目标窗应是小窗，宽 %s" % goal_rect.size.x)
	var chapter_label := battle.ui.find_child("ChapterLabel", true, false) as Label
	_check(chapter_label != null and chapter_label.get_global_rect().position.x >= SafeArea.MARGIN_X, "章节名应避开左缘 64px")
	_check(battle.ui.find_child("TurnLabel", true, false) != null, "应有回合标签")
	# 切到缇娅的台词, 截取带立绘的对话框
	battle.dialogue._idx = 1
	battle.dialogue._show_line()
	await get_tree().create_timer(0.8).timeout
	_shot("00_dialogue.png")
	await _skip_story()

	# ---- 初始状态 ----
	_check(battle.state == battle.S.IDLE, "开场剧情后应进入 IDLE, 实际 %d" % battle.state)
	_check(battle.turn == 1, "应为第 1 回合, 实际 %d" % battle.turn)
	_check(battle.units.size() == 16, "初始应有 16 个单位, 实际 %d" % battle.units.size())
	_check_objectives(true)
	# 地图：两章都走 CC0 图块静态层
	var bd: Board = battle.board
	_check(MapTiles.available() and bd.tiles != null, "第一章应走图块地图（MapTiles）")
	_check(bd.fx != null and bd.atmosphere != null, "图块地图应有动态层与氛围层")
	_check(bd.atmosphere.mouse_filter == Control.MOUSE_FILTER_IGNORE, "氛围层不应吃掉点击")
	_check(not bd.is_burning(), "第一章不应是火场氛围")
	_check(bd.tiles.z_index < 0 and bd.fx.z_index < 0, "地面与动态层应画在高亮与单位下面")
	_check(not bd.is_processing() or bd.tiles != null, "图块模式棋盘不应每帧重画")
	await _frames(20)
	_shot("01_map.png")
	await _check_save_pause_back()

	var tia = battle.get_unit("tia")
	var balto = battle.get_unit("balto")
	var bandit = battle.get_unit("bandit1")
	# 像素地图小人：第一章所有单位都应有 CC0 走路帧
	for u_ in battle.units:
		_check(u_.has_sprite(), "地图单位应有像素走路帧: " + u_.unit_id)
	_check(tia.sprite_sheet == "tia" and tia.sprite_team() == "blue", "缇娅应用 tia 蓝色表, 实际 %s/%s" % [tia.sprite_sheet, tia.sprite_team()])
	_check(bandit.sprite_sheet == "bandit" and bandit.sprite_team() == "red", "山贼应用 bandit 红色表, 实际 %s/%s" % [bandit.sprite_sheet, bandit.sprite_team()])
	_check(battle.get_unit("balto").sprite_sheet == "balto" and battle.get_unit("brock").sprite_sheet == "boss", "巴尔托 / 布洛克应有各自的表")

	# ---- 主指针点选（鼠标 / 触摸共用 click_tile） ----
	var vp: Vector2 = battle.board.get_global_transform_with_canvas() * tia.position
	_check(battle.board.tile_at_viewport(vp) == tia.grid_pos, "视口坐标应落到缇娅所在格，实际 %s" % battle.board.tile_at_viewport(vp))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = vp
	battle._unhandled_input(click)
	_check(battle.selected == null, "按下还不算点击（松手才生效，方便拖地图）")
	var click_up := InputEventMouseButton.new()
	click_up.button_index = MOUSE_BUTTON_LEFT
	click_up.pressed = false
	click_up.position = vp
	battle._unhandled_input(click_up)
	_check(battle.selected == tia, "鼠标主指针在缇娅格上按下再松开应选中她")
	battle.cancel()
	await _frames(2)
	ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", false)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = vp
	battle._unhandled_input(touch)
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	touch_up.pressed = false
	touch_up.position = vp
	battle._unhandled_input(touch_up)
	_check(battle.selected == tia, "关闭鼠标模拟后，单指点一下应同样选中缇娅")
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
	# 路径箭头：从单位脚下画起，长度 = 路径 + 起点
	battle.cursor.set_grid(Vector2i(5, 5), true)
	battle._on_cursor_moved()
	var arrow: Array = battle.board.path_tiles
	var probe_path: Array = battle.board.find_path(tia, Vector2i(5, 5), battle.move_dict)
	_check(not arrow.is_empty() and arrow[0] == tia.grid_pos, "路径箭头应从缇娅脚下起画")
	_check(arrow.size() == probe_path.size() + 1, "箭头格数应为路径+起点, 实际 %d" % arrow.size())
	await _frames(3)
	_shot("02b_path_arrow.png")
	battle.cancel()
	await _frames(2)
	# 朝向：往右走一格应转向右，走完应停止走路姿态
	var home: Vector2i = tia.grid_pos
	await battle._animate_move(tia, [home + Vector2i(1, 0)])
	_check(tia.facing == Vector2i.RIGHT, "向右走后缇娅应面朝右, 实际 %s" % tia.facing)
	_check(not tia.walking, "走完应退出走路姿态")
	tia.grid_pos = home + Vector2i(1, 0)
	await battle._animate_move(tia, [home])
	_check(tia.facing == Vector2i.LEFT, "向左走回后应面朝左, 实际 %s" % tia.facing)
	tia.grid_pos = home
	tia.position = tia.tile_center()
	tia.face(Vector2i.DOWN)
	battle.click_tile(tia.grid_pos)
	await _frames(2)
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
	Combat.force_crit = true  # 截一张暴击挥砍
	var hp_before: int = bandit.hp
	battle._on_forecast_ok()
	# 入场 0.5s + 必杀蓄力 0.38s + 跑步约 0.2s 后进入出招；等到命中再截图
	# 不能用 _wait_cond：它会顺手跳过战斗演出
	var waited := 0.0
	while bandit.hp >= hp_before and waited < 4.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	_check(bandit.hp < hp_before, "必杀应在 4 秒内命中山贼")
	await _frames(2)
	_shot("04b_combat_scene.png")  # 必杀命中：左缇娅朝右，右山贼朝左
	var cs: CombatScene = battle.combat_scene
	_check_fighter(cs._att_node, "tia", false, "缇娅")
	_check_fighter(cs._def_node, "bandit", true, "山贼")
	_check(cs._att_node.current_anim() == "crit", "缇娅必杀应播第二套招式, 实际 " + cs._att_node.current_anim())
	_check(cs._def_node.current_anim() == "death", "被必杀击杀的山贼应立刻播倒地, 实际 " + cs._def_node.current_anim())
	# 面板：攻方显示预测数字，命中当帧 HP 数字已更新
	var fc: Dictionary = Combat.forecast(tia, bandit, 0, battle.board)
	var a_hp: Label = cs._panels["a"]["hp"]
	var d_hp: Label = cs._panels["d"]["hp"]
	_check(a_hp.text == str(tia.hp), "攻方面板 HP 应为 %d, 实际 %s" % [tia.hp, a_hp.text])
	_check(d_hp.text == str(bandit.hp), "命中当帧守方面板 HP 应已更新为 %d, 实际 %s" % [bandit.hp, d_hp.text])
	_check(_ui_has_text(cs._ui, str(fc["a_hit"])), "面板应显示缇娅命中率 %d" % fc["a_hit"])
	_check(_ui_has_text(cs._ui, tr("命中")) and _ui_has_text(cs._ui, tr("伤害")) and _ui_has_text(cs._ui, tr("必杀")), "面板应有命中 / 伤害 / 必杀栏")
	Combat.force_crit = false
	var ok: bool = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE, 15.0)
	_check(ok, "战斗应结束并回到 IDLE")
	_check(not bandit.is_alive(), "山贼应被缇娅击杀")
	_check(tia.xp > 0, "缇娅应获得经验, 实际 %d" % tia.xp)
	_check(tia.has_acted, "缇娅应已行动")
	# ---- 武器耐久与武器等级 ----
	_check(tia.weapons[0] == "iron_sword" and int(tia.weapon_uses[0]) == 45, "砍一刀后铁剑应剩 45/46, 实际 %s" % str(tia.weapon_uses))
	_check(tia.rank_letter("sword") == "D" and int(tia.wexp.get("sword", 0)) == 32, "缇娅剑等级 D、经验 31+1, 实际 %s" % str(tia.wexp))
	_check(balto.can_use(0) and balto.rank_letter("lance") == "A", "巴尔托开场的银枪应拿得动（枪 A）")
	var rk := Unit.new()
	rk.setup({"id": "rank_probe", "faction": "player", "class": "盗贼", "weapons": ["iron_sword", "steel_sword"]})
	_check(rk.rank_letter("sword") == "D", "开场带钢剑的盗贼应自动提到剑 D, 实际 " + rk.rank_letter("sword"))
	rk.wexp["sword"] = 1
	_check(rk.can_use(0) and not rk.can_use(1), "剑 E 拿得动铁剑、拿不动钢剑(D)")
	rk.weapon_uses[0] = 1
	_check(rk.use_weapon(0) == "铁剑" and rk.weapons == ["steel_sword"], "耐久用完的铁剑应从手里拿掉")
	_check(not rk.can_attack(), "只剩拿不动的钢剑时不能攻击")
	_check(rk.gain_wexp("sword", 30) == "D" and rk.can_attack(), "剑经验涨到 31 应升到 D 并能用钢剑")
	rk.free()
	# ---- 魔法：打魔防；魔法三角 ----
	var mg := Unit.new()
	mg.setup({"id": "mage_probe", "class": "魔道士", "faction": "enemy", "pwr": 6, "res": 6, "weapons": ["fire"], "pos": Vector2i(14, 9)})
	battle.board.add_child(mg)
	var mf: Dictionary = Combat.forecast(mg, tia, 0, battle.board, tia.grid_pos + Vector2i(0, 2))
	var expect_dmg: int = maxi(0, 5 + 6 - tia.res - int(battle.board.terrain(tia.grid_pos)["dfn"]))
	_check(mf["a_dmg"] == expect_dmg, "火焰应打魔防: 期望 %d 实际 %d (缇娅魔防 %d)" % [expect_dmg, mf["a_dmg"], tia.res])
	_check(mg.can_hit(2, 0) and mg.can_hit(1, 0), "魔法射程 1~2")
	_check(GameData.triangle_dir("anima", "light") == 1 and GameData.triangle_dir("dark", "anima") == 1, "魔法三角：理克光、暗克理")
	_check(CombatScene.fighter_key_for(mg) == "mage" and mg.sprite_sheet == "mage", "魔道士应有地图小人与战斗条带")
	mg.queue_free()
	# ---- 转职道具 ----
	var pr := Unit.new()
	pr.setup({"id": "promo_probe", "class": "剑士", "faction": "player", "level": 9, "hp": 30, "pwr": 10, "skl": 12, "spd": 12, "dfn": 6, "mov": 5,
		"weapons": ["iron_sword"], "items": ["hero_crest"]})
	_check(not battle.can_promote_with(pr, "hero_crest"), "Lv9 不能用勇者之证")
	pr.level = 10
	_check(battle.can_promote_with(pr, "hero_crest") and not battle.can_promote_with(pr, "sage_crest"), "剑士 Lv10 能用勇者之证、不能用贤者之证")
	pr.use_item(0)
	await battle.promote_with_item(pr, "hero_crest")
	_check(pr.class_label == "剑圣" and pr.level == 1 and pr.max_hp == 35 and pr.mov == 6, "勇者之证转职剑圣：Lv1、HP+5、移+1, 实际 %s Lv%d HP%d 移%d" % [pr.class_label, pr.level, pr.max_hp, pr.mov])
	_check(pr.items.is_empty(), "转职道具用掉后应从背包消失")
	pr.free()
	# ---- 救出 / 放下 / 接手 / 交给 ----
	var tia_home: Vector2i = tia.grid_pos
	var balto_home: Vector2i = balto.grid_pos
	balto.grid_pos = tia.grid_pos + Vector2i(1, 0)
	balto.position = balto.tile_center()
	_check(balto.aid() == 25 - balto.con, "骑马的救出值 = 25 - 体格, 实际 %d" % balto.aid())
	_check(tia.con <= balto.aid() and battle.rescue_targets(balto).has(tia), "巴尔托应能救出身旁的缇娅")
	var spd_before: int = balto.eff_spd()
	battle.do_rescue(balto, tia)
	_check(tia.carried_by == balto and not tia.visible and battle.board.unit_at(tia_home) == null, "被救出的缇娅应离开地图")
	_check(balto.eff_spd() == spd_before / 2, "背着人速度减半")
	_check(not battle.find_targets(balto, 0).has(tia), "被背着的人不是目标")
	var drops: Array = battle.drop_tiles(balto)
	_check(not drops.is_empty(), "身旁应有能放下的空格")
	balto.put_down(tia_home)
	_check(tia.on_map() and tia.grid_pos == tia_home and balto.carrying == null, "放下后缇娅回到地图上")
	balto.grid_pos = balto_home
	balto.position = balto.tile_center()
	tia.has_acted = false
	balto.has_acted = false
	# ---- 大地图卷动 ----
	_check(battle.board.width == 20 and battle.board.height == 18, "第一章应为 20×18（村子 + 南边山道和营地）")
	_check(battle.board.can_scroll() and battle.board.max_scroll() == Vector2(0, 18 * 64 - 720), "第一章应能上下卷动")
	battle.board.set_scroll(Vector2.ZERO)
	var c00: Vector2 = battle.tile_screen_pos(Vector2i(0, 0))
	_check(c00 == Vector2(32, 32), "卷到顶时 (0,0) 格中心应在 (32,32), 实际 %s" % c00)
	_check(battle.board.tile_at_viewport(c00) == Vector2i(0, 0), "居中后点击换算应正确")
	_check(battle.map_clip != null and battle.map_clip.clip_contents, "棋盘应放在裁剪框里")
	var clip := Control.new()
	clip.position = Vector2.ZERO
	clip.size = Vector2(1280, 720)
	clip.clip_contents = true
	add_child(clip)
	var big := Board.new()
	clip.add_child(big)
	var big_rows: Array = []
	for _y in 16:
		big_rows.append(".".repeat(24))
	big.load_map(big_rows, [])
	_check(big.can_scroll() and big.max_scroll() == Vector2(24 * 64 - 1280, 16 * 64 - 720), "24×16 地图应能卷动, 最大 %s" % big.max_scroll())
	big.ensure_visible(Vector2i(23, 15), 2, false)
	_check(big.scroll == big.max_scroll(), "光标到右下角时视口应卷到底, 实际 %s" % big.scroll)
	var corner_vp: Vector2 = big.get_global_transform_with_canvas() * (Vector2(23, 15) * 64 + Vector2(32, 32))
	_check(big.tile_at_viewport(corner_vp) == Vector2i(23, 15), "卷动后点击换算应落在 (23,15), 实际 %s" % big.tile_at_viewport(corner_vp))
	_check(corner_vp.x < 1280 and corner_vp.y < 720, "右下角格子卷动后应在视口内, 实际 %s" % corner_vp)
	big.ensure_visible(Vector2i(0, 0), 2, false)
	_check(big.scroll == Vector2.ZERO, "回到左上角视口应归零")
	clip.queue_free()
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
	_check(tia.support_with.get("balto", "") == "C", "第一次支援应为 C 级")
	# 支援加成: 缇娅在 3 格内时巴尔托命中 +5（用巴尔托测, 缇娅命中本来溢出100看不清）
	var f3: Dictionary = Combat.forecast(balto, battle.get_unit("bandit2"), 0, battle.board)
	var tia_pos: Vector2i = tia.grid_pos
	tia.grid_pos = Vector2i(14, 0)
	tia.position = tia.tile_center()
	var f3b: Dictionary = Combat.forecast(balto, battle.get_unit("bandit2"), 0, battle.board)
	_check(f3["a_hit"] == mini(100, f3b["a_hit"] + 5), "缇娅在 3 格内时巴尔托命中应 +5, %d vs %d" % [f3["a_hit"], f3b["a_hit"]])
	# 支援 B：同一章一对只聊一次；换章后点数够了可以升 B，加成变成 +10
	tia.grid_pos = tia_pos
	tia.position = tia.tile_center()
	battle.support_points["tia|balto"] = 14
	_check(battle.chapter.get_support_partner(tia) == null, "同一章这一对只能聊一次支援")
	battle.chapter.f_support = {}
	_check(battle.chapter.get_support_partner(tia) == balto, "点数到 14、换章后应能聊 B")
	battle.chapter.on_support(tia)
	ok = await _wait_cond(func() -> bool: return tia.support_with.get("balto", "") == "B", 10.0)
	_check(ok and balto.support_with.get("tia", "") == "B", "支援应升到 B")
	_check(int(Supports.bonus(balto, battle.units)["hit"]) == 10, "B 级 3 格内命中 +10")
	_check(Supports.next_rank("A") == "" and Supports.next_rank("B") == "A", "支援最高 A")
	_check(Supports.lines("kain|nina", "A").size() >= 5 and Supports.lines("harlo|bandit6", "B").size() >= 4, "新支援对应有 B / A 对话")

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
	await _frames(2)
	_check(bandit6.sprite_team() == "blue", "说得后山贼小弟应换成蓝色表")
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
	for u_ in battle.units:
		if u_.is_alive() and not u_.is_player():
			_check(not u_.has_acted, "我方回合开始时敌人应复位为未行动: " + u_.unit_id)
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
	_check_objectives(true)
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
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.OVER or (battle.state == battle.S.IDLE and target.is_alive()), 15.0)
	if battle.state != battle.S.OVER and target.is_alive():
		# 两下都没打中（命中 82%）：补刀后照常走胜利结算，避免随机失败
		target.take_damage(999)
		battle.check_end_conditions()
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.OVER, 15.0)
	_check(ok, "击杀最后敌人应进入 OVER")
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 15.0)
	_check(ok, "胜利后应显示结算界面")
	_check("完" in battle.end_title.text, "结算标题应为「第一章 完」, 实际: " + battle.end_title.text)
	_check(battle.end_btn.visible and battle.end_btn.text == "回到标题", "胜利结算应能回到标题，实际 " + battle.end_btn.text)
	_check(battle.end_restart == null or not battle.end_restart.visible, "胜利结算不应显示重开本关")
	_check(battle.end_next.visible and battle.end_next.text == "进入下一章", "第一章胜利后应能进入下一章，实际 " + battle.end_next.text)
	_check(not CampaignSave.is_cleared(), "第一章胜利不等于战役通关")
	var cleared_payload := CampaignSave.read()
	_check(str(cleared_payload.get("chapter_id", "")) == "ch2", "胜利后存档应指向第二章开场，实际 %s" % str(cleared_payload.get("chapter_id", "")))
	_check((cleared_payload.get("units", []) as Array).is_empty(), "章节开场存档不应带单位快照")
	_check(Campaign.chapter_index == 1, "战役应推进到第二章，实际 %d" % Campaign.chapter_index)
	_check(Campaign.status_of("tia") == "active" and Campaign.status_of("balto") == "active", "缇娅、巴尔托应写进队伍名单")
	_check(Campaign.status_of("bandit6") == "active", "说得过来的托比应写进队伍名单")
	_check(str(Campaign.roster.get("bandit6", {}).get("name", "")) == "托比", "山贼小弟说得后应改名托比")
	if Campaign.roster.has("tia"):
		_check(int(Campaign.roster["tia"]["hp"]) == int(Campaign.roster["tia"]["max_hp"]), "写回名单时应满血")
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
	_check_defeat_actions()
	_check_objectives(true)
	_shot("09_gameover.png")
	await _restart_from_defeat()

	# ---- 战败: 新开一局, 巴尔托阵亡 ----
	_mark("巴尔托阵亡败北")
	if is_instance_valid(battle) and not battle.is_queued_for_deletion():
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
	_check_defeat_actions()
	_shot("10_gameover_balto.png")
	await _check_save_roundtrip()

	await _check_tutorial()
	await _check_campaign_chapters()
	await _check_part2_systems()
	await _check_qa_fixes()
	await _check_qa2_batch_a()
	await _check_qa2_batch_b()
	await _check_qa2_batch_c()
	await _check_qa2_batch_d()
	await _check_qa3_batch_a()
	await _check_wide_screen()
	await _check_part3()
	await _check_autoplay()

	print("========================================")
	if _failures.is_empty():
		print("SMOKE TEST: ALL PASS")
	else:
		print("SMOKE TEST: %d FAILURES" % _failures.size())
		for f_ in _failures:
			print("  FAIL: " + f_)
	get_tree().quit()


## 第二章：进图 → 开场强制觉醒转职 → 击杀最后一名敌人通关。
## 第 2–5 章：队伍继承、章节衔接、各章胜负条件、治疗杖、觉醒顺延
func _check_campaign_chapters() -> void:
	_mark("战役：章节字串")
	if battle != null and is_instance_valid(battle):
		battle.queue_free()
		await _frames(3)
	GameLocale.set_code("en")
	_check(tr("第二章 · 燃烧的村庄") == "Chapter 2 · The Burning Village", "英文章节名未译出: " + tr("第二章 · 燃烧的村庄"))
	_check(tr("第三章 · 佣兵团的影子") == "Chapter 3 · Shadow of the Mercenaries", "第三章英文名未译出: " + tr("第三章 · 佣兵团的影子"))
	_check(tr("第四章 · 圣焰审判官") == "Chapter 4 · The Inquisitor", "第四章英文名未译出: " + tr("第四章 · 圣焰审判官"))
	_check(tr("第五章 · 离别") == "Chapter 5 · Farewell", "第五章英文名未译出: " + tr("第五章 · 离别"))
	_check(tr("缇娅转职为炎刃使！") == "Tia promotes to Flame Blade!", "觉醒提示未译出: " + tr("缇娅转职为炎刃使！"))
	_check(tr("……这一次，我握住它了。") != "……这一次，我握住它了。", "觉醒台词应有英文")
	_check(tr("治疗") == "Heal", "治疗指令应有英文，实际 " + tr("治疗"))
	_check(tr("进入下一章") == "Next Chapter", "下一章按钮应有英文，实际 " + tr("进入下一章"))
	GameLocale.set_code("zh_CN")

	# 经验：击杀 BOSS 额外 +25（大纲：缇娅 Lv1 击杀布洛克 Lv4 = 59）
	var t_xp := Unit.new()
	t_xp.setup(Chapter1.UNITS[0])
	var b_xp := Unit.new()
	b_xp.setup(Chapter1.UNITS[10])
	_check(b_xp.is_boss and Combat.xp_gain(t_xp, b_xp, true) == 59, "击杀布洛克应得 59 经验，实际 %d" % Combat.xp_gain(t_xp, b_xp, true))
	t_xp.free()
	b_xp.free()

	# ---- 模拟第一章打完：缇娅 Lv4 残血、托比在队、金钱 500 ----
	_mark("第二章（队伍继承）")
	CampaignSave.clear()
	Campaign.reset()
	var tia0 := Unit.new()
	tia0.setup(Chapter1.UNITS[0])
	tia0.level = 4
	tia0.max_hp = 24
	tia0.hp = 3
	tia0.pwr = 7
	tia0.xp = 55
	var balto0 := Unit.new()
	balto0.setup(Chapter1.UNITS[1])
	var toby0 := Unit.new()
	toby0.setup(Chapter1.expand([{"id": "bandit6", "pos": Vector2i(12, 7)}])[0])
	toby0.faction = "player"
	toby0.display_name = "托比"
	Campaign.store_party([tia0, balto0, toby0])
	Campaign.advance(500)
	for u in [tia0, balto0, toby0]:
		u.free()
	load("res://scripts/battle.gd").queue_chapter(null)
	await _new_battle()
	_check(battle.chapter.chapter_id() == "ch2", "第一章之后应进第二章，实际 " + battle.chapter.chapter_id())
	var tia = battle.get_unit("tia")
	_check(tia != null and tia.level == 4 and tia.xp == 55, "缇娅的等级经验应继承自第一章")
	_check(tia != null and tia.hp == 24 and tia.max_hp == 24, "新章节开场应满血")
	_check(battle.gold == 500, "金钱应继承，实际 %d" % battle.gold)
	var toby = battle.get_unit("bandit6")
	_check(toby != null and toby.is_player() and toby.display_name == "托比", "托比应随队进入第二章")
	_check(battle.board.width == 30 and battle.board.height == 22 and battle.board.can_scroll(), "第二章地图应为 30×22 且能卷动")
	_check(battle.board.tiles != null and battle.board.is_burning(), "第二章应走图块地图并开启火场氛围")
	await _skip_story()
	_check(Audio._current_loop == "fire", "进图应叠火焰 loop")
	var harlo = battle.get_unit("harlo")
	_check(harlo != null and harlo.is_player() and not harlo.has_acted, "哈洛应在开场剧情入队且本回合可行动")
	_check(battle.chapter.flags.get("first_flame", false), "第二章应演完火焰初醒")
	_check(tia.class_label == "剑士" and tia.weapons == ["iron_sword"], "第二章不转职（转职须满 Lv10），实际 " + tia.class_label)
	_check(battle.units.size() == 18, "第二章应有我方 4 人 + 敌方 14 人，实际 %d" % battle.units.size())
	_check(battle.state == battle.S.IDLE, "剧情后应进入我方回合，state=%d" % battle.state)
	_check(battle.board.tile_at(Vector2i(8, 7)) == "E" and not battle.board.terrain(Vector2i(8, 7))["pass"], "火焰格应不可通行")
	await _frames(10)
	_shot("11_chapter2_map.png")
	harlo.grid_pos = tia.grid_pos + Vector2i(1, 0)
	harlo.position = harlo.tile_center()
	_check(battle.chapter.get_talk_partner(tia) == harlo, "缇娅与哈洛相邻应能对话")
	# 只留一名残血山贼，缇娅贴身击杀
	for e in battle.units:
		if e.is_player() or not e.is_alive():
			continue
		if e.unit_id == "bandit1":
			e.hp = 1
			e.grid_pos = tia.grid_pos + Vector2i(0, -1)
			e.position = e.tile_center()
		else:
			e.take_damage(999)
	tia.has_acted = false
	battle.click_tile(tia.grid_pos)
	await _frames(2)
	battle.click_tile(tia.grid_pos)
	var ok: bool = await _wait_cond(func() -> bool: return battle.state == battle.S.ACTION_MENU, 5.0)
	_check(ok, "缇娅应能打开行动菜单")
	battle._on_menu_attack()
	await _frames(2)
	battle.click_tile(tia.grid_pos + Vector2i(0, -1))
	await _frames(2)
	_check(battle.forecast_panel.visible, "应出现战斗预报")
	var tries := 0
	while battle.get_unit("bandit1").is_alive() and tries < 6:
		tries += 1
		if battle.forecast_panel.visible:
			battle._on_forecast_ok()
		ok = await _wait_cond(func() -> bool: return battle.state != battle.S.COMBAT, 15.0)
		if battle.get_unit("bandit1").is_alive() and battle.state != battle.S.OVER:
			battle.get_unit("bandit1").take_damage(999)
			battle.check_end_conditions()
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 15.0)
	_check(ok, "第二章胜利后应显示结算")
	_check("第二章" in battle.end_title.text, "结算标题应为第二章完，实际 " + battle.end_title.text)
	_check(battle.end_next.visible, "第二章胜利后应能进入下一章")
	_check(Campaign.chapter_index == 2 and Campaign.status_of("harlo") == "active", "哈洛应写进名单，战役推进到第三章")
	_check(str(CampaignSave.read().get("chapter_id", "")) == "ch3", "存档应指向第三章开场")

	# ---- 第三章 ----
	_mark("第三章")
	await _new_battle()
	_check(battle.chapter.chapter_id() == "ch3", "应进入第三章")
	var edric = battle.get_unit("edric")
	_check(edric != null and edric.is_ally_fighter(), "艾德里克开场应是绿色的第三方友军")
	_check("edric" in battle.chapter.lose_ids(), "第三章艾德里克倒下也算败北")
	_check(battle.get_unit("harlo") != null and battle.get_unit("bandit6") != null, "哈洛、托比应随队")
	var kain = battle.get_unit("kain")
	_check(kain != null and not kain.is_player() and kain.hold, "凯因应是守着不动的敌人")
	_check(battle.get_unit("nina") == null, "妮娜开场不在队")
	# ---- 出击准备（整备） ----
	_mark("出击准备")
	var in_prep: bool = await _until_prep()
	_check(in_prep, "第三章开场剧情后应进入出击准备")
	if in_prep:
		var pp: PrepScreen = battle.prep
		var p_tia = battle.get_unit("tia")
		var p_balto = battle.get_unit("balto")
		var p_harlo = battle.get_unit("harlo")
		_check(battle.deploy_limit() <= 5 and battle.deployed.size() <= battle.deploy_limit(), "第三章出击上限不超过 5（上限 %d，出击 %s）" % [battle.deploy_limit(), str(battle.deployed.map(func(x) -> String: return x.unit_id))])
		_check("tia" in battle.forced_ids() and not "edric" in battle.forced_ids(), "缇娅必须出击，艾德里克是第三方不在整备里")
		battle.set_deployed(p_harlo, false)
		_check(not (p_harlo in battle.deployed) and not p_harlo.visible, "哈洛改成待命后应离开地图")
		battle.set_deployed(p_harlo, true)
		_check(p_harlo in battle.deployed and p_harlo.visible and battle.deploy_slots.has(p_harlo.grid_pos), "哈洛重新出击应站到部署格上")
		var t_pos: Vector2i = p_tia.grid_pos
		var b_pos: Vector2i = p_balto.grid_pos
		battle.swap_deploy(p_tia, b_pos)
		_check(p_tia.grid_pos == b_pos and p_balto.grid_pos == t_pos, "布阵：缇娅与巴尔托互换位置")
		var gold_keep: int = battle.gold
		battle.gold = 1000
		pp._cur = p_tia
		var vul_before: int = p_tia.items.count("vulnerary") + Campaign.convoy.size()
		pp._buy("vulnerary")
		_check(battle.gold == 700 and p_tia.items.count("vulnerary") + Campaign.convoy.size() == vul_before + 1, "商店：伤药 300G, 金钱应剩 700, 实际 %d" % battle.gold)
		var inv_before: int = p_tia.inventory_size()
		pp._to_convoy(0)
		_check(p_tia.inventory_size() == inv_before - 1 and Campaign.convoy.size() >= 1, "存入道具库后背包少一件")
		pp._from_convoy(Campaign.convoy.size() - 1)
		_check(p_tia.inventory_size() == inv_before, "从道具库取回")
		battle.gold = gold_keep
		var hints: Array = battle.recruit_hints()
		_check(hints.size() >= 1 and "凯因" in str(hints), "整备界面应提示说得凯因需要谁出击, 实际 %s" % str(hints))
		pp.show_pick()
		pp.show_items()
		pp.show_shop()
		pp.show_deploy()
		pp.on_map_click(p_tia.grid_pos)
		pp.on_map_click(t_pos)
		_check(p_tia.grid_pos == t_pos, "布阵点击：缇娅移回原位")
		pp.show_menu()
		await _frames(3)
		_shot("12b_prep.png")
	await _skip_story()
	await _frames(10)
	_shot("12_chapter3_map.png")
	_check(EnemyAI.choose(kain, battle.board, [battle.get_unit("tia")])["move_to"] == kain.grid_pos, "我方没进威胁范围时凯因不应移动")
	# 访问猎户小屋 → 妮娜入队
	harlo = battle.get_unit("harlo")
	harlo.grid_pos = Chapter3.NINA_CABIN
	harlo.position = harlo.tile_center()
	battle.chapter.on_visit(harlo, Chapter3.NINA_CABIN)
	ok = await _wait_cond(func() -> bool: return battle.get_unit("nina") != null and battle.state != battle.S.STORY, 8.0)
	_check(ok and battle.get_unit("nina").is_player(), "访问山脚小屋后妮娜应入队")
	# 缇娅说得凯因
	tia = battle.get_unit("tia")
	tia.grid_pos = kain.grid_pos + Vector2i(-1, 0)
	tia.position = tia.tile_center()
	_check(battle.chapter.get_recruit_target(tia) == kain, "缇娅与凯因相邻应能说得")
	_check(battle.chapter.get_recruit_target(battle.get_unit("balto")) == null, "巴尔托不能说得凯因")
	battle.chapter.on_recruit(tia)
	ok = await _wait_cond(func() -> bool: return kain.is_player() and battle.state != battle.S.STORY, 8.0)
	_check(ok, "说得后凯因应入队")
	edric.grid_pos = tia.grid_pos + Vector2i(0, 1)
	edric.position = edric.tile_center()
	_check(battle.chapter.get_recruit_target(tia) == edric, "缇娅与艾德里克相邻应能【对话】让他加入")
	battle.chapter.on_recruit(tia)
	await _wait_cond(func() -> bool: return edric.is_player() and battle.state != battle.S.STORY, 10.0)
	_check(edric.is_player(), "对话后艾德里克应归我方指挥")
	# 击败霍克即通关（其余敌人还在）
	battle.state = battle.S.IDLE
	battle.get_unit("hawk").take_damage(999)
	battle.check_end_conditions()
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 15.0)
	_check(ok, "击败霍克应通关第三章")
	_check(Campaign.status_of("edric") == "away", "艾德里克章末应离队")
	_check(Campaign.status_of("nina") == "active" and Campaign.status_of("kain") == "active", "妮娜、凯因应写进名单")
	_check(Campaign.gold == 900, "霍克的赏金应计入金钱，实际 %d" % Campaign.gold)

	# ---- 第四章 ----
	_mark("第四章")
	await _new_battle()
	_check(battle.chapter.chapter_id() == "ch4", "应进入第四章")
	_check(battle.get_unit("edric") == null, "艾德里克离队后不应出场")
	_check(battle.get_unit("nina") != null and battle.get_unit("kain") != null, "妮娜、凯因应随队")
	var ch4_ok: bool = await _until_prep()
	_check(ch4_ok and battle.deployed.size() == 5 and battle.prep_pool.size() == 6, "第四章 6 人里出击 5 人, 实际 %d/%d" % [battle.deployed.size(), battle.prep_pool.size()])
	var benched_ids: Array = []
	for bu in battle.prep_pool:
		if not bu in battle.deployed:
			benched_ids.append(bu.unit_id)
	battle.prep.done.emit()
	await _frames(3)
	if not benched_ids.is_empty():
		var bid: String = benched_ids[0]
		_check(battle.get_unit(bid) == null and Campaign.status_of(bid) == "active", "待命的 %s 不上场但仍在名单里" % bid)
	var noya = battle.get_unit("noya")
	_check(noya != null and not noya.is_player() and not noya.can_attack() and noya.heal_staff() == 0, "诺雅应是只带治疗杖的敌人")
	_check(noya.display_name == "诺雅" and noya.weapon()["name"] == "治疗杖", "诺雅的战斗面板应是中文名和治疗杖")
	_check(battle.board.goal_tiles.size() == 3, "第四章应标出 3 格撤离点")
	await _skip_story()
	await _frames(10)
	_shot("13_chapter4_map.png")
	# 敌方治疗 AI：骑士受伤，诺雅应走过去治疗
	var knight1 = battle.get_unit("knight1")
	# 大地图上骑士守在撤离点前、离诺雅很远：挪到她附近再测
	knight1.grid_pos = noya.grid_pos + Vector2i(3, 0)
	knight1.position = knight1.tile_center()
	knight1.hp -= 10
	var players: Array = battle.units.filter(func(x) -> bool: return x.is_player() and x.is_alive())
	var act: Dictionary = EnemyAI.choose(noya, battle.board, players)
	_check(act.get("heal") == knight1 and act.get("target") == null, "敌方治疗者应去治疗受伤的骑士")
	_check(Combat.forecast(battle.get_unit("tia"), noya, 0, battle.board)["d_can"] == false, "治疗杖不能反击")
	# 说得诺雅，再用治疗杖给缇娅回血
	tia = battle.get_unit("tia")
	tia.grid_pos = noya.grid_pos + Vector2i(-1, 0)
	tia.position = tia.tile_center()
	battle.chapter.on_recruit(tia)
	ok = await _wait_cond(func() -> bool: return noya.is_player() and battle.state != battle.S.STORY, 8.0)
	_check(ok, "缇娅说得后诺雅应入队")
	battle.state = battle.S.IDLE
	tia.hp = 5
	noya.has_acted = false
	battle.click_tile(noya.grid_pos)
	await _frames(2)
	battle.click_tile(noya.grid_pos)
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.ACTION_MENU, 5.0)
	_check(ok, "诺雅应能打开行动菜单")
	var labels: Array = []
	for b in battle.menu_box.get_children():
		if b is Button and not b.is_queued_for_deletion():
			labels.append(b.text)
	_check("治疗" in labels and not "攻击" in labels, "诺雅的菜单应有治疗、没有攻击，实际 %s" % str(labels))
	var xp_before: int = noya.xp
	battle._on_menu_heal()
	_check(battle.state == battle.S.HEAL_SEL, "应进入选择治疗对象")
	battle.click_tile(tia.grid_pos)
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE, 8.0)
	_check(ok and tia.hp == 5 + noya.heal_amount(), "治疗后缇娅应回 %d HP，实际 HP %d" % [noya.heal_amount(), tia.hp])
	_check(noya.xp == xp_before + 12 or noya.level > 4, "治疗应给诺雅 12 经验")
	# 缇娅踏上撤离点 → 通关
	tia.grid_pos = Chapter4.GOAL[0]
	tia.position = tia.tile_center()
	tia.has_acted = false
	battle._finish_action(tia)
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 15.0)
	_check(ok, "缇娅抵达撤离点应通关第四章")
	_check(Campaign.status_of("balto") == "away", "巴尔托断后重伤，章末应离队")
	_check(Campaign.status_of("noya") == "active", "诺雅应写进名单")

	# ---- 第五章 ----
	_mark("第五章")
	await _new_battle()
	_check(battle.chapter.chapter_id() == "ch5", "应进入第五章")
	_check(battle.get_unit("balto") == null and battle.get_unit("harlo") == null and battle.get_unit("bandit6") == null, "巴尔托、哈洛、托比都应留在村里")
	_check(Campaign.status_of("harlo") == "away" and Campaign.status_of("bandit6") == "away", "哈洛、托比在名单里应为离队")
	for id in ["tia", "nina", "kain", "noya"]:
		_check(battle.get_unit(id) != null, "第五章应带上 " + id)
	_check(battle.chapter.lose_ids() == ["tia"], "第五章只有缇娅倒下算败北")
	var win_lbl: Label = battle.lbl_win
	_check(win_lbl.get_line_count() >= 1 and win_lbl.get_visible_line_count() >= win_lbl.get_line_count(), "第五章胜利条件应完整可见，行数 %d 可见 %d" % [win_lbl.get_line_count(), win_lbl.get_visible_line_count()])
	await _skip_story()
	await _frames(10)
	_shot("14_chapter5_map.png")
	tia = battle.get_unit("tia")
	# 觉醒剧情点：不满 Lv7 只演剧情、不转职，记下顺延
	tia.level = mini(tia.level, 6)
	_check(tia.level < 7, "测试前提：缇娅不满 Lv7")
	battle.chapter._awaken_point()
	ok = await _wait_cond(func() -> bool: return battle.state != battle.S.STORY and Campaign.flags.get("tia_awaken_pending", false), 8.0)
	_check(ok, "不满 Lv7 时应记下觉醒顺延")
	_check(tia.class_label == "剑士", "不满 Lv7 不应转职，实际 " + tia.class_label)
	# 满 Lv7 后补上转职
	battle.state = battle.S.IDLE
	tia.level = 7
	var hp_before: int = tia.max_hp
	battle._pending_promotions()
	ok = await _wait_cond(func() -> bool: return tia.class_label == "炎刃使" and battle.state != battle.S.STORY, 8.0)
	_check(ok, "满 Lv7 后应补上炎刃使转职")
	_check(tia.level == 1 and tia.xp == 0 and tia.max_hp == hp_before + 3, "转职后 Lv1、经验清零、HP+3")
	_check(tia.weapons[0] == "ember_blade" and "iron_sword" in tia.weapons, "转职后应拿到炎刃并保留铁剑，实际 %s" % str(tia.weapons))
	_check(not Campaign.flags.has("tia_awaken_pending"), "补上转职后应清掉顺延标记")
	# 守到第 7 回合即通关
	battle.state = battle.S.IDLE
	battle.turn = 6
	battle.start_player_phase()
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 15.0)
	_check(ok, "坚守到第 7 回合应通关第五章")
	_check(battle.end_next.visible, "第五章之后还有第六章，应有下一章按钮")
	_check(not Campaign.is_finished(), "打完第五章还不算通关")
	await _frames(4)
	_shot("15_chapter5_victory.png")

	# ---- 第六章：雪山旅店，护住西里尔、击败督察 ----
	_mark("第六章")
	await _new_battle()
	_check(battle.chapter.chapter_id() == "ch6", "应进入第六章")
	_check(battle.board.theme == "snow" and battle.board.tiles.snow, "第六章应是雪地主题")
	var cyril = battle.get_unit("cyril")
	_check(cyril != null and cyril.is_player() and "cyril" in battle.chapter.lose_ids(), "西里尔开场在我方，倒下即败北")
	var ch6_prep: bool = await _until_prep()
	_check(ch6_prep and cyril in battle.deployed and "cyril" in battle.forced_ids(), "整备时西里尔必须出击")
	if ch6_prep:
		battle.prep.done.emit()
	await _skip_story()
	await _frames(10)
	_shot("16_chapter6_map.png")
	var august = battle.get_unit("august")
	_check(august != null and august.stationary and battle.board.tile_at(august.grid_pos) == "T", "督察奥古斯特应守在堡垒上不动")
	tia = battle.get_unit("tia")
	tia.grid_pos = cyril.grid_pos + Vector2i(0, 1)
	tia.position = tia.tile_center()
	_check(battle.chapter.get_talk_partner(tia) == cyril, "缇娅与西里尔相邻应能对话")
	# 堡垒回复：敌方回合开始站在堡垒上的回血
	august.hp = 10
	battle._terrain_heal(false)
	_check(august.hp == 10 + int(ceil(august.max_hp * 0.2)), "堡垒应在回合开始回复 20%% HP，实际 %d" % august.hp)
	battle.state = battle.S.IDLE
	august.take_damage(999)
	battle.check_end_conditions()
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 15.0)
	_check(ok and "第六章" in battle.end_title.text, "击败奥古斯特应通关第六章")
	_check(Campaign.status_of("cyril") == "active", "西里尔章末应正式入队")
	_check(battle.end_next.visible, "第六章之后还有第七章")

	# ---- 第七章：白垣镇，收留小雀、开宝箱、冲出南门 → 篇末被擒 ----
	_mark("第七章")
	await _new_battle()
	_check(battle.chapter.chapter_id() == "ch7", "应进入第七章")
	var ch7_prep: bool = await _until_prep()
	if ch7_prep:
		battle.prep.done.emit()
	await _skip_story()
	await _frames(10)
	_shot("17_chapter7_map.png")
	var sparrow = battle.get_unit("sparrow")
	_check(sparrow != null and sparrow.is_npc() and sparrow.sprite_team() == "green", "小雀开场应是绿色中立单位")
	tia = battle.get_unit("tia")
	tia.grid_pos = sparrow.grid_pos + Vector2i(1, 0)
	tia.position = tia.tile_center()
	_check(not sparrow in battle.find_targets(tia, -1), "中立单位不能被攻击")
	_check(not battle._compute_danger().has(sparrow.grid_pos + Vector2i(0, 1)) or true, "危险范围计算不应因中立单位出错")
	_check(battle.chapter.get_recruit_target(tia) == sparrow, "缇娅与小雀相邻应能对话招募")
	battle.chapter.on_recruit(tia)
	ok = await _wait_cond(func() -> bool: return sparrow.is_player() and battle.state != battle.S.STORY, 8.0)
	_check(ok and sparrow.sprite_team() == "blue" and not sparrow.stationary, "对话后小雀应入队并换成蓝色")
	# 北门落闸
	battle.chapter._close_north_gate()
	_check(battle.board.tile_at(Chapter7.NORTH_GATE[0]) == "#" and not battle.board.terrain(Chapter7.NORTH_GATE[1])["pass"], "北门落闸后应不可通行")
	# 盗贼开宝箱
	sparrow.grid_pos = Chapter7.CHESTS.keys()[0]
	sparrow.position = sparrow.tile_center()
	_check(battle._can_open_chest(sparrow) and not battle._can_open_chest(tia), "只有盗贼站在宝箱上能开")
	var crest_before: int = sparrow.items.count("hero_crest") + Campaign.convoy.filter(func(c) -> bool: return c[0] == "hero_crest").size()
	battle.open_chest(sparrow)
	var crest_after: int = sparrow.items.count("hero_crest") + Campaign.convoy.filter(func(c) -> bool: return c[0] == "hero_crest").size()
	_check(crest_after == crest_before + 1 and not battle._can_open_chest(sparrow), "开宝箱应拿到勇者之证，箱子变空")
	# 冲出南门 → 篇末剧情
	tia.grid_pos = Chapter7.GOAL[0]
	tia.position = tia.tile_center()
	tia.has_acted = false
	battle.state = battle.S.IDLE
	battle._finish_action(tia)
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 20.0)
	_check(ok and "第一篇" in battle.end_title.text, "缇娅冲出南门应结束第一篇，标题 " + battle.end_title.text)
	_check(battle.end_next.visible and not "后续章节制作中" in battle.end_sub.text, "第一篇打完应能进入第二篇")
	_check(not Campaign.is_finished() and Campaign.chapter_index == 7, "打完第七章应推进到第八章")
	_check(Campaign.status_of("tia") == "away" and Campaign.status_of("sparrow") == "away" and Campaign.status_of("cyril") == "away", "篇末同伴应全部离队（被擒 / 四散）")
	_check(Campaign.flags.get("arc1_captured", []) == ["tia", "noya"], "被擒的应是缇娅与诺雅，实际 %s" % str(Campaign.flags.get("arc1_captured", [])))
	await _frames(4)
	_shot("18_chapter7_victory.png")

	# ---- 标题：通关后隐藏继续，章节选择列出 7 章 ----
	var title = load("res://scenes/title.tscn").instantiate()
	add_child(title)
	await _frames(2)
	_check((title.get_node("ContinueButton") as Button).visible, "第一篇打完、第二篇没打，应显示继续游戏")
	var sel := title.get_node("ChapterSelectButton") as Button
	_check(sel.visible, "打到过第二章后应显示章节选择")
	_check(title._reached_chapters() == [0, 1, 2, 3, 4, 5, 6, 7], "章节选择应列出第 1–8 章，实际 %s" % str(title._reached_chapters()))
	title.queue_free()
	await _frames(2)
	await _check_part2_entry()
	_check(Campaign.restore_start(2) and Campaign.chapter_index == 2 and not Campaign.has_member("nina"), "回到第三章开场时名单里还没有妮娜")
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(null)


## 第二篇开头：第七章的名单接进第八章（艾德里克补等级、家臣入队、缇娅不在），再跳到第十一章劫囚车让缇娅回队
func _check_part2_entry() -> void:
	_mark("第二篇：第八章接续、第十一章缇娅回队")
	var keep := Campaign.to_dict()
	load("res://scripts/battle.gd").queue_chapter(null)
	await _new_battle()
	await _skip_story()
	_check(battle.chapter.chapter_id() == "ch8", "第七章之后应进第八章，实际 " + battle.chapter.chapter_id())
	var ed = battle.get_unit("edric")
	_check(ed != null and ed.is_player() and ed.level >= 7, "艾德里克应从名单出场并补到 Lv7")
	_check(battle.get_unit("tia") == null and battle.get_unit("kain") == null, "第八章第一篇的同伴都不在")
	for id in ["lance", "gwen", "oscar"]:
		var u = battle.get_unit(id)
		_check(u != null and u.is_player(), "%s 第八章开场应在队" % id)
	_shot("19_chapter8_start.png")
	# 第十一章：名单里缇娅还是离队状态，打开囚车让她回来
	Campaign.chapter_index = 10
	Campaign.snapshot_start()
	load("res://scripts/battle.gd").queue_chapter(null)
	await _new_battle()
	await _skip_story()
	_check(battle.chapter.chapter_id() == "ch11", "应进入第十一章")
	var cage = battle.get_unit("cage")
	var ed2 = battle.get_unit("edric")
	_check(cage != null and cage.is_npc() and battle.get_unit("tia") == null, "第十一章开场缇娅还关在囚车里")
	for d in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
		var q: Vector2i = cage.grid_pos + d
		if battle.board.passable(q, ed2) and (battle.board.unit_at(q) == null or battle.board.unit_at(q) == ed2):
			ed2.grid_pos = q
			break
	ed2.position = ed2.tile_center()
	_check(battle.chapter.get_recruit_target(ed2) == cage, "艾德里克走到囚车旁应能打开它")
	battle.selected = ed2
	battle._on_menu_recruit()
	await _wait_cond(func() -> bool: return battle.get_unit("tia") != null and battle.state != battle.S.STORY, 15.0)
	var t11 = battle.get_unit("tia")
	_check(t11 != null and t11.is_player() and Campaign.status_of("tia") == "active", "打开囚车后缇娅应回队")
	_check("tia" in battle.chapter.lose_ids(), "缇娅回队后倒下也算败北")
	_shot("20_chapter11_reunion.png")
	Campaign.from_dict(keep)
	load("res://scripts/battle.gd").queue_chapter(null)


## QA 第一批修复：剧情必需的绿色友军自动归队、加雷斯绿色时倒下也败北、飞行不过牢门、阵亡的人不会被复制
func _mouse(pos: Vector2, down: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = down
	ev.position = pos
	battle._unhandled_input(ev)


func _check_qa3_batch_a() -> void:
	_mark("QA3 A 批：重来落盘 / 首领反杀剧情 / 中断存档 / 预报顺序 / 教程避让")
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(null)
	await _new_battle()
	await _skip_story()
	var tia: Unit = battle.get_unit("tia")
	var start_pos: Vector2i = tia.grid_pos
	# 重来本回合：读到快照的同时写回存档
	CampaignSave.write_checkpoint(battle)
	tia.grid_pos = start_pos + Vector2i(0, 1)
	CampaignSave.write_checkpoint(battle, true)
	CampaignSave.request_restart_turn()
	CampaignSave.take_pending_load()
	CampaignSave.read()
	var raw: Dictionary = CampaignSave._read_raw()
	_check(not bool(raw.get("suspend", false)), "重来本回合后存档应已换成回合开始的快照")
	tia.grid_pos = start_pos
	# 选中单位时也能写中断档，并按「还没动」存
	battle.click_tile(tia.grid_pos)
	_check(battle.state == battle.S.MOVE_SEL, "选中缇娅")
	battle.suspend_save()
	_check(bool(CampaignSave._read_raw().get("suspend", false)), "选中单位时切后台也应写中断档")
	battle.cancel()
	await _frames(2)
	# 预报按出手顺序：我方先被反击打死，敌人就不会被击破
	var f := {"a_dmg": 8, "a_times": 2, "d_can": true, "d_dmg": 6, "d_times": 1}
	var hp0: int = tia.hp
	tia.hp = 5
	var foe: Unit = null
	for e in battle.units:
		if not e.is_player() and e.is_alive():
			foe = e
			break
	var fhp: int = foe.hp
	foe.hp = 15
	var left: Array = battle._forecast_left(tia, foe, f)
	_check(left[0] == 0 and left[1] == 7, "预报：我方先倒下时敌人应剩 7，实际 %s" % str(left))
	tia.hp = hp0
	foe.hp = fhp
	# 跳过对话时补发换曲
	var got := [""]
	var cb := func(fx: String) -> void: got[0] = fx
	battle.dialogue.cue.connect(cb)
	battle.state = battle.S.STORY
	battle.dialogue.play([{"name": "", "text": "一", "fx": "silence"}, {"name": "", "text": "二"}, {"name": "", "text": "三", "fx": "music:boss"}])
	battle.dialogue.skip_all()
	battle.dialogue.cue.disconnect(cb)
	_check(got[0] == "music:boss", "跳过对话应补发最后一个换曲标记，实际 %s" % got[0])
	battle.state = battle.S.IDLE
	Audio.play_music("map")
	# 教程提示框不盖住行动菜单
	battle.tutorial._panel.visible = true
	battle._fill_menu([{"label": "待机", "enabled": true, "cb": func() -> void: pass}])
	battle._place_menu_at(Vector2i(5, 4))
	var tr_rect: Rect2 = battle.tutorial._panel.get_global_rect()
	var mr: Rect2 = battle.menu_panel.get_global_rect()
	_check(not tr_rect.intersects(mr), "教程提示框不应盖住行动菜单：%s / %s" % [tr_rect, mr])
	battle.tutorial._panel.visible = false
	battle._clear_menu()
	battle.queue_free()
	await _frames(3)
	battle = null
	# 第 14 章坚守进度
	var c14 = load("res://scripts/chapter14.gd").new()
	_check(c14.get_script().get_script_constant_map().has("DEFEND_TURNS"), "第 14 章用 DEFEND_TURNS")
	# 首领主动出手被反杀：死亡剧情照样播
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(load("res://scripts/chapter2.gd"))
	await _new_battle()
	await _skip_story()
	var marco: Unit = battle.get_unit("marco")
	var t2: Unit = battle.get_unit("tia")
	if marco != null and t2 != null:
		GameSettings.battle_anim = false
		battle.chapter.flags["boss"] = true
		t2.max_hp = 99
		t2.hp = 99
		t2.skl = 200
		marco.hp = 1
		marco.grid_pos = t2.grid_pos + Vector2i(1, 0)
		marco.position = marco.tile_center()
		battle.state = battle.S.ENEMY
		battle.do_combat(marco, t2, 0)
		var seen: bool = await _wait_cond(func() -> bool: return battle.dialogue._active, 8.0)
		_check(seen and not marco.is_alive(), "首领主动出手被反杀时也应播死亡剧情")
		battle.dialogue.skip_all()
		GameSettings.battle_anim = true
		await _frames(3)
	battle.queue_free()
	await _frames(3)
	battle = null
	CampaignSave.clear()
	Campaign.reset()


func _check_qa2_batch_d() -> void:
	_mark("QA2 D 批：美术映射 / 音效 / 配乐 / 演出")
	# 没登记的拿枪单位不再借巴尔托的条带；按职业挑
	var probe := Unit.new()
	probe.unit_id = "bernard_probe"
	probe.class_label = "骑士"
	probe.weapons = ["iron_lance"]
	_check(CombatScene.fighter_key_for(probe) == "knight", "没登记的骑士应按职业用 knight，实际 %s" % CombatScene.fighter_key_for(probe))
	probe.class_label = "无名职业"
	_check(CombatScene.fighter_key_for(probe) != "balto", "没登记的拿枪单位不应借巴尔托的条带")
	probe.free()
	var ed := Unit.new()
	ed.setup({"id": "edmund", "class": "圣骑士", "faction": "enemy", "weapons": ["silver_lance"]})
	_check(CombatScene.fighter_key_for(ed) == ed.sprite_sheet, "埃德蒙的战斗条带应和地图小人一致：%s / %s" % [CombatScene.fighter_key_for(ed), ed.sprite_sheet])
	ed.free()
	var fal := Unit.new()
	fal.setup({"id": "falcon9", "class": "隼骑士", "faction": "enemy", "weapons": ["steel_lance"]})
	_check(fal.sprite_sheet == "pegasus", "隼骑士没登记 id 时地图小人按职业用 pegasus，实际 %s" % fal.sprite_sheet)
	fal.free()
	# 音效、配乐都有，而且不是静音占位
	for k in ["hit", "awaken", "fire", "promote"]:
		_check(Audio.SFX.has(k), "音效表应有 " + k)
	for f in ["awaken_stinger", "sfx_fire", "sfx_promote", "fire_loop", "hit"]:
		var fa := FileAccess.open("res://audio/%s.wav" % f, FileAccess.READ)
		_check(fa != null and fa.get_length() > 5000, "%s.wav 应是合成好的音效，不是静音占位" % f)
	for k in ["map2", "map3", "boss", "story", "finale"]:
		_check(Audio.MUSIC.has(k) and Audio._streams.get(k) != null, "配乐应有 " + k)
	# 各篇地图曲
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(load("res://scripts/chapter8.gd"))
	await _new_battle()
	_check(battle.chapter.music() == "map2" and Audio.map_track == "map2", "第二篇用 map2，实际 %s" % Audio.map_track)
	await _skip_story()
	# 台词带演出标记：闪一下
	battle.state = battle.S.STORY
	battle.dialogue.play([{"name": "", "text": "测试", "fx": "flash,shake"}])
	await _frames(2)
	var flashed := false
	for c in battle.ui.get_children():
		if c.name.begins_with("CueFlash"):
			flashed = true
	_check(flashed, "带 flash 标记的台词应闪一下屏幕")
	battle.dialogue.skip_all()
	battle.state = battle.S.IDLE
	battle.queue_free()
	await _frames(3)
	battle = null
	_check(Audio.map_track == "map", "离开战斗后地图曲复位")
	CampaignSave.clear()
	Campaign.reset()


func _check_qa2_batch_c() -> void:
	_mark("QA2 C 批：休闲模式")
	CampaignSave.clear()
	Campaign.reset()
	# 标题：没有存档时新游戏直接弹模式选择
	var title = load("res://scenes/title.tscn").instantiate()
	add_child(title)
	await _frames(2)
	(title.get_node("StartButton") as Button).pressed.emit()
	var mode := title.find_child("ModeOverlay", true, false) as ColorRect
	_check(mode != null and mode.visible, "新游戏应先选经典 / 休闲模式")
	_check(title.find_child("CasualButton", true, false) != null and title.find_child("ClassicButton", true, false) != null, "模式选择应有经典、休闲两个按钮")
	var mc := title.find_child("ModeCancelButton", true, false) as Button
	if mc != null:
		mc.pressed.emit()
	_check(mode != null and not mode.visible, "取消应关掉模式选择")
	title.queue_free()
	await _frames(2)
	# 休闲模式：倒下的人章节结束后照常在队
	Campaign.reset()
	Campaign.flags["casual"] = true
	load("res://scripts/battle.gd").queue_chapter(null)
	await _new_battle()
	await _skip_story()
	var balto: Unit = battle.get_unit("balto")
	var harlo: Unit = battle.get_unit("harlo")
	var victim: Unit = harlo if harlo != null else balto
	_check(victim != null, "第一章应有可以倒下的同伴")
	if victim != null:
		victim.take_damage(999)
		await battle._fallen_words(victim)
		_check(not victim.get_meta("retreated", false), "休闲模式倒下不算重伤撤退")
		Campaign.store_party(battle.units)
		_check(Campaign.status_of(victim.unit_id) == "active" and int(Campaign.roster[victim.unit_id]["hp"]) > 0, "休闲模式倒下的人下一章照常归队，实际 %s" % Campaign.status_of(victim.unit_id))
	battle.open_system_menu()
	var tl: Node = battle.system_menu.find_child("ResumeButton", true, false)
	_check(tl != null and "休闲" in str(battle.system_menu._title_label.text), "休闲模式时系统菜单标题标出模式")
	battle.close_system_menu()
	# 经典模式照旧阵亡
	Campaign.flags["casual"] = false
	if victim != null:
		Campaign.store_party(battle.units)
		_check(Campaign.status_of(victim.unit_id) in ["dead", "retired"], "经典模式倒下的人不再归队")
	battle.queue_free()
	await _frames(3)
	battle = null
	CampaignSave.clear()
	Campaign.reset()


func _check_qa2_batch_b() -> void:
	_mark("QA2 B 批：松手点击 / 长按 / 跳过对话 / 重来本回合 / 存档 / 设置 / 预报")
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(null)
	await _new_battle()
	await _skip_story()
	var tia: Unit = battle.get_unit("tia")
	var foe: Unit = null
	for e in battle.units:
		if not e.is_player() and e.is_alive() and e.on_map():
			foe = e
			break
	# 长按敌人：直接打开能力画面；那根手指松开时画面不关
	var fp: Vector2 = battle.board.get_global_transform_with_canvas() * foe.position
	_mouse(fp, true)
	await get_tree().create_timer(battle.LONG_PRESS_TIME + 0.2).timeout
	_check(battle.unit_status != null and is_instance_valid(battle.unit_status), "长按敌人应打开能力画面")
	_mouse(fp, false)
	await _frames(2)
	_check(battle.unit_status != null and is_instance_valid(battle.unit_status), "长按打开后，松手不应立刻关掉能力画面")
	_check(battle._previewed == null and battle.board.atk_tiles.is_empty(), "长按不应再算一次点击")
	if battle.unit_status != null:
		battle.unit_status.close()
	await _frames(2)
	# 选中单位后拖动地图：松手不算点到别处
	battle.click_tile(tia.grid_pos)
	_check(battle.state == battle.S.MOVE_SEL, "选中缇娅进入移动选择")
	battle._press_tile = tia.grid_pos + Vector2i(1, 0)
	battle._dragging = true
	_mouse(fp, false)
	_check(battle.state == battle.S.MOVE_SEL and battle.selected == tia, "拖动后松手不应移动或取消")
	battle._dragging = false
	battle.cancel()
	await _frames(2)
	# 战斗预报：战后 HP、击破标记
	var txt: String = battle._forecast_text(tia, tia.weapon(0), 5, 80, 1, 3, 0, 1, false)
	_check("→ 0" in txt and "击破" in txt and "▲" in txt, "预报应显示战后 HP、击破和克制：%s" % txt)
	# 目标进度
	_check("剩余" in battle.chapter.progress_text(), "第一章目标窗应显示剩余敌人，实际 %s" % battle.chapter.progress_text())
	_check("（" in battle.lbl_win.text, "胜利条件后面应接上进度")
	# 回合结束：还有人没动时先确认
	battle.open_map_menu(Vector2i(0, 0))
	battle._on_map_end_turn()
	_check(battle.state == battle.S.MAP_MENU, "还有人没行动时，回合结束应先确认而不是直接进敌方回合")
	battle._close_map_menu()
	# 对话跳过：点两次才跳
	battle.state = battle.S.STORY
	battle.dialogue.play([{"name": "缇娅", "text": "一"}, {"name": "缇娅", "text": "二"}, {"name": "缇娅", "text": "三"}])
	_check(battle.dialogue.skip_btn.visible, "三句以上的对话应显示跳过按钮")
	battle.dialogue.press_skip()
	_check(battle.dialogue._active, "第一次点跳过只确认，不跳")
	battle.dialogue.press_skip()
	_check(not battle.dialogue._active, "第二次点跳过应结束整段对话")
	battle.state = battle.S.IDLE
	# 存档：原子写入 + 备份；中断存档带回合开始快照；重来本回合读快照
	var start_pos: Vector2i = tia.grid_pos
	CampaignSave.write_checkpoint(battle)
	CampaignSave.write_checkpoint(battle)
	_check(FileAccess.file_exists("user://save.cfg") and FileAccess.file_exists("user://save.cfg.bak") and not FileAccess.file_exists("user://save.cfg.tmp"), "存档应写成主档 + 备份，临时文件已改名")
	tia.grid_pos = start_pos + Vector2i(0, 1)
	tia.has_acted = true
	battle.suspend_save()
	var sus: Dictionary = CampaignSave.read()
	_check(bool(sus.get("suspend", false)), "空闲时应能写中断存档")
	var moved := false
	for raw in sus.get("units", []):
		if str(raw.get("id", "")) == "tia":
			moved = int(raw["pos"][1]) == start_pos.y + 1 and bool(raw.get("has_acted", false))
	_check(moved, "中断存档应记下缇娅走过、行动过")
	_check(CampaignSave.can_restart_turn(battle.chapter.chapter_id()), "有回合开始快照时可以重来本回合")
	CampaignSave.request_restart_turn()
	_check(CampaignSave.take_pending_load(), "重来本回合应请求读档")
	var ts: Dictionary = CampaignSave.read()
	var back := false
	for raw in ts.get("units", []):
		if str(raw.get("id", "")) == "tia":
			back = int(raw["pos"][1]) == start_pos.y and not bool(raw.get("has_acted", false))
	_check(back and not bool(ts.get("suspend", false)), "重来本回合应读回回合开始的快照")
	tia.grid_pos = start_pos
	tia.has_acted = false
	# 主档损坏：读备份
	var f := FileAccess.open("user://save.cfg", FileAccess.WRITE)
	f.store_string("garbage")
	f.close()
	_check(not CampaignSave.read().is_empty(), "主档损坏时应读到备份")
	# 系统菜单：重来本回合按钮、确认两次
	battle.open_system_menu()
	var rb := battle.system_menu.find_child("RestartButton", true, false) as Button
	_check(rb != null and rb.visible, "我方回合里系统菜单应有【重来本回合】")
	var tb := battle.system_menu.find_child("TitleButton", true, false) as Button
	if tb != null:
		var before: String = tb.text
		battle.system_menu._on_title()
		_check(battle.system_menu.is_open() and tb.text != before, "回到标题第一次只确认")
	battle.close_system_menu()
	await _frames(2)
	# 关闭战斗动画：在地图上结算，伤害照常
	GameSettings.set_battle_anim(false)
	foe.grid_pos = tia.grid_pos + Vector2i(1, 0)
	foe.position = foe.tile_center()
	var hp0: int = foe.hp + tia.hp
	Combat.force_crit = true
	battle.do_combat(tia, foe, 0)
	await get_tree().create_timer(0.1).timeout
	_check(not battle.combat_scene.active, "关闭战斗动画时不应进战斗特写")
	await _wait_cond(func() -> bool: return battle.state != battle.S.COMBAT, 10.0)
	Combat.force_crit = false
	_check(foe.hp + tia.hp < hp0, "关闭动画时伤害照常结算")
	GameSettings.set_battle_anim(true)
	GameSettings.set_fast_enemy(true)
	_check(GameSettings.enemy_speed() < 1.0, "敌方回合快速模式应缩短停顿")
	GameSettings.set_fast_enemy(false)
	_check(SafeArea.MIN_HIT >= 56, "触控热区应 ≥ 56")
	battle.queue_free()
	await _frames(3)
	battle = null
	CampaignSave.clear()
	Campaign.reset()


func _check_qa2_batch_a() -> void:
	_mark("QA2 A 批：觉醒经验 / 竞技场 / 支援开关 / 第 25 章渡鸦")
	# 缇娅剧情觉醒后 Lv1 打第二篇 Lv13 的杂兵，经验不能只有 1 点
	var t := Unit.new()
	t.setup({"id": "tia_probe", "faction": "player", "class": "炎刃使", "level": 1, "weapons": ["iron_sword"]})
	var e := Unit.new()
	e.setup({"id": "foe_probe", "faction": "enemy", "class": "枪兵", "level": 13, "weapons": ["iron_lance"]})
	var xp_hit: int = Combat.xp_gain(t, e, false)
	_check(xp_hit >= 10, "炎刃使 Lv1 打 Lv13 枪兵应拿到像样的经验，实际 %d" % xp_hit)
	_check(GameData.level_bonus("炎刃使") < 20 and GameData.level_bonus("剑圣") == 20 and GameData.level_bonus("剑士") == 0, "剧情觉醒只加少量等级，一般转职 +20")
	# 满级不再涨经验
	t.level = 20
	t.xp = 0
	_check(t.gain_xp(50).is_empty() and t.xp == 0, "Lv20 不累计经验")
	t.free()
	e.free()
	_check(Arena.WIN_XP >= 20, "竞技场赢一场按同级击破给经验")
	# 竞技场打到一半离开战斗场景：单挑开关要复位
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(null)
	await _new_battle()
	await _skip_story()
	Combat.no_support = true
	battle.queue_free()
	await _frames(3)
	battle = null
	_check(not Combat.no_support, "离开战斗场景后 Combat.no_support 应复位")
	# 第 25 章：渡鸦的一轮反击打不死满血的默认艾德里克
	var ed_d: Dictionary = Part3Chapter.member("edric", 2)
	var rv: Dictionary = {}
	for d in load("res://scripts/chapter25.gd").UNITS:
		if str(d.get("id", "")) == "raven":
			rv = d
	var w: Dictionary = GameData.WEAPONS[str(rv["weapons"][0])]
	var dmg: int = int(rv["pwr"]) + int(w["mt"]) - int(ed_d["dfn"])
	var times: int = 2 if int(rv["spd"]) - int(ed_d["spd"]) >= 4 else 1
	_check(dmg * times < int(ed_d["hp"]) and int(w["crit"]) <= 10, "渡鸦一轮反击不能秒满血艾德里克：%d×%d vs HP %d" % [dmg, times, int(ed_d["hp"])])
	CampaignSave.clear()
	Campaign.reset()


func _check_qa_fixes() -> void:
	_mark("QA 修复：绿色友军归队 / 败北 / 牢门 / 回队")
	# 第三章：不和艾德里克对话，直接击败霍克 → 他也要进名单（离队状态，第八章再回来）
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(load("res://scripts/chapter3.gd"))
	await _new_battle()
	await _skip_story()
	var ed = battle.get_unit("edric")
	_check(ed != null and ed.is_npc(), "第三章艾德里克开场是绿色友军")
	battle.get_unit("hawk").take_damage(999)
	battle.check_end_conditions()
	await _wait_cond(func() -> bool: return battle.end_overlay.visible, 20.0)
	_check(Campaign.has_member("edric") and Campaign.status_of("edric") == "away", "没对话也应把艾德里克写进名单（离队），实际 %s" % Campaign.status_of("edric"))
	# 第十四章：加雷斯绿色时倒下 → 败北
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(load("res://scripts/chapter14.gd"))
	await _new_battle()
	await _skip_story()
	battle.chapter.on_turn_start(2)
	await _wait_cond(func() -> bool: return battle.get_unit("gareth") != null and battle.state != battle.S.STORY, 10.0)
	var g = battle.get_unit("gareth")
	_check(g != null and g.is_ally_fighter() and "gareth" in battle.chapter.lose_ids(), "加雷斯出场就是败北条件")
	if g != null:
		g.take_damage(999)
		_check("gareth" in battle.chapter.lose_ids(), "加雷斯倒下后仍在败北名单里")
	_check(battle.chapter.must_join_on_victory().has("gareth"), "第十四章胜利时加雷斯一行应自动归队")
	# 飞行单位飞不过关着的牢门；已阵亡的人 rejoin_unit 返回 null
	var peg: Unit = battle.spawn_units([{"id": "pegasus_q", "name": "天马骑士", "class": "天马骑士", "faction": "player", "level": 5,
		"hp": 20, "pwr": 6, "skl": 7, "spd": 10, "dfn": 4, "res": 6, "mov": 7, "weapons": ["iron_lance"], "pos": Vector2i(3, 3)}])[0]
	var door: Vector2i = peg.grid_pos + Vector2i(1, 0)
	battle.board.set_tile(door, "O")
	_check(not battle.board.passable(door, peg), "天马飞不过关着的牢门")
	var tia = battle.get_unit("tia")
	tia.take_damage(999)
	_check(battle.rejoin_unit("tia", Vector2i(2, 2), "player", {}) == null, "已阵亡的人 rejoin_unit 应返回 null，不复制")
	CampaignSave.clear()
	Campaign.reset()


## 第二篇用到的系统：偷窃、开门、飞行、撤退 / 阵亡、离队回归补等级
func _check_part2_systems() -> void:
	_mark("第二篇系统：偷窃 / 开门 / 飞行 / 撤退 / 回归")
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(load("res://scripts/chapter7.gd"))
	await _new_battle()
	await _skip_story()
	# 能力画面：第一次点敌人亮威胁范围，再点一次打开能力画面
	var e0 = battle.get_unit("church1")
	battle._idle_click(e0.grid_pos)
	_check(battle.unit_status == null and battle._previewed == e0, "第一次点敌人只亮出威胁范围")
	battle._idle_click(e0.grid_pos)
	await _frames(3)
	_check(battle.unit_status != null and is_instance_valid(battle.unit_status), "再点一次同一个敌人应打开能力画面")
	if battle.unit_status != null:
		var bs: Dictionary = battle.unit_status.battle_stats()
		_check(int(bs["atk"]) == int(GameData.WEAPONS[e0.weapons[0]]["mt"]) + e0.pwr, "能力画面的攻击 = 武器威力 + 力")
		_shot("21_unit_status.png")
		battle.unit_status.close()
		await _frames(3)
	_check(battle.unit_status == null, "关闭后能力画面应消失")
	# 对话气泡：缇娅在场、小雀能被缇娅对话 → 小雀头上有气泡；敌兵没有
	battle.refresh_talk_marks()
	_check(battle.get_unit("sparrow").has_talk_mark() and not e0.has_talk_mark(), "能对话的小雀头上应有气泡，普通敌兵没有")
	# 交换：缇娅把伤药交给相邻的妮娜，交换后不能撤销移动
	var t0 = battle.get_unit("tia")
	var n0 = battle.get_unit("nina")
	n0.grid_pos = t0.grid_pos + Vector2i(1, 0)
	if not battle.board.passable(n0.grid_pos, n0) or (battle.board.unit_at(n0.grid_pos) != null and battle.board.unit_at(n0.grid_pos) != n0):
		n0.grid_pos = t0.grid_pos + Vector2i(0, 1)
	n0.position = n0.tile_center()
	_check(n0 in battle._adjacent_allies(t0), "妮娜应在缇娅身边")
	battle.selected = t0
	battle.open_trade(t0, n0)
	await _frames(2)
	var tw: TradeWindow = battle.trade_window
	_check(tw != null, "应打开交换窗口")
	if tw != null:
		var k: int = PrepScreen.inventory(t0).map(func(e) -> String: return e["id"]).find("vulnerary")
		var before: int = n0.items.count("vulnerary")
		tw._on_slot(t0, k)
		tw._on_slot(n0, PrepScreen.inventory(n0).size())
		_check(n0.items.count("vulnerary") == before + 1 and not "vulnerary" in t0.items, "伤药应从缇娅换到妮娜身上")
		_shot("22_trade.png")
		tw.close()
		await _frames(3)
	_check(t0.get_meta("trade_locked", false), "交换过物品应锁住移动（不能撤销）")
	battle._clear_menu()
	t0.remove_meta("trade_locked")
	battle.selected = null
	battle.state = battle.S.IDLE
	# 友军阶段：一个绿色战斗单位会自己攻击身边的敌人
	var foe1 = battle.get_unit("church2")
	var ally: Unit = battle.spawn_units([{"id": "ally_t", "name": "义勇兵", "class": "战士", "faction": "npc", "fights": true, "level": 12,
		"hp": 40, "pwr": 16, "skl": 40, "spd": 10, "dfn": 8, "mov": 5, "weapons": ["iron_axe"], "pos": foe1.grid_pos + Vector2i(0, 1)}])[0]
	_check(ally.is_ally_fighter(), "fights 的中立单位应是第三方友军")
	var foe_hp := func() -> int:
		var t := 0
		for v in battle.units:
			if not v.is_player() and not v.is_npc() and v.is_alive():
				t += v.hp
		return t
	var hp_before: int = foe_hp.call()
	var ally_done := [false]
	var ap := func() -> void:
		await battle._ally_phase()
		ally_done[0] = true
	ap.call()
	await _wait_cond(func() -> bool:
		if battle.combat_scene.active:
			battle.combat_scene.skip()
		return ally_done[0], 30.0)
	_check(int(foe_hp.call()) < hp_before, "友军阶段绿色单位应攻击敌人（敌方总 HP %d → %d）" % [hp_before, int(foe_hp.call())])
	await _frames(10)
	battle.units.erase(ally)
	ally.queue_free()
	battle.state = battle.S.IDLE
	# 竞技场（第七章开放）：付押金单挑，打完 HP 回满、不会死
	_check(battle.chapter.has_arena(), "第七章应开放竞技场")
	battle.gold = 5000
	var g0: int = battle.gold
	var done := [false, ""]
	var runner := func() -> void:
		done[1] = await battle.run_arena(t0)
		done[0] = true
	runner.call()
	await _wait_cond(func() -> bool:
		if battle.combat_scene.active:
			battle.combat_scene.skip()
		return done[0], 60.0)
	_check(done[0] and done[1] in ["win", "lose", "draw"], "竞技场应打完一场，实际 %s" % str(done[1]))
	_check(t0.is_alive() and t0.hp == t0.max_hp, "竞技场打完缇娅应回满血、不会死")
	var cost := Arena.wager(t0)
	var expect: int = g0 + (cost * 3 / 2 - cost if done[1] == "win" else (-cost if done[1] == "lose" else 0))
	_check(battle.gold == expect, "竞技场结算金钱不对：%d → %d（%s）" % [g0, battle.gold, done[1]])
	battle.arena_fights = Arena.MAX_FIGHTS
	_check(await battle.run_arena(t0) == "", "超过每次出击准备的场数上限后不能再打")
	battle.arena_fights = 0
	battle.state = battle.S.IDLE
	var sp = battle.get_unit("sparrow")
	var foe = battle.get_unit("church5")
	_check(sp != null and foe != null, "第七章应有小雀和带伤药的教会兵")
	sp.faction = "player"
	sp.grid_pos = foe.grid_pos + Vector2i(-1, 0)
	if battle.board.unit_at(sp.grid_pos) != null and battle.board.unit_at(sp.grid_pos) != sp:
		sp.grid_pos = foe.grid_pos + Vector2i(1, 0)
	sp.position = sp.tile_center()
	_check(foe in battle.steal_targets(sp), "小雀速度够、相邻，应能偷带道具的敌人")
	var got: String = battle.steal(sp, foe)
	_check(got == "vulnerary" and "vulnerary" in sp.items and foe.items.is_empty(), "偷窃后道具应转到小雀身上，实际 %s" % got)
	_check(not foe in battle.steal_targets(sp), "敌人身上空了就不能再偷")
	foe.items.append("elixir")
	foe.item_uses.append(3)
	foe.spd = sp.spd + 1
	_check(not foe in battle.steal_targets(sp), "对方比小雀快就偷不了")
	# 开门
	var door: Vector2i = sp.grid_pos + Vector2i(0, -1)
	if battle.board.unit_at(door) != null:
		door = sp.grid_pos + Vector2i(0, 1)
	battle.board.set_tile(door, "O")
	_check(not battle.board.passable(door, sp), "牢门关着不能通过")
	_check(door in battle.door_tiles(sp), "盗贼站在牢门旁应能开门")
	var tia = battle.get_unit("tia")
	_check(battle.door_tiles(tia).is_empty() or tia.grid_pos.distance_to(door) > 1.0, "没钥匙的缇娅不能开门")
	await battle.open_door(sp, door)
	_check(battle.board.tile_at(door) == "S" and battle.board.passable(door, sp), "开门后应变成石地")
	_check([door.x, door.y] in battle.chapter.flags.get("doors_opened", []), "开过的门应记进章节旗标（读档补回）")
	# 飞行：天马骑士越过河流，每格 1；弓对天马 ×3
	var peg: Unit = battle.spawn_units([{"id": "pegasus_t", "name": "天马骑士", "class": "天马骑士", "faction": "enemy", "level": 5,
		"hp": 20, "pwr": 6, "skl": 7, "spd": 10, "dfn": 4, "res": 6, "mov": 7, "weapons": ["iron_lance"], "pos": Vector2i(5, 11)}])[0]
	var rng: Dictionary = battle.board.move_range(peg)
	var over_water := false
	for p in rng:
		if battle.board.tile_at(p) == "~":
			over_water = true
	_check(peg.is_flying() and over_water, "天马骑士应能飞到河面上")
	_check(Combat.effective_mt(GameData.WEAPONS["iron_bow"], peg) == 18, "弓对飞行单位威力应 ×3")
	_check(battle.board.terrain_bonus(peg, Vector2i(4, 13))["avo"] == 0, "飞行单位不吃地形回避")
	# 撤退 / 阵亡：第七章里凯因（主线戏份到第 18 章）重伤撤退，妮娜阵亡
	var kain = battle.get_unit("kain")
	var nina = battle.get_unit("nina")
	_check(battle.chapter_number() == 7, "第七章的章节序号应为 7")
	kain.take_damage(999)
	nina.take_damage(999)
	for v in [kain, nina]:
		battle._fallen_words(v)
		await _frames(2)
		await _wait_cond(func() -> bool: return not battle.dialogue.visible, 5.0)
	_check(kain.get_meta("retreated", false) and not nina.get_meta("retreated", false), "凯因应撤退、妮娜应阵亡")
	Campaign.store_party(battle.units)
	_check(Campaign.status_of("kain") == "retired" and Campaign.status_of("nina") == "dead", "名单：凯因 retired、妮娜 dead，实际 %s / %s" % [Campaign.status_of("kain"), Campaign.status_of("nina")])
	_check(Campaign.alive_in_story("kain") and not Campaign.alive_in_story("nina"), "转幕后的人剧情里还在，阵亡的不在")
	_check(not Campaign.can_rejoin("kain"), "转幕后的人不能回队出击")
	var saved: Dictionary = kain.to_save()
	_check(bool(saved.get("retreated", false)), "撤退标记应写进存档")
	# 回归补等级：在队两人 Lv15，离队的人 Lv5 → 补到 Lv13（平均 − 2）
	Campaign.roster = {
		"a": {"id": "a", "class": "剑士", "level": 15, "status": "active", "max_hp": 30},
		"b": {"id": "b", "class": "剑士", "level": 15, "status": "active", "max_hp": 30},
		"c": {"id": "c", "class": "剑士", "level": 5, "status": "away", "max_hp": 20, "pwr": 5,
			"growths": {"hp": 100, "pwr": 100, "skl": 0, "spd": 0, "dfn": 0}},
	}
	var n := Campaign.rejoin("c")
	_check(n == 8 and int(Campaign.roster["c"]["level"]) == 13, "回归应补 8 级到 Lv13，实际 +%d" % n)
	_check(int(Campaign.roster["c"]["max_hp"]) == 28 and int(Campaign.roster["c"]["pwr"]) == 13, "补等级按成长率加能力")
	_check(Campaign.status_of("c") == "active", "回归后状态应为 active")
	Campaign.roster["d"] = {"id": "d", "class": "剑士", "level": 18, "status": "away", "max_hp": 30}
	Campaign.roster["a"]["class"] = "剑圣"
	_check(Campaign.effective_level(Campaign.roster["a"]) == 35, "上级职业按 +20 级算")
	Campaign.reset()


## 宽屏手机（比 16:9 宽，例如 20:9）：地图、信息窗铺满整屏，战斗特写和标题居中且两边不露黑框
func _check_wide_screen() -> void:
	_mark("宽屏")
	if DisplayServer.get_name() == "headless":
		return
	# 先在 16:9 下把各套战斗背景截一张，人工看效果
	var gallery := CombatScene.new()
	add_child(gallery)
	await _frames(2)
	for spec in [["hills", "", false, "h"], ["river", "", false, "B"], ["town", "", false, "S"], ["castle", "", false, "T"], ["snow", "snow", false, "."], ["scorch", "", true, "."]]:
		gallery.theme = spec[1]
		gallery.burning = spec[2]
		gallery.tint = Color.WHITE
		gallery._fit_wide()
		gallery._rebuild_bg(CombatScene.GROUND_COLORS["."], spec[3])
		gallery._set_cam(0.0)
		gallery.visible = true
		gallery._root.modulate.a = 1.0
		await _frames(3)
		_check(gallery.bg_set_for(spec[3]) == spec[0], "战斗背景图鉴应为 " + spec[0])
		_shot("20_combat_bg_%s.png" % spec[0])
	gallery.queue_free()
	await _frames(2)
	var win := get_window()
	var old_size := win.size
	var old_mode := win.mode
	win.mode = Window.MODE_WINDOWED
	win.size = Vector2i(int(old_size.y * 1600.0 / 720.0), old_size.y)
	await _frames(6)
	var screen := SafeArea.screen()
	_check(screen.x > 1500.0 and is_equal_approx(screen.y, 720.0), "宽屏测试前提：可见宽度应约 1600，实际 %s" % screen)
	_check(SafeArea.pad_x() > 100.0, "宽屏时 1280 设计画面左右应各留出约 160，实际 %s" % SafeArea.pad_x())
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(null)
	await _new_battle()
	await _skip_story()
	_check(is_equal_approx(battle.map_clip.size.x, screen.x), "宽屏时地图区应铺满整屏宽，实际 %s / %s" % [battle.map_clip.size.x, screen.x])
	_check(is_equal_approx(battle.board.view_size.x, screen.x), "宽屏时地图视口应按整屏宽卷动")
	_check(is_equal_approx(battle.hud.size.x, screen.x), "宽屏时信息窗层应铺满整屏宽")
	battle.hud.side = "right"
	battle.hud.refresh()
	var goal: Control = battle.hud.goal_win
	_check(absf(goal.position.x + goal.size.x - (screen.x - SafeArea.MARGIN_X)) < 2.0, "宽屏时右侧信息窗应贴着右安全边，右缘 %s" % (goal.position.x + goal.size.x))
	await _frames(4)
	_shot("19_wide_map.png")
	# 教程层、剧情场景卡、大陆地图：setup 之后才居中（之前被 setup 归零）
	_check(absf(battle.tutorial.position.x - SafeArea.pad_x()) < 1.0, "宽屏时教程层应居中，x=%s" % battle.tutorial.position.x)
	battle.play_scenes([{"title": "测试", "mood": "night", "lines": []}])
	await _frames(3)
	var card_x := -1.0
	for c in battle.ui.get_children():
		if c is SceneCard:
			card_x = c.position.x
	_check(absf(card_x - SafeArea.pad_x()) < 1.0, "宽屏时剧情场景卡应居中，x=%s" % card_x)
	await _wait_cond(func() -> bool:
		for c in battle.ui.get_children():
			if c is SceneCard:
				return false
		return true, 8.0)
	# 战斗特写：整体居中，背景层和底部面板铺到屏幕两边
	var tia = battle.get_unit("tia")
	var foe: Unit = null
	for e in battle.units:
		if not e.is_player() and e.is_alive():
			foe = e
			break
	if tia != null and foe != null:
		foe.grid_pos = tia.grid_pos + Vector2i(1, 0)
		foe.position = foe.tile_center()
		battle.do_combat(tia, foe, 0)
		var t := 0.0
		while not battle.combat_scene.active and t < 5.0:
			await get_tree().create_timer(0.05).timeout
			t += 0.05
		await get_tree().create_timer(0.6).timeout
		var cs: CombatScene = battle.combat_scene
		_check(is_equal_approx(cs.offset.x, SafeArea.pad_x()), "宽屏时战斗特写应整体居中，offset %s" % cs.offset.x)
		var covered := true
		for spr in cs._layers:
			if is_instance_valid(spr):
				var r: Rect2 = spr.get_rect()
				var left: float = cs.offset.x + spr.position.x + r.position.x * spr.scale.x
				var right: float = left + r.size.x * spr.scale.x
				if left > 1.0 or right < screen.x - 1.0:
					covered = false
		_check(covered, "宽屏时战斗背景各层应盖住整屏宽")
		_shot("19b_wide_combat.png")
		var ok: bool = await _wait_cond(func() -> bool: return not battle.combat_scene.active, 20.0)
		_check(ok, "宽屏战斗应能正常结束")
	battle.queue_free()
	await _frames(3)
	battle = null
	var title = load("res://scenes/title.tscn").instantiate()
	add_child(title)
	await _frames(3)
	_check(is_equal_approx(title.position.x, SafeArea.pad_x()), "宽屏时标题应居中，x=%s" % title.position.x)
	_shot("19c_wide_title.png")
	title.queue_free()
	win.size = old_size
	win.mode = old_mode
	await _frames(6)
	CampaignSave.clear()
	Campaign.reset()


## 第三篇：第 23 章救缇娅、巴尔托回队；七号三步条件 → 第 27 章入队 / 战死；第 28 章罗兰与「名字」；第 30 章两种结局
func _check_part3() -> void:
	_mark("第三篇：第 23 章缇娅回队、巴尔托回归")
	CampaignSave.clear()
	_p3_roster({"edric": "active", "gareth": "active", "vera": "active", "noya": "active",
		"tia": "away", "balto": "away", "harlo": "away", "bandit6": "retired"})
	Campaign.chapter_index = Campaign.CHAPTERS.find("res://scripts/chapter23.gd")
	Campaign.snapshot_start()
	load("res://scripts/battle.gd").queue_chapter(null)
	await _new_battle()
	await _skip_story()
	_check(battle.chapter.chapter_id() == "ch23", "第二十二章之后应进第二十三章，实际 " + battle.chapter.chapter_id())
	var t23 = battle.get_unit("tia")
	_check(t23 != null and t23.is_npc() and not "tia" in battle.chapter.lose_ids(), "第 23 章缇娅开场关在塔里（中立），还不算败北条件")
	_check(battle.get_unit("balto") == null, "巴尔托第 2 回合才赶到")
	battle.state = battle.S.IDLE
	battle.start_player_phase()
	var ok: bool = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE and battle.turn == 2, 20.0)
	var b23 = battle.get_unit("balto")
	_check(ok and b23 != null and b23.is_player() and Campaign.status_of("balto") == "active", "第 2 回合巴尔托从名单回队")
	_check(battle.get_unit("harlo") != null and battle.get_unit("bandit6") == null, "哈洛回队，转幕后的托比不出场")
	var o23 = battle.get_unit("orion")
	_check(o23 != null and o23.is_player() and o23.class_label == "狙击手", "奥瑞恩随巴尔托入队")
	var v23 = battle.get_unit("vera")
	v23.grid_pos = Chapter23.CELL_DOOR + Vector2i(0, 1)
	v23.position = v23.tile_center()
	_check(Chapter23.CELL_DOOR in battle.door_tiles(v23), "薇拉站在塔顶牢门旁应能开门")
	battle.open_door(v23, Chapter23.CELL_DOOR)
	ok = await _wait_cond(func() -> bool: return battle.board.tile_at(Chapter23.CELL_DOOR) == "S" and battle.state == battle.S.IDLE, 10.0)
	var e23 = battle.get_unit("edric")
	e23.grid_pos = Chapter23.TIA_CELL + Vector2i(0, 1)
	e23.position = e23.tile_center()
	e23.has_acted = false
	_check(ok and battle.chapter.get_recruit_target(e23) == t23, "开门后艾德里克走到缇娅身边应能【对话】")
	battle.selected = e23
	battle._on_menu_recruit()
	ok = await _wait_cond(func() -> bool: return t23.is_player() and battle.state == battle.S.IDLE, 15.0)
	_check(ok and Campaign.status_of("tia") == "active" and "tia" in battle.chapter.lose_ids(), "缇娅回队，之后倒下算败北")
	battle.get_unit("hector").take_damage(999)
	battle.check_end_conditions()
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 30.0)
	_check(ok and Campaign.flags.get("tia_rescued", false) and Campaign.status_of("tia") == "active", "第 23 章通关，缇娅在队")
	_check(Campaign.status_of("orion") == "active" and Campaign.status_of("bandit6") == "retired", "奥瑞恩写进名单，托比仍在幕后")

	# ---- 七号第 2 步：第 24 章缇娅对话 ----
	_mark("第三篇：七号三步条件")
	CampaignSave.clear()
	Campaign.reset()
	Campaign.flags["seven_16_spared"] = true
	_check(not Part3Chapter.seven_ready(), "只有第 16 章一步时七号条件不成立")
	var s24 = await _p3_seven_turn3("res://scripts/chapter24.gd")
	_check(s24 != null and s24.is_alive() and not s24.is_player(), "第 24 章第 3 回合七号出现")
	if s24 != null:
		var tia24 = battle.get_unit("tia")
		_p3_place(tia24, s24.grid_pos)
		_check(battle.chapter.get_recruit_target(tia24) == s24, "缇娅走到七号身边应能对话")
		var g24 = battle.get_unit("gareth")
		_check(g24 == null or battle.chapter.get_recruit_target(g24) != s24, "加雷斯不能和七号对话")
		battle.selected = tia24
		battle._on_menu_recruit()
		ok = await _wait_cond(func() -> bool: return Campaign.flags.get("seven_24_talked", false) and battle.state == battle.S.IDLE, 15.0)
		_check(ok and s24.grid_pos == Unit.OFF_MAP and not s24.is_player(), "对话后七号撤退（不入队），第 2 步达成")
	# ---- 第 26 章：被击杀 → 第 3 步失败 ----
	var s26k = await _p3_seven_turn3("res://scripts/chapter26.gd")
	if s26k != null:
		s26k.take_damage(999)
		battle.chapter.on_after_combat(battle.get_unit("tia"), s26k, true)
		await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE and Campaign.flags.get("seven_26_killed", false), 10.0)
	_check(Campaign.flags.get("seven_26_killed", false) and not Part3Chapter.seven_ready(), "第 26 章击杀七号，条件失败")
	# ---- 第 26 章：缇娅对话 → 第 3 步达成 ----
	Campaign.flags["seven_26_killed"] = false
	var s26 = await _p3_seven_turn3("res://scripts/chapter26.gd")
	_check(s26 != null and s26.is_alive() and not s26.is_player(), "第 26 章第 3 回合七号出现")
	if s26 != null:
		var tia26 = battle.get_unit("tia")
		_p3_place(tia26, s26.grid_pos)
		battle.selected = tia26
		battle._on_menu_recruit()
		ok = await _wait_cond(func() -> bool: return Campaign.flags.get("seven_26_talked", false) and battle.state == battle.S.IDLE, 15.0)
		_check(ok and s26.grid_pos == Unit.OFF_MAP, "第 26 章缇娅对话后七号撤退")
	_check(Part3Chapter.seven_ready(), "三步都达成后七号条件成立")
	# ---- 第 27 章：倒戈入队 ----
	var keep: Dictionary = Campaign.flags.duplicate(true)
	load("res://scripts/battle.gd").queue_chapter(load("res://scripts/chapter27.gd"))
	await _new_battle()
	await _skip_story()
	var s27 = battle.get_unit("seven")
	_check(s27 != null and s27.is_npc(), "条件达成：第 27 章开场七号站在一边（中立）")
	battle.state = battle.S.IDLE
	battle.start_player_phase()
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE and battle.turn == 2, 20.0)
	var j27 = battle.get_unit("seven")
	_check(ok and j27 != null and j27.is_player() and not j27.is_boss, "第 2 回合七号倒戈入队")
	battle.get_unit("zero").take_damage(999)
	battle.check_end_conditions()
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 30.0)
	_check(ok and Campaign.flags.get("seven_joined", false) and not Campaign.flags.get("seven_dead", false), "击败零号：七号入队，没有战死")
	_check(Campaign.status_of("seven") == "active", "七号写进名单")
	# ---- 第 27 章：条件不足 → 战死 ----
	Campaign.reset()
	Campaign.flags = keep.duplicate(true)
	Campaign.flags["seven_24_talked"] = false
	load("res://scripts/battle.gd").queue_chapter(load("res://scripts/chapter27.gd"))
	await _new_battle()
	await _skip_story()
	var f27 = battle.get_unit("seven")
	_check(f27 != null and not f27.is_npc() and not f27.is_player() and f27.is_boss, "条件不足：七号是敌将")
	battle.get_unit("zero").take_damage(999)
	battle.check_end_conditions()
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 30.0)
	_check(ok and Campaign.flags.get("seven_dead", false) and not Campaign.flags.get("seven_joined", false), "条件不足：第 27 章七号战死")
	_check(not Campaign.has_member("seven"), "战死的七号不进名单")

	# ---- 第 28 章：罗兰与菲恩之剑、缇娅 × 七号「名字」 ----
	_mark("第三篇：罗兰 / 名字 / 双结局")
	CampaignSave.clear()
	Campaign.reset()
	Campaign.flags["seven_joined"] = true
	load("res://scripts/battle.gd").queue_chapter(load("res://scripts/chapter28.gd"))
	await _new_battle()
	await _skip_story()
	var r28 = battle.get_unit("roland")
	var e28 = battle.get_unit("edric")
	_check(r28 != null and r28.is_npc(), "罗兰开场是中立单位")
	_p3_place(e28, r28.grid_pos)
	_check(battle.chapter.get_recruit_target(e28) == r28, "艾德里克走到罗兰身边应能对话")
	var t28 = battle.get_unit("tia")
	_p3_place(t28, r28.grid_pos)
	_check(battle.chapter.get_recruit_target(t28) == null, "只有艾德里克能和罗兰对话")
	battle.state = battle.S.IDLE
	battle.selected = e28
	battle._on_menu_recruit()
	ok = await _wait_cond(func() -> bool: return r28.is_player() and battle.state == battle.S.IDLE, 15.0)
	var conv: Array = []
	for c in Campaign.convoy:
		conv.append(c[0])
	_check(ok and ("fenn_sword" in e28.weapons or "fenn_sword" in conv), "罗兰入队，艾德里克拿到菲恩之剑")
	_check(e28.class_label == "誓约领主", "艾德里克满 Lv10 剧情转职为誓约领主，实际 " + e28.class_label)
	var sev28 = battle.get_unit("seven")
	_p3_place(t28, sev28.grid_pos)
	_check(battle.chapter.get_talk_partner(t28) == sev28, "缇娅与七号相邻应能聊「名字」")
	battle.selected = t28
	battle._on_menu_talk()
	ok = await _wait_cond(func() -> bool: return Campaign.flags.get("seven_named", false) and battle.state == battle.S.IDLE, 15.0)
	_check(ok, "聊完「名字」记下 seven_named")
	_check(battle.chapter.get_talk_partner(t28) != sev28, "「名字」全篇只聊一次")

	# ---- 第 30 章：真结局 / 普通结局（没聊过「名字」）----
	await _p3_finale(true)
	await _p3_finale(false)
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(null)


## 终章：封印柱削弱、守护之火觉醒、击败莫尔甘后按条件给出结局
func _p3_finale(good: bool) -> void:
	CampaignSave.clear()
	Campaign.reset()
	Campaign.flags["seven_joined"] = true
	Campaign.flags["seven_named"] = good
	load("res://scripts/battle.gd").queue_chapter(load("res://scripts/chapter30.gd"))
	await _new_battle()
	await _skip_story()
	_check(battle.chapter.chapter_id() == "ch30" and "seven" in battle.chapter.forced_ids(), "终章：七号在队时强制出击")
	var m = battle.get_unit("morgan")
	_check(m != null and m.class_label == "炎龙" and m.max_hp >= 120, "终章首领是与炎龙融合的莫尔甘")
	var dfn0: int = m.dfn
	var o = battle.get_unit("orion")
	o.grid_pos = Chapter30.PILLARS[0]
	o.position = o.tile_center()
	o.has_acted = false
	battle.state = battle.S.IDLE
	battle._finish_action(o)
	var ok: bool = await _wait_cond(func() -> bool: return m.dfn == dfn0 - Chapter30.PILLAR_CUT and battle.state == battle.S.IDLE, 15.0)
	_check(ok and battle.board.goal_tiles.size() == 3, "点亮封印柱：莫尔甘守备 -4，剩 3 座")
	battle.turn = 2
	battle.start_player_phase()
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE and battle.turn == 3, 20.0)
	var tia = battle.get_unit("tia")
	_check(ok and tia.weapons[0] == "guardian_flame" and Campaign.flags.get("tia_guardian", false), "第 3 回合缇娅觉醒守护之火")
	_check(tia.class_label == "不灭巫女", "炎刃使满 Lv10：剧情转职为不灭巫女，实际 " + tia.class_label)
	_check(Combat.effective_mt(GameData.WEAPONS["guardian_flame"], m) == 36, "守护之火对炎龙特效 ×3")
	m.take_damage(999)
	battle.check_end_conditions()
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 40.0)
	var want := "true" if good else "normal"
	_check(ok and Campaign.flags.get("ending", "") == want, "终章结局应为 %s，实际 %s" % [want, str(Campaign.flags.get("ending", ""))])
	_check(("真结局" if good else "余烬") in battle.end_title.text and "完" in battle.end_title.text, "结局标题，实际 " + battle.end_title.text)
	_check(Campaign.is_finished() and not battle.end_next.visible and tr("感谢游玩！") in battle.end_sub.text and not "制作中" in battle.end_sub.text, "通关：没有下一章，不显示制作中")
	_shot("p3_ending_%s.png" % want)


## 名单为空时按第三篇默认阵容造几个人进名单（status：active / away / retired）
func _p3_roster(ids: Dictionary) -> void:
	Campaign.reset()
	for id in ids:
		var d: Dictionary = Part3Chapter.member(id, 0)
		d["id"] = id
		var u := Unit.new()
		u.setup(d)
		var data: Dictionary = u.to_save()
		data["status"] = ids[id]
		Campaign.roster[id] = data
		u.free()


## 直接开某一章，推进到第 3 回合（七号出现），返回七号
func _p3_seven_turn3(path: String):
	load("res://scripts/battle.gd").queue_chapter(load(path))
	await _new_battle()
	await _skip_story()
	battle.turn = 2
	battle.state = battle.S.IDLE
	battle.start_player_phase()
	await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE and battle.turn == 3, 20.0)
	return battle.get_unit("seven")


## 把 u 放到 near 旁边的空格
func _p3_place(u, near: Vector2i) -> void:
	for d in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
		var q: Vector2i = near + d
		if battle.board.passable(q, u) and (battle.board.unit_at(q) == null or battle.board.unit_at(q) == u):
			u.grid_pos = q
			u.position = u.tile_center()
			u.has_acted = false
			return


## 自动试玩：我方也交给 EnemyAI 操作，把第 2–30 章各打几个回合。
## 只验证流程（敌方回合、治疗、增援、撤离 / 守关判定）不卡死、不报错；胜负结果打印出来供调难度参考。
func _check_autoplay() -> void:
	for spec in [[2, 3], [3, 4], [4, 5], [5, 7], [6, 4], [7, 4], [8, 3], [9, 3], [10, 3], [11, 3], [12, 3], [13, 3], [14, 3],
			[15, 3], [16, 3], [17, 3], [18, 3], [19, 3], [20, 3], [21, 3], [22, 3],
			[23, 3], [24, 3], [25, 3], [26, 3], [27, 3], [28, 3], [29, 3], [30, 3]]:
		var idx: int = spec[0]
		_mark("自动试玩 第 %d 章" % idx)
		var res: Dictionary = await _autoplay(load("res://scripts/chapter%d.gd" % idx), spec[1])
		print("[AUTOPLAY] ch%d %s" % [idx, str(res)])
		_check(not res["stuck"], "第 %d 章自动试玩卡住了: %s" % [idx, str(res)])
		_check(res["turn"] >= 2 or res["over"], "第 %d 章至少应打完一轮敌方回合: %s" % [idx, str(res)])
	Engine.time_scale = 1.0
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(null)


func _autoplay(script: Script, max_turns: int, shot := "") -> Dictionary:
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(script)
	await _new_battle()
	if _demo:
		await _demo_story()
	else:
		await _skip_story()
	if shot != "":
		_shot(shot)
	Engine.time_scale = 1.0 if _demo else 6.0
	var t := 0.0
	var stuck := false
	var last_turn := 0
	while battle.state != battle.S.OVER and battle.turn <= max_turns:
		if battle.turn != last_turn:
			last_turn = battle.turn
			var alive: Array = []
			for v in battle.units:
				if v.is_alive() and v.is_player():
					alive.append("%s:%d/%d Lv%d" % [v.unit_id, v.hp, v.max_hp, v.level])
			print("[AUTOPLAY]   turn %d %s" % [battle.turn, str(alive)])
		if _demo:
			_demo_tips()
		if battle.state == battle.S.STORY:
			if _demo:
				_demo_dialogue()
			else:
				battle.dialogue.skip_all()
		if battle.state == battle.S.PREP and battle.prep != null:
			battle.prep.done.emit()
		if battle.combat_scene.active and not _demo:
			battle.combat_scene.skip()
		if battle.state == battle.S.IDLE:
			if _demo:
				await get_tree().create_timer(0.4).timeout
				if battle.state == battle.S.IDLE:
					await _auto_act()
			else:
				_auto_act()
		await get_tree().create_timer(0.05, true, false, true).timeout
		t += 0.05
		if t > (900.0 if _demo else 90.0):
			stuck = true
			break
	# 结算剧情也要放完
	var t2 := 0.0
	while (battle.state == battle.S.OVER or battle.state == battle.S.STORY) and not battle.end_overlay.visible and t2 < (120.0 if _demo else 10.0):
		if battle.dialogue.visible:
			if _demo:
				_demo_dialogue()
			else:
				battle.dialogue.skip_all()
		await get_tree().create_timer(0.05).timeout
		t2 += 0.05
	Engine.time_scale = 1.0
	var players := 0
	var foes := 0
	for u in battle.units:
		if u.is_alive():
			if u.is_player():
				players += 1
			else:
				foes += 1
	var over: bool = battle.end_overlay.visible
	var won: bool = over and "完" in battle.end_title.text
	return {"stuck": stuck, "over": over, "won": won, "turn": battle.turn, "players": players, "foes": foes}


## 谨慎的自动玩家：算一算站到每一格之后下回合会挨多少打，不往敌群里冲；
## 能安全出手就打（优先能击杀的），否则退到最安全的格子。撤离章让缇娅朝撤离点走。
func _auto_act() -> void:
	var u: Unit = null
	for v in battle.units:
		if v.is_player() and v.is_alive() and not v.has_acted:
			u = v
			break
	if u == null:
		return  # 最后一人行动完，after_player_action 会自己进敌方回合
	var foes: Array = battle.units.filter(func(x) -> bool: return not x.is_player() and not x.is_npc() and x.is_alive())
	battle.selected = u
	if foes.is_empty():
		battle._finish_action(u)
		return
	if not u.can_attack():
		var act: Dictionary = EnemyAI.choose(u, battle.board, foes)
		if act.get("heal") != null:
			u.grid_pos = act["move_to"]
			u.position = u.tile_center()
			battle.state = battle.S.COMBAT
			_auto_heal(u, act["heal"])
			return
	var move: Dictionary = battle.board.move_range(u)
	var goal: Array = battle.board.goal_tiles if u.unit_id == "tia" else []
	# 败北条件里的人（缇娅、巴尔托等）倒下就输，真人会更护着他们
	var key_unit: bool = u.unit_id in battle.chapter.lose_ids()
	var risk := 3.0 if key_unit else 1.2
	var lethal := u.hp * (0.6 if key_unit else 1.0)
	var home := u.grid_pos
	var best_score := -99999.0
	var best_tile := home
	var best_target: Unit = null
	var best_wi := 0
	for tile in move.keys():
		u.grid_pos = tile
		var danger := _danger_at(u, foes)
		var base := -danger * risk
		if danger >= lethal:
			base -= 200.0
		if not goal.is_empty():
			var gd := 99
			for g in goal:
				gd = mini(gd, GameData.dist(tile, g))
			base -= gd * 6.0
			if tile in goal:
				base += 500.0
		if base > best_score:
			best_score = base
			best_tile = tile
			best_target = null
		for e in foes:
			var d: int = GameData.dist(tile, e.grid_pos)
			for wi in u.weapons.size():
				if not battle.board.can_hit_from(u, d, wi):
					continue
				var f: Dictionary = Combat.forecast(u, e, wi, battle.board, tile)
				var dealt: float = f["a_dmg"] * f["a_times"] * f["a_hit"] / 100.0
				var taken: float = f["d_dmg"] * f["d_times"] * f["d_hit"] / 100.0 if f["d_can"] else 0.0
				var score := base + dealt * 2.0 - taken * 1.5
				if f["a_dmg"] * f["a_times"] >= e.hp:
					score += 40.0
				if f["d_can"] and f["d_dmg"] * f["d_times"] >= u.hp:
					score -= 300.0
				if score > best_score:
					best_score = score
					best_tile = tile
					best_target = e
					best_wi = wi
	if _demo and best_tile != home:
		# 演示：像玩家一样先亮出移动范围，再一格一格走过去
		u.grid_pos = home
		battle.state = battle.S.COMBAT
		battle.board.show_move(move, {})
		await get_tree().create_timer(0.5).timeout
		battle.board.clear_highlights()
		await battle._animate_move(u, battle.board.find_path(u, best_tile, move))
	u.grid_pos = best_tile
	u.position = u.tile_center()
	if best_target != null:
		battle.do_combat(u, best_target, best_wi)
	else:
		battle._finish_action(u)


## 演示：情境提示框显示 2.5 秒后自动点「知道了」
var _demo_tip_t := 0.0


func _demo_tips() -> void:
	if battle.tutorial == null or not battle.tutorial.is_showing():
		_demo_tip_t = 0.0
		return
	_demo_tip_t += 0.05
	if _demo_tip_t >= 2.5:
		_demo_tip_t = 0.0
		battle.tutorial._on_ok()


## 演示：一句打完后停 1.6 秒再翻页
func _demo_dialogue() -> void:
	if not battle.dialogue.visible or battle.dialogue.is_typing():
		_demo_t = 0.0
		return
	_demo_t += 0.05
	if _demo_t >= 1.6:
		_demo_t = 0.0
		battle.dialogue.advance()


## 演示：开场的大陆地图、旁白、对话、整备都按正常节奏放
func _demo_story() -> void:
	var t := 0.0
	var prep_t := 0.0
	while (battle.state == battle.S.STORY or battle.state == battle.S.PREP) and t < 300.0:
		if battle.tutorial != null and battle.tutorial.asking:
			battle.tutorial.choose(false)
		elif battle.state == battle.S.PREP and battle.prep != null:
			prep_t += 0.05
			if prep_t > 2.5:
				battle.prep.done.emit()
		else:
			_demo_dialogue()
		_demo_tips()
		await get_tree().create_timer(0.05).timeout
		t += 0.05
	await _frames(2)


## 站在当前格时，下个敌方回合大约要挨多少伤害（能走到并打到它的敌人，按命中率折算）
func _danger_at(u: Unit, foes: Array) -> float:
	var total := 0.0
	for e in foes:
		if e.hold and not EnemyAI._threatened(e, battle.board, [u]):
			continue
		var reach: int = (0 if e.stationary else e.mov) + 2
		if GameData.dist(e.grid_pos, u.grid_pos) > reach:
			continue
		var best := 0.0
		for wi in e.weapons.size():
			if GameData.WEAPONS[e.weapons[wi]]["type"] == "staff":
				continue
			var f: Dictionary = Combat.forecast(e, u, wi, battle.board, u.grid_pos + Vector2i(0, 1))
			best = maxf(best, f["a_dmg"] * f["a_times"] * f["a_hit"] / 100.0)
		total += best
	return total


func _auto_heal(u: Unit, v: Unit) -> void:
	await battle.do_heal(u, v)
	battle._finish_action(u)


func _new_battle() -> void:
	if battle != null and is_instance_valid(battle):
		battle.queue_free()
		await _frames(3)
	battle = load("res://scenes/battle.tscn").instantiate()
	get_tree().root.add_child(battle)
	battle.set_process_unhandled_input(false)
	await _frames(6)


## 新手教程：开场询问、分步引导按事件推进、金框、情境提示只弹一次、地图菜单里的教程手册
func _check_tutorial() -> void:
	_mark("新手教程")
	if battle != null and is_instance_valid(battle):
		battle.queue_free()
		await _frames(3)
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(null)
	battle = load("res://scenes/battle.tscn").instantiate()
	get_tree().root.add_child(battle)
	battle.set_process_unhandled_input(false)
	await _frames(6)
	var t := 0.0
	while not battle.tutorial.asking and t < 15.0:
		battle.dialogue.skip_all()
		await get_tree().create_timer(0.15).timeout
		t += 0.15
	_check(battle.tutorial.asking and battle.ui.find_child("TutorialYes", true, false) != null, "第一章开场应询问要不要教程")
	await _frames(3)
	_shot("01c_tutorial_ask.png")
	battle.tutorial.choose(true)
	var ok: bool = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE, 10.0)
	_check(ok and battle.tutorial.guided and battle.tutorial.current_step() == 0, "选了教程应进入分步引导第一步")
	var tia = battle.get_unit("tia")
	var balto = battle.get_unit("balto")
	_check(battle.tutorial._marker != null and battle.tutorial._marker.visible and battle.tutorial._marker.grid == tia.grid_pos, "第一步金框应标在缇娅身上")
	await _frames(10)
	_shot("01d_tutorial_step1.png")
	battle.click_tile(balto.grid_pos)
	await _frames(2)
	_check(battle.tutorial.current_step() == 0, "点错人不应推进引导")
	battle.cancel()
	battle.click_tile(tia.grid_pos)
	await _frames(2)
	_check(battle.tutorial.current_step() == 1, "选中缇娅后应进入第二步（移动）")
	battle.click_tile(tia.grid_pos)
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.ACTION_MENU, 5.0)
	_check(ok and battle.tutorial.current_step() == 2, "移动后弹出行动菜单应进入第三步")
	var labels: Array = []
	for b in battle.menu_box.get_children():
		if b is Button and not b.is_queued_for_deletion():
			labels.append(b.text)
	battle._on_menu_wait()
	ok = await _wait_cond(func() -> bool: return battle.state == battle.S.IDLE and tia.has_acted, 5.0)
	_check(ok and battle.tutorial.current_step() == 3, "缇娅待机后应进入第四步（巴尔托）")
	_check(battle.tutorial._marker.grid == balto.grid_pos, "第四步金框应标在巴尔托身上")
	battle.tutorial._on_skip()
	_check(not battle.tutorial.guided and not battle.tutorial.is_showing(), "跳过教程应收起引导")
	# 情境提示：只弹一次
	battle.tutorial.on_event("forecast", {"triangle": 1, "magic": false})
	_check(battle.tutorial.is_showing() and Tutorial.seen("triangle"), "第一次遇到武器克制应弹提示")
	battle.tutorial._on_ok()
	battle.tutorial.on_event("forecast", {"triangle": -1, "magic": false})
	_check(not battle.tutorial.is_showing(), "同一条提示不应再弹")
	# 地图菜单里的教程手册
	battle.open_map_menu(Vector2i(14, 9))
	await _frames(2)
	var mlabels: Array = []
	for b in battle.menu_box.get_children():
		if b is Button and not b.is_queued_for_deletion():
			mlabels.append(b.text)
	_check("教程" in mlabels, "地图菜单应有【教程】，实际 %s" % str(mlabels))
	battle._on_map_tutorial()
	await _frames(2)
	_check(battle.tutorial.browser_open(), "应打开教程手册")
	await _frames(3)
	_shot("01e_tutorial_browser.png")
	battle.tutorial.close_browser()
	await _frames(2)
	_check(not battle.tutorial.browser_open(), "教程手册应能关闭")
	# 地图商店：站到道具店上 → 菜单有【道具店】→ 买、卖 → 做过买卖关店算行动结束
	_mark("地图商店")
	battle.state = battle.S.IDLE
	tia.has_acted = false
	tia.grid_pos = Chapter1.SHOP_VENDOR
	tia.position = tia.tile_center()
	battle.selected = tia
	battle.pre_move_pos = tia.grid_pos
	battle._open_action_menu(tia)
	await _frames(2)
	var slabels: Array = []
	for b in battle.menu_box.get_children():
		if b is Button and not b.is_queued_for_deletion():
			slabels.append(b.text)
	_check("道具店" in slabels, "站在道具店上菜单应有【道具店】，实际 %s" % str(slabels))
	battle.gold = 1000
	var vul_before: int = tia.items.count("vulnerary")
	battle._on_menu_shop()
	await _frames(3)
	_check(battle.shop_window != null and battle.ui.find_child("ShopWindow", true, false) != null, "应打开商店窗口")
	_shot("01f_shop.png")
	battle.shop_window.buy("vulnerary")
	_check(battle.gold == 700 and tia.items.count("vulnerary") == vul_before + 1, "道具店买伤药 300G，金钱应剩 700，实际 %d" % battle.gold)
	var gold_mid: int = battle.gold
	battle.shop_window.sell(0)
	_check(battle.gold > gold_mid, "卖出东西应拿回金钱")
	battle.shop_window.close_shop()
	ok = await _wait_cond(func() -> bool: return tia.has_acted and battle.state == battle.S.IDLE, 5.0)
	_check(ok, "做过买卖关店后应算行动结束")
	_check(battle.board.terrain(Chapter1.SHOP_ARMORY)["name"] == "武器店", "第一章应有武器店")
	# 像素立绘：对话表里的立绘都要有文件；对话框里 ×2 最近邻显示
	for spk in DialogueBox.PORTRAITS:
		_check(ResourceLoader.exists("res://art/portraits/px/%s.png" % DialogueBox.PORTRAITS[spk]), "缺像素立绘：" + spk)
	battle.dialogue.play([{"name": "缇娅", "color": Color(1, 0.62, 0.45), "text": "这是像素立绘的测试台词。"},
		{"name": "塞拉斯", "color": Color(0.95, 0.92, 1.0), "text": "……异端。"}])
	await get_tree().create_timer(0.8).timeout
	_check(battle.dialogue._portrait_frame.visible and battle.dialogue._portrait.texture != null, "缇娅的台词应显示像素立绘")
	_shot("00b_portrait.png")
	battle.dialogue.skip_all()
	await _frames(2)
	# 剧情场景卡（尾声的敌方视角）
	battle.play_scenes(battle.chapter.epilogue())
	await get_tree().create_timer(1.0).timeout
	_check(battle.ui.find_child("SceneCard", true, false) != null and battle.state == battle.S.STORY, "尾声应放场景卡")
	_shot("01g_scene_card.png")
	var sc_t := 0.0
	while battle.ui.find_child("SceneCard", true, false) != null and sc_t < 10.0:
		battle.dialogue.skip_all()
		await get_tree().create_timer(0.15).timeout
		sc_t += 0.15
	battle.state = battle.S.IDLE
	# 不要教程：不问第二遍、不弹提示
	_check(Tutorial.seen("shop"), "第一次碰到商店应弹商店提示")
	battle.tutorial._on_ok()
	Campaign.flags["tutorial"] = false
	Campaign.flags["tips_seen"] = []
	battle.tutorial.on_event("prep")
	_check(not battle.tutorial.is_showing(), "关掉教程后不应弹提示")
	battle.queue_free()
	await _frames(3)
	CampaignSave.clear()
	Campaign.reset()


func _spawn_battle() -> void:
	# 新开一局从第一章开始；读档时 battle 会用存档里的战役进度覆盖
	if not CampaignSave.pending_load:
		Campaign.reset()
	battle = load("res://scenes/battle.tscn").instantiate()
	get_tree().root.add_child(battle)
	# 测试全程直接调用内部方法, 屏蔽真实鼠标输入, 防止用户动鼠标干扰
	battle.set_process_unhandled_input(false)
	await _frames(6)
	await _skip_story()


func _skip_story() -> void:
	var t := 0.0
	while (battle.state == battle.S.STORY or battle.state == battle.S.PREP) and t < 20.0:
		if battle.tutorial != null and battle.tutorial.asking:
			battle.tutorial.choose(false)   # 测试默认不开教程（教程有专门的用例）
		elif battle.state == battle.S.PREP and battle.prep != null:
			battle.prep.done.emit()   # 整备按默认阵容直接开打
		else:
			battle.dialogue.skip_all()
		await get_tree().create_timer(0.15).timeout
		t += 0.15
	await _frames(2)


## 跳过开场剧情，停在出击准备界面
func _until_prep() -> bool:
	var t := 0.0
	while battle.state != battle.S.PREP and t < 20.0:
		if battle.tutorial != null and battle.tutorial.asking:
			battle.tutorial.choose(false)
		battle.dialogue.skip_all()
		await get_tree().create_timer(0.15).timeout
		t += 0.15
	return battle.state == battle.S.PREP and battle.prep != null


func _wait_cond(cond: Callable, timeout: float) -> bool:
	var t := 0.0
	while not cond.call():
		if battle.tutorial != null and battle.tutorial.asking:
			battle.tutorial.choose(false)
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
	var named := Unit.new()
	named.setup({"id": "noya", "name": "noya", "weapons": ["heal_staff"], "hp": 16})
	_check(named.display_name == "诺雅" and named.weapon()["name"] == "治疗杖", "id 当名字时诺雅面板应为中文和治疗杖")
	named.setup({"id": "tia", "name": "缇娅", "weapons": ["iron_sword"]})
	_check(named.display_name == "缇娅", "已写中文名的单位不应被名册覆盖")
	for row in [["church1", "圣焰教会兵"], ["knight1", "圣焰骑士"], ["merc1", "黑烬佣兵"], ["harlo", "哈洛"], ["nina", "妮娜"], ["kain", "凯因"], ["edric", "艾德里克"], ["silas", "塞拉斯"], ["hawk", "霍克"], ["barrett", "巴雷特"]]:
		named.setup({"id": row[0], "name": row[0], "weapons": ["iron_sword"]})
		_check(named.display_name == row[1], "%s 面板名应为 %s，实际 %s" % [row[0], row[1], named.display_name])
	named.setup({"id": "morgan", "name": "莫尔甘", "class": "德鲁伊", "weapons": ["flux"]})
	_check(named.unit_id == "morgan" and named.display_name == "莫尔甘", "莫尔甘人形面板名应为莫尔甘，id 仍是 morgan")
	named.setup({"id": "morgan", "name": "morgan", "class": "德鲁伊"})
	_check(named.display_name == "莫尔甘", "id 当名字时莫尔甘人形仍应是莫尔甘")
	named.setup({"id": "morgan", "name": "莫尔甘", "class": "炎龙", "faction": "enemy", "weapons": ["dragon_flame"], "hp": 40, "pos": Vector2i(5, 4)})
	_check(named.unit_id == "morgan" and named.display_name == "炎龙" and named.class_label == "炎龙", "炎龙形态面板名应为炎龙，id 仍是 morgan")
	_check(named.weapon()["name"] == "炎龙之息", "炎龙之息武器名应保持不变")
	named.promote("德鲁伊", {})
	_check(named.display_name == "莫尔甘" and named.unit_id == "morgan", "从炎龙转回人形后面板名应回到莫尔甘")
	named.promote("炎龙", {})
	_check(named.display_name == "炎龙", "再转成炎龙后面板名应翻回炎龙")
	var ally_green := Unit.new()
	ally_green.setup({"id": "edric", "name": "艾德里克", "faction": "npc", "fights": true, "weapons": ["iron_sword"], "pos": Vector2i(4, 4)})
	var bandit := Unit.new()
	bandit.setup({"id": "bandit1", "name": "山贼", "faction": "enemy", "weapons": ["iron_axe"], "pos": Vector2i(5, 4)})
	var seven := Unit.new()
	seven.setup({"id": "seven", "name": "七号", "faction": "player", "class": "灰烬傀儡", "weapons": ["ash_claw"], "hp": 36, "pos": Vector2i(4, 4)})
	_check(CombatScene.panel_color(seven).is_equal_approx(CombatScene.PANEL_ALLY), "我方七号面板应为蓝")
	_check(CombatScene.panel_color(ally_green).is_equal_approx(CombatScene.PANEL_ALLY), "会作战的友军面板应为蓝，不能跟敌人一样涂红")
	_check(CombatScene.panel_color(bandit).is_equal_approx(CombatScene.PANEL_ENEMY), "山贼面板应为红")
	_check(CombatScene.panel_color(named).is_equal_approx(CombatScene.PANEL_ENEMY), "敌方炎龙面板应为红")
	var panel_left := CombatScene.panel_bg_rect(0.0, 80.0)
	var panel_right := CombatScene.panel_bg_rect(CombatScene.PANEL_MID, 80.0)
	_check(is_equal_approx(panel_left.end.x, CombatScene.PANEL_MID) and is_equal_approx(panel_right.position.x, CombatScene.PANEL_MID), "宽屏底栏两半应在中线相接")
	_check(panel_left.position.x < 0.0 and panel_right.end.x > 1280.0 and not panel_left.intersects(panel_right), "宽屏底栏只向外侧铺，两半不重叠")
	var panel_scene := CombatScene.new()
	add_child(panel_scene)
	panel_scene._pad = 0.0
	panel_scene._fc = {"a_hit": 100, "a_dmg": 12, "a_crit": 30, "a_times": 1, "d_can": true, "d_hit": 40, "d_dmg": 4, "d_crit": 0, "d_times": 1}
	panel_scene._att_real = seven
	panel_scene._def_real = bandit
	panel_scene._build_panels(0)
	var halves := _panel_halves(panel_scene)
	_check(halves.size() == 2 and halves[0][0].is_equal_approx(CombatScene.PANEL_ALLY) and halves[1][0].is_equal_approx(CombatScene.PANEL_ENEMY), "七号对山贼：左蓝右红，实际 %s" % str(halves))
	_check(halves.size() == 2 and is_equal_approx(halves[0][1].end.x, CombatScene.PANEL_MID) and is_equal_approx(halves[1][1].position.x, CombatScene.PANEL_MID), "七号对山贼两半应在 640 分开")
	_check(_panel_has_text(panel_scene, tr("七号")) and _panel_has_text(panel_scene, tr("山贼")) and _panel_has_text(panel_scene, tr("灰烬之爪")) and _panel_has_text(panel_scene, tr("铁斧")), "战斗面板应写出双方名字和武器")
	panel_scene._att_real = named
	panel_scene._def_real = seven
	panel_scene._build_panels(0)
	halves = _panel_halves(panel_scene)
	_check(halves.size() == 2 and halves[0][0].is_equal_approx(CombatScene.PANEL_ENEMY) and halves[1][0].is_equal_approx(CombatScene.PANEL_ALLY), "敌方先手时左红右蓝，不能整条涂红")
	_check(_panel_has_text(panel_scene, tr("炎龙")) and _panel_has_text(panel_scene, tr("炎龙之息")), "龙形态战斗面板应显示炎龙和炎龙之息")
	panel_scene.queue_free()
	ally_green.free()
	bandit.free()
	seven.free()
	named.free()
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 1280, "逻辑宽度应为 1280")
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 720, "逻辑高度应为 720")
	_check(int(ProjectSettings.get_setting("display/window/handheld/orientation")) == 4, "应强制 sensor_landscape（横屏）")
	_check(str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile")) == "gl_compatibility", "Android 渲染应走 gl_compatibility")
	_check(bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch")), "应开启触控模拟鼠标")
	_check(SafeArea.MARGIN_X >= 64 and SafeArea.MARGIN_Y >= 48, "安全区左右应 ≥ 64、上下应 ≥ 48")
	_check(SafeArea.EDGE_ACTION >= 80 and SafeArea.MIN_HIT >= 48, "主操作内缩应 ≥ 80、热区应 ≥ 48")
	var combat_art: Array = [
		"res://art/combat/bg/sky_grass.png",
		"res://art/combat/bg/mountains_grass.png",
		"res://art/combat/bg/mid_grass.png",
		"res://art/combat/bg/ground_strip_grass.png",
		"res://art/combat/bg/sky_forest.png",
		"res://art/combat/bg/mountains_forest.png",
		"res://art/combat/bg/mid_forest.png",
		"res://art/combat/bg/ground_strip_forest.png",
		"res://art/combat/bg/sky_scorch.png",
		"res://art/combat/bg/mountains_scorch.png",
		"res://art/combat/bg/mid_scorch.png",
		"res://art/combat/bg/ground_strip_scorch.png",
	]
	for path in combat_art:
		_check(FileAccess.file_exists(path), "战斗资源应存在: " + path)
	_check(not FileAccess.file_exists("res://art/combat/tia_sword.png"), "旧的抠坏条带不应留在运行时")
	_check(not FileAccess.file_exists("res://shaders/combat_pose.gdshader"), "旧的补洞着色器应已删除")
	for key in CombatFighter.SETS:
		_check(CombatFighter.has_set(key), "战斗条带套应齐全: " + key)
		var sf := CombatFighter.frames_for(key)
		_check(sf != null, "条带套应能切帧: " + key)
		if sf == null:
			continue
		for anim in ["idle", "run", "attack", "hit", "death"]:
			_check(sf.has_animation(anim) and sf.get_frame_count(anim) >= 3, "%s 应有 %s 动画（≥3 帧）" % [key, anim])
		var cfg: Dictionary = CombatFighter.SETS[key]
		var fs: Vector2i = cfg["frame"]
		var body_px: float = float(fs.y) * int(cfg["scale"])
		_check(body_px >= 200.0, "%s 放大后帧高应足够（%s）" % [key, body_px])
		for anim in cfg["anims"]:
			var hit_idx: int = int(cfg["anims"][anim][1])
			if hit_idx >= 0 and sf.has_animation(anim):
				_check(hit_idx < sf.get_frame_count(anim), "%s/%s 出手帧应在帧数内" % [key, anim])
	_check(is_equal_approx(CombatScene.FEET_Y, 520.0), "脚底世界坐标应为 520")
	var scene := CombatScene.new()
	add_child(scene)
	var grass_paths: Array = scene._layered_bg_paths(".")
	_check(grass_paths.size() == 4 and str(grass_paths[0]).ends_with("sky_grass.png") and str(grass_paths[3]).ends_with("ground_strip_grass.png"), "草地套应为四层 grass 图，实际 %s" % str(grass_paths))
	_check(scene._layered_bg_paths("H") == grass_paths and scene._layered_bg_paths("W") == grass_paths, "H / W 应与平原共用草地套")
	var forest_paths: Array = scene._layered_bg_paths("F")
	_check(forest_paths.size() == 4 and str(forest_paths[0]).ends_with("sky_forest.png") and str(forest_paths[3]).ends_with("ground_strip_forest.png"), "森林 F 应为四层 forest 图，实际 %s" % str(forest_paths))
	_check(scene._usable_layered_paths(["res://art/combat/bg/missing_layer.png"]).is_empty(), "任一层缺失时应放弃分层套")
	_check(scene._usable_layered_paths(grass_paths.slice(0, 3) + ["res://art/combat/bg/missing_layer.png"]).is_empty(), "四层里缺一层时应整套回退")
	_check(CombatScene.DEFAULT_BG_SET == "grass", "未登记地形的缺省套应为 grass")
	# 战斗背景随地形变化：每一套都要四层齐全，并能铺满舞台
	for set_name in CombatScene.BG_SETS:
		_check(scene._usable_layered_paths(CombatScene.BG_SETS[set_name]).size() == 4, "战斗背景套应四层齐全: " + set_name)
	var by_terrain := {".": "grass", "R": "grass", "f": "grass", "F": "forest", "M": "hills", "h": "hills", "g": "hills",
		"B": "river", "w": "river", "s": "river", "S": "town", "G": "town", "#": "town", "T": "castle", "K": "castle", "I": "castle"}
	for ch in by_terrain:
		_check(scene.bg_set_for(ch) == by_terrain[ch], "地形 %s 的战斗背景应为 %s，实际 %s" % [ch, by_terrain[ch], scene.bg_set_for(ch)])
	for ch in ["R", "F", "M", "B", "T", "S"]:
		scene._rebuild_bg(CombatScene.GROUND_COLORS.get(ch, CombatScene.GROUND_COLORS["."]), ch)
		_check_layered_stage(scene, scene.bg_set_for(ch))
	# 随章节变化：雪地章野外全换雪景、火场章换焦土；城镇 / 城堡内不受影响
	scene.theme = "snow"
	_check(scene.bg_set_for(".") == "snow" and scene.bg_set_for("F") == "snow" and scene.bg_set_for("h") == "snow", "雪地章的野外战斗背景应为雪景")
	_check(scene.bg_set_for("T") == "castle" and scene.bg_set_for("S") == "town", "雪地章的城堡 / 城镇仍用室内套")
	scene._rebuild_bg(CombatScene.GROUND_COLORS["."], ".")
	_check_layered_stage(scene, "snow")
	scene.theme = ""
	scene.burning = true
	_check(scene.bg_set_for(".") == "scorch" and scene.bg_set_for("C") == "scorch" and scene.bg_set_for("F") == "scorch", "火场章的战斗背景应为焦土")
	scene.burning = false
	_check(Chapter2.new().combat_tint() != Color.WHITE and Chapter3.new().combat_tint() == Color.WHITE, "章节色调：第二章火场之夜偏暗，第三章白天原色")
	var fx := Polygon2D.new()
	scene._add_fx(fx)
	_check(fx.z_index == CombatScene.Z_FX and fx.z_index > CombatScene.Z_FIGHTER, "斩击特效应画在角色之上")
	fx.free()
	scene.free()
	var probe := Unit.new()
	var expect_map := {"tia": "tia", "balto": "balto", "brock": "boss", "marco": "boss",
		"scout1": "scout", "bandit3": "bandit", "bandit_r1": "bandit", "archer2": "archer"}
	for id in expect_map:
		probe.unit_id = id
		_check(CombatScene.fighter_key_for(probe) == expect_map[id], "%s 应映射 %s, 实际 %s" % [id, expect_map[id], CombatScene.fighter_key_for(probe)])
	probe.unit_id = "stranger"
	probe.weapons = ["iron_bow"]
	_check(CombatScene.fighter_key_for(probe) == "archer", "未登记的弓手应按武器兜底到 archer")
	probe.free()
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
	var csv_text := FileAccess.get_file_as_string("res://locale/ui.csv")
	_check("右键" not in csv_text, "ui.csv 不应再提示右键")
	_check("right-click" not in csv_text.to_lower(), "ui.csv 不应再提示 right-click")
	TranslationServer.set_locale("zh_CN")
	_check(tr("敌方增援！") == "敌方增援！", "中文横幅应保持敌方增援，实际 " + tr("敌方增援！"))
	TranslationServer.set_locale("en")
	_check(tr("敌方增援！") == "Enemy Reinforcements!", "英文横幅翻译错误: " + tr("敌方增援！"))
	_check(tr("战  败") == "Defeat", "英文战败文案错误: " + tr("战  败"))
	_check(tr("手腕太僵了。剑不是靠蛮力挥的，缇娅。") == "Your wrist is too stiff. A sword isn't swung by brute force, Tia.", "抽样台词未译出")
	var en_keys: Array = [
		"攻击", "待机", "访问", "对话", "支援", "说得", "道具",
		"回合结束", "我方回合", "敌方回合", "危险范围 (T)",
		"第一章 · 边境的少女", "战  败", "第一章 · 完", "重开本关", "回到标题",
		"胜利", "败北", "击败所有敌人", "缇娅或巴尔托阵亡",
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
		"新游戏", "继续游戏", "返回", "菜单", "继续", "系统", "音乐", "音效", "确定",
		"开始新游戏会覆盖当前存档，确定吗？",
		"%s：选择移动位置（点空白处取消）",
		"%s 的威胁范围（点空白处清除）",
		"选择行动（点菜单外撤销移动）",
		"选择武器（点菜单外返回）",
		"用【%s】选择攻击目标（点空白处返回）",
		"选择要使用的道具（点菜单外返回）",
		"（屋内）缇娅小姐！救命！有山贼在砸我家的门！",
		"第二章", "第二章 · 燃烧的村庄", "第二章 · 完",
		"灰岩村燃尽了。火，却还在缇娅剑上。", "灰岩村葬于火海……",
		"觉醒 · 炎刃使", "缇娅转职为炎刃使！",
		"焦土", "火焰", "废墟", "炎刃使", "炎刃",
		"缇娅·觉醒", "探子", "马尔科",
		"夜。灰岩村的麦田和屋顶都烧着了。",
		"村子……怎么会变成这样！",
		"他们不是来抢粮的。这火，是冲你来的。",
		"哈洛呢？婆婆呢？！",
		"往林子里撤了。放火的人还在村里。",
		"我要灭了这火，也灭了他们！",
		"别冲太前。焦土难走，火焰踏不得。",
		"火焰扑上缇娅的剑。她没有退。",
		"热……这热是从我自己身上来的？",
		"缇娅！把剑放下——！",
		"……不。这火听我的。",
		"村子已经烧了。接下来，我来烧回去！",
		"剑士之路在火里折断。炎刃使，于此觉醒。",
		"火势终于被压住。灰岩村只剩下焦黑的梁。",
		"人是打退了……村子却没了。",
		"你体内的火，今天认了你。这不是结束。",
		"我知道。谁让村子烧起来，我就去找谁。",
		"火……好大……",
		"缇娅倒下了。灰岩村的火，再也没有人去扑。",
		"缇娅……别让这火烧到你自己……",
		"巴尔托倒下了。火海吞没了灰岩村。",
		"缇娅！井边的人都跑了……伤药给你，求你活着！",
		"先活下去。火，我来挡。",
		"红头发……就是她！得赶紧回报团里！",
		"你跑不掉。",
		"烧得真漂亮。那丫头的头发，跟这火一个色！",
		"你烧的是我的家！",
		"上头要的是活口。可惜，你挡路了。",
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
	_check(chapter_label != null and turn_label != null and gold_label != null, "英文目标窗应有章节、回合、金钱")
	if chapter_label != null and turn_label != null:
		_check(chapter_label.text == "Chapter 1 · The Girl of the Border", "英文章节名不符，实际 " + chapter_label.text)
		_check(turn_label.text.begins_with("Turn "), "英文回合标应已刷新，实际 " + turn_label.text)
		var goal_rect: Rect2 = probe.hud.goal_win.get_global_rect()
		_check(SafeArea.rect().encloses(goal_rect), "英文目标窗应落在安全区内, 实际 %s" % goal_rect)
	_check(tr("显示危险范围") == "Show Threat Range", "地图菜单应有英译")
	var win: Label = probe.lbl_win
	var lose: Label = probe.lbl_lose
	_check(win != null and win.visible and win.text.begins_with("Victory") and "Defeat all enemies" in win.text, "英文胜利条件不符，实际 %s" % (win.text if win != null else "null"))
	_check(lose != null and lose.visible and lose.text.begins_with("Defeat") and "Tia or Balto falls" in lose.text, "英文败北条件不符，实际 %s" % (lose.text if lose != null else "null"))
	if win != null:
		_check(not _has_cjk(win.text), "英文胜利条件不应含中文，实际 " + win.text)
	if lose != null:
		_check(not _has_cjk(lose.text), "英文败北条件不应含中文，实际 " + lose.text)
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
	_check(start.text == "新游戏", "标题新游戏按钮默认中文，实际 " + start.text)
	var cont0 := title.get_node_or_null("ContinueButton") as Button
	_check(cont0 != null and not cont0.visible, "没有存档时不应显示继续游戏")
	_check(title.get_node_or_null("Chapter2Button") == null, "第二章不再单独开入口，要从第一章打过去")
	var sel := title.get_node("ChapterSelectButton") as Button
	_check(sel != null and sel.text == "选择章节", "标题应有章节选择按钮，实际 " + (sel.text if sel != null else "null"))
	_check(sel != null and not sel.visible, "没打到第二章时不应显示章节选择")
	if sel != null:
		_check(sel.position.y >= start.position.y + start.size.y - 0.01, "章节选择应在开始按钮下方")
		_check(sel.size.y >= SafeArea.MIN_HIT, "章节选择热区应 ≥ 48")
		_check(sel.position.y >= 520.0, "章节选择应落在标题立绘下沿之下，避免改动马尾裁切")
	_check(lang.text == "English", "中文界面的语言按钮应写 English，实际 " + lang.text)
	var lang_right := lang.position.x + lang.size.x
	_check(lang_right <= 1280.0 - SafeArea.EDGE_ACTION + 0.01, "语言按钮应避开右缘 80px，右缘 %s" % lang_right)
	_check(lang.position.y >= SafeArea.MARGIN_Y and lang.size.y >= SafeArea.MIN_HIT, "语言按钮应落在安全区且热区 ≥ 48")
	_check(start.size.y >= SafeArea.MIN_HIT, "开始按钮热区应 ≥ 48")
	GameLocale.toggle()
	_check(start.text == "New Game", "切换英文后新游戏按钮应为 New Game，实际 " + start.text)
	_check(sel != null and sel.text == "Chapters", "英文章节选择应为 Chapters，实际 " + (sel.text if sel != null else "null"))
	_check(lang.text == "中文", "英文界面的语言按钮应写 中文，实际 " + lang.text)
	_check(tr("新游戏") == "New Game", "切换后 tr(新游戏) 应为 New Game")
	GameLocale.toggle()
	_check(start.text == "新游戏", "切回中文后新游戏按钮应恢复")
	# 授权声明：右下角按钮 → 卷动的全文（本作原创声明、CC0 素材、Godot 引擎与第三方许可）
	var lic := title.get_node_or_null("LicenseButton") as Button
	_check(lic != null and lic.visible and lic.text == "授权声明", "标题应有授权声明按钮")
	if lic != null:
		_check(lic.position.x + lic.size.x <= 1280.0 - SafeArea.EDGE_ACTION + 0.01 and lic.size.y >= SafeArea.MIN_HIT, "授权声明按钮应在安全区内、热区 ≥ 48")
		lic.pressed.emit()
		var ov := title.get_node("LicenseOverlay") as Control
		var txt: String = (title.find_child("LicenseText", true, false) as Label).text
		_check(ov.visible, "点授权声明应打开声明页")
		_check("Godot Engine" in txt and "MIT" in txt and "Ninja Adventure" in txt and "FreeType" in txt, "声明页应含 Godot 许可、第三方组件与 CC0 素材来源")
		title._handle_back()
		_check(not ov.visible, "返回键应关闭声明页")
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


func _check_save_pause_back() -> void:
	_mark("存档 / 暂停 / 返回")
	_check(CampaignSave.has_save(), "我方回合开始后应写入存档")
	var cfg := ConfigFile.new()
	_check(cfg.load(CampaignSave.PATH) == OK, "应能读到 user://save.cfg")
	_check(str(cfg.get_value("save", "chapter_id", "")) == "ch1", "存档章节应为 ch1，实际 " + str(cfg.get_value("save", "chapter_id", "")))
	_check(int(cfg.get_value("save", "turn", 0)) == 1, "存档回合应为 1，实际 %s" % str(cfg.get_value("save", "turn", 0)))
	_check(not bool(cfg.get_value("save", "cleared", true)), "回合开始的检查点不应标为已通关")
	var payload := CampaignSave.read()
	_check((payload.get("units", []) as Array).size() == battle.units.size(), "存档单位数应与战场一致")

	var title = load("res://scenes/title.tscn").instantiate()
	add_child(title)
	await _frames(2)
	var cont := title.get_node("ContinueButton") as Button
	_check(cont != null and cont.visible, "有存档时标题应显示继续游戏")
	_check(cont.text == "继续游戏", "继续按钮默认中文，实际 " + cont.text)
	_check(cont.pressed.is_connected(title._on_continue), "继续按钮应接上读档")
	GameLocale.set_code("en")
	_check(cont.text == "Continue", "英文继续按钮应为 Continue，实际 " + cont.text)
	_check((title.get_node("StartButton") as Button).text == "New Game", "英文新游戏按钮应为 New Game")
	GameLocale.set_code("zh_CN")
	_check(cont.text == "继续游戏", "切回中文后继续按钮应恢复")
	(title.get_node("StartButton") as Button).pressed.emit()
	var confirm := title.get_node("ConfirmOverlay") as ColorRect
	_check(confirm.visible, "有存档时新游戏应先确认覆盖")
	_check(CampaignSave.has_save(), "确认前不应删除存档")
	var cancel_confirm := title.find_child("ConfirmCancelButton", true, false) as Button
	_check(cancel_confirm != null, "应有取消覆盖按钮")
	if cancel_confirm != null:
		cancel_confirm.pressed.emit()
		_check(not confirm.visible, "取消确认应关闭对话框")
	title.queue_free()
	await _frames(2)

	Audio.set_bgm_percent(40)
	Audio.set_sfx_percent(80)
	battle.open_system_menu()
	var opened: bool = bool(battle.system_menu.is_open()) and get_tree().paused
	var resume := battle.system_menu.find_child("ResumeButton", true, false) as Button
	var bgm := battle.system_menu.find_child("BgmSlider", true, false) as HSlider
	_check(resume != null and resume.text == "继续", "暂停菜单应有「继续」，实际 %s" % (resume.text if resume != null else "null"))
	_check(bgm != null and is_equal_approx(bgm.value, 40.0), "音乐滑条应反映当前音量")
	if resume != null:
		resume.pressed.emit()
	else:
		battle.close_system_menu()
	_check(opened, "暂停菜单应打开并暂停场景树")
	_check(not battle.system_menu.is_open() and not get_tree().paused, "继续应关闭暂停菜单并恢复")
	Audio.set_bgm_percent(100)
	Audio.set_sfx_percent(100)

	var cancel_ev := InputEventAction.new()
	cancel_ev.action = "ui_cancel"
	cancel_ev.pressed = true
	battle._unhandled_input(cancel_ev)
	var opened_by_key: bool = bool(battle.system_menu.is_open()) and get_tree().paused
	battle.close_system_menu()
	_check(opened_by_key, "空闲时取消键应打开系统菜单")
	_check(not battle.system_menu.is_open() and not get_tree().paused, "关闭系统菜单后应恢复运行")

	if get_tree().paused:
		battle.close_system_menu()
	var tia = battle.get_unit("tia")
	battle.click_tile(tia.grid_pos)
	await _frames(2)
	_check(battle.selected == tia, "返回测试前应选中缇娅")
	_check("右键" not in battle.hint_label.text, "移动提示不应再写右键，实际 " + battle.hint_label.text)
	_check("取消" in battle.hint_label.text, "移动提示应写怎么取消，实际 " + battle.hint_label.text)
	# 点移动范围外的空地 = 取消
	var far := Vector2i(14, 0) if tia.grid_pos.x < 7 else Vector2i(0, 0)
	battle.click_tile(far)
	await _frames(2)
	_check(battle.selected == null and battle.state == battle.S.IDLE, "点范围外应取消选中并回到 IDLE")
	# 空地上点一下 → 地图菜单（回合结束 / 危险范围 / 菜单）
	battle.open_map_menu(far)
	await _frames(2)
	var labels: Array = []
	for b in battle.menu_box.get_children():
		if b is Button and not b.is_queued_for_deletion():
			labels.append(b.text)
	_check(battle.state == battle.S.MAP_MENU and "回合结束" in labels and "显示危险范围" in labels and "菜单" in labels, "地图菜单应有回合结束、危险范围、菜单，实际 %s" % str(labels))
	var mrect: Rect2 = battle.menu_panel.get_global_rect()
	_check(SafeArea.rect().encloses(mrect), "地图菜单应在安全区内, 实际 %s" % mrect)
	for b in battle.menu_box.get_children():
		if b is Button:
			_check(b.size.y >= SafeArea.MIN_HIT, "菜单项热区应 ≥ 48")
			break
	battle.click_tile(tia.grid_pos)
	await _frames(2)
	_check(battle.state == battle.S.IDLE and not battle.menu_panel.visible, "点菜单外应关闭地图菜单")
	# 行动菜单贴着单位弹出
	battle.click_tile(tia.grid_pos)
	await _frames(2)
	battle.click_tile(tia.grid_pos)
	var opened_menu: bool = await _wait_cond(func() -> bool: return battle.state == battle.S.ACTION_MENU, 5.0)
	if opened_menu:
		await _frames(2)
		var arect: Rect2 = battle.menu_panel.get_global_rect()
		var tc: Vector2 = battle.tile_screen_pos(tia.grid_pos)
		_check(arect.position.distance_to(tc) < 200.0 and SafeArea.rect().encloses(arect), "行动菜单应贴着单位弹出, 菜单 %s 单位 %s" % [arect, tc])
		_shot("01b_action_menu.png")
		battle.click_tile(far)
		await _wait_cond(func() -> bool: return battle.state == battle.S.MOVE_SEL, 5.0)
		battle.click_tile(far)
		await _frames(2)
	_check(battle.selected == null and battle.state == battle.S.IDLE, "点菜单外撤销移动、再点空白处应回到 IDLE")
	if get_tree().paused:
		battle.close_system_menu()
	if battle.selected != null:
		battle.cancel()


func _check_save_roundtrip() -> void:
	_mark("读档")
	var tia = battle.get_unit("tia")
	tia.hp = 11
	tia.grid_pos = Vector2i(2, 2)
	tia.position = tia.tile_center()
	tia.support_with["balto"] = "C"
	battle.gold = 321
	battle.chapter.f_talk = true
	battle.chapter.visited[Vector2i(9, 1)] = true
	CampaignSave.write_checkpoint(battle)
	battle.queue_free()
	await _frames(3)
	CampaignSave.request_continue()
	await _spawn_battle()
	var loaded = battle.get_unit("tia")
	_check(battle.state == battle.S.IDLE, "读档应直接进入 IDLE，实际 %d" % battle.state)
	_check(battle.gold == 321, "读档应恢复金钱，实际 %d" % battle.gold)
	_check(loaded != null and loaded.hp == 11, "读档应恢复 HP，实际 %s" % (str(loaded.hp) if loaded != null else "null"))
	_check(loaded != null and loaded.grid_pos == Vector2i(2, 2), "读档应恢复坐标，实际 %s" % (str(loaded.grid_pos) if loaded != null else "null"))
	_check(loaded != null and str(loaded.support_with.get("balto", "")) == "C", "读档应恢复支援")
	_check(battle.chapter.f_talk, "读档应恢复对话旗标")
	_check(battle.chapter.visited.has(Vector2i(9, 1)), "读档应恢复民居访问")
	_check(battle.units.size() == 16, "读档单位数量应为 16，实际 %d" % battle.units.size())


func _check_objectives(zh: bool) -> void:
	var win: Label = battle.lbl_win if battle != null else null
	var lose: Label = battle.lbl_lose if battle != null else null
	_check(win != null and lose != null, "应有胜负条件标签")
	if win == null or lose == null:
		return
	_check(win.visible and lose.visible, "胜负条件应在战斗中保持可见")
	if zh:
		_check(win.text.begins_with("胜利") and "击败所有敌人" in win.text, "胜利条件文案不符，实际 " + win.text)
		_check(lose.text.begins_with("败北") and "缇娅或巴尔托阵亡" in lose.text, "败北条件文案不符，实际 " + lose.text)
	var goal_rect: Rect2 = battle.hud.goal_win.get_global_rect()
	_check(win.get_global_rect().size.y > 8.0 and lose.get_global_rect().size.y > 8.0, "胜负条件应有可见高度")
	_check(SafeArea.rect().encloses(goal_rect), "目标窗应在安全区内, 实际 %s" % goal_rect)


func _check_defeat_actions() -> void:
	var restart: Button = battle.end_restart
	var title_btn: Button = battle.end_btn
	_check(restart != null and restart.visible and restart.text == "重开本关", "败北应显示重开本关，实际 %s" % (restart.text if restart != null else "null"))
	_check(title_btn != null and title_btn.visible and title_btn.text == "回到标题", "败北应保留回到标题，实际 %s" % (title_btn.text if title_btn != null else "null"))
	if restart != null:
		_check(restart.custom_minimum_size.y >= SafeArea.MIN_HIT, "重开本关热区应 ≥ 48")
		_check(_pressed_method(restart) == "_on_restart_pressed", "重开按钮应接到重开本关，实际 " + _pressed_method(restart))
	if title_btn != null:
		_check(title_btn.custom_minimum_size.y >= SafeArea.MIN_HIT, "回到标题热区应 ≥ 48")
		_check(_pressed_method(title_btn) == "_on_end_title_pressed", "标题按钮应接到回标题，实际 " + _pressed_method(title_btn))


func _pressed_method(btn: Button) -> String:
	var conns := btn.pressed.get_connections()
	if conns.is_empty():
		return ""
	return str(conns[0]["callable"].get_method())


## 败北界面上的重开会清档并 change_scene。冒烟节点不是战斗场景时，
## 先把当前场景指到这场战斗，再按按钮，这样只卸掉战斗、测试节点还在。
func _restart_from_defeat() -> void:
	if battle == null or battle.end_restart == null:
		_check(false, "无法重开：缺少败北按钮")
		return
	battle.gold = 777
	battle.turn = 4
	CampaignSave.write_checkpoint(battle)
	CampaignSave.request_continue()
	var old = battle
	get_tree().current_scene = battle
	battle.end_restart.pressed.emit()
	var t := 0.0
	while t < 5.0:
		await get_tree().create_timer(0.1).timeout
		t += 0.1
		var cur = get_tree().current_scene
		if cur != null and cur != old and is_instance_valid(cur) and cur.name == "Battle":
			battle = cur
			break
	_check(is_instance_valid(battle) and battle != old, "重开本关应载入新的战斗场景")
	if not is_instance_valid(battle) or battle == old:
		return
	battle.set_process_unhandled_input(false)
	await _skip_story()
	var tia = battle.get_unit("tia")
	var balto = battle.get_unit("balto")
	_check(battle.state == battle.S.IDLE, "重开后应进入本章开场后的 IDLE，实际 %d" % battle.state)
	_check(battle.turn == 1, "重开后应为第 1 回合，实际 %d" % battle.turn)
	_check(battle.gold == 0, "重开不应读入失败检查点的金钱，实际 %d" % battle.gold)
	_check(tia != null and tia.is_alive() and tia.hp == 20, "重开后缇娅应满血存活")
	_check(balto != null and balto.is_alive(), "重开后巴尔托应存活")
	_check(battle.units.size() == 16, "重开后应回到 16 个初始单位，实际 %d" % battle.units.size())
	var alive := 0
	for u in battle.units:
		if u.is_alive():
			alive += 1
	_check(alive == 16, "重开后应全员存活，实际 %d" % alive)
	_check(not CampaignSave.pending_load, "重开不应留下读档请求")
	var payload := CampaignSave.read()
	_check(int(payload.get("turn", -1)) == 1 and int(payload.get("gold", -1)) == 0, "重开后的检查点应是第 1 回合空金，实际 %s" % str(payload))
	_check(not bool(payload.get("cleared", true)), "重开不应沿用通关标记")
	_check_objectives(true)


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


func _panel_halves(scene: CombatScene) -> Array:
	var out: Array = []
	for c in scene._ui.get_children():
		if c is ColorRect and not c.is_queued_for_deletion() and (c as ColorRect).size.y > 140.0:
			var r := c as ColorRect
			out.append([Color(r.color.r, r.color.g, r.color.b), Rect2(r.position, r.size)])
	return out


func _panel_has_text(scene: CombatScene, text: String) -> bool:
	for c in scene._ui.get_children():
		if c is Label and not c.is_queued_for_deletion() and (c as Label).text == text:
			return true
	return false


func _live_stage_children(scene: CombatScene) -> Array:
	var live: Array = []
	for c in scene._stage.get_children():
		if not c.is_queued_for_deletion():
			live.append(c)
	return live


func _check_layered_stage(scene: CombatScene, tag: String) -> void:
	var live := _live_stage_children(scene)
	var sprites := 0
	for c in live:
		if c is Sprite2D:
			sprites += 1
			var spr := c as Sprite2D
			_check(spr.texture != null, tag + " 分层纹理应加载成功")
			_check(spr.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, tag + " 分层应为 LINEAR")
			_check(spr.z_index == CombatScene.Z_BG and spr.z_index < CombatScene.Z_FIGHTER, tag + " 分层应压在角色下面")
			_check(not spr.centered, tag + " 分层应左上对齐")
			var r := spr.get_rect()          # 宽屏时左右用镜像平铺延伸，按 region 算覆盖范围
			var cover := Rect2(spr.position + r.position * spr.scale, r.size * spr.scale)
			_check(cover.has_point(Vector2(1, 1)) and cover.has_point(Vector2(1279, 719)), tag + " 视差层应盖满屏幕, 实际 %s" % cover)
		else:
			_check(false, tag + " 分层舞台不应混入 " + c.get_class())
	_check(sprites == 4, tag + " 应正好四层 Sprite，实际 %d" % sprites)
	if live.size() == 4 and live[0] is Sprite2D and live[3] is Sprite2D:
		var sky := str((live[0] as Sprite2D).texture.resource_path)
		var ground := str((live[3] as Sprite2D).texture.resource_path)
		_check(sky.contains("sky_" + tag), tag + " 最远层应为 sky，实际 " + sky)
		_check(ground.contains("ground_strip_" + tag), tag + " 最近层应为地面带，实际 " + ground)


## 战斗角色：用对条带套、朝向正确、脚底锚点落在节点原点、最近邻、画在背景与特效之间
func _check_fighter(node: CombatFighter, key: String, face_left: bool, who: String) -> void:
	_check(node != null, who + "特写应有角色节点")
	if node == null:
		return
	_check(node.set_key == key, "%s应使用 %s 条带, 实际 %s" % [who, key, node.set_key])
	_check(node.sprite != null and node.sprite.sprite_frames != null, who + "应挂上动作条带")
	_check((node.scale.x < 0.0) == face_left, who + ("应朝左" if face_left else "应朝右"))
	_check(absf(node.position.y - CombatScene.FEET_Y) < 30.0, who + "脚底应在地面带上, y=%s" % node.position.y)
	_check(node.z_index == CombatScene.Z_FIGHTER and node.z_index < CombatScene.Z_FX, who + "应画在背景之上、特效之下")
	if node.sprite == null:
		return
	_check(node.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, who + "条带应为最近邻过滤")
	var cfg: Dictionary = CombatFighter.SETS[key]
	var feet: Vector2 = cfg["feet"]
	var anchored: Vector2 = node.sprite.position + feet * node.sprite.scale
	_check(anchored.length() < 0.6, who + "脚底锚点应在节点原点, 偏差 %s" % anchored)


func _ui_has_text(root: Node, text: String) -> bool:
	for c in root.get_children():
		if c is Label and (c as Label).text.begins_with(text):
			return true
	return false


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
