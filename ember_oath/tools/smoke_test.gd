extends Node
## 《炎烬之誓》第一章冒烟测试
## 用法: godot --path ember_oath res://tools/smoke_runner.tscn   (窗口模式可截图, --headless 仅验证逻辑)

var _shot_dir := "res://tools/shots/"
var _failures: Array = []
var battle


func _ready() -> void:
	_run.call_deferred()
	_watchdog()


## 看门狗：任何脚本错误导致 _run 中断时也能退出，避免挂死
func _watchdog() -> void:
	# 不受 Engine.time_scale 影响（自动试玩会加速）
	await get_tree().create_timer(300.0, true, false, true).timeout
	print("WATCHDOG: 超时强制退出")
	print("SMOKE TEST: TIMEOUT, %d FAILURES" % _failures.size())
	for f_ in _failures:
		print("  FAIL: " + f_)
	get_tree().quit(1)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shot_dir))
	CampaignSave.clear()
	_check_infra()
	await _check_title_and_narration()
	await _check_en_topbar()
	GameLocale.set_code("zh_CN")
	Campaign.reset()
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
	_check(_ui_has_text(cs._ui, "HIT") and _ui_has_text(cs._ui, "CRT"), "面板应有 HIT / DMG / CRT 栏")
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

	await _check_campaign_chapters()
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
	_check(battle.board.width == 15 and battle.board.height == 10, "第二章地图应为 15×10")
	_check(battle.board.tiles != null and battle.board.is_burning(), "第二章应走图块地图并开启火场氛围")
	_check(Audio._current_loop == "fire", "进图应叠火焰 loop")
	await _skip_story()
	var harlo = battle.get_unit("harlo")
	_check(harlo != null and harlo.is_player() and not harlo.has_acted, "哈洛应在开场剧情入队且本回合可行动")
	_check(battle.chapter.flags.get("first_flame", false), "第二章应演完火焰初醒")
	_check(tia.class_label == "剑士" and tia.weapons == ["iron_sword"], "第二章不转职（转职须满 Lv10），实际 " + tia.class_label)
	_check(battle.units.size() == 11, "第二章应有我方 4 人 + 敌方 7 人，实际 %d" % battle.units.size())
	_check(battle.state == battle.S.IDLE, "剧情后应进入我方回合，state=%d" % battle.state)
	_check(not battle.board.terrain(Vector2i(4, 0))["pass"], "火焰格应不可通行")
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
	_check(edric != null and edric.is_player(), "艾德里克应以客串身份在我方")
	_check("edric" in battle.chapter.lose_ids(), "第三章艾德里克倒下也算败北")
	_check(battle.get_unit("harlo") != null and battle.get_unit("bandit6") != null, "哈洛、托比应随队")
	var kain = battle.get_unit("kain")
	_check(kain != null and not kain.is_player() and kain.hold, "凯因应是守着不动的敌人")
	_check(battle.get_unit("nina") == null, "妮娜开场不在队")
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
	_check(battle.chapter.get_talk_partner(tia) == edric, "缇娅与艾德里克相邻应能对话")
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
	var noya = battle.get_unit("noya")
	_check(noya != null and not noya.is_player() and not noya.can_attack() and noya.heal_staff() == 0, "诺雅应是只带治疗杖的敌人")
	_check(battle.board.goal_tiles.size() == 3, "第四章应标出 3 格撤离点")
	await _skip_story()
	await _frames(10)
	_shot("13_chapter4_map.png")
	# 敌方治疗 AI：骑士受伤，诺雅应走过去治疗
	var knight1 = battle.get_unit("knight1")
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
	_check(win_lbl.get_line_count() == 2 and win_lbl.get_visible_line_count() >= 2, "第五章胜利条件应折成两行且完整可见，行数 %d 可见 %d" % [win_lbl.get_line_count(), win_lbl.get_visible_line_count()])
	await _skip_story()
	await _frames(10)
	_shot("14_chapter5_map.png")
	tia = battle.get_unit("tia")
	# 觉醒剧情点：不满 Lv10 只演剧情、不转职，记下顺延
	_check(tia.level < 10, "测试前提：缇娅不满 Lv10")
	battle.chapter._awaken_point()
	ok = await _wait_cond(func() -> bool: return battle.state != battle.S.STORY and Campaign.flags.get("tia_awaken_pending", false), 8.0)
	_check(ok, "不满 Lv10 时应记下觉醒顺延")
	_check(tia.class_label == "剑士", "不满 Lv10 不应转职，实际 " + tia.class_label)
	# 满 Lv10 后补上转职
	battle.state = battle.S.IDLE
	tia.level = 10
	var hp_before: int = tia.max_hp
	battle._pending_promotions()
	ok = await _wait_cond(func() -> bool: return tia.class_label == "炎刃使" and battle.state != battle.S.STORY, 8.0)
	_check(ok, "满 Lv10 后应补上炎刃使转职")
	_check(tia.level == 1 and tia.xp == 0 and tia.max_hp == hp_before + 3, "转职后 Lv1、经验清零、HP+3")
	_check(tia.weapons[0] == "ember_blade" and "iron_sword" in tia.weapons, "转职后应拿到炎刃并保留铁剑，实际 %s" % str(tia.weapons))
	_check(not Campaign.flags.has("tia_awaken_pending"), "补上转职后应清掉顺延标记")
	# 守到第 7 回合即通关
	battle.state = battle.S.IDLE
	battle.turn = 6
	battle.start_player_phase()
	ok = await _wait_cond(func() -> bool: return battle.end_overlay.visible, 15.0)
	_check(ok, "坚守到第 7 回合应通关第五章")
	_check(not battle.end_next.visible, "第五章是目前最后一章，不应有下一章按钮")
	_check("后续章节制作中" in battle.end_sub.text, "最后一章结算应说明后续制作中，实际 " + battle.end_sub.text)
	_check(Campaign.is_finished() and CampaignSave.is_cleared(), "打完第五章应标为已通关")
	await _frames(4)
	_shot("15_chapter5_victory.png")

	# ---- 标题：通关后隐藏继续，章节选择列出 5 章 ----
	var title = load("res://scenes/title.tscn").instantiate()
	add_child(title)
	await _frames(2)
	_check(not (title.get_node("ContinueButton") as Button).visible, "通关后不应再显示继续游戏")
	var sel := title.get_node("ChapterSelectButton") as Button
	_check(sel.visible, "打到过第二章后应显示章节选择")
	_check(title._reached_chapters() == [0, 1, 2, 3, 4], "章节选择应列出第 1–5 章，实际 %s" % str(title._reached_chapters()))
	title.queue_free()
	await _frames(2)
	_check(Campaign.restore_start(2) and Campaign.chapter_index == 2 and not Campaign.has_member("nina"), "回到第三章开场时名单里还没有妮娜")
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(null)


## 自动试玩：我方也交给 EnemyAI 操作，把第 2–5 章各打几个回合。
## 只验证流程（敌方回合、治疗、增援、撤离 / 守关判定）不卡死、不报错；胜负结果打印出来供调难度参考。
func _check_autoplay() -> void:
	for spec in [[2, 3], [3, 4], [4, 5], [5, 7]]:
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


func _autoplay(script: Script, max_turns: int) -> Dictionary:
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(script)
	await _new_battle()
	await _skip_story()
	Engine.time_scale = 6.0
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
		if battle.state == battle.S.STORY:
			battle.dialogue.skip_all()
		if battle.combat_scene.active:
			battle.combat_scene.skip()
		if battle.state == battle.S.IDLE:
			_auto_act()
		await get_tree().create_timer(0.05, true, false, true).timeout
		t += 0.05
		if t > 90.0:
			stuck = true
			break
	# 结算剧情也要放完
	var t2 := 0.0
	while (battle.state == battle.S.OVER or battle.state == battle.S.STORY) and not battle.end_overlay.visible and t2 < 10.0:
		if battle.dialogue.visible:
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
	var foes: Array = battle.units.filter(func(x) -> bool: return not x.is_player() and x.is_alive())
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
	u.grid_pos = best_tile
	u.position = u.tile_center()
	if best_target != null:
		battle.do_combat(u, best_target, best_wi)
	else:
		battle._finish_action(u)


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
	var scorch_paths: Array = scene._layered_bg_paths("f")
	_check(scorch_paths.size() == 4 and str(scorch_paths[0]).ends_with("sky_scorch.png") and str(scorch_paths[3]).ends_with("ground_strip_scorch.png"), "焦土 f 应为四层 scorch 图，实际 %s" % str(scorch_paths))
	_check(scene._layered_bg_paths("B") == scorch_paths, "B 应与焦土 f 共用 scorch 套")
	for plain in [".", "H", "W"]:
		scene._rebuild_bg(CombatScene.GROUND_COLORS[plain], plain)
		_check_layered_stage(scene, "grass")
	scene._rebuild_bg(CombatScene.GROUND_COLORS["F"], "F")
	_check_layered_stage(scene, "forest")
	for scorched in ["f", "B"]:
		scene._rebuild_bg(CombatScene.GROUND_COLORS[scorched], scorched)
		_check_layered_stage(scene, "scorch")
	_check(scene._usable_layered_paths(["res://art/combat/bg/missing_layer.png"]).is_empty(), "任一层缺失时应放弃分层套")
	_check(scene._usable_layered_paths(grass_paths.slice(0, 3) + ["res://art/combat/bg/missing_layer.png"]).is_empty(), "四层里缺一层时应整套回退")
	_check(CombatScene.DEFAULT_BG_SET == "grass", "未登记地形的缺省套应为 grass")
	var explicit := {".": "grass", "H": "grass", "W": "grass", "F": "forest", "f": "scorch", "B": "scorch"}
	_check(CombatScene.TERRAIN_BG == explicit, "显式地形映射应只保留平原/民居/水井、森林、焦土/木桥")
	var unregistered: Array[String] = ["R", "M", "X", "g", "~", "s", "C", "E", "Z", "=", "?"]
	for ch in GameData.TERRAIN.keys():
		var key := str(ch)
		if not explicit.has(key) and not unregistered.has(key):
			unregistered.append(key)
	for plain_char in unregistered:
		_check(not CombatScene.TERRAIN_BG.has(plain_char), "缺省用例不应写进显式表: " + plain_char)
		_check(scene._layered_bg_paths(plain_char) == grass_paths, "未登记地形应默认 grass 四层: " + plain_char)
		scene._rebuild_bg(CombatScene.GROUND_COLORS.get(plain_char, CombatScene.GROUND_COLORS["."]), plain_char)
		_check_layered_stage(scene, "grass")
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
		"%s：选择移动位置（返回取消）",
		"%s 的威胁范围（返回清除）",
		"选择行动（返回撤销移动）",
		"选择武器（返回）",
		"用【%s】选择攻击目标（返回）",
		"选择要使用的道具（返回）",
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
	_check("返回" in battle.hint_label.text, "移动提示应改用返回，实际 " + battle.hint_label.text)
	var back := battle.ui.find_child("BackButton", true, false) as Button
	_check(back != null, "应有返回按钮")
	if back != null:
		_check(back.text == "返回", "返回按钮应为中文，实际 " + back.text)
		_check(back.position.x >= SafeArea.MARGIN_X and back.position.y >= SafeArea.MARGIN_Y, "返回按钮应落在安全区内")
		_check(back.position.x + back.size.x <= 1280.0 - SafeArea.MARGIN_X + 0.01, "返回按钮应避开右安全区，右缘 %s" % (back.position.x + back.size.x))
		_check(back.position.y + back.size.y <= 720.0 - SafeArea.MARGIN_Y + 0.01, "返回按钮应避开下安全区，底边 %s" % (back.position.y + back.size.y))
		_check(back.size.y >= SafeArea.MIN_HIT, "返回按钮热区应 ≥ 48")
		back.pressed.emit()
	var menu_btn := battle.ui.find_child("MenuButton", true, false) as Button
	if menu_btn != null:
		var menu_right := menu_btn.position.x + menu_btn.size.x
		_check(menu_right <= 1280.0 - SafeArea.MARGIN_X + 0.01, "菜单按钮应避开右安全区，右缘 %s" % menu_right)
		_check(menu_btn.position.y + menu_btn.size.y <= 720.0 - SafeArea.MARGIN_Y + 0.01, "菜单按钮应避开下安全区")
	_check(battle.selected == null and battle.state == battle.S.IDLE, "返回按钮应取消选中并回到 IDLE")
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
	_check(battle.units.size() == 11, "读档单位数量应为 11，实际 %d" % battle.units.size())


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
	var back: Button = battle.btn_back
	if back != null:
		var win_rect := win.get_global_rect()
		var lose_rect := lose.get_global_rect()
		var back_rect := back.get_global_rect()
		_check(win_rect.size.y > 8.0 and lose_rect.size.y > 8.0, "胜负条件应有可见高度")
		_check(lose_rect.end.y <= back_rect.position.y + 0.01, "胜负条件不应压到返回按钮，底 %s 返回 %s" % [lose_rect.end.y, back_rect.position.y])
		_check(win_rect.position.x >= 960.0, "胜负条件应在右侧信息栏，x=%s" % win_rect.position.x)
		_check(win_rect.end.x <= 1280.0 - SafeArea.MARGIN_X + 1.0, "胜利条件应避开右安全区，右缘 %s" % win_rect.end.x)


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
	_check(battle.units.size() == 11, "重开后应回到 11 个初始单位，实际 %d" % battle.units.size())
	var alive := 0
	for u in battle.units:
		if u.is_alive():
			alive += 1
	_check(alive == 11, "重开后应全员存活，实际 %d" % alive)
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
			var cover := Rect2(spr.position, spr.texture.get_size() * spr.scale)
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
