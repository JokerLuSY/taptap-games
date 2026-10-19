extends Node2D
## 《炎烬之誓》战斗场景：回合制战棋主循环（第一章原型）

const TILE := 64

enum S { STORY, IDLE, MOVE_SEL, ACTION_MENU, WEAPON_SEL, TARGET_SEL, ITEM_MENU, COMBAT, ENEMY, OVER, HEAL_SEL, PICK, PREP }

var state: int = S.STORY
var board: Board
var cursor: MapCursor
var units: Array = []
var turn := 1
var gold := 0
## 进战斗前由标题写入。null = 第一章。重试本章不清除，回到标题再开第一章时由标题清掉。
static var pending_chapter: Script = null
var chapter = null
var support_points := {}          # {支援对 key: 点数}

var selected: Unit = null
var sel_weapon := 0
var move_dict: Dictionary = {}
var pre_move_pos := Vector2i.ZERO
var _last_path: Array = []    # 最近一次我方移动的路径（撤销时原路走回）
var targets: Array = []
var prep: PrepScreen = null      # 出击准备界面
var prep_pool: Array = []         # 本章可出击的我方单位
var deployed: Array = []          # 出击中的单位
var deploy_slots: Array = []      # 可部署的格子
var _pick_tiles := {}             # 救出 / 放下 / 接手 / 交给：可点的格子
var _pick_cb: Callable
var danger_on := false

# ---- UI ----
var ui: CanvasLayer
var lbl_chapter: Label
var lbl_turn: Label
var lbl_gold: Label
var btn_threat: Button
var info_label: Label
var info_portrait_frame: Panel
var info_portrait: TextureRect
var hint_label: Label
var toast_label: Label
var banner_label: Label
var menu_panel: PanelContainer
var menu_box: VBoxContainer
var forecast_panel: PanelContainer
var forecast_att: Label
var forecast_def: Label
var levelup_panel: PanelContainer
var levelup_label: Label
var end_overlay: ColorRect
var end_title: Label
var end_sub: Label
var end_btn: Button
var end_restart: Button
var end_next: Button
var lbl_win: Label
var lbl_lose: Label
var dialogue: DialogueBox
var combat_scene: CombatScene
var system_menu
var btn_back: Button
var btn_menu: Button

var _forecast_target: Unit = null
var _banner_tween: Tween = null


static func queue_chapter(chapter_script) -> void:
	pending_chapter = chapter_script


func _ready() -> void:
	var save_data := {}
	if CampaignSave.take_pending_load():
		save_data = CampaignSave.read()
		Campaign.load_payload(save_data)
	var script: Script = pending_chapter
	if script == null:
		script = Campaign.chapter_script()
	else:
		var idx := Campaign.index_of(script)
		if idx >= 0:
			Campaign.chapter_index = idx
	chapter = script.new()
	chapter.battle = self
	_build_board()
	var loaded := false
	if not save_data.is_empty():
		loaded = _apply_checkpoint(save_data)
	if not loaded:
		gold = Campaign.gold
		var sp = Campaign.flags.get("support_points", {})
		support_points = sp.duplicate() if sp is Dictionary else {}
		_build_units()
	_build_ui()
	Audio.play_music("map")
	if not get_tree().root.go_back_requested.is_connected(_on_android_back):
		get_tree().root.go_back_requested.connect(_on_android_back)
	if loaded:
		_resume_idle.call_deferred()
	else:
		_start_chapter.call_deferred()


func _exit_tree() -> void:
	Audio.stop_loop()


# ==================== 构建 ====================

var map_clip: Control              # 地图裁剪框：棋盘比视口大时只露出这一块
var _drag_from := Vector2.ZERO
var _drag_scroll := Vector2.ZERO
var _dragging := false
var _pressing := false
const DRAG_START := 16.0


func _build_board() -> void:
	map_clip = Control.new()
	map_clip.name = "MapClip"
	map_clip.position = Vector2(0, 48)
	map_clip.size = Vector2(960, 640)
	map_clip.clip_contents = true
	map_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_clip)
	board = Board.new()
	board.units = units
	map_clip.add_child(board)
	board.load_map(chapter.MAP, chapter.LEVELS, chapter.BG)
	cursor = MapCursor.new()
	cursor.set_grid(Vector2i(4, 3))
	board.add_child(cursor)


## 开场生成：章节 UNITS 里的我方单位优先取战役名单里的存档（等级、能力、道具随队继承），
## 名单里离队 / 阵亡的不出场；名单里在队但本章没写位置的，放到 extra_slots。
func _build_units() -> void:
	var st: Dictionary = chapter.before_spawn_status()
	for id in st:
		Campaign.set_status(id, st[id])
	var placed := {}
	for def in chapter.UNITS:
		var id: String = def.get("id", "")
		if str(def.get("faction", "")) != "player" and not Campaign.has_member(id):
			continue
		placed[id] = true
	var defs: Array = []
	var fresh := Campaign.roster.is_empty()
	for def in chapter.UNITS:
		var id: String = def.get("id", "")
		if not Campaign.has_member(id):
			# 名单里没有的我方单位：本章新加入（join）或直接进本章（名单为空，测试 / 调试）才用默认数值
			if str(def.get("faction", "")) == "player" and not fresh and not def.get("join", false):
				continue
			defs.append(def)
			continue
		if Campaign.status_of(id) != "active":
			continue
		var pos: Vector2i = def.get("pos", Vector2i.ZERO)
		_spawn_from_roster(id, pos)
	var slots: Array = chapter.extra_slots()
	for id in Campaign.active_ids():
		if placed.has(id):
			continue
		var pos: Vector2i = slots.pop_front() if not slots.is_empty() else Vector2i(0, board.height - 1)
		_spawn_from_roster(id, pos)
	spawn_units(defs)


func _spawn_from_roster(id: String, pos: Vector2i) -> void:
	var u := Unit.new()
	u.apply_save(Campaign.roster[id])
	u.faction = "player"
	u.grid_pos = pos
	u.hp = u.max_hp
	u.has_acted = false
	u.visible = true
	u.modulate.a = 1.0
	if board.unit_at(u.grid_pos) != null or not board.terrain(u.grid_pos)["pass"]:
		u.grid_pos = _nearest_free(u.grid_pos)
	u.position = u.tile_center()
	board.add_child(u)
	units.append(u)


func spawn_units(defs: Array) -> Array:
	var made: Array = []
	for def in ChapterBase.expand_with(defs, chapter.templates()):
		var u := Unit.new()
		u.setup(def)
		if board.unit_at(u.grid_pos) != null:
			u.grid_pos = _nearest_free(u.grid_pos)
			u.position = u.tile_center()
		board.add_child(u)
		units.append(u)
		made.append(u)
	update_topbar()
	return made


## 剧情加入：在 near 附近生成一名我方单位（本回合不能行动）
func join_unit(def: Dictionary, near: Vector2i) -> Unit:
	var d := def.duplicate()
	d["faction"] = "player"
	d["pos"] = near
	var made := spawn_units([d])
	if made.is_empty():
		return null
	var u: Unit = made[0]
	u.has_acted = true
	u.queue_redraw()
	notify(tr("%s 成为同伴了！") % tr(u.display_name))
	return u


func _nearest_free(p: Vector2i) -> Vector2i:
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var np := Vector2i(p.x + dx, p.y + dy)
				if board.in_bounds(np) and board.terrain(np)["pass"] and board.unit_at(np) == null:
					return np
	return p


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	# GBA 风暖色滤镜（微降饱和）
	var tint := ColorRect.new()
	tint.color = Color(1.0, 0.88, 0.66, 0.05)
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(tint)
	# 顶栏占住上安全区；贴边的主操作再内缩 EDGE_ACTION
	var top := Panel.new()
	top.position = Vector2.ZERO
	top.size = Vector2(1280, SafeArea.MARGIN_Y)
	_style_panel(top, Color(0.08, 0.10, 0.16, 0.95))
	ui.add_child(top)
	lbl_chapter = _make_label(top, Vector2(SafeArea.MARGIN_X, 12), tr(chapter.CHAPTER_TITLE), 22)
	lbl_chapter.name = "ChapterLabel"
	lbl_turn = _make_label(top, Vector2(SafeArea.MARGIN_X, 12), "", 22)
	lbl_turn.name = "TurnLabel"
	lbl_gold = _make_label(top, Vector2(SafeArea.MARGIN_X, 12), "", 22)
	lbl_gold.name = "GoldLabel"
	var end_size := Vector2(156, SafeArea.MIN_HIT)
	# 「Threat Range (T)」在 210 宽里刚好放下，不要再加长。
	var danger_size := Vector2(210, SafeArea.MIN_HIT)
	var end_pos := Vector2(1280.0 - SafeArea.EDGE_ACTION - end_size.x, 0)
	var danger_pos := Vector2(end_pos.x - 8 - danger_size.x, 0)
	btn_threat = _make_button(tr("危险范围 (T)"), danger_pos, danger_size, toggle_danger)
	btn_threat.name = "ThreatButton"
	top.add_child(btn_threat)
	var btn_end := _make_button(tr("回合结束"), end_pos, end_size, on_end_turn)
	btn_end.name = "EndTurnButton"
	top.add_child(btn_end)
	update_topbar()
	# 右侧信息栏
	var side := Panel.new()
	side.position = Vector2(960, 48)
	side.size = Vector2(320, 640)
	_style_panel(side, Color(0.08, 0.10, 0.16, 0.92))
	ui.add_child(side)
	# 胜负条件常驻在信息栏顶部，不随回合提示或结算消失。
	var obj_w := 320.0 - 16.0 - SafeArea.MARGIN_X
	# 胜负条件各留两行（后面章节的条件比较长）
	lbl_win = _make_label(side, Vector2(16, 4), "", 16)
	lbl_win.name = "WinCondition"
	lbl_win.size = Vector2(obj_w, 50)
	lbl_win.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_win.clip_text = true
	lbl_win.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_win.add_theme_color_override("font_color", Color(0.96, 0.86, 0.45))
	lbl_lose = _make_label(side, Vector2(16, 56), "", 16)
	lbl_lose.name = "LoseCondition"
	lbl_lose.size = Vector2(obj_w, 50)
	lbl_lose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_lose.clip_text = true
	lbl_lose.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_lose.add_theme_color_override("font_color", Color(0.95, 0.62, 0.48))
	_refresh_objectives()
	# 立绘框（默认隐藏），让出上方胜负条件
	info_portrait_frame = Panel.new()
	info_portrait_frame.position = Vector2(16, 112)
	info_portrait_frame.size = Vector2(128, 128)
	info_portrait_frame.visible = false
	var ipb := StyleBoxFlat.new()
	ipb.bg_color = Color(0.10, 0.13, 0.22)
	ipb.border_color = Color(0.85, 0.75, 0.45)
	ipb.set_border_width_all(2)
	ipb.set_corner_radius_all(6)
	info_portrait_frame.add_theme_stylebox_override("panel", ipb)
	side.add_child(info_portrait_frame)
	info_portrait = TextureRect.new()
	info_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	info_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	info_portrait_frame.add_child(info_portrait)
	info_label = _make_label(side, Vector2(16, 112), "", 20)
	info_label.size = Vector2(320 - 16 - SafeArea.MARGIN_X, 540)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# 底部提示栏
	var bottom := Panel.new()
	bottom.position = Vector2(0, 688)
	bottom.size = Vector2(1280, 32)
	_style_panel(bottom, Color(0.08, 0.10, 0.16, 0.95))
	ui.add_child(bottom)
	hint_label = _make_label(bottom, Vector2(SafeArea.MARGIN_X, 3), "", 18)
	hint_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	# 中央阶段横幅
	banner_label = Label.new()
	banner_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	banner_label.position = Vector2(0, 290)
	banner_label.size = Vector2(1280, 90)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 56)
	banner_label.modulate.a = 0.0
	ui.add_child(banner_label)
	# 顶部 toast
	toast_label = Label.new()
	toast_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	toast_label.position = Vector2(0, 58)
	toast_label.size = Vector2(1280, 36)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 24)
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	toast_label.modulate.a = 0.0
	ui.add_child(toast_label)
	# 行动菜单
	menu_panel = PanelContainer.new()
	menu_panel.visible = false
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color(0.10, 0.13, 0.22, 0.97)
	msb.border_color = Color(0.85, 0.75, 0.45)
	msb.set_border_width_all(2)
	msb.set_corner_radius_all(6)
	msb.content_margin_left = 8
	msb.content_margin_right = 8
	msb.content_margin_top = 8
	msb.content_margin_bottom = 8
	menu_panel.add_theme_stylebox_override("panel", msb)
	menu_box = VBoxContainer.new()
	menu_panel.add_child(menu_box)
	ui.add_child(menu_panel)
	_build_forecast_panel()
	_build_levelup_panel()
	_build_end_overlay()
	dialogue = DialogueBox.new()
	ui.add_child(dialogue)
	combat_scene = CombatScene.new()
	add_child(combat_scene)
	_build_corner_buttons()
	system_menu = load("res://scripts/system_menu.gd").new()
	system_menu.title_requested.connect(_on_system_title)
	add_child(system_menu)


func _build_corner_buttons() -> void:
	# 右侧信息栏底部、安全区内。不盖地图格子。
	var size := Vector2(116, SafeArea.MIN_HIT)
	var y := 720.0 - SafeArea.MARGIN_Y - size.y
	btn_back = _make_button(tr("返回"), Vector2(976, y), size, _on_back_pressed)
	btn_back.name = "BackButton"
	ui.add_child(btn_back)
	btn_menu = _make_button(tr("菜单"), Vector2(976 + size.x + 8, y), size, _on_menu_pressed)
	btn_menu.name = "MenuButton"
	ui.add_child(btn_menu)


func _build_forecast_panel() -> void:
	forecast_panel = PanelContainer.new()
	forecast_panel.position = Vector2(340, 190)
	forecast_panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.16, 0.97)
	sb.border_color = Color(0.85, 0.75, 0.45)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	forecast_panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	forecast_panel.add_child(vb)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	forecast_att = Label.new()
	forecast_att.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	forecast_att.custom_minimum_size = Vector2(250, 0)
	forecast_att.add_theme_font_size_override("font_size", 21)
	hb.add_child(forecast_att)
	var vs := Label.new()
	vs.text = "VS"
	vs.custom_minimum_size = Vector2(70, 0)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.add_theme_font_size_override("font_size", 30)
	vs.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
	hb.add_child(vs)
	forecast_def = Label.new()
	forecast_def.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	forecast_def.custom_minimum_size = Vector2(250, 0)
	forecast_def.add_theme_font_size_override("font_size", 21)
	hb.add_child(forecast_def)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vb.add_child(btn_row)
	var ok := Button.new()
	ok.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	ok.text = tr("确认攻击")
	ok.custom_minimum_size = Vector2(168, SafeArea.MIN_HIT)
	ok.pressed.connect(_on_forecast_ok)
	btn_row.add_child(ok)
	var cancel := Button.new()
	cancel.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	cancel.text = tr("取消")
	cancel.custom_minimum_size = Vector2(168, SafeArea.MIN_HIT)
	cancel.pressed.connect(_on_forecast_cancel)
	btn_row.add_child(cancel)
	ui.add_child(forecast_panel)


func _build_levelup_panel() -> void:
	levelup_panel = PanelContainer.new()
	levelup_panel.position = Vector2(490, 240)
	levelup_panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.10, 0.97)
	sb.border_color = Color(0.6, 0.9, 0.5)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	levelup_panel.add_theme_stylebox_override("panel", sb)
	levelup_label = Label.new()
	levelup_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	levelup_label.add_theme_font_size_override("font_size", 24)
	levelup_panel.add_child(levelup_label)
	ui.add_child(levelup_panel)


func _build_end_overlay() -> void:
	end_overlay = ColorRect.new()
	end_overlay.color = Color(0, 0, 0, 0.85)
	end_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_overlay.visible = false
	ui.add_child(end_overlay)
	end_title = Label.new()
	end_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	end_title.position = Vector2(0, 210)
	end_title.size = Vector2(1280, 90)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_font_size_override("font_size", 64)
	end_overlay.add_child(end_title)
	end_sub = Label.new()
	end_sub.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	end_sub.position = Vector2(0, 330)
	end_sub.size = Vector2(1280, 80)
	end_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_sub.add_theme_font_size_override("font_size", 26)
	end_sub.add_theme_color_override("font_color", Color(0.8, 0.78, 0.72))
	end_overlay.add_child(end_sub)
	end_btn = Button.new()
	end_btn.name = "EndTitleButton"
	end_btn.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	end_btn.custom_minimum_size = Vector2(420, maxi(56, SafeArea.MIN_HIT))
	end_btn.position = Vector2(430, 460)
	end_btn.add_theme_font_size_override("font_size", 26)
	end_btn.visible = false
	end_overlay.add_child(end_btn)
	end_restart = Button.new()
	end_restart.name = "RestartButton"
	end_restart.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	end_restart.custom_minimum_size = Vector2(420, maxi(56, SafeArea.MIN_HIT))
	end_restart.position = Vector2(430, 420)
	end_restart.add_theme_font_size_override("font_size", 26)
	end_restart.visible = false
	end_overlay.add_child(end_restart)
	end_next = Button.new()
	end_next.name = "NextChapterButton"
	end_next.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	end_next.custom_minimum_size = Vector2(420, maxi(56, SafeArea.MIN_HIT))
	end_next.add_theme_font_size_override("font_size", 26)
	end_next.visible = false
	end_overlay.add_child(end_next)


func _style_panel(p: Panel, c: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	p.add_theme_stylebox_override("panel", sb)


func _make_label(parent: Node, pos: Vector2, text: String, size: int) -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.position = pos
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l


func _make_button(text: String, pos: Vector2, min_size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.text = text
	b.position = pos
	b.custom_minimum_size = min_size
	b.size = min_size
	b.pressed.connect(cb)
	return b


# ==================== 章节流程 ====================

func _start_chapter() -> void:
	state = S.STORY
	update_topbar()
	board.goal_tiles = chapter.goal_tiles()
	await chapter.on_battle_start()
	if chapter.prep_mode() != "":
		await _run_prep()
	await _pending_promotions()
	start_player_phase(true)


## 剧情转职顺延：剧情点到了但不满 Lv10 的，满级后在队的下一章开场补上
func _pending_promotions() -> void:
	var tia := get_unit("tia")
	if Campaign.flags.get("tia_awaken_pending", false) and tia != null and tia.is_player() and tia.level >= 10:
		Campaign.flags.erase("tia_awaken_pending")
		await awaken_tia(true)


## 缇娅觉醒为炎刃使（剧情转职，不耗道具）。late = 顺延到后面章节开场补上的那一次。
func awaken_tia(late := false) -> void:
	var tia := get_unit("tia")
	if tia == null:
		return
	var c_narr := Color(0.82, 0.82, 0.88)
	var c_awake := Color(1.0, 0.45, 0.2)
	var lines: Array = []
	if late:
		lines.append({"name": "", "color": c_narr, "text": tr("缇娅握剑的手忽然一烫。那天在渡口没能握住的火，这一次没有散去。")})
	lines.append({"name": "缇娅·觉醒", "color": c_awake, "text": tr("……这一次，我握住它了。")})
	lines.append({"name": "", "color": c_narr, "text": tr("剑士之路在火里折断。炎刃使，于此觉醒。")})
	Audio.play_sfx("awaken")
	await play_dialogue(lines)
	tia.promote("炎刃使", {"hp": 3, "pwr": 2, "dfn": 1}, ["ember_blade"] + tia.weapons)
	tia.hair_color = Color(1.0, 0.42, 0.12)
	tia.armor_color = Color(0.72, 0.28, 0.16)
	tia.body_color = Color(0.95, 0.40, 0.22)
	tia.queue_redraw()
	Audio.play_sfx("promote")
	Audio.play_sfx("fire")
	show_banner(tr("觉醒 · 炎刃使"), Color(1.0, 0.45, 0.15))
	notify(tr("缇娅转职为炎刃使！"))


func start_player_phase(first := false) -> void:
	# 敌方也要复位，否则行动过的敌人在我方回合一直是灰的
	for u in units:
		if u.is_alive():
			u.has_acted = false
			u.queue_redraw()
	if not first:
		turn += 1
	state = S.STORY
	update_topbar()
	Audio.play_sfx("phase")
	show_banner(tr("第 %d 回合 · 我方回合") % turn, Color(0.45, 0.7, 1.0))
	_gain_support_points()
	if not first and await check_end_conditions():
		return
	await chapter.on_turn_start(turn)
	if state == S.OVER:
		return
	state = S.IDLE
	if pending_chapter == null:
		CampaignSave.write_checkpoint(self)
	hint(tr("点击我方单位行动 · 点击敌人查看其威胁范围"))
	_update_hover_info()


func enemy_phase() -> void:
	if state == S.OVER:
		return
	state = S.ENEMY
	_clear_menu()
	forecast_panel.visible = false
	selected = null
	danger_on = false
	board.set_danger({})
	board.clear_highlights()
	update_topbar()
	Audio.play_sfx("phase", 0.85)
	show_banner(tr("敌方回合"), Color(1.0, 0.45, 0.4))
	await get_tree().create_timer(0.9).timeout
	for e in units.duplicate():
		if state == S.OVER:
			return
		if e.is_player() or not e.is_alive():
			continue
		var players: Array = units.filter(func(x) -> bool: return x.is_player() and x.on_map())
		if players.is_empty():
			return
		var act: Dictionary = EnemyAI.choose(e, board, players)
		var mv: Vector2i = act["move_to"]
		# 先把光标滑到行动的敌人身上，亮一下它的移动范围，让玩家看清是谁在动
		cursor.set_grid(e.grid_pos)
		board.ensure_visible(e.grid_pos)
		var erange := board.move_range(e)
		if mv != e.grid_pos or act.get("target") != null or act.get("heal") != null:
			board.show_move(erange, {})
			await get_tree().create_timer(ENEMY_FOCUS_TIME).timeout
			board.clear_highlights()
			if state == S.OVER:
				return
		if mv != e.grid_pos:
			board.ensure_visible(mv, 1)
			var path := board.find_path(e, mv, erange)
			await _animate_move(e, path)
			e.grid_pos = mv
			e.position = e.tile_center()
		if act.get("target") != null:
			await do_combat(e, act["target"], act.get("weapon", 0))
			if state == S.OVER:
				return
		elif act.get("heal") != null:
			await do_heal(e, act["heal"])
		e.has_acted = true
		e.queue_redraw()
		await get_tree().create_timer(ENEMY_GAP_TIME).timeout
	start_player_phase()


# ==================== 输入 ====================

func _unhandled_input(event: InputEvent) -> void:
	# 菜单打开时场景树已暂停，引擎不会把事件送到这里。
	# 直接调用（冒烟）或同一帧的排序仍可能进来，交给菜单自己关。
	if system_menu != null and system_menu.is_open():
		return
	if event.is_action_pressed("ui_cancel"):
		if PointerInput.accept_back():
			_handle_system_back()
		get_viewport().set_input_as_handled()
		return
	if state == S.STORY or state == S.COMBAT or state == S.ENEMY or state == S.OVER:
		return
	if _scroll_input(event):
		return
	if PointerInput.is_pointer_move(event):
		var p := board.tile_at_viewport(PointerInput.viewport_position(event))
		if board.in_bounds(p) and p != cursor.grid_pos:
			cursor.set_grid(p)
			_on_cursor_moved()
	elif PointerInput.is_primary_press(event):
		click_tile(board.tile_at_viewport(PointerInput.viewport_position(event)))
	elif PointerInput.is_secondary_press(event):
		cancel()
	elif event.is_action_pressed("ui_accept"):
		click_tile(cursor.grid_pos)
	elif event.is_action_pressed("ui_up"):
		_move_cursor(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down"):
		_move_cursor(Vector2i(0, 1))
	elif event.is_action_pressed("ui_left"):
		_move_cursor(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		_move_cursor(Vector2i(1, 0))
	elif event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_T:
		toggle_danger()


## 大地图卷动：滚轮（Shift = 横向）、按住拖动平移。点击照常在按下时生效，拖过阈值后才开始平移。
## 返回 true 表示事件已被卷动吃掉
func _scroll_input(event: InputEvent) -> bool:
	if board == null or not board.can_scroll():
		return false
	if event is InputEventMouseButton and event.pressed:
		var step := Vector2.ZERO
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				step = Vector2(-TILE, 0) if event.shift_pressed else Vector2(0, -TILE)
			MOUSE_BUTTON_WHEEL_DOWN:
				step = Vector2(TILE, 0) if event.shift_pressed else Vector2(0, TILE)
			MOUSE_BUTTON_WHEEL_LEFT:
				step = Vector2(-TILE, 0)
			MOUSE_BUTTON_WHEEL_RIGHT:
				step = Vector2(TILE, 0)
		if step != Vector2.ZERO:
			board.set_scroll(board.scroll + step, true)
			return true
	if PointerInput.is_primary_press(event):
		_pressing = true
		_dragging = false
		_drag_from = PointerInput.viewport_position(event)
		_drag_scroll = board.scroll
		return false
	if (event is InputEventMouseButton and not event.pressed) or (event is InputEventScreenTouch and not event.pressed):
		var was := _dragging
		_pressing = false
		_dragging = false
		return was
	if _pressing and PointerInput.is_pointer_move(event):
		var d := PointerInput.viewport_position(event) - _drag_from
		if _dragging or d.length() > DRAG_START:
			_dragging = true
			board.set_scroll(_drag_scroll - d)
			return true
	return false


func _move_cursor(d: Vector2i) -> void:
	var np := cursor.grid_pos + d
	if board.in_bounds(np):
		cursor.set_grid(np)
		_on_cursor_moved()


func _on_cursor_moved() -> void:
	board.ensure_visible(cursor.grid_pos)
	_update_hover_info()
	Audio.play_sfx("cursor")
	if state == S.MOVE_SEL and selected != null:
		if move_dict.has(cursor.grid_pos):
			# 箭头从单位脚下画起（find_path 不含起点）
			board.set_path([selected.grid_pos] + board.find_path(selected, cursor.grid_pos, move_dict))
		else:
			board.set_path([])


func click_tile(p: Vector2i) -> void:
	if not board.in_bounds(p):
		return
	match state:
		S.IDLE:
			_idle_click(p)
		S.MOVE_SEL:
			_move_click(p)
		S.TARGET_SEL:
			_target_click(p)
		S.HEAL_SEL:
			_heal_click(p)
		S.PICK:
			if _pick_tiles.has(p):
				_pick_cb.call(p)
		S.PREP:
			if prep != null:
				prep.on_map_click(p)


func cancel() -> void:
	Audio.play_sfx("cancel")
	match state:
		S.MOVE_SEL:
			_deselect()
		S.ACTION_MENU:
			_cancel_action_menu()
		S.WEAPON_SEL:
			_open_action_menu(selected)
		S.TARGET_SEL:
			forecast_panel.visible = false
			_open_action_menu(selected)
		S.ITEM_MENU:
			_open_action_menu(selected)
		S.HEAL_SEL:
			_open_action_menu(selected)
		S.PICK:
			board.clear_highlights()
			_open_action_menu(selected)
		S.PREP:
			if prep != null and prep.in_deploy():
				prep.show_menu()
		S.IDLE:
			board.clear_highlights()


func _on_android_back() -> void:
	if not is_inside_tree():
		return
	if not PointerInput.accept_back():
		return
	_handle_system_back()


func _handle_system_back() -> void:
	if system_menu != null and system_menu.is_open():
		system_menu.close()
		return
	if _has_cancel_layer():
		cancel()
		return
	open_system_menu()


func _has_cancel_layer() -> bool:
	if state in [S.MOVE_SEL, S.ACTION_MENU, S.WEAPON_SEL, S.TARGET_SEL, S.ITEM_MENU, S.HEAL_SEL, S.PICK]:
		return true
	if state == S.IDLE and (not board.move_tiles.is_empty() or not board.atk_tiles.is_empty()):
		return true
	return false


func _on_back_pressed() -> void:
	if system_menu != null and system_menu.is_open():
		system_menu.close()
		return
	if state == S.STORY or state == S.COMBAT or state == S.ENEMY or state == S.OVER:
		return
	cancel()


func _on_menu_pressed() -> void:
	if system_menu != null and system_menu.is_open():
		system_menu.close()
	else:
		open_system_menu()


func open_system_menu() -> void:
	if system_menu == null or system_menu.is_open():
		return
	system_menu.open()


func close_system_menu() -> void:
	if system_menu != null:
		system_menu.close()


func _on_system_title() -> void:
	close_system_menu()
	get_tree().change_scene_to_file("res://scenes/title.tscn")


func _resume_idle() -> void:
	board.goal_tiles = chapter.goal_tiles()
	state = S.IDLE
	update_topbar()
	hint(tr("点击我方单位行动 · 点击敌人查看其威胁范围"))
	_update_hover_info()
	var tia := get_unit("tia")
	if tia != null and tia.is_alive():
		cursor.set_grid(tia.grid_pos)


func _apply_checkpoint(data: Dictionary) -> bool:
	if str(data.get("chapter_id", "")) != chapter.chapter_id():
		return false
	var list = data.get("units", [])
	if typeof(list) != TYPE_ARRAY or list.is_empty():
		return false
	turn = int(data.get("turn", 1))
	gold = int(data.get("gold", 0))
	var sp = data.get("support_points", {})
	support_points = sp.duplicate() if sp is Dictionary else {}
	var flags = data.get("flags", {})
	if flags is Dictionary:
		chapter.import_flags(flags)
	for raw in list:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var u := Unit.new()
		u.apply_save(raw)
		if u.is_alive() and board.unit_at(u.grid_pos) != null:
			u.grid_pos = _nearest_free(u.grid_pos)
			u.position = u.tile_center()
		board.add_child(u)
		units.append(u)
	# 救出状态：被背着的人重新挂回背他的人身上
	for raw in list:
		if typeof(raw) == TYPE_DICTIONARY and str(raw.get("carried_by", "")) != "":
			var t := get_unit(str(raw.get("id", "")))
			var by := get_unit(str(raw["carried_by"]))
			if t != null and by != null and t.is_alive() and by.is_alive():
				by.pick_up(t)
	return not units.is_empty()


# ==================== 选择与移动 ====================

func _idle_click(p: Vector2i) -> void:
	var u := board.unit_at(p)
	if u == null:
		board.clear_highlights()
		return
	if u.is_player() and not u.has_acted:
		select_unit(u)
	elif not u.is_player():
		_preview_enemy(u)
	else:
		_update_hover_info()


func select_unit(u: Unit) -> void:
	selected = u
	Audio.play_sfx("select")
	pre_move_pos = u.grid_pos
	sel_weapon = 0
	move_dict = board.move_range(u)
	var atk := board.full_attack_area(u, move_dict)
	for t in move_dict:
		atk.erase(t)
	board.show_move(move_dict, atk)
	state = S.MOVE_SEL
	u.hop()
	hint(tr("%s：选择移动位置（返回取消）") % tr(u.display_name))
	_update_hover_info()


func _deselect() -> void:
	selected = null
	move_dict = {}
	board.clear_highlights()
	state = S.IDLE
	hint(tr("点击我方单位行动 · 点击敌人查看其威胁范围"))


func _move_click(p: Vector2i) -> void:
	if selected == null:
		state = S.IDLE
		return
	if move_dict.has(p):
		_player_move(selected, p)
		return
	var u := board.unit_at(p)
	if u != null and u.is_player() and not u.has_acted and u != selected:
		select_unit(u)
	else:
		cancel()


func _player_move(u: Unit, dst: Vector2i) -> void:
	state = S.COMBAT
	Audio.play_sfx("move")
	board.clear_highlights()
	board.set_path([])
	var path := board.find_path(u, dst, move_dict)
	_last_path = path.duplicate()
	await _animate_move(u, path)
	u.grid_pos = dst
	u.position = u.tile_center()
	_open_action_menu(u)


const STEP_TIME := 0.09   # 平地每格耗时；高消耗地形按消耗放慢
const ENEMY_FOCUS_TIME := 0.25   # 敌人行动前亮出移动范围的停顿
const ENEMY_GAP_TIME := 0.3      # 敌人之间的间隔


## 沿路径逐格走：每格转身、起步缓加速、到站缓减速，脚下扬尘
func _animate_move(u: Unit, path: Array, step_time := STEP_TIME) -> void:
	if path.is_empty():
		return
	var t := create_tween()
	var prev: Vector2i = u.grid_pos
	var n := path.size()
	u.set_walking(true)
	for i in n:
		var step: Vector2i = path[i]
		var cost := 1
		if board.in_bounds(step):
			cost = maxi(1, int(board.terrain(step).get("cost", 1)))
		var dur := step_time * (1.0 + 0.35 * (cost - 1))
		t.tween_callback(u.face.bind(step - prev))
		t.tween_callback(_step_dust.bind(u))
		var pt := t.tween_property(u, "position", Vector2(step) * TILE + Vector2(TILE / 2.0, TILE / 2.0), dur)
		pt.set_trans(Tween.TRANS_SINE)
		if n == 1:
			pt.set_ease(Tween.EASE_IN_OUT)
		elif i == 0:
			pt.set_ease(Tween.EASE_IN)
		elif i == n - 1:
			pt.set_ease(Tween.EASE_OUT)
		prev = step
	await t.finished
	u.set_walking(false)


## 落脚处的一小团尘土
func _step_dust(u: Unit) -> void:
	if not is_instance_valid(u):
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 6
	p.lifetime = 0.35
	p.explosiveness = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 14.0
	p.initial_velocity_max = 30.0
	p.gravity = Vector2(0, 40)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.5
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.86, 0.78, 0.62, 0.55))
	ramp.set_color(1, Color(0.86, 0.78, 0.62, 0.0))
	p.color_ramp = ramp
	# 落在脚底；y 比单位大，y 排序时画在单位前面，像从脚边扬起
	p.position = u.position + Vector2(0, 18)
	board.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _preview_enemy(u: Unit) -> void:
	var move := board.move_range(u)
	var area := board.full_attack_area(u, move)
	for t in move:
		area[t] = true
	board.show_move({}, area)
	hint(tr("%s 的威胁范围（返回清除）") % tr(u.display_name))
	_update_hover_info()


# ==================== 行动菜单 ====================

## 回合开始时：相邻的支援对 +1 点数
func _gain_support_points() -> void:
	for key in chapter.supports():
		var pair: Array = String(key).split("|")
		var a := get_unit(pair[0])
		var b := get_unit(pair[1])
		if a == null or b == null or not a.on_map() or not b.on_map() or not a.is_player() or not b.is_player():
			continue
		if GameData.dist(a.grid_pos, b.grid_pos) != 1:
			continue
		var nxt := Supports.next_rank(Supports.rank_of(a, b.unit_id))
		if nxt == "":
			continue
		var need := Supports.need_points(key, nxt)
		if support_points.get(key, 0) < need:
			support_points[key] = support_points.get(key, 0) + 1
			if support_points[key] == need:
				notify(tr("%s 与 %s 的羁绊加深了……（相邻时可用【支援】）") % [tr(a.display_name), tr(b.display_name)])


func _open_action_menu(u: Unit) -> void:
	state = S.ACTION_MENU
	Audio.play_sfx("select")
	var opts: Array = []
	if u.can_attack():
		opts.append({"label": tr("攻击"), "enabled": not find_targets(u, -1).is_empty(), "cb": _on_menu_attack})
	if u.heal_staff() >= 0:
		opts.append({"label": tr("治疗"), "enabled": not heal_targets(u).is_empty(), "cb": _on_menu_heal})
	if board.tile_at(u.grid_pos) == "H" and not chapter.visited.has(u.grid_pos):
		opts.append({"label": tr("访问"), "enabled": true, "cb": _on_menu_visit})
	if chapter.get_talk_partner(u) != null:
		opts.append({"label": tr("对话"), "enabled": true, "cb": _on_menu_talk})
	if chapter.get_support_partner(u) != null:
		opts.append({"label": tr("支援"), "enabled": true, "cb": _on_menu_support})
	if chapter.get_recruit_target(u) != null:
		opts.append({"label": tr("说得"), "enabled": true, "cb": _on_menu_recruit})
	if not rescue_targets(u).is_empty():
		opts.append({"label": tr("救出"), "enabled": true, "cb": _on_menu_rescue})
	if u.carrying != null:
		opts.append({"label": tr("放下"), "enabled": not drop_tiles(u).is_empty(), "cb": _on_menu_drop})
	if not take_sources(u).is_empty():
		opts.append({"label": tr("接手"), "enabled": true, "cb": _on_menu_take})
	if not give_targets(u).is_empty():
		opts.append({"label": tr("交给"), "enabled": true, "cb": _on_menu_give})
	if not u.items.is_empty():
		opts.append({"label": tr("道具"), "enabled": true, "cb": _on_menu_item})
	opts.append({"label": tr("待机"), "enabled": true, "cb": _on_menu_wait})
	_fill_menu(opts)
	_place_menu(u)
	hint(tr("选择行动（返回撤销移动）"))


func _fill_menu(opts: Array) -> void:
	for c in menu_box.get_children():
		c.queue_free()
	for o in opts:
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = o["label"]
		b.custom_minimum_size = Vector2(170, SafeArea.MIN_HIT)
		b.disabled = not o["enabled"]
		b.pressed.connect(o["cb"])
		menu_box.add_child(b)
	menu_panel.visible = true


func _place_menu(u: Unit) -> void:
	var gp := u.get_global_position()
	var pos := gp + Vector2(44, -10)
	pos.x = clampf(pos.x, 8, 1280 - 200)
	pos.y = clampf(pos.y, 56, 620)
	menu_panel.position = pos


func _clear_menu() -> void:
	menu_panel.visible = false
	for c in menu_box.get_children():
		c.queue_free()


func _cancel_action_menu() -> void:
	_clear_menu()
	var u := selected
	# 原路快速走回（路径里不含起点，倒序后去掉当前格再补上起点）
	var back: Array = []
	if not _last_path.is_empty() and _last_path.back() == u.grid_pos:
		back = _last_path.duplicate()
		back.reverse()
		back.pop_front()
		back.append(pre_move_pos)
	_last_path = []
	if not back.is_empty():
		state = S.COMBAT
		await _animate_move(u, back, STEP_TIME * 0.6)
		if selected != u or state == S.OVER:
			return
	u.grid_pos = pre_move_pos
	u.position = u.tile_center()
	move_dict = board.move_range(selected)
	var atk := board.full_attack_area(selected, move_dict)
	for t in move_dict:
		atk.erase(t)
	board.show_move(move_dict, atk)
	state = S.MOVE_SEL
	hint(tr("%s：选择移动位置（返回取消）") % tr(selected.display_name))


func _on_menu_attack() -> void:
	var usable: Array = []
	for i in selected.weapons.size():
		if selected.weapon(i)["type"] != "staff":
			usable.append(i)
	if usable.size() > 1:
		state = S.WEAPON_SEL
		var opts: Array = []
		for i in usable:
			var w: Dictionary = selected.weapon(i)
			var idx: int = i
			var lock := "" if selected.can_use(i) else tr("（等级不足）")
			opts.append({
				"label": tr("%s %s 攻%d 命%d%s") % [tr(w["name"]), selected.uses_text(i), w["mt"], w["hit"], lock],
				"enabled": selected.can_use(i) and not find_targets(selected, i).is_empty(),
				"cb": func() -> void: _on_weapon_chosen(idx),
			})
		_fill_menu(opts)
		hint(tr("选择武器（返回）"))
	else:
		_on_weapon_chosen(usable[0] if not usable.is_empty() else 0)


## 选中的武器装备到最前（GBA 火纹式：用哪把就换上哪把）
func _on_weapon_chosen(idx: int) -> void:
	selected.equip(idx)
	sel_weapon = 0
	_enter_target_select()


func _enter_target_select() -> void:
	targets = find_targets(selected, sel_weapon)
	if targets.is_empty():
		_open_action_menu(selected)
		return
	state = S.TARGET_SEL
	_clear_menu()
	var tiles := {}
	for t in targets:
		tiles[t.grid_pos] = true
	board.show_move({}, tiles)
	hint(tr("用【%s】选择攻击目标（返回）") % tr(selected.weapon(sel_weapon)["name"]))


func _target_click(p: Vector2i) -> void:
	var u := board.unit_at(p)
	if u != null and u in targets:
		_show_forecast(selected, u, sel_weapon)


func _on_menu_visit() -> void:
	_clear_menu()
	state = S.COMBAT
	await chapter.on_visit(selected, selected.grid_pos)
	_finish_action(selected)


func _on_menu_talk() -> void:
	_clear_menu()
	state = S.COMBAT
	await chapter.on_talk(selected)
	_finish_action(selected)


func _on_menu_support() -> void:
	_clear_menu()
	state = S.COMBAT
	await chapter.on_support(selected)
	_finish_action(selected)


func _on_menu_recruit() -> void:
	_clear_menu()
	state = S.COMBAT
	await chapter.on_recruit(selected)
	_finish_action(selected)


func _on_menu_item() -> void:
	state = S.ITEM_MENU
	var opts: Array = []
	for i in selected.items.size():
		var item: Dictionary = GameData.ITEMS[selected.items[i]]
		var idx := i
		opts.append({"label": tr("%s %d（%s）") % [tr(item["name"]), int(selected.item_uses[idx]), tr(item["desc"])], "enabled": _item_usable(selected, idx), "cb": func() -> void: _on_use_item(idx)})
	_fill_menu(opts)
	hint(tr("选择要使用的道具（返回）"))


func _item_usable(u: Unit, idx: int) -> bool:
	var item: Dictionary = GameData.ITEMS[u.items[idx]]
	if item.has("heal"):
		return u.hp < u.max_hp
	if item.get("promote", false):
		return can_promote_with(u, u.items[idx])
	return false


func _on_use_item(idx: int) -> void:
	var id: String = selected.items[idx]
	var item: Dictionary = GameData.ITEMS[id]
	var u := selected
	_clear_menu()
	if item.get("promote", false):
		state = S.COMBAT
		u.use_item(idx)
		await promote_with_item(u, id)
		_finish_action(u)
		return
	u.use_item(idx)
	u.heal(item["heal"])
	Audio.play_sfx("heal")
	_float_text(u, "HP +%d" % item["heal"], Color(0.5, 1.0, 0.5))
	_finish_action(u)


# ==================== 转职道具 ====================

## 道具转职：当前职业满 Lv10，且职业表里要的就是这件转职道具
func can_promote_with(u: Unit, item_id: String) -> bool:
	var cls := GameData.class_data(u.class_label)
	return u.level >= 10 and str(cls.get("item", "")) == item_id and str(cls.get("promote", "")) != ""


func promote_with_item(u: Unit, item_id: String) -> void:
	var cls := GameData.class_data(u.class_label)
	var to: String = cls["promote"]
	var before := tr(u.class_label)
	u.promote(to, cls.get("bonus", {}))
	Audio.play_sfx("levelup")
	notify(tr("%s 使用了%s，从%s转职为%s！") % [tr(u.display_name), tr(GameData.ITEMS[item_id]["name"]), before, tr(to)])
	_float_text(u, tr("转职！"), Color(1.0, 0.85, 0.4))
	await get_tree().create_timer(1.0).timeout


func _on_menu_wait() -> void:
	_clear_menu()
	_finish_action(selected)


func _finish_action(u: Unit) -> void:
	u.has_acted = true
	u.queue_redraw()
	board.clear_highlights()
	selected = null
	if state == S.OVER:
		return
	state = S.COMBAT
	await chapter.on_action_end(u)
	if await check_end_conditions():
		return
	state = S.IDLE
	_update_hover_info()
	after_player_action()


# ==================== 出击准备（整备） ====================

func prep_mode() -> String:
	return chapter.prep_mode()


func deploy_limit() -> int:
	return clampi(chapter.deploy_limit(), forced_ids().filter(func(id) -> bool: return get_unit(id) != null).size(), prep_pool.size())


func forced_ids() -> Array:
	return chapter.forced_ids()


func shop_items() -> Array:
	return chapter.shop_items()


## 招募提示：本章说得要谁出击
func recruit_hints() -> Array:
	var out: Array = []
	var table: Dictionary = chapter.recruits()
	for eid in table:
		var e := get_unit(eid)
		if e == null or e.is_player():
			continue
		var names: Array = []
		for id in table[eid]:
			var who := get_unit(id)
			names.append(tr(who.display_name) if who != null else id)
		out.append(tr("说得 %s：需要 %s 出击") % [tr(e.display_name), tr("、").join(PackedStringArray(names))])
	return out


## 开整备：开场站位 + 额外格子是部署格；先上必须出击的，再按顺序补满上限，其余待命
func _run_prep() -> void:
	prep_pool = units.filter(func(u) -> bool: return u.is_player() and u.on_map())
	deploy_slots = []
	for u in prep_pool:
		deploy_slots.append(u.grid_pos)
	for p in chapter.extra_deploy_slots():
		if board.in_bounds(p) and board.terrain(p)["pass"] and not deploy_slots.has(p):
			deploy_slots.append(p)
	deployed = prep_pool.duplicate()
	var limit := deploy_limit()
	var forced := forced_ids()
	var extra := deployed.filter(func(u) -> bool: return not u.unit_id in forced)
	while deployed.size() > limit and not extra.is_empty():
		set_deployed(extra.pop_back(), false)
	state = S.PREP
	prep = PrepScreen.new()
	prep.name = "PrepScreen"
	ui.add_child(prep)
	prep.setup(self)
	hint(tr("出击准备：选人、布阵、整理物品，准备好后点【开始战斗】"))
	await prep.done
	prep.queue_free()
	prep = null
	_finish_prep()
	state = S.STORY


## 结束整备：待命的人写回名单（物品交换的结果要留下），从本章地图上拿掉
func _finish_prep() -> void:
	for u in prep_pool:
		if u in deployed:
			continue
		var data: Dictionary = u.to_save()
		data["status"] = Campaign.status_of(u.unit_id) if Campaign.has_member(u.unit_id) else "active"
		data["alive"] = true
		data["hp"] = u.max_hp
		Campaign.roster[u.unit_id] = data
		units.erase(u)
		u.queue_free()
	board.clear_highlights()
	update_topbar()


## 出击 / 待命：待命的人移到地图外藏起来；出击的放到第一个空着的部署格
func set_deployed(u: Unit, on: bool) -> void:
	if on:
		if u in deployed or deployed.size() >= deploy_limit():
			return
		for p in deploy_slots:
			if board.unit_at(p) == null:
				u.grid_pos = p
				u.position = u.tile_center()
				u.visible = true
				deployed.append(u)
				return
		return
	if not u in deployed:
		return
	deployed.erase(u)
	u.grid_pos = Unit.OFF_MAP
	u.visible = false


## 布阵：把 u 挪到部署格 p；p 上有出击的同伴就互换
func swap_deploy(u: Unit, p: Vector2i) -> void:
	if not deploy_slots.has(p) or not u in deployed:
		return
	var other := board.unit_at(p)
	var from := u.grid_pos
	if other != null and other != u:
		other.grid_pos = from
		other.position = other.tile_center()
	u.grid_pos = p
	u.position = u.tile_center()


# ==================== 救出 / 放下 / 接手 / 交给 ====================

func _adjacent_allies(u: Unit) -> Array:
	var out: Array = []
	for v in units:
		if v != u and v.on_map() and v.is_player() == u.is_player() and GameData.dist(u.grid_pos, v.grid_pos) == 1:
			out.append(v)
	return out


## 身边能背起来的同伴（体格 ≤ 自己的救出值）
func rescue_targets(u: Unit) -> Array:
	if u.carrying != null:
		return []
	return _adjacent_allies(u).filter(func(v) -> bool: return u.can_carry(v))


## 背着的人能放下的空格
func drop_tiles(u: Unit) -> Array:
	var out: Array = []
	if u.carrying == null:
		return out
	for d in Board.DIRS4:
		var p: Vector2i = u.grid_pos + d
		if board.in_bounds(p) and board.unit_at(p) == null and board.terrain(p)["pass"]:
			out.append(p)
	return out


## 身边背着人、能把人交过来的同伴
func take_sources(u: Unit) -> Array:
	if u.carrying != null:
		return []
	return _adjacent_allies(u).filter(func(v) -> bool: return v.carrying != null and v.carrying.con <= u.aid())


## 身边能接过自己背着的人的同伴
func give_targets(u: Unit) -> Array:
	if u.carrying == null:
		return []
	return _adjacent_allies(u).filter(func(v) -> bool: return v.can_carry(u.carrying))


func _start_pick(tiles: Array, cb: Callable, text: String, as_move := true) -> void:
	_pick_tiles = {}
	for p in tiles:
		_pick_tiles[p] = true
	_pick_cb = cb
	state = S.PICK
	_clear_menu()
	if as_move:
		board.show_move(_pick_tiles, {})
	else:
		board.show_move({}, _pick_tiles)
	hint(text)


func _units_at(list: Array) -> Array:
	return list.map(func(v) -> Vector2i: return v.grid_pos)


func _on_menu_rescue() -> void:
	_start_pick(_units_at(rescue_targets(selected)), _do_rescue_at, tr("选择要救出的同伴（返回）"))


func _do_rescue_at(p: Vector2i) -> void:
	var t := board.unit_at(p)
	var u := selected
	board.clear_highlights()
	do_rescue(u, t)
	_finish_action(u)


func do_rescue(u: Unit, t: Unit) -> void:
	u.pick_up(t)
	Audio.play_sfx("select")
	notify(tr("%s 救出了 %s（技巧、速度减半）") % [tr(u.display_name), tr(t.display_name)])


func _on_menu_drop() -> void:
	_start_pick(drop_tiles(selected), _do_drop_at, tr("选择放下的位置（返回）"))


func _do_drop_at(p: Vector2i) -> void:
	var u := selected
	board.clear_highlights()
	var t := u.put_down(p)
	if t != null:
		Audio.play_sfx("move")
	_finish_action(u)


func _on_menu_take() -> void:
	_start_pick(_units_at(take_sources(selected)), _do_take_at, tr("从谁手里接过同伴（返回）"))


func _do_take_at(p: Vector2i) -> void:
	var u := selected
	var from := board.unit_at(p)
	board.clear_highlights()
	var t := from.carrying
	from.carrying = null
	from.queue_redraw()
	u.pick_up(t)
	_finish_action(u)


func _on_menu_give() -> void:
	_start_pick(_units_at(give_targets(selected)), _do_give_at, tr("交给谁（返回）"))


func _do_give_at(p: Vector2i) -> void:
	var u := selected
	var to := board.unit_at(p)
	board.clear_highlights()
	var t := u.carrying
	u.carrying = null
	u.queue_redraw()
	to.pick_up(t)
	_finish_action(u)


## 背人的单位倒下：背着的人放到最近的空格
func _drop_from_fallen(u: Unit) -> void:
	if u.carrying == null:
		return
	var t := u.carrying
	u.carrying = null
	var p := _nearest_free(u.grid_pos)
	t.carried_by = null
	t.grid_pos = p
	t.position = t.tile_center()
	t.visible = true
	t.modulate.a = 1.0
	notify(tr("%s 被放了下来") % tr(t.display_name))


# ==================== 治疗 ====================

## u 身边能治疗的友方（相邻、受伤、存活）
func heal_targets(u: Unit) -> Array:
	var out: Array = []
	if u.heal_staff() < 0:
		return out
	for v in units:
		if v == u or not v.is_alive() or v.is_player() != u.is_player():
			continue
		if v.hp < v.max_hp and GameData.dist(u.grid_pos, v.grid_pos) == 1:
			out.append(v)
	return out


func _on_menu_heal() -> void:
	targets = heal_targets(selected)
	if targets.is_empty():
		return
	state = S.HEAL_SEL
	_clear_menu()
	var tiles := {}
	for t in targets:
		tiles[t.grid_pos] = true
	board.show_move(tiles, {})
	hint(tr("选择要治疗的同伴（返回）"))


func _heal_click(p: Vector2i) -> void:
	var v := board.unit_at(p)
	if v == null or not v in targets:
		return
	var u := selected
	state = S.COMBAT
	board.clear_highlights()
	await do_heal(u, v)
	_finish_action(u)


## 治疗：杖的回复量 + 力（魔力）。我方治疗者每次得 12 经验。
func do_heal(healer: Unit, target: Unit) -> void:
	var amount := healer.heal_amount()
	var si := healer.heal_staff()
	target.heal(amount)
	Audio.play_sfx("heal")
	_float_text(target, "HP +%d" % amount, Color(0.5, 1.0, 0.5))
	await get_tree().create_timer(0.45).timeout
	if healer.is_player() and healer.is_alive():
		_after_weapon_use(healer, si, 1)
		await _give_xp(healer, 12)


func after_player_action() -> void:
	update_topbar()
	for u in units:
		if u.is_player() and u.on_map() and not u.has_acted:
			hint(tr("点击我方单位行动"))
			return
	hint(tr("全军行动完毕……"))
	await get_tree().create_timer(0.6).timeout
	if state == S.IDLE:
		enemy_phase()


func on_end_turn() -> void:
	if state == S.STORY or state == S.COMBAT or state == S.ENEMY or state == S.OVER:
		return
	_clear_menu()
	forecast_panel.visible = false
	selected = null
	board.clear_highlights()
	enemy_phase()


func toggle_danger() -> void:
	if state == S.STORY or state == S.COMBAT or state == S.ENEMY or state == S.OVER:
		return
	danger_on = not danger_on
	board.set_danger(_compute_danger() if danger_on else {})


func _compute_danger() -> Dictionary:
	var all := {}
	for e in units:
		if e.is_player() or not e.is_alive():
			continue
		var move := board.move_range(e)
		for t in move:
			all[t] = true
		var area := board.full_attack_area(e, move)
		for t in area:
			all[t] = true
	return all


# ==================== 战斗 ====================

func find_targets(u: Unit, wi: int) -> Array:
	var out: Array = []
	for e in units:
		if e.is_player() == u.is_player() or not e.is_alive():
			continue
		var d: int = GameData.dist(u.grid_pos, e.grid_pos)
		if wi == -1:
			for i in u.weapons.size():
				if board.can_hit_from(u, d, i):
					out.append(e)
					break
		elif board.can_hit_from(u, d, wi):
			out.append(e)
	return out


func _show_forecast(att: Unit, def: Unit, wi: int) -> void:
	_forecast_target = def
	var f: Dictionary = Combat.forecast(att, def, wi, board)
	forecast_att.text = _forecast_text(att, att.weapon(wi), f["a_dmg"], f["a_hit"], f["a_times"], f["a_crit"])
	if f["d_can"]:
		var dwi: int = def.counter_weapon(GameData.dist(att.grid_pos, def.grid_pos))
		forecast_def.text = _forecast_text(def, def.weapon(dwi), f["d_dmg"], f["d_hit"], f["d_times"], f["d_crit"])
	else:
		forecast_def.text = _forecast_text(def, def.weapon(), 0, 0, 0, 0) + "\n" + tr("（无法反击）")
	forecast_panel.visible = true


func _forecast_text(u: Unit, w: Dictionary, dmg: int, hit: int, times: int, crit: int) -> String:
	var wname := tr(str(w.get("name", "")))
	var s := tr("%s  Lv%d %s") % [tr(u.display_name), u.level, tr(u.class_label)]
	s += "\nHP %d/%d" % [u.hp, u.max_hp]
	s += "\n" + wname
	s += "\n" + (tr("攻击 %d") % dmg)
	if times == 2:
		s += "×2"
	s += "\n" + (tr("命中 %d   必杀 %d") % [hit, crit])
	return s


func _on_forecast_ok() -> void:
	forecast_panel.visible = false
	if _forecast_target != null and selected != null:
		do_combat(selected, _forecast_target, sel_weapon)


func _on_forecast_cancel() -> void:
	forecast_panel.visible = false


func do_combat(att: Unit, def: Unit, wi: int) -> void:
	state = S.COMBAT
	_clear_menu()
	board.clear_highlights()
	await chapter.on_before_combat(att, def)
	state = S.COMBAT
	var fc := Combat.forecast(att, def, wi, board)
	var events := Combat.resolve(att, def, wi, board)
	var dwi: int = def.counter_weapon(GameData.dist(att.grid_pos, def.grid_pos))
	await combat_scene.play(att, def, wi, events, board.tile_at(def.grid_pos), fc)
	var a_n := 0
	var d_n := 0
	for ev in events:
		if ev["side"] == "a":
			a_n += 1
		else:
			d_n += 1
	if att.is_player() and att.is_alive():
		_after_weapon_use(att, wi, a_n)
	if def.is_player() and def.is_alive() and dwi >= 0:
		_after_weapon_use(def, dwi, d_n)
	for u in [att, def]:
		if not u.is_alive() and u.visible:
			await _death_anim(u)
			_drop_from_fallen(u)
	if att.is_alive() and att.is_player():
		var xp: int = Combat.xp_gain(att, def, not def.is_alive())
		await _give_xp(att, xp)
	elif def.is_alive() and def.is_player() and not att.is_player():
		# 防守方也拿经验（被打、反击都算）
		var dxp: int = Combat.xp_gain(def, att, not att.is_alive())
		await _give_xp(def, dxp)
	await chapter.on_after_combat(att, def, not def.is_alive())
	if await check_end_conditions():
		return
	att.has_acted = true
	att.queue_redraw()
	if att.is_player():
		_finish_action(att)
	else:
		state = S.ENEMY


## 我方用了 n 次第 idx 把武器：扣耐久（坏了提示）、涨武器经验（升级提示）
func _after_weapon_use(u: Unit, idx: int, n: int) -> void:
	if n <= 0 or idx < 0 or idx >= u.weapons.size():
		return
	var w: Dictionary = u.weapon(idx)
	var t: String = w["type"]
	var up := u.gain_wexp(t, int(w.get("wexp", 1)))
	if up != "":
		notify(tr("%s 的%s等级提升到 %s！") % [tr(u.display_name), tr(GameData.TYPE_NAMES.get(t, t)), up])
	for i in n:
		var broke := u.use_weapon(idx)
		if broke != "":
			Audio.play_sfx("miss", 0.7)
			notify(tr("%s 的%s坏掉了！") % [tr(u.display_name), tr(broke)])
			break


func _give_xp(u: Unit, n: int) -> void:
	var res: Dictionary = u.gain_xp(n)
	_float_text(u, "EXP +%d" % n, Color(0.6, 0.9, 1.0))
	await get_tree().create_timer(0.35).timeout
	if res.is_empty():
		return
	Audio.play_sfx("levelup")
	var lines: Array = [tr("%s 升级了！  Lv %d") % [tr(u.display_name), res["level"]], ""]
	var gains: Dictionary = res["gains"]
	if gains.is_empty():
		lines.append(tr("（能力没有提升……）"))
	else:
		var names := {"hp": "HP", "pwr": tr("力量"), "skl": tr("技巧"), "spd": tr("速度"), "dfn": tr("守备"), "res": tr("魔防")}
		for k in gains:
			lines.append("%s +1" % names[k])
	levelup_label.text = "\n".join(PackedStringArray(lines))
	levelup_panel.visible = true
	await get_tree().create_timer(1.5).timeout
	levelup_panel.visible = false


# ==================== 胜负 ====================

func check_end_conditions() -> bool:
	if state == S.OVER:
		return true
	for id in chapter.lose_ids():
		var u := get_unit(id)
		if u == null or not u.is_alive():
			await _game_over()
			return true
	if not chapter.is_won():
		return false
	await _victory()
	return true


func _victory() -> void:
	state = S.OVER
	hide_banner()
	update_topbar()
	Audio.stop_music()
	Audio.stop_loop()
	Audio.play_sfx("victory")
	await get_tree().create_timer(0.7).timeout
	await chapter.on_victory()
	# 存活的我方写回战役名单，推进到下一章
	Campaign.store_party(units)
	var st: Dictionary = chapter.after_victory_status()
	for id in st:
		Campaign.set_status(id, st[id])
	Campaign.flags["support_points"] = support_points.duplicate()
	Campaign.advance(gold)
	if pending_chapter == null:
		CampaignSave.write_chapter_start()
	elif not Campaign.is_finished():
		pending_chapter = Campaign.chapter_script()
	end_restart.visible = false
	var sub := tr(chapter.VICTORY_SUB)
	if Campaign.is_finished():
		end_next.visible = false
		sub += "
" + tr("（后续章节制作中）")
	else:
		end_next.visible = true
		end_next.text = tr("进入下一章")
		_bind_pressed(end_next, _on_next_chapter_pressed)
	end_btn.visible = true
	end_btn.text = tr("回到标题")
	_bind_pressed(end_btn, _on_end_title_pressed)
	_show_end(tr(chapter.VICTORY_TITLE), sub)


func _on_next_chapter_pressed() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	tree.change_scene_to_file("res://scenes/battle.tscn")


func _game_over() -> void:
	state = S.OVER
	hide_banner()
	Audio.stop_music()
	Audio.stop_loop()
	Audio.play_sfx("defeat")
	await get_tree().create_timer(0.6).timeout
	await chapter.on_defeat()
	end_restart.visible = true
	end_restart.text = tr("重开本关")
	_bind_pressed(end_restart, _on_restart_pressed)
	end_btn.visible = true
	end_btn.text = tr("回到标题")
	_bind_pressed(end_btn, _on_end_title_pressed)
	_show_end(tr("战  败"), tr(chapter.DEFEAT_SUB))


func _show_end(title: String, sub: String) -> void:
	end_title.text = title
	end_sub.text = sub
	hide_banner()
	_layout_end_buttons()
	end_overlay.visible = true


func _layout_end_buttons() -> void:
	var shown: Array[Button] = []
	if end_next != null and end_next.visible:
		shown.append(end_next)
	if end_restart != null and end_restart.visible:
		shown.append(end_restart)
	if end_btn != null and end_btn.visible:
		shown.append(end_btn)
	var w := 420.0
	var h := maxf(56.0, float(SafeArea.MIN_HIT))
	var gap := 16.0
	var y := 460.0 if shown.size() <= 1 else 420.0
	for b in shown:
		b.custom_minimum_size = Vector2(w, h)
		b.size = Vector2(w, h)
		b.position = Vector2((1280.0 - w) * 0.5, y)
		y += h + gap


func _bind_pressed(btn: Button, cb: Callable) -> void:
	for c in btn.pressed.get_connections():
		btn.pressed.disconnect(c["callable"])
	btn.pressed.connect(cb)


func _on_end_title_pressed() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	tree.change_scene_to_file("res://scenes/title.tscn")


## 重开本关：丢掉本关检查点，从本章开场重打。不走 pending_load。
func _on_restart_pressed() -> void:
	restart_chapter()


func restart_chapter() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	# 回到本章开场时的战役状态（名单、金钱、旗标），丢掉本关检查点
	CampaignSave.pending_load = false
	if not Campaign.restore_start(Campaign.chapter_index):
		Campaign.snapshot_start()
	if pending_chapter == null:
		CampaignSave.write_chapter_start()
	tree.change_scene_to_file("res://scenes/battle.tscn")


func _refresh_objectives() -> void:
	if lbl_win == null or lbl_lose == null:
		return
	lbl_win.text = tr("胜利") + "  " + chapter.win_condition()
	lbl_lose.text = tr("败北") + "  " + chapter.lose_condition()
	# 中文句子里没有空格，按词折行折不开，改为按字折行；英文仍按词折行
	var wrap := TextServer.AUTOWRAP_ARBITRARY if TranslationServer.get_locale().begins_with("zh") else TextServer.AUTOWRAP_WORD_SMART
	lbl_win.autowrap_mode = wrap
	lbl_lose.autowrap_mode = wrap


func get_unit(id: String) -> Unit:
	for u in units:
		if u.unit_id == id:
			return u
	return null


# ==================== 表现 ====================

func play_dialogue(lines: Array) -> void:
	var prev := state
	state = S.STORY
	dialogue.play(lines)
	await dialogue.all_finished
	if state == S.STORY:
		state = prev


func hint(text: String) -> void:
	if hint_label != null:
		hint_label.text = text


func notify(text: String) -> void:
	if toast_label == null:
		return
	toast_label.text = text
	toast_label.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.4)
	t.tween_property(toast_label, "modulate:a", 0.0, 0.5)


func show_banner(text: String, color: Color) -> void:
	if banner_label == null:
		return
	_stop_banner_tween()
	banner_label.visible = true
	banner_label.text = text
	banner_label.add_theme_color_override("font_color", color)
	banner_label.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(banner_label, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_interval(0.8)
	_banner_tween.tween_property(banner_label, "modulate:a", 0.0, 0.4)


## 结算层是半透明黑底，相位横幅不关掉会从「战败」上透出来。
func hide_banner() -> void:
	if banner_label == null:
		return
	_stop_banner_tween()
	banner_label.modulate.a = 0.0
	banner_label.visible = false


func _stop_banner_tween() -> void:
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = null


func update_topbar() -> void:
	if lbl_turn == null or lbl_chapter == null or lbl_gold == null:
		return
	var phase := tr("敌方回合") if state == S.ENEMY else tr("我方回合")
	lbl_turn.text = tr("第 %d 回合 · %s") % [turn, phase]
	lbl_gold.text = tr("金钱 %d G") % gold
	_layout_topbar()


## 章节列先按中文标题宽 ×1.3 预留，当前文案更长时再加宽，然后排回合和金钱。
## 横坐标随文案走，避免英文标题顶到「Turn」。排不下时裁章节，不侵占回合或危险范围按钮。
func _layout_topbar() -> void:
	var gap := 16.0
	var row_h := 28.0
	var zh_w := _top_text_width(chapter.CHAPTER_TITLE)
	var chapter_w := _top_text_width(lbl_chapter.text)
	var slot := maxf(zh_w * 1.3, chapter_w)
	var player_w := _top_text_width(tr("第 %d 回合 · %s") % [turn, tr("我方回合")])
	var enemy_w := _top_text_width(tr("第 %d 回合 · %s") % [turn, tr("敌方回合")])
	var turn_w := maxf(player_w, enemy_w)
	var gold_w := _top_text_width(lbl_gold.text)
	var threat_left := btn_threat.position.x if btn_threat != null else 826.0
	var max_slot := threat_left - gap - turn_w - gap - gold_w - gap - SafeArea.MARGIN_X
	if slot > max_slot:
		slot = maxf(max_slot, 0.0)
	var shown := minf(chapter_w, slot)
	lbl_chapter.position = Vector2(SafeArea.MARGIN_X, 12)
	lbl_chapter.size = Vector2(shown, row_h)
	lbl_chapter.clip_text = chapter_w > shown + 0.5
	lbl_chapter.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if lbl_chapter.clip_text else TextServer.OVERRUN_NO_TRIMMING
	var turn_x := SafeArea.MARGIN_X + slot + gap
	lbl_turn.position = Vector2(turn_x, 12)
	lbl_turn.size = Vector2(_top_text_width(lbl_turn.text), row_h)
	lbl_gold.position = Vector2(turn_x + turn_w + gap, 12)
	lbl_gold.size = Vector2(gold_w, row_h)


func _top_text_width(text: String) -> float:
	var font := lbl_chapter.get_theme_font("font")
	if font == null:
		return 0.0
	var font_size := lbl_chapter.get_theme_font_size("font_size")
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func add_gold(n: int) -> void:
	gold += n
	Audio.play_sfx("coin")
	update_topbar()


func _update_hover_info() -> void:
	if info_label == null:
		return
	var u: Unit = selected if selected != null else board.unit_at(cursor.grid_pos)
	if u != null:
		var portrait_key := _unit_portrait_key(u)
		if portrait_key != "":
			info_portrait.texture = load("res://art/portraits/%s.jpg" % portrait_key)
			info_portrait_frame.visible = true
			info_label.position = Vector2(16, 252)
		else:
			info_portrait_frame.visible = false
			info_label.position = Vector2(16, 112)
		info_label.text = _unit_info_text(u)
	else:
		info_portrait_frame.visible = false
		info_label.position = Vector2(16, 112)
		var t: Dictionary = board.terrain(cursor.grid_pos)
		var lv := board.level_at(cursor.grid_pos)
		info_label.text = tr("【%s】 高度 Lv%d") % [tr(t["name"]), lv] + "\n" + tr("守备 +%d   回避 +%d") % [t["dfn"], t["avo"]]
		if cursor.grid_pos in board.goal_tiles:
			info_label.text += "\n" + tr("（撤离点）")


func _unit_portrait_key(u: Unit) -> String:
	match u.unit_id:
		"harlo":
			# 第一章报信的村里少年，沿用村民立绘
			return "portrait_villager"
		"tia":
			# TODO(M3): 觉醒后仍用第一章立绘。专用「缇娅·觉醒」未到。
			return "portrait_tia"
		"balto":
			return "portrait_balto"
		"brock":
			return "portrait_brock"
		"scout1", "marco":
			# TODO(M3): 探子立绘未到，暂用山贼，不挡通关。
			return "portrait_bandit"
	if u.unit_id.begins_with("bandit"):
		return "portrait_bandit"
	return ""


func _unit_info_text(u: Unit) -> String:
	var lines: Array = []
	var side := tr("我方") if u.is_player() else tr("敌方")
	lines.append(tr("%s  Lv%d %s（%s）") % [tr(u.display_name), u.level, tr(u.class_label), side])
	lines.append("HP %d/%d   EXP %d" % [u.hp, u.max_hp, u.xp])
	lines.append(tr("力 %d   技 %d   速 %d") % [u.pwr, u.skl, u.spd])
	lines.append(tr("守 %d   魔防 %d   移 %d") % [u.dfn, u.res, u.mov])
	if u.carrying != null:
		lines.append(tr("背着：%s（技、速减半）") % tr(u.carrying.display_name))
	var wnames: Array = []
	for i in u.weapons.size():
		wnames.append("%s %s" % [tr(GameData.WEAPONS[u.weapons[i]]["name"]), u.uses_text(i)])
	lines.append(tr("武器：") + tr("、").join(PackedStringArray(wnames)))
	if u.is_player():
		var ranks: Array = []
		for t in GameData.WEAPON_TYPES:
			var r := u.rank_letter(t)
			if r != "":
				ranks.append("%s%s" % [tr(GameData.TYPE_NAMES[t]), r])
		if not ranks.is_empty():
			lines.append(tr("武器等级：") + " ".join(PackedStringArray(ranks)))
	if not u.items.is_empty():
		var inames: Array = []
		for i in u.items.size():
			inames.append("%s %d" % [tr(GameData.ITEMS[u.items[i]]["name"]), int(u.item_uses[i])])
		lines.append(tr("道具：") + tr("、").join(PackedStringArray(inames)))
	return "\n".join(PackedStringArray(lines))


func _float_text(u: Unit, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", color)
	l.position = u.position + Vector2(-24, -52)
	l.z_index = 5   # 棋盘开了 y 排序，飘字要压在所有单位上面
	board.add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 30, 0.8)
	t.tween_property(l, "modulate:a", 0.0, 0.8)
	t.finished.connect(l.queue_free)


func _death_anim(u: Unit) -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(u, "modulate:a", 0.0, 0.5)
	t.tween_property(u, "scale", Vector2(0.5, 0.5), 0.5)
	await t.finished
	u.visible = false
