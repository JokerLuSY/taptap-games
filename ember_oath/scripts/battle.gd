extends Node2D
## 《炎烬之誓》战斗场景：回合制战棋主循环（第一章原型）

const TILE := 64

enum S { STORY, IDLE, MOVE_SEL, ACTION_MENU, WEAPON_SEL, TARGET_SEL, ITEM_MENU, COMBAT, ENEMY, OVER, HEAL_SEL, PICK, PREP, MAP_MENU }

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
var hud: MapHud                    # 浮动信息窗（目标 / 单位 / 地形 / 提示）
var tutorial: Tutorial             # 新手教程：分步引导 + 情境提示
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
const NO_TILE := Vector2i(-9999, -9999)
var _map_menu_tile := NO_TILE        # 空地上按下的格子：松手且没拖动时弹地图菜单


func _build_board() -> void:
	# 地图铺满整屏；比屏幕小的地图居中，四周是深色底
	var screen := SafeArea.screen()
	var bg := ColorRect.new()
	bg.name = "MapBackdrop"
	bg.color = Color(0.05, 0.06, 0.09)
	bg.size = screen
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -100                  # 地面层 MapTiles 是 z -2，底色要压在它下面
	add_child(bg)
	map_clip = Control.new()
	map_clip.name = "MapClip"
	map_clip.position = Vector2.ZERO
	map_clip.size = screen               # 宽屏手机上铺满整屏，右边不留黑框
	map_clip.clip_contents = true
	map_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_clip)
	board = Board.new()
	board.units = units
	board.view_size = map_clip.size
	board.theme = str(chapter.get_script().get_script_constant_map().get("THEME", ""))
	map_clip.add_child(board)
	board.load_map(chapter.MAP, chapter.LEVELS, chapter.BG)
	cursor = MapCursor.new()
	cursor.set_grid(Vector2i(4, 3))
	board.add_child(cursor)
	if not get_viewport().size_changed.is_connected(_on_screen_resized):
		get_viewport().size_changed.connect(_on_screen_resized)


## 画面尺寸变了（宽屏手机、窗口缩放）：地图区、信息窗、横幅、结算层跟着铺满，全屏小窗重新居中
func _on_screen_resized() -> void:
	var screen := SafeArea.screen()
	var bg := get_node_or_null("MapBackdrop") as ColorRect
	if bg != null:
		bg.size = screen
	if map_clip != null:
		map_clip.size = screen
	if board != null:
		board.view_size = screen
		board.update_origin()
		board.set_scroll(board.scroll)
	if hud != null:
		hud.size = screen
		hud.refresh()
	for l in [banner_label, toast_label, end_title, end_sub]:
		if l != null:
			l.size.x = screen.x
	_layout_end_buttons()
	if prep != null and is_instance_valid(prep):
		SafeArea.fit_right(prep)
	for c in [shop_window, tutorial, unit_status, trade_window]:
		if c != null and is_instance_valid(c):
			SafeArea.fit(c)


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


## 教程事件（tutorial 不在时什么也不做）
func tut(n: String, d = null) -> void:
	if tutorial != null:
		tutorial.on_event(n, d)


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
	if turn > 1 and made.any(func(m) -> bool: return not m.is_player()):
		tut("spawn")
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


## 离队的同伴回队（剧情加入 / 救出 / 对话）：按回归规则补等级，从名单生成到 pos 附近。
## faction = "npc" 时先作为中立单位出场（例如等着被救的囚犯），被【对话】/【说得】后才算回队。
## 名单里没有这个人（直接从这一章开打的测试）就用 fallback 的默认数值；转幕后、阵亡的回不来，返回 null。
func rejoin_unit(id: String, pos: Vector2i, faction := "player", fallback := {}) -> Unit:
	var existing := get_unit(id)
	if existing != null:
		return existing if existing.is_alive() else null
	if Campaign.has_member(id):
		if not (Campaign.can_rejoin(id) or Campaign.status_of(id) == "active"):
			return null
		var n := Campaign.catch_up(id)
		if faction == "player":
			Campaign.set_status(id, "active")
		_spawn_from_roster(id, pos)
		var u: Unit = units.back()
		u.faction = faction
		u.has_acted = faction == "player"
		u.queue_redraw()
		if faction == "player":
			notify(tr("%s 回到了队伍！") % tr(u.display_name))
		if n > 0:
			notify(tr("%s 补上了离队期间的成长（+%d 级）") % [tr(u.display_name), n])
		update_topbar()
		return u
	if fallback.is_empty():
		return null
	var d := fallback.duplicate()
	d["id"] = id
	d["faction"] = faction
	d["pos"] = pos
	var made := spawn_units([d])
	if made.is_empty():
		return null
	var nu: Unit = made[0]
	nu.has_acted = faction == "player"
	return nu


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
	# 信息窗：地图全屏，目标 / 单位 / 地形窗浮在光标另一侧（火纹式），没有常驻的侧栏和顶栏
	hud = MapHud.new()
	ui.add_child(hud)
	lbl_chapter = hud.lbl_chapter
	lbl_chapter.text = tr(chapter.CHAPTER_TITLE)
	lbl_turn = hud.lbl_turn
	lbl_gold = hud.lbl_gold
	lbl_win = hud.lbl_win
	lbl_lose = hud.lbl_lose
	hint_label = hud.hint_label
	update_topbar()
	_refresh_objectives()
	# 中央阶段横幅
	banner_label = Label.new()
	banner_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	banner_label.position = Vector2(0, 290)
	banner_label.size = Vector2(SafeArea.screen().x, 90)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 56)
	banner_label.modulate.a = 0.0
	ui.add_child(banner_label)
	# 顶部 toast
	toast_label = Label.new()
	toast_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	toast_label.position = Vector2(0, 100)
	toast_label.size = Vector2(SafeArea.screen().x, 36)
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
	tutorial = Tutorial.new()
	ui.add_child(tutorial)
	SafeArea.fit(tutorial)
	tutorial.setup(self)
	dialogue = DialogueBox.new()
	ui.add_child(dialogue)
	combat_scene = CombatScene.new()
	add_child(combat_scene)
	system_menu = load("res://scripts/system_menu.gd").new()
	system_menu.title_requested.connect(_on_system_title)
	add_child(system_menu)


func _build_forecast_panel() -> void:
	forecast_panel = PanelContainer.new()
	forecast_panel.name = "ForecastPanel"
	forecast_panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.16, 0.94)
	sb.border_color = Color(0.85, 0.75, 0.45)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	forecast_panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	forecast_panel.add_child(vb)
	# 火纹式：上面是对方，下面是自己
	forecast_def = Label.new()
	forecast_def.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	forecast_def.custom_minimum_size = Vector2(280, 0)
	forecast_def.add_theme_font_size_override("font_size", 18)
	forecast_def.add_theme_color_override("font_color", Color(1.0, 0.72, 0.68))
	vb.add_child(forecast_def)
	var vs := Label.new()
	vs.text = "VS"
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.add_theme_font_size_override("font_size", 22)
	vs.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
	vb.add_child(vs)
	forecast_att = Label.new()
	forecast_att.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	forecast_att.custom_minimum_size = Vector2(280, 0)
	forecast_att.add_theme_font_size_override("font_size", 18)
	forecast_att.add_theme_color_override("font_color", Color(0.72, 0.85, 1.0))
	vb.add_child(forecast_att)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vb.add_child(btn_row)
	var ok := Button.new()
	ok.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	ok.text = tr("确认攻击")
	ok.custom_minimum_size = Vector2(134, SafeArea.MIN_HIT)
	ok.pressed.connect(_on_forecast_ok)
	btn_row.add_child(ok)
	var cancel := Button.new()
	cancel.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	cancel.text = tr("取消")
	cancel.custom_minimum_size = Vector2(134, SafeArea.MIN_HIT)
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
	end_title.size = Vector2(SafeArea.screen().x, 90)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_font_size_override("font_size", 64)
	end_overlay.add_child(end_title)
	end_sub = Label.new()
	end_sub.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	end_sub.position = Vector2(0, 330)
	end_sub.size = Vector2(SafeArea.screen().x, 80)
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
	board.opened = chapter.visited
	var lead := get_unit("tia")
	if lead == null:
		for id in chapter.lose_ids():
			lead = get_unit(id)
			if lead != null and lead.is_player():
				break
	if lead != null:
		board.center_on(lead.grid_pos)
	await play_prologue()
	await chapter.on_battle_start()
	if chapter.prep_mode() != "":
		await _run_prep()
	await _pending_promotions()
	start_player_phase(true)


## 剧情转职顺延：剧情点到了但不满 Lv10 的，满级后在队的下一章开场补上
func _pending_promotions() -> void:
	var tia := get_unit("tia")
	if Campaign.flags.get("tia_awaken_pending", false) and tia != null and tia.is_player() and tia.level >= 7:
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
	if not first:
		_terrain_heal(true)
	_gain_support_points()
	if not first and await check_end_conditions():
		return
	await chapter.on_turn_start(turn)
	if state == S.OVER:
		return
	state = S.IDLE
	if pending_chapter == null:
		CampaignSave.write_checkpoint(self)
	tut("player_phase", turn)
	refresh_talk_marks()
	_idle_hint()
	_update_hover_info()


func enemy_phase() -> void:
	if state == S.OVER:
		return
	state = S.ENEMY
	_clear_menu()
	_hide_forecast()
	selected = null
	danger_on = false
	board.set_danger({})
	board.clear_highlights()
	update_topbar()
	Audio.play_sfx("phase", 0.85)
	show_banner(tr("敌方回合"), Color(1.0, 0.45, 0.4))
	tut("enemy_phase")
	_terrain_heal(false)
	await get_tree().create_timer(0.9).timeout
	for e in units.duplicate():
		if state == S.OVER:
			return
		if e.is_player() or e.is_npc() or not e.is_alive():
			continue
		var players: Array = units.filter(func(x) -> bool: return (x.is_player() or x.is_ally_fighter()) and x.on_map())
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
	await _ally_phase()
	if state == S.OVER:
		return
	start_player_phase()


## 友军阶段（火纹的 Other Phase）：绿色的第三方战斗单位自己行动，打敌人
func _ally_phase() -> void:
	var allies: Array = units.filter(func(x) -> bool: return x.is_ally_fighter() and x.is_alive() and x.on_map())
	if allies.is_empty():
		return
	state = S.ENEMY
	Audio.play_sfx("phase", 0.85)
	show_banner(tr("友军回合"), Color(0.45, 0.9, 0.5))
	await get_tree().create_timer(0.7).timeout
	for n in allies:
		if state == S.OVER:
			return
		if not n.is_alive() or not n.is_ally_fighter():
			continue
		var foes: Array = units.filter(func(x) -> bool: return not x.is_player() and not x.is_npc() and x.is_alive() and x.on_map())
		if foes.is_empty():
			return
		# 能招募的敌人不打（别替玩家把人打死）；倒下就败北的友军只原地迎击，不往敌群里冲
		var rec: Dictionary = chapter.recruits()
		foes = foes.filter(func(x) -> bool: return not rec.has(x.unit_id))
		if foes.is_empty():
			continue
		var keep_still: bool = n.unit_id in chapter.lose_ids()
		var was_still: bool = n.stationary
		if keep_still:
			n.stationary = true
		var act: Dictionary = EnemyAI.choose(n, board, foes)
		n.stationary = was_still
		var mv: Vector2i = act["move_to"]
		cursor.set_grid(n.grid_pos)
		board.ensure_visible(n.grid_pos)
		if mv != n.grid_pos:
			var nrange := board.move_range(n)
			board.ensure_visible(mv, 1)
			await _animate_move(n, board.find_path(n, mv, nrange))
			n.grid_pos = mv
			n.position = n.tile_center()
		if act.get("target") != null:
			await do_combat(n, act["target"], act.get("weapon", 0))
			if state == S.OVER:
				return
		elif act.get("heal") != null:
			await do_heal(n, act["heal"])
		n.has_acted = true
		n.queue_redraw()
		await get_tree().create_timer(ENEMY_GAP_TIME).timeout


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
	if PointerInput.is_primary_release(event):
		# 松手时没拖动过地图，才算在空地上「点了一下」
		var dragged := _dragging
		_scroll_input(event)
		var p0 := _map_menu_tile
		_map_menu_tile = NO_TILE
		if not dragged and p0 != NO_TILE and state == S.IDLE:
			open_map_menu(p0)
		return
	if _scroll_input(event):
		_map_menu_tile = NO_TILE
		return
	if PointerInput.is_pointer_move(event):
		var p := board.tile_at_viewport(PointerInput.viewport_position(event))
		if board.in_bounds(p) and p != cursor.grid_pos:
			cursor.set_grid(p)
			_on_cursor_moved()
	elif PointerInput.is_primary_press(event):
		var p := board.tile_at_viewport(PointerInput.viewport_position(event))
		# 空闲时点空地：松手后弹地图菜单（敌人威胁范围亮着时先只清掉范围）
		var arm := state == S.IDLE and board.in_bounds(p) and board.unit_at(p) == null \
			and board.move_tiles.is_empty() and board.atk_tiles.is_empty()
		click_tile(p)
		_map_menu_tile = p if arm else NO_TILE
	elif PointerInput.is_secondary_press(event):
		cancel()
	elif event.is_action_pressed("ui_accept"):
		if state == S.IDLE and board.unit_at(cursor.grid_pos) == null and board.move_tiles.is_empty() and board.atk_tiles.is_empty():
			open_map_menu(cursor.grid_pos)
		else:
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


## 格子中心在屏幕上的位置（地图会卷动 / 居中）
func tile_screen_pos(p: Vector2i) -> Vector2:
	return board.get_global_transform_with_canvas() * (Vector2(p) * TILE + Vector2(TILE, TILE) / 2.0)


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
			else:
				cancel()
		S.PREP:
			if prep != null:
				prep.on_map_click(p)
		# 下拉菜单开着时点到菜单外的地图 = 取消
		S.ACTION_MENU, S.WEAPON_SEL, S.ITEM_MENU, S.MAP_MENU:
			cancel()


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
			_hide_forecast()
			_open_action_menu(selected)
		S.ITEM_MENU:
			_open_action_menu(selected)
		S.HEAL_SEL:
			_open_action_menu(selected)
		S.PICK:
			board.clear_highlights()
			_open_action_menu(selected)
		S.PREP:
			if prep != null and prep.in_subpage():
				prep.show_menu()
		S.MAP_MENU:
			_clear_menu()
			state = S.IDLE
			_idle_hint()
		S.IDLE:
			board.clear_highlights()
			_idle_hint()


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
	if unit_status != null and is_instance_valid(unit_status):
		unit_status.close()
		return
	if trade_window != null and is_instance_valid(trade_window):
		trade_window.close()
		return
	if _has_cancel_layer():
		cancel()
		return
	open_system_menu()


func _has_cancel_layer() -> bool:
	if state == S.PREP and prep != null and prep.in_subpage():
		return true
	if state in [S.MOVE_SEL, S.ACTION_MENU, S.WEAPON_SEL, S.TARGET_SEL, S.ITEM_MENU, S.HEAL_SEL, S.PICK, S.MAP_MENU]:
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
	for pair in chapter.flags.get("doors_opened", []):
		if typeof(pair) == TYPE_ARRAY and pair.size() >= 2:
			board.set_tile(Vector2i(int(pair[0]), int(pair[1])), "S")
	chapter.on_resume()
	refresh_talk_marks()
	board.goal_tiles = chapter.goal_tiles()
	board.opened = chapter.visited
	if board.tiles != null:
		board.tiles.queue_redraw()
	state = S.IDLE
	update_topbar()
	_idle_hint()
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
		_previewed = null
		board.clear_highlights()
		return
	if u.is_player() and not u.has_acted:
		select_unit(u)
	elif not u.is_player():
		# 火纹式：第一次点亮出威胁范围，再点一次同一个人打开能力画面
		if _previewed == u and (not board.move_tiles.is_empty() or not board.atk_tiles.is_empty()):
			open_unit_status(u)
		else:
			_preview_enemy(u)
	else:
		open_unit_status(u)


var _previewed: Unit = null
var unit_status: UnitStatus = null


## 单位能力画面（立绘、能力、战斗数值、持有物、武器等级）；点任意处关闭
func open_unit_status(u: Unit) -> void:
	if unit_status != null and is_instance_valid(unit_status):
		return
	unit_status = UnitStatus.new()
	ui.add_child(unit_status)
	unit_status.open(self, u)
	SafeArea.fit(unit_status)
	tut("status", u)
	var prev := state
	state = S.COMBAT
	await unit_status.closed
	unit_status = null
	if state == S.COMBAT:
		state = prev
		if prev == S.IDLE:
			after_player_action()


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
	tut("select", u)
	hint(tr("%s：选择移动位置（点空白处取消）") % tr(u.display_name))
	_update_hover_info()


func _deselect() -> void:
	selected = null
	move_dict = {}
	board.clear_highlights()
	state = S.IDLE
	_idle_hint()


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
	p.local_coords = true             # 扬尘跟着地图卷动
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
	_previewed = u
	hint(tr("%s 的威胁范围（再点一次看详细能力，点空白处清除）") % tr(u.display_name))
	tut("preview", u)
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
	var rt = chapter.get_recruit_target(u)
	if rt != null:
		opts.append({"label": tr("对话") if rt.is_npc() else tr("说得"), "enabled": true, "cb": _on_menu_recruit})
	if _can_open_chest(u):
		opts.append({"label": tr("开宝箱"), "enabled": true, "cb": _on_menu_chest})
	if not door_tiles(u).is_empty():
		opts.append({"label": tr("开门"), "enabled": true, "cb": _on_menu_door})
	if not steal_targets(u).is_empty():
		opts.append({"label": tr("偷窃"), "enabled": true, "cb": _on_menu_steal})
	if chapter.shops().has(u.grid_pos):
		opts.append({"label": tr("武器店") if board.tile_at(u.grid_pos) == "Y" else tr("道具店"), "enabled": true, "cb": _on_menu_shop})
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
	if not _adjacent_allies(u).is_empty():
		opts.append({"label": tr("交换"), "enabled": true, "cb": _on_menu_trade})
	opts.append({"label": tr("待机"), "enabled": true, "cb": _on_menu_wait})
	_fill_menu(opts)
	_place_menu(u)
	hint(tr("选择行动（点菜单外撤销移动）"))
	tut("menu", u)
	tut("menu_opts", opts.map(func(o) -> String: return o["label"]))


func _fill_menu(opts: Array) -> void:
	for c in menu_box.get_children():
		c.queue_free()
	for o in opts:
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = o["label"]
		b.custom_minimum_size = Vector2(150, SafeArea.MIN_HIT)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not o["enabled"]
		b.pressed.connect(o["cb"])
		menu_box.add_child(b)
	menu_panel.visible = true


func _place_menu(u: Unit) -> void:
	_place_menu_at(u.grid_pos)


## 下拉菜单贴在格子旁边：默认在右侧，放不下就放左侧；上下夹在安全区里
func _place_menu_at(p: Vector2i) -> void:
	menu_panel.reset_size()
	var ms := menu_panel.get_combined_minimum_size()
	var c := tile_screen_pos(p)
	var safe := SafeArea.rect()
	var x := c.x + TILE / 2.0 + 6.0
	if x + ms.x > safe.end.x:
		x = c.x - TILE / 2.0 - 6.0 - ms.x
	var y := c.y - TILE / 2.0
	menu_panel.position = Vector2(clampf(x, safe.position.x, safe.end.x - ms.x), clampf(y, safe.position.y, safe.end.y - ms.y))


# ==================== 地图菜单（空地上点一下） ====================

func open_map_menu(p: Vector2i) -> void:
	if state != S.IDLE:
		return
	state = S.MAP_MENU
	Audio.play_sfx("select")
	var opts: Array = [
		{"label": tr("回合结束"), "enabled": true, "cb": _on_map_end_turn},
		{"label": tr("隐藏危险范围") if danger_on else tr("显示危险范围"), "enabled": true, "cb": _on_map_danger},
		{"label": tr("教程"), "enabled": true, "cb": _on_map_tutorial},
		{"label": tr("菜单"), "enabled": true, "cb": _on_map_system},
	]
	_fill_menu(opts)
	_place_menu_at(p)
	hint(tr("点菜单外关闭"))


func _close_map_menu() -> void:
	_clear_menu()
	if state == S.MAP_MENU:
		state = S.IDLE
	_idle_hint()


func _on_map_end_turn() -> void:
	_close_map_menu()
	on_end_turn()


func _on_map_danger() -> void:
	_close_map_menu()
	toggle_danger()


func _on_map_tutorial() -> void:
	_close_map_menu()
	tutorial.open_browser()


func _on_map_system() -> void:
	_close_map_menu()
	open_system_menu()


func _idle_hint() -> void:
	hint(tr("点击我方单位行动 · 点空地打开菜单"))


func _clear_menu() -> void:
	menu_panel.visible = false
	for c in menu_box.get_children():
		c.queue_free()


func _cancel_action_menu() -> void:
	# 交换过物品就不能再撤销移动（火纹规矩）：留在行动菜单
	if selected != null and selected.get_meta("trade_locked", false):
		_open_action_menu(selected)
		return
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
	hint(tr("%s：选择移动位置（点空白处取消）") % tr(selected.display_name))


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
		hint(tr("选择武器（点菜单外返回）"))
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
	hint(tr("用【%s】选择攻击目标（点空白处返回）") % tr(selected.weapon(sel_weapon)["name"]))


func _target_click(p: Vector2i) -> void:
	var u := board.unit_at(p)
	if u != null and u in targets:
		_show_forecast(selected, u, sel_weapon)
	else:
		cancel()


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


var shop_window: ShopWindow = null


func _on_menu_shop() -> void:
	_clear_menu()
	var u := selected
	open_shop(u)
	var traded: bool = await shop_window.closed
	shop_window = null
	if traded:
		_finish_action(u)
	else:
		_open_action_menu(u)


## 打开站着的那家店（武器店 / 道具店）。关店时 closed(做过买卖) 信号发出
func open_shop(u: Unit) -> void:
	state = S.COMBAT
	shop_window = ShopWindow.new()
	ui.add_child(shop_window)
	shop_window.open(self, u, "weapon" if board.tile_at(u.grid_pos) == "Y" else "item", chapter.shops().get(u.grid_pos, []))
	SafeArea.fit(shop_window)


func _can_open_chest(u: Unit) -> bool:
	return u.class_label in ["盗贼", "刺客"] and board.tile_at(u.grid_pos) == "Q" \
		and not chapter.visited.has(u.grid_pos) and chapter.chests().has(u.grid_pos)


func _on_menu_chest() -> void:
	_clear_menu()
	var u := selected
	open_chest(u)
	_finish_action(u)


## 盗贼开宝箱：东西进背包（满了进道具库），箱子换成打开的样子
func open_chest(u: Unit) -> void:
	var item: String = chapter.chests().get(u.grid_pos, "")
	chapter.visited[u.grid_pos] = true
	board.opened = chapter.visited
	if board.tiles != null:
		board.tiles.queue_redraw()
	if item == "":
		return
	Audio.play_sfx("coin")
	u.receive(item)
	notify(tr("%s 打开了宝箱：获得 %s") % [tr(u.display_name), tr(PrepScreen.item_name(item))])


## 交换：和相邻的同伴互换物品。只有一个人就直接打开，几个人先选人
var trade_window: TradeWindow = null


func _on_menu_trade() -> void:
	var near := _adjacent_allies(selected)
	if near.size() == 1:
		_clear_menu()
		await open_trade(selected, near[0])
	else:
		_start_pick(_units_at(near), _do_trade_at, tr("选择交换的同伴（点空白处返回）"), false)


func _do_trade_at(p: Vector2i) -> void:
	board.clear_highlights()
	var v := board.unit_at(p)
	if v != null:
		await open_trade(selected, v)


func open_trade(u: Unit, v: Unit) -> void:
	state = S.COMBAT
	trade_window = TradeWindow.new()
	ui.add_child(trade_window)
	trade_window.open(self, u, v)
	SafeArea.fit(trade_window)
	var did: bool = await trade_window.closed
	trade_window = null
	if did:
		u.set_meta("trade_locked", true)
	_open_action_menu(u)


## 头顶气泡：场上有我方的人能【对话】/【说得】的单位（招募表里列的、招募者此刻在场）
func refresh_talk_marks() -> void:
	var table: Dictionary = chapter.recruits()
	var present := {}
	for v in units:
		if v.is_player() and v.on_map():
			present[v.unit_id] = true
	for u in units:
		var on := false
		if u.is_alive() and u.on_map() and not u.is_player() and table.has(u.unit_id):
			for id in table[u.unit_id]:
				if present.has(id):
					on = true
					break
		u.set_talk_mark(on)


## 开门：盗贼 / 刺客，或者背包里有钥匙的人，相邻的牢门
func door_tiles(u: Unit) -> Array:
	if not (u.class_label in ["盗贼", "刺客"] or "door_key" in u.items):
		return []
	var out: Array = []
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var p: Vector2i = u.grid_pos + d
		if board.in_bounds(p) and board.tile_at(p) == "O":
			out.append(p)
	return out


func _on_menu_door() -> void:
	_start_pick(door_tiles(selected), _do_door_at, tr("选择要打开的门（点空白处返回）"), false)


func _do_door_at(p: Vector2i) -> void:
	var u := selected
	board.clear_highlights()
	state = S.COMBAT
	await open_door(u, p)
	_finish_action(u)


## 打开一扇牢门：变成石地（记进章节旗标，读档后补回来）；不是盗贼就用掉一把钥匙
func open_door(u: Unit, p: Vector2i) -> void:
	if not u.class_label in ["盗贼", "刺客"]:
		var k := u.items.find("door_key")
		if k >= 0:
			u.use_item(k)
	board.set_tile(p, "S")
	var opened: Array = chapter.flags.get("doors_opened", [])
	opened.append([p.x, p.y])
	chapter.flags["doors_opened"] = opened
	Audio.play_sfx("coin")
	notify(tr("%s 打开了门") % tr(u.display_name))
	await chapter.on_door(u, p)


## 偷窃（盗贼 / 刺客）：相邻、速度不低于对方、对方身上有道具（武器偷不了）
func steal_targets(u: Unit) -> Array:
	if not u.class_label in ["盗贼", "刺客"]:
		return []
	var out: Array = []
	for v in units:
		if v.is_alive() and v.on_map() and not v.is_player() and not v.is_npc() 				and GameData.dist(u.grid_pos, v.grid_pos) == 1 and not v.items.is_empty() and u.eff_spd() >= v.eff_spd():
			out.append(v)
	return out


func _on_menu_steal() -> void:
	_start_pick(_units_at(steal_targets(selected)), _do_steal_at, tr("选择要偷的敌人（点空白处返回）"), false)


func _do_steal_at(p: Vector2i) -> void:
	var t := board.unit_at(p)
	var u := selected
	board.clear_highlights()
	state = S.COMBAT
	steal(u, t)
	await _give_xp(u, 10)
	_finish_action(u)


## 偷走对方最值钱的一件道具（剩余次数一起带走）
func steal(u: Unit, t: Unit) -> String:
	var best := -1
	var best_price := -1
	for i in t.items.size():
		var price := GameData.item_price(t.items[i])
		if price > best_price:
			best_price = price
			best = i
	if best < 0:
		return ""
	var id: String = t.items[best]
	var uses := int(t.item_uses[best]) if best < t.item_uses.size() else -2
	t.items.remove_at(best)
	if best < t.item_uses.size():
		t.item_uses.remove_at(best)
	if not u.give(id, uses):
		Campaign.convoy.append([id, uses if uses > 0 else int(GameData.ITEMS.get(id, {}).get("uses", 1))])
	Audio.play_sfx("coin")
	notify(tr("%s 从 %s 身上偷到了 %s") % [tr(u.display_name), tr(t.display_name), tr(PrepScreen.item_name(id))])
	tut("steal", u)
	return id


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
	hint(tr("选择要使用的道具（点菜单外返回）"))


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
	u.remove_meta("trade_locked")
	refresh_talk_marks()
	u.has_acted = true
	u.queue_redraw()
	tut("acted", u)
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
		var fmt := "对话 %s：需要 %s 出击" if e.is_npc() else "说得 %s：需要 %s 出击"
		out.append(tr(fmt) % [tr(e.display_name), tr("、").join(PackedStringArray(names))])
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
	SafeArea.fit_right(prep)
	hud.forced_side = "left"
	_update_hover_info()
	prep.setup(self)
	hint(tr("出击准备：选人、布阵、整理物品，准备好后点【开始战斗】"))
	tut("prep")
	await prep.done
	prep.queue_free()
	prep = null
	hud.forced_side = ""
	_update_hover_info()
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
	_start_pick(_units_at(rescue_targets(selected)), _do_rescue_at, tr("选择要救出的同伴（点空白处返回）"))


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
	_start_pick(drop_tiles(selected), _do_drop_at, tr("选择放下的位置（点空白处返回）"))


func _do_drop_at(p: Vector2i) -> void:
	var u := selected
	board.clear_highlights()
	var t := u.put_down(p)
	if t != null:
		Audio.play_sfx("move")
	_finish_action(u)


func _on_menu_take() -> void:
	_start_pick(_units_at(take_sources(selected)), _do_take_at, tr("从谁手里接过同伴（点空白处返回）"))


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
	_start_pick(_units_at(give_targets(selected)), _do_give_at, tr("交给谁（点空白处返回）"))


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
	hint(tr("选择要治疗的同伴（点空白处返回）"))


func _heal_click(p: Vector2i) -> void:
	var v := board.unit_at(p)
	if v == null or not v in targets:
		cancel()
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
	_hide_forecast()
	selected = null
	board.clear_highlights()
	enemy_phase()


func toggle_danger() -> void:
	if state == S.STORY or state == S.COMBAT or state == S.ENEMY or state == S.OVER:
		return
	danger_on = not danger_on
	board.set_danger(_compute_danger() if danger_on else {})
	tut("danger")


func _compute_danger() -> Dictionary:
	var all := {}
	for e in units:
		if e.is_player() or e.is_npc() or not e.is_alive():
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
		if e.is_player() == u.is_player() or e.is_npc() or not e.is_alive():
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
	var aw: Dictionary = att.weapon(wi)
	var dw: Dictionary = def.weapon()
	tut("forecast", {"triangle": GameData.triangle_dir(str(aw.get("type", "")), str(dw.get("type", ""))), "magic": aw.get("magic", false) or dw.get("magic", false)})
	# 停在目标的另一侧，不挡住交战双方
	forecast_panel.reset_size()
	var safe := SafeArea.rect()
	var fs := forecast_panel.get_combined_minimum_size()
	var right := tile_screen_pos(def.grid_pos).x < 640.0
	forecast_panel.position = Vector2(safe.end.x - fs.x if right else safe.position.x, clampf(360.0 - fs.y / 2.0, safe.position.y, safe.end.y - fs.y))
	if hud != null:
		hud.hide_unit()
		hud.goal_win.visible = false
		hud.terrain_win.visible = false


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


func _hide_forecast() -> void:
	forecast_panel.visible = false
	if hud != null:
		hud.goal_win.visible = true
		hud.terrain_win.visible = true
		_update_hover_info()


func _on_forecast_ok() -> void:
	_hide_forecast()
	if _forecast_target != null and selected != null:
		do_combat(selected, _forecast_target, sel_weapon)


func _on_forecast_cancel() -> void:
	_hide_forecast()


func do_combat(att: Unit, def: Unit, wi: int) -> void:
	state = S.COMBAT
	_clear_menu()
	board.clear_highlights()
	await chapter.on_before_combat(att, def)
	state = S.COMBAT
	var fc := Combat.forecast(att, def, wi, board)
	var events := Combat.resolve(att, def, wi, board)
	var dwi: int = def.counter_weapon(GameData.dist(att.grid_pos, def.grid_pos))
	combat_scene.theme = board.theme
	combat_scene.burning = board.is_burning()
	combat_scene.tint = chapter.combat_tint()
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
			print("[FALL] %s (%s) by %s (%s Lv%d)" % [u.unit_id, u.faction, (def if u == att else att).unit_id, (def if u == att else att).class_label, (def if u == att else att).level])
			if u.is_player():
				await _fallen_words(u)
			elif u.is_npc() and Campaign.status_of(u.unit_id) == "away":
				var r := Fates.retreats(u.unit_id, chapter_number())
				Campaign.set_status(u.unit_id, "retired" if r else "dead")
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
			tut("weapon_broke", u)
			break


func _give_xp(u: Unit, n: int) -> void:
	var res: Dictionary = u.gain_xp(n)
	_float_text(u, "EXP +%d" % n, Color(0.6, 0.9, 1.0))
	await get_tree().create_timer(0.35).timeout
	if res.is_empty():
		return
	tut("levelup", u)
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
			print("[DEFEAT] ch%d turn %d: %s %s" % [chapter_number(), turn, id, "missing" if u == null else "fell"])
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
	await play_scenes(chapter.epilogue())
	# 剧情必需的绿色友军没被【对话】也自动归队，再把存活的我方写回战役名单，推进到下一章
	for id in chapter.must_join_on_victory():
		var g := get_unit(id)
		if g != null and g.is_alive() and g.is_npc():
			g.faction = "player"
			if Campaign.status_of(id) == "away":
				Campaign.set_status(id, "active")
	Campaign.store_party(units)
	var st: Dictionary = chapter.after_victory_status()
	for id in st:
		Campaign.set_status(id, st[id])
	Campaign.flags["support_points"] = support_points.duplicate()
	var bonus: int = chapter.victory_gold()
	if bonus > 0:
		gold += bonus
		notify(tr("胜利奖金 %d G") % bonus)
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
" + (tr("感谢游玩！") if chapter.is_final() else tr("（后续章节制作中）"))
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
		b.position = Vector2((SafeArea.screen().x - w) * 0.5, y)
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
	if hud != null:
		hud.refresh()


func get_unit(id: String) -> Unit:
	for u in units:
		if u.unit_id == id:
			return u
	return null


# ==================== 表现 ====================

## 章节开场：大陆地图（来路虚线、当前地点脉动）+ 旁白
func play_prologue() -> void:
	var pr: Dictionary = chapter.prologue()
	if pr.is_empty():
		return
	var wm := WorldMap.new()
	ui.add_child(wm)
	SafeArea.fit(wm)
	ui.move_child(wm, dialogue.get_index())
	wm.setup(str(pr.get("place", "")), str(pr.get("from", "")), tr(chapter.CHAPTER_TITLE))
	await wm.intro()
	await play_dialogue(pr.get("lines", []))
	await wm.outro()
	wm.queue_free()


## 剧情场景：全屏氛围底 + 地点标题，台词走对话框
func play_scenes(scenes: Array) -> void:
	for sc in scenes:
		var card := SceneCard.new()
		ui.add_child(card)
		SafeArea.fit(card)
		ui.move_child(card, dialogue.get_index())
		card.setup(tr(str(sc.get("title", ""))), str(sc.get("mood", "night")))
		await card.intro()
		await play_dialogue(sc.get("lines", []))
		await card.outro()
		card.queue_free()


func play_dialogue(lines: Array) -> void:
	var prev := state
	state = S.STORY
	dialogue.play(lines)
	await dialogue.all_finished
	if state == S.STORY:
		state = prev


func hint(text: String) -> void:
	if hud != null:
		hud.set_hint(text)


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
	if lbl_turn == null or lbl_gold == null:
		return
	var phase := tr("敌方回合") if state == S.ENEMY else tr("我方回合")
	lbl_turn.text = tr("第 %d 回合 · %s") % [turn, phase]
	lbl_gold.text = tr("金钱 %d G") % gold
	if hud != null:
		hud.refresh()


## 竞技场（出击准备里）：付押金单挑同等级对手。返回 "win" / "lose" / "draw"，钱不够或打不了返回 ""
var arena_fights := 0              # 本章出击准备里已经打了几场竞技场


func run_arena(u: Unit) -> String:
	var cost := Arena.wager(u)
	var pw: Array = Arena.pick_weapon(u)
	if gold < cost or int(pw[0]) < 0 or arena_fights >= Arena.MAX_FIGHTS:
		return ""
	arena_fights += 1
	var spots := _arena_spots(int(pw[1]))
	if spots.is_empty():
		return ""
	add_gold(-cost)
	var home := u.grid_pos
	var foe := Arena.make_foe(u, int(pw[1]))
	foe.visible = false
	board.add_child(foe)
	u.grid_pos = spots[0]
	foe.grid_pos = spots[1]
	var result := "draw"
	Combat.no_support = true
	for r in Arena.MAX_ROUNDS:
		# 双方轮流先手
		var att: Unit = u if r % 2 == 0 else foe
		var dfd: Unit = foe if att == u else u
		var wi: int = int(pw[0]) if att == u else 0
		var fc := Combat.forecast(att, dfd, wi, board)
		var events := Combat.resolve(att, dfd, wi, board)
		await combat_scene.play(att, dfd, wi, events, "S", fc)
		if not foe.is_alive():
			result = "win"
			break
		if not u.is_alive():
			result = "lose"
			break
	Combat.no_support = false
	u.grid_pos = home
	u.position = u.tile_center()
	var xp := Combat.xp_gain(u, foe, true)
	foe.queue_free()
	# 还没开战：打完回满；输了也不会死
	u.hp = u.max_hp
	u.visible = true
	u.modulate.a = 1.0
	if result == "win":
		add_gold(cost * 3 / 2)
		notify(tr("竞技场：%s 获胜！得到 %d G") % [tr(u.display_name), cost * 3 / 2])
		await _give_xp(u, xp)
	elif result == "lose":
		notify(tr("竞技场：%s 落败……押金 %d G 没了") % [tr(u.display_name), cost])
	else:
		add_gold(cost)
		notify(tr("竞技场：平局，退回押金"))
	u.queue_redraw()
	return result


## 竞技场借用地图上的两块平地（同高度、无地形加成）当擂台，相距 dist 格
func _arena_spots(dist: int) -> Array:
	for y in board.height:
		for x in board.width:
			var a := Vector2i(x, y)
			var b := a + Vector2i(dist, 0)
			if not board.in_bounds(b):
				continue
			var ok := true
			for p in [a, b]:
				var t: Dictionary = board.terrain(p)
				if not t["pass"] or int(t["dfn"]) != 0 or int(t["avo"]) != 0:
					ok = false
			if ok and board.level_at(a) == board.level_at(b):
				return [a, b]
	return []


func add_gold(n: int) -> void:
	gold += n
	Audio.play_sfx("coin")
	update_topbar()


func _update_hover_info() -> void:
	if hud == null:
		return
	hud.follow(tile_screen_pos(cursor.grid_pos))
	var u: Unit = selected if selected != null else board.unit_at(cursor.grid_pos)
	if state in [S.IDLE, S.MOVE_SEL]:
		if u != null:
			tut("hover_unit", u)
		tut("hover_tile", cursor.grid_pos)
	if u != null and u.on_map():
		var key := _unit_portrait_key(u)
		var tex: Texture2D = load("res://art/portraits/px/%s.png" % key) if key != "" else null
		hud.show_unit(_unit_info_text(u), tex)
	else:
		hud.hide_unit()
	var t: Dictionary = board.terrain(cursor.grid_pos)
	var lv := board.level_at(cursor.grid_pos)
	var text := tr("【%s】 高度 Lv%d") % [tr(t["name"]), lv] + "\n" + tr("守备 +%d   回避 +%d") % [t["dfn"], t["avo"]]
	if int(t.get("heal", 0)) > 0:
		text += "\n" + tr("回合开始回复 %d%%") % int(t["heal"])
	if cursor.grid_pos in board.goal_tiles:
		text += "\n" + tr("（%s）") % tr(chapter.goal_label())
	hud.show_terrain(text)


## 单位 → 像素立绘（art/portraits/px）：有专属立绘的按 id，杂兵按 id 前缀
const PORTRAIT_BY_ID := {
	"tia": "tia", "balto": "balto", "harlo": "harlo", "bandit6": "toby", "nina": "nina", "kain": "kain", "edric": "edric",
	"noya": "noya", "cyril": "cyril", "sparrow": "sparrow", "silas": "silas", "hawk": "hawk", "brock": "brock",
	"marco": "marco", "barrett": "barrett", "august": "august", "lorenz": "lorenz", "scout1": "scout",
	"lance": "lance", "gwen": "knight", "oscar": "knight", "mira": "villager_w", "victor": "mage", "bruno": "smith", "selene": "villager_w", "gareth": "knight", "hagen": "smith", "liss": "villager_w", "shuo": "merc", "gerard": "elder", "ivy": "granny", "ivan": "church", "vera": "vera", "gray": "gray", "talia": "villager_w", "benedict": "elder", "kira": "villager_w", "rock": "knight", "edmund": "edmund", "seven": "seven",
	"caspar": "scout", "skarl": "brock", "hermann": "mage", "bernard": "knight", "carlton": "knight", "grimm": "knight", "varen": "knight", "simon": "archer", "barlow": "knight", "aurelia": "mage", "adeline": "church", "oswald": "mage", "ignaz": "knight",
	"orion": "archer", "owen": "mage", "lilith": "villager_w", "roland": "merc",
	"hector": "knight", "werner": "mage", "raven": "scout", "marcus": "mage", "zero": "seven", "alban": "church", "morgan": "morgan",
}
const PORTRAIT_BY_PREFIX := [["bandit", "bandit"], ["merc", "merc"], ["church", "church"], ["knight", "knight"],
	["archer", "archer"], ["mage", "mage"], ["soldier", "church"], ["armor", "knight"], ["pegasus", "church"], ["puppet", "seven"], ["pirate", "bandit"], ["darkmage", "mage"], ["graycloak", "scout"], ["cleric", "church"], ["sniper", "archer"], ["paladin", "knight"], ["general", "knight"], ["sage", "mage"], ["brodden", "merc"], ["thief", "bandit"], ["fighter", "bandit"], ["myrm", "merc"]]


func _unit_portrait_key(u: Unit) -> String:
	if PORTRAIT_BY_ID.has(u.unit_id):
		return PORTRAIT_BY_ID[u.unit_id]
	for rule in PORTRAIT_BY_PREFIX:
		if u.unit_id.begins_with(rule[0]):
			return rule[1]
	return ""


func _unit_info_text(u: Unit) -> String:
	var lines: Array = []
	var side := tr("我方") if u.is_player() else (tr("中立") if u.is_npc() else tr("敌方"))
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


## 回合开始：站在堡垒等回复地形上的一方回复最大 HP 的 heal%
func _terrain_heal(player_side: bool) -> void:
	for u in units:
		if not u.is_alive() or not u.on_map() or u.is_player() != player_side or u.hp >= u.max_hp:
			continue
		var pct := int(board.terrain(u.grid_pos).get("heal", 0))
		if pct <= 0:
			continue
		var n := maxi(1, int(ceil(u.max_hp * pct / 100.0)))
		n = mini(n, u.max_hp - u.hp)
		u.heal(n)
		_float_text(u, "+%d" % n, Color(0.5, 1.0, 0.6))


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


## 我方倒下（永久死亡）：主线还有戏份的人重伤撤退、转到幕后（之后不能再出击），其余阵亡。各留一句话。
## 倒下即败北的主角不走这里（直接进败北演出）。
func _fallen_words(u: Unit) -> void:
	if u.unit_id in chapter.lose_ids():
		return
	var retreat := Fates.retreats(u.unit_id, chapter_number())
	u.set_meta("retreated", retreat)
	var text := Fates.last_words(u.unit_id, retreat)
	if text != "":
		await play_dialogue([{"name": u.display_name, "color": Color(0.7, 0.85, 1.0), "text": tr(text)}])
	if retreat:
		notify(tr("%s 重伤撤退了（之后不能再出击）") % tr(u.display_name))
	else:
		notify(tr("%s 阵亡了") % tr(u.display_name))


## 当前是第几章（从 1 数；不在战役章节表里返回 0）
func chapter_number() -> int:
	return Campaign.index_of(chapter.get_script()) + 1


func _death_anim(u: Unit) -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(u, "modulate:a", 0.0, 0.5)
	t.tween_property(u, "scale", Vector2(0.5, 0.5), 0.5)
	await t.finished
	u.visible = false
