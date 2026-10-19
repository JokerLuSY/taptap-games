class_name CombatScene
extends CanvasLayer
## 战斗特写演出：GBA 火纹式横版对砍。角色是原创像素条带（CombatFighter，tools/pixelart/fe_combat.py 生成），
## 背景按地形换四层远景并做视差；底部双方面板显示 HIT / DMG / CRT 和 HP。点击 / 回车可跳过。

signal finished

const GROUND_COLORS := {
	".": Color(0.47, 0.62, 0.34), "R": Color(0.74, 0.65, 0.47),
	"F": Color(0.26, 0.46, 0.25), "H": Color(0.47, 0.62, 0.34),
	"B": Color(0.62, 0.45, 0.28), "M": Color(0.50, 0.47, 0.42),
	"f": Color(0.56, 0.44, 0.29), "W": Color(0.47, 0.62, 0.34),
	"X": Color(0.50, 0.47, 0.42),
}

const ATT_X := 400.0
const DEF_X := 880.0
## 角色脚底世界坐标。分层远景是 1280×720 整图，地面带盖住 y=438..559，脚底就落在这条带上。
const FEET_Y := 520.0
## 条带缺图时的程序 Q 版兜底放大倍数
const UNIT_SCALE := 3.2
const HP_BAR_W := 250.0
const PANEL_Y := 566.0

## 分层战斗背景套。从远到近四层，全部 1280×720，LINEAR，脚底仍落在 FEET_Y。
const BG_SETS := {
	"grass": [
		"res://art/combat/bg/sky_grass.png",
		"res://art/combat/bg/mountains_grass.png",
		"res://art/combat/bg/mid_grass.png",
		"res://art/combat/bg/ground_strip_grass.png",
	],
	"forest": [
		"res://art/combat/bg/sky_forest.png",
		"res://art/combat/bg/mountains_forest.png",
		"res://art/combat/bg/mid_forest.png",
		"res://art/combat/bg/ground_strip_forest.png",
	],
	"scorch": [
		"res://art/combat/bg/sky_scorch.png",
		"res://art/combat/bg/mountains_scorch.png",
		"res://art/combat/bg/mid_scorch.png",
		"res://art/combat/bg/ground_strip_scorch.png",
	],
}
## terrain_char → 套名。表里没有的字符（道路等）默认 grass，不再铺纯色扁底。
const DEFAULT_BG_SET := "grass"
const TERRAIN_BG := {
	".": "grass",
	"H": "grass",
	"W": "grass",
	"F": "forest",
	"f": "scorch",
	"B": "scorch",
}
## 视差：镜头横移 cam_x 时，各层（远→近）跟着移动的比例；整套放大一点留出移动余量
const PARALLAX := [0.0, 0.12, 0.35, 0.65]
const BG_ZOOM := 1.08

## 单位 → 战斗条带套（见 CombatSets.SETS）。按 id，再按 id 前缀，最后按武器类型兜底。
const FIGHTER_BY_ID := {
	"tia": "tia",
	"balto": "balto",
	"brock": "boss",
	"marco": "boss",
	"scout1": "scout",
}
const FIGHTER_BY_PREFIX := [["bandit", "bandit"], ["archer", "archer"]]
const FIGHTER_BY_WEAPON := {"sword": "scout", "lance": "balto", "axe": "bandit", "bow": "archer"}
const SLASH_FX := "res://art/cc0/ninja_adventure/fx/SlashCurved.png"
## 同一套条带的不同角色靠调色区分（马尔科和布洛克同用角盔头目）
const TINT_BY_ID := {"marco": Color(1.0, 0.80, 0.70)}

## 背景在角色下面，斩击火花在角色上面。
const Z_BG := 0
const Z_FIGHTER := 10
const Z_FX := 30

var active := false

var _root: Node2D
var _cam: Node2D                    # 镜头推拉（必杀时推近）
var _stage: Node2D                  # 背景 + 单位 + 特效（震屏对象）
var _ambient: Node2D                # 环境粒子（不随震屏）
var _ui: Node2D                     # 底部面板（不震）
var _flash_rect: ColorRect
var _layers: Array = []
var _cam_x := 0.0
var _att_node: CombatFighter = null
var _def_node: CombatFighter = null
var _att_real: Unit = null
var _def_real: Unit = null
var _fc: Dictionary = {}
var _panels := {}                   # "a" / "d" → {name, wpn, hp_fill, hp_label, stats}
var _skip := false


func _ready() -> void:
	visible = false
	layer = 10
	_root = Node2D.new()
	add_child(_root)
	_cam = Node2D.new()
	_root.add_child(_cam)
	_stage = Node2D.new()
	_cam.add_child(_stage)
	_ambient = Node2D.new()
	_root.add_child(_ambient)
	_ui = Node2D.new()
	_root.add_child(_ui)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.size = Vector2(1280, 720)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash_rect)


## fc 是 Combat.forecast 的结果，只用来在面板上显示命中 / 伤害 / 必杀
func play(att: Unit, def: Unit, wi: int, events: Array, terrain_char: String, fc := {}) -> void:
	if active:
		return
	active = true
	_skip = false
	_att_real = att
	_def_real = def
	_fc = fc
	_cam.scale = Vector2.ONE
	_cam.position = Vector2.ZERO
	_rebuild_bg(GROUND_COLORS.get(terrain_char, GROUND_COLORS["."]), terrain_char)
	_build_ambient(str(TERRAIN_BG.get(terrain_char, DEFAULT_BG_SET)))
	_setup_units(wi)
	_build_panels(wi)
	_update_bars(0.0)
	visible = true
	_root.modulate.a = 1.0
	Audio.play_music("combat")
	# 开场：白闪 + 双方跑进场，镜头从右往中间收
	_flash_rect.color.a = 0.6
	create_tween().tween_property(_flash_rect, "color:a", 0.0, 0.22)
	_set_cam(70.0)
	await _slide_in()
	for ev in events:
		if _skip:
			_apply_damage(ev)
		else:
			await _strike(ev)
		_update_bars()
	# 阵亡：倒地动作已在命中时开始播，这里等它播完再淡出
	if not _skip:
		var dead: CombatFighter = null
		if not _att_real.is_alive():
			dead = _att_node
		elif not _def_real.is_alive():
			dead = _def_node
		if dead != null:
			if dead.current_anim() != "death":
				dead.play_once("death")
			await get_tree().create_timer(0.75).timeout
			var dt := create_tween()
			dt.tween_property(dead, "modulate:a", 0.0, 0.3)
			await dt.finished
		else:
			await get_tree().create_timer(0.35).timeout
	var out := create_tween()
	out.tween_property(_root, "modulate:a", 0.0, 0.22)
	await out.finished
	visible = false
	active = false
	Audio.play_music("map")
	finished.emit()


func skip() -> void:
	if active:
		_skip = true


func _input(event: InputEvent) -> void:
	if not active:
		return
	if PointerInput.is_primary_press(event) or event.is_action_pressed("ui_accept"):
		skip()


# ==================== 背景 ====================

func _rebuild_bg(ground_color: Color, terrain_char: String) -> void:
	for c in _stage.get_children():
		c.queue_free()
	_layers = []
	if _build_layered_bg(_layered_bg_paths(terrain_char)):
		return
	# 天空三段渐变
	var sky_colors := [Color(0.42, 0.60, 0.84), Color(0.60, 0.76, 0.91), Color(0.76, 0.87, 0.95)]
	for i in 3:
		var band := ColorRect.new()
		band.color = sky_colors[i]
		band.position = Vector2(0, i * 140)
		band.size = Vector2(1280, 140)
		_stage.add_child(band)
	# 远山剪影
	var m1 := Polygon2D.new()
	m1.polygon = PackedVector2Array([
		Vector2(-50, 430), Vector2(200, 250), Vector2(420, 430),
		Vector2(600, 300), Vector2(800, 430), Vector2(1000, 280), Vector2(1330, 430)])
	m1.color = Color(0.52, 0.60, 0.70)
	_stage.add_child(m1)
	var m2 := Polygon2D.new()
	m2.polygon = PackedVector2Array([
		Vector2(-50, 440), Vector2(150, 320), Vector2(350, 440),
		Vector2(650, 340), Vector2(950, 440), Vector2(1150, 330), Vector2(1330, 440)])
	m2.color = Color(0.44, 0.52, 0.63)
	_stage.add_child(m2)
	# 地面
	var ground := ColorRect.new()
	ground.color = ground_color
	ground.position = Vector2(0, 430)
	ground.size = Vector2(1280, 290)
	_stage.add_child(ground)
	var horizon := ColorRect.new()
	horizon.color = ground_color.darkened(0.25)
	horizon.position = Vector2(0, 430)
	horizon.size = Vector2(1280, 5)
	_stage.add_child(horizon)
	_pin_stage_background()


func _pin_stage_background() -> void:
	for c in _stage.get_children():
		if c is CanvasItem and not c.is_queued_for_deletion():
			var item := c as CanvasItem
			item.z_index = Z_BG
			item.z_as_relative = true


func _add_fx(node: CanvasItem) -> void:
	node.z_index = Z_FX
	node.z_as_relative = true
	_stage.add_child(node)


## 当前地形对应的分层路径。未登记字符默认 grass。任一层资源缺失时返回空数组（那时才回退色块）。
func _layered_bg_paths(terrain_char: String) -> Array:
	var set_name := str(TERRAIN_BG.get(terrain_char, DEFAULT_BG_SET))
	if not BG_SETS.has(set_name):
		set_name = DEFAULT_BG_SET
	if not BG_SETS.has(set_name):
		return []
	return _usable_layered_paths(BG_SETS[set_name])


func _usable_layered_paths(paths: Array) -> Array:
	var out: Array = []
	for path in paths:
		var p := str(path)
		if p.is_empty() or not ResourceLoader.exists(p):
			return []
		out.append(p)
	return out


## 铺四层 Sprite2D（以脚底线为基准放大 BG_ZOOM，留出视差余量）。缺层时不改舞台，返回 false。
func _build_layered_bg(paths: Array) -> bool:
	var usable := _usable_layered_paths(paths)
	if usable.is_empty():
		return false
	var textures: Array = []
	for path in usable:
		var tex = load(path)
		if tex == null:
			return false
		textures.append(tex)
	for tex in textures:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = false
		spr.scale = Vector2(BG_ZOOM, BG_ZOOM)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_stage.add_child(spr)
		_layers.append(spr)
	_pin_stage_background()
	_set_cam(_cam_x)
	return true


## 镜头横移：近景移得多、远景移得少
func _set_cam(x: float) -> void:
	_cam_x = x
	for i in _layers.size():
		var spr: Sprite2D = _layers[i]
		if not is_instance_valid(spr):
			continue
		var f: float = PARALLAX[mini(i, PARALLAX.size() - 1)]
		spr.position = Vector2(640.0 * (1.0 - BG_ZOOM) - x * f, FEET_Y * (1.0 - BG_ZOOM))


func _pan_cam(x: float, time: float) -> void:
	create_tween().tween_method(_set_cam, _cam_x, x, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## 镜头推近 / 复原（以 focus 为中心缩放 _cam）
func _zoom(s: float, focus: Vector2, time: float) -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(_cam, "scale", Vector2(s, s), time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_cam, "position", focus * (1.0 - s), time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## 环境粒子：草地飘花粉、森林落叶、焦土火星上飘
func _build_ambient(set_name: String) -> void:
	for c in _ambient.get_children():
		c.queue_free()
	var p := CPUParticles2D.new()
	p.amount = 26
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	match set_name:
		"scorch":
			p.position = Vector2(640, 600)
			p.emission_rect_extents = Vector2(700, 30)
			p.direction = Vector2(0.2, -1)
			p.spread = 25.0
			p.initial_velocity_min = 40.0
			p.initial_velocity_max = 90.0
			p.gravity = Vector2(10, -6)
			p.color = Color(1.0, 0.55, 0.18, 0.9)
			p.amount = 40
		"forest":
			p.position = Vector2(640, -20)
			p.emission_rect_extents = Vector2(700, 10)
			p.direction = Vector2(-0.4, 1)
			p.spread = 30.0
			p.initial_velocity_min = 25.0
			p.initial_velocity_max = 55.0
			p.gravity = Vector2(-4, 12)
			p.angular_velocity_min = -90.0
			p.angular_velocity_max = 90.0
			p.color = Color(0.45, 0.62, 0.25, 0.85)
			p.scale_amount_min = 3.0
			p.scale_amount_max = 5.0
		_:
			p.position = Vector2(640, 380)
			p.emission_rect_extents = Vector2(700, 160)
			p.direction = Vector2(-1, -0.2)
			p.spread = 40.0
			p.initial_velocity_min = 12.0
			p.initial_velocity_max = 30.0
			p.gravity = Vector2(0, -2)
			p.color = Color(1.0, 0.97, 0.8, 0.7)
			p.amount = 20
	_ambient.add_child(p)


# ==================== 角色 ====================

## 单位 → 条带套名
static func fighter_key_for(u: Unit) -> String:
	if FIGHTER_BY_ID.has(u.unit_id):
		return FIGHTER_BY_ID[u.unit_id]
	for rule in FIGHTER_BY_PREFIX:
		if u.unit_id.begins_with(rule[0]):
			return rule[1]
	return str(FIGHTER_BY_WEAPON.get(u.weapon_kind(), "scout"))


func _setup_units(wi: int) -> void:
	var dist: int = GameData.dist(_att_real.grid_pos, _def_real.grid_pos)
	var dwi := maxi(0, _def_real.counter_weapon(dist))
	_att_node = _make_fighter(_att_real, wi, false)
	_def_node = _make_fighter(_def_real, dwi, true)
	_att_node.position = Vector2(-220, FEET_Y)
	_def_node.position = Vector2(1500, FEET_Y)
	_stage.add_child(_att_node)
	_stage.add_child(_def_node)


func _make_fighter(u: Unit, wi: int, face_left: bool) -> CombatFighter:
	var f := CombatFighter.new()
	f.name = "Fighter_" + u.unit_id
	f.z_index = Z_FIGHTER
	f.z_as_relative = true
	var kind := "sword"
	if wi >= 0 and wi < u.weapons.size():
		kind = str(u.weapon(wi)["type"])
	if not f.setup(fighter_key_for(u), kind, face_left, TINT_BY_ID.get(u.unit_id, Color.WHITE)):
		# 缺图兜底：程序 Q 版（站在 CombatFighter 里，镜像由父节点负责）
		var c := Unit.new()
		c.faction = u.faction
		c.is_boss = u.is_boss
		c.armor_color = u.armor_color
		c.hair_style = u.hair_style
		c.hair_color = u.hair_color
		c.skin_color = u.skin_color
		c.scar = u.scar
		c.weapons = u.weapons.duplicate()
		c.draw_ring = false
		c.draw_hp_bar = false
		c.facing = Vector2i.RIGHT
		c.scale = Vector2(UNIT_SCALE, UNIT_SCALE)
		c.position = Vector2(0, -20 * UNIT_SCALE)
		f.add_child(c)
		f.weapon_kind = kind
		f.scale = Vector2(-1.0 if face_left else 1.0, 1.0)
	return f


# ==================== 底部面板 ====================

func _build_panels(wi: int) -> void:
	for c in _ui.get_children():
		c.queue_free()
	_panels = {}
	var dist: int = GameData.dist(_att_real.grid_pos, _def_real.grid_pos)
	var dwi := _def_real.counter_weapon(dist)
	var a_stats := [_fc.get("a_hit", -1), _fc.get("a_dmg", -1), _fc.get("a_crit", -1)]
	var d_stats := [_fc.get("d_hit", -1), _fc.get("d_dmg", -1), _fc.get("d_crit", -1)]
	if not _fc.get("d_can", true) or dwi < 0:
		d_stats = [-1, -1, -1]
	_panels["a"] = _make_panel(0.0, _att_real, tr(_att_real.weapon(wi)["name"]), a_stats, int(_fc.get("a_times", 1)))
	var dwpn := tr(_def_real.weapon(dwi)["name"]) if dwi >= 0 else "--"
	_panels["d"] = _make_panel(640.0, _def_real, dwpn, d_stats, int(_fc.get("d_times", 1)))


func _make_panel(x: float, u: Unit, wpn: String, stats: Array, times: int) -> Dictionary:
	var base := Color(0.14, 0.25, 0.52) if u.is_player() else Color(0.50, 0.15, 0.15)
	var bg := ColorRect.new()
	bg.color = Color(base.r, base.g, base.b, 0.94)
	bg.position = Vector2(x, PANEL_Y)
	bg.size = Vector2(640, 720 - PANEL_Y)
	_ui.add_child(bg)
	var edge := ColorRect.new()
	edge.color = base.lightened(0.45)
	edge.position = Vector2(x, PANEL_Y)
	edge.size = Vector2(640, 3)
	_ui.add_child(edge)
	var sep := ColorRect.new()
	sep.color = Color(0, 0, 0, 0.35)
	sep.position = Vector2(x + 380, PANEL_Y + 16)
	sep.size = Vector2(2, 720 - PANEL_Y - 32)
	_ui.add_child(sep)
	var name_l := _label(Vector2(x + 40, PANEL_Y + 12), 30)
	name_l.text = tr(u.display_name)
	var wpn_l := _label(Vector2(x + 40, PANEL_Y + 54), 20)
	wpn_l.text = wpn
	wpn_l.add_theme_color_override("font_color", Color(0.92, 0.9, 0.8))
	var hp_l := _label(Vector2(x + 40, PANEL_Y + 96), 26)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0, 0, 0, 0.55)
	bar_bg.position = Vector2(x + 110, PANEL_Y + 106)
	bar_bg.size = Vector2(HP_BAR_W, 16)
	_ui.add_child(bar_bg)
	var fill := ColorRect.new()
	fill.position = bar_bg.position + Vector2(2, 2)
	fill.size = Vector2(HP_BAR_W - 4, 12)
	_ui.add_child(fill)
	# 每格 HP 一道刻度（GBA 式）
	var mhp := maxi(1, u.max_hp)
	if mhp <= 60:
		for i in range(1, mhp):
			var tick := ColorRect.new()
			tick.color = Color(0, 0, 0, 0.28)
			tick.position = fill.position + Vector2((HP_BAR_W - 4) * i / float(mhp), 0)
			tick.size = Vector2(1, 12)
			_ui.add_child(tick)
	var keys := ["HIT", "DMG", "CRT"]
	for i in 3:
		var k := _label(Vector2(x + 410, PANEL_Y + 14 + i * 40), 22)
		k.text = keys[i]
		k.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
		var v := _label(Vector2(x + 490, PANEL_Y + 12 + i * 40), 26)
		var n: int = int(stats[i])
		v.text = "--" if n < 0 else str(n)
		if i == 1 and n >= 0 and times > 1:
			v.text += " ×%d" % times
	return {"fill": fill, "hp": hp_l, "unit": u}


func _label(pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	_ui.add_child(l)
	return l


## HP 条：命中当帧就开始消减（不再等整套动作播完）
func _update_bars(time := 0.3) -> void:
	for side in _panels:
		var p: Dictionary = _panels[side]
		var u: Unit = p["unit"]
		var r: float = clampf(float(u.hp) / float(maxi(1, u.max_hp)), 0.0, 1.0)
		var fill: ColorRect = p["fill"]
		fill.color = _hp_color(r)
		(p["hp"] as Label).text = str(u.hp)
		if time <= 0.0:
			fill.size.x = (HP_BAR_W - 4) * r
		else:
			create_tween().tween_property(fill, "size:x", (HP_BAR_W - 4) * r, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.3, 0.9, 0.3)
	if ratio > 0.25:
		return Color(0.95, 0.8, 0.2)
	return Color(0.9, 0.25, 0.2)


# ==================== 演出 ====================

func _slide_in() -> void:
	if _skip:
		_att_node.position.x = ATT_X
		_def_node.position.x = DEF_X
		_set_cam(0.0)
		return
	_att_node.play_loop("run")
	_def_node.play_loop("run")
	var t := create_tween().set_parallel(true)
	t.tween_property(_att_node, "position:x", ATT_X, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_def_node, "position:x", DEF_X, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_method(_set_cam, _cam_x, 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t.finished
	_att_node.play_loop("idle")
	_def_node.play_loop("idle")
	await get_tree().create_timer(0.12).timeout


## 单次攻击：必杀先蓄力，弓手原地放箭，其余跑到对面挥砍
func _strike(ev: Dictionary) -> void:
	var striker: CombatFighter = _att_node if ev["side"] == "a" else _def_node
	var victim: CombatFighter = _def_node if ev["side"] == "a" else _att_node
	var dir: float = 1.0 if ev["side"] == "a" else -1.0
	var crit: bool = ev.get("crit", false)
	if crit:
		await _crit_charge(striker)
	if _skip:
		_apply_damage(ev)
		return
	if striker.weapon_kind == "bow":
		await _strike_bow(striker, victim, ev, dir, crit)
	else:
		await _strike_melee(striker, victim, ev, dir, crit)


func _crit_charge(striker: CombatFighter) -> void:
	striker.set_glow(Color(1.0, 0.82, 0.3, 1.0))
	_big_text(tr("必 杀 !"), Color(1.0, 0.85, 0.25))
	_zoom(1.1, Vector2(striker.position.x, FEET_Y - 90), 0.25)
	await get_tree().create_timer(0.38).timeout
	striker.set_glow(Color(1.0, 0.82, 0.3, 0.0))


## 近战：跑到对手面前 → 出招（出手帧结算）→ 后跳归位
func _strike_melee(striker: CombatFighter, victim: CombatFighter, ev: Dictionary, dir: float, crit: bool) -> void:
	var home := striker.position.x
	var reach := float(CombatFighter.SETS.get(striker.set_key, {}).get("reach", 140))
	var target_x := victim.position.x - dir * reach
	var run_time := clampf(absf(target_x - home) / 1500.0, 0.12, 0.32)
	striker.play_loop("run")
	var t := create_tween()
	t.tween_property(striker, "position:x", target_x, run_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_pan_cam(dir * 30.0, run_time)
	await t.finished
	if _skip:
		_apply_damage(ev)
		striker.position.x = home
		striker.play_loop("idle")
		return
	var anim := striker.attack_anim(crit)
	striker.play_once(anim)
	await striker.impact
	_impact(striker, victim, ev, dir, crit)
	if striker.is_playing(anim):
		await striker.sprite.animation_finished
	# 后跳归位
	striker.play_loop("idle")
	var back := create_tween().set_parallel(true)
	back.tween_property(striker, "position:x", home, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	back.tween_property(striker, "position:y", FEET_Y - 22.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	back.chain().tween_property(striker, "position:y", FEET_Y, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_pan_cam(0.0, 0.3)
	if crit:
		_zoom(1.0, Vector2(640, FEET_Y - 90), 0.3)
	await back.finished


## 弓手：原地拉弓，放箭帧射出箭矢，箭到才结算
func _strike_bow(striker: CombatFighter, victim: CombatFighter, ev: Dictionary, dir: float, crit: bool) -> void:
	Audio.play_sfx("bow", randf_range(0.95, 1.05))
	var anim := striker.attack_anim(crit)
	striker.play_once(anim)
	await striker.impact
	if _skip:
		_apply_damage(ev)
		return
	var arrow := Sprite2D.new()
	arrow.texture = load(CombatFighter.ROOT + "arrow.png")
	arrow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arrow.scale = Vector2(3.0 * dir, 3.0)
	var from := striker.position + Vector2(dir * 50, -84)
	var to := victim.position + Vector2(-dir * 30, -84)
	arrow.position = from
	_add_fx(arrow)
	var fly := create_tween()
	fly.tween_property(arrow, "position", to, 0.17)
	await fly.finished
	arrow.queue_free()
	_impact(striker, victim, ev, dir, crit)
	if striker.is_playing(anim):
		await striker.sprite.animation_finished
	striker.play_loop("idle")
	if crit:
		_zoom(1.0, Vector2(640, FEET_Y - 90), 0.3)
	await get_tree().create_timer(0.25).timeout


## 命中 / 未命中结算 + 打击感（顿帧、闪白、震屏、击退、火花、伤害数字）
func _impact(striker: CombatFighter, victim: CombatFighter, ev: Dictionary, dir: float, crit: bool) -> void:
	if _skip:
		_apply_damage(ev)
		return
	var vx := victim.position.x
	if not ev["landed"]:
		Audio.play_sfx("miss")
		_damage_label(victim, "MISS", Color(0.85, 0.85, 0.9), 1.0)
		var dg := create_tween()
		dg.tween_property(victim, "position:x", vx + dir * 46.0, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		dg.tween_property(victim, "position:x", vx, 0.16)
		return
	_apply_damage(ev)
	_update_bars(0.25)
	Audio.play_sfx("crit" if crit else striker.weapon_kind, randf_range(0.95, 1.05))
	var real_victim: Unit = _def_real if ev["side"] == "a" else _att_real
	var dying := not real_victim.is_alive()
	victim.flash(1.0, 0.25)
	if dying:
		victim.play_once("death")
	else:
		_hit_react(victim)
	_shake(crit)
	var hit_pos := victim.position + Vector2(-dir * 10, -80)
	if striker.weapon_kind != "bow":
		_slash_fx(hit_pos, dir, crit)
	_spark_effect(hit_pos, Color(1.0, 0.85, 0.5), 18 if crit else 10)
	if crit:
		_flash_rect.color.a = 0.55
		create_tween().tween_property(_flash_rect, "color:a", 0.0, 0.25)
	_damage_label(victim, str(ev["dmg"]), Color(1.0, 0.35, 0.2) if crit else Color(1.0, 0.92, 0.85), 1.5 if crit else 1.0)
	# 顿帧：双方动画停一下，打击更有分量
	for f in [striker, victim]:
		if f.sprite != null:
			f.sprite.speed_scale = 0.0
	await get_tree().create_timer(0.12 if crit else 0.06).timeout
	for f in [striker, victim]:
		if is_instance_valid(f) and f.sprite != null:
			f.sprite.speed_scale = 1.0
	if dying:
		return
	var kb := create_tween()
	kb.tween_property(victim, "position:x", vx + dir * (36.0 if crit else 22.0), 0.08)
	kb.tween_property(victim, "position:x", vx, 0.14)


func _hit_react(victim: CombatFighter) -> void:
	await victim.play_once("hit")
	if is_instance_valid(victim) and victim.current_anim() == "hit":
		victim.play_loop("idle")


func _apply_damage(ev: Dictionary) -> void:
	if not ev["landed"]:
		return
	var real_victim: Unit = _def_real if ev["side"] == "a" else _att_real
	real_victim.take_damage(ev["dmg"])


func _shake(strong := false) -> void:
	var t := create_tween()
	var amp := 12.0 if strong else 6.0
	for i in 6 if strong else 4:
		t.tween_property(_stage, "position", Vector2(randi_range(-amp, amp), randi_range(-amp * 0.6, amp * 0.6)), 0.03)
	t.tween_property(_stage, "position", Vector2.ZERO, 0.05)


## 刀光：Ninja Adventure 的弧形斩击帧（CC0），朝攻击方向，必杀放大
func _slash_fx(pos: Vector2, dir: float, crit: bool) -> void:
	if not ResourceLoader.exists(SLASH_FX):
		return
	var sf := SpriteFrames.new()
	sf.add_animation("s")
	sf.set_animation_loop("s", false)
	sf.set_animation_speed("s", 20.0)
	var tex: Texture2D = load(SLASH_FX)
	for i in 4:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * 32, 0, 32, 32)
		sf.add_frame("s", at)
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = sf
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var k := 6.0 if crit else 4.5
	fx.scale = Vector2(k * dir, k)
	fx.position = pos
	if crit:
		fx.modulate = Color(1.0, 0.9, 0.55)
	_add_fx(fx)
	fx.play("s")
	fx.animation_finished.connect(fx.queue_free)


## 火花粒子
func _spark_effect(pos: Vector2, color: Color, n: int) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = n
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 320.0
	p.gravity = Vector2(0, 600)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color.r, color.g * 0.6, color.b * 0.3, 0.0))
	p.color_ramp = ramp
	p.position = pos
	_add_fx(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## 中央大字（必杀等）
func _big_text(text: String, color: Color) -> void:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.text = text
	l.add_theme_font_size_override("font_size", 72)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 3)
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.position = Vector2(0, 110)
	l.size = Vector2(1280, 100)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.scale = Vector2(0.5, 0.5)
	l.pivot_offset = Vector2(640, 50)
	_ui.add_child(l)
	var t := create_tween()
	t.tween_property(l, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.35)
	t.tween_property(l, "modulate:a", 0.0, 0.2)
	t.finished.connect(l.queue_free)


func _damage_label(victim: CombatFighter, text: String, color: Color, scale := 1.0) -> void:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.text = text
	l.add_theme_font_size_override("font_size", 44)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.05))
	l.add_theme_constant_override("outline_size", 8)
	l.position = victim.position + Vector2(-40, -240)
	l.scale = Vector2(scale, scale)
	l.pivot_offset = Vector2(40, 20)
	_ui.add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 50, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.25)
	t.finished.connect(l.queue_free)
