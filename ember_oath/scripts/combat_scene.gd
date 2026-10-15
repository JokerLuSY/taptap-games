class_name CombatScene
extends CanvasLayer
## 战斗特写演出：GBA 火纹式横版对砍（放大 Q 版小人 + 震屏 + 伤害数字 + HP 条）
## 点击 / 回车可跳过

signal finished

const GROUND_COLORS := {
	".": Color(0.47, 0.62, 0.34), "R": Color(0.74, 0.65, 0.47),
	"F": Color(0.26, 0.46, 0.25), "H": Color(0.47, 0.62, 0.34),
	"B": Color(0.62, 0.45, 0.28), "M": Color(0.50, 0.47, 0.42),
	"f": Color(0.56, 0.44, 0.29), "W": Color(0.47, 0.62, 0.34),
	"X": Color(0.50, 0.47, 0.42),
}

const ATT_X := 380.0
const DEF_X := 900.0
const FEET_Y := 520.0
const UNIT_SCALE := 3.2
const HP_BAR_W := 300.0

var active := false

var _root: Node2D
var _stage: Node2D                  # 背景 + 单位（震屏对象）
var _ui: Node2D                     # 顶部/底部 UI（不震）
var _flash_rect: ColorRect
var _att_node: Unit = null
var _def_node: Unit = null
var _att_real: Unit = null
var _def_real: Unit = null
var _att_name: Label
var _def_name: Label
var _att_wpn: Label
var _def_wpn: Label
var _att_hp_fill: ColorRect
var _def_hp_fill: ColorRect
var _att_hp_label: Label
var _def_hp_label: Label
var _skip := false


func _ready() -> void:
	visible = false
	layer = 10
	_root = Node2D.new()
	add_child(_root)
	_stage = Node2D.new()
	_root.add_child(_stage)
	_ui = Node2D.new()
	_root.add_child(_ui)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.size = Vector2(1280, 720)
	_root.add_child(_flash_rect)


func play(att: Unit, def: Unit, wi: int, events: Array, terrain_char: String) -> void:
	if active:
		return
	active = true
	_skip = false
	_att_real = att
	_def_real = def
	_rebuild_bg(GROUND_COLORS.get(terrain_char, GROUND_COLORS["."]))
	_setup_units()
	_setup_labels(wi)
	_update_bars()
	visible = true
	_root.modulate.a = 1.0
	Audio.play_music("combat")
	# 开场白闪 + 双方入场
	_flash_rect.color.a = 0.65
	var ft := create_tween()
	ft.tween_property(_flash_rect, "color:a", 0.0, 0.22)
	await get_tree().create_timer(0.12).timeout
	await _slide_in()
	# 逐次攻击
	for ev in events:
		if _skip:
			_apply_damage(ev)
		else:
			await _strike(ev)
		_update_bars()
	# 阵亡倒下
	if not _skip:
		var dead_node: Unit = null
		if not _att_real.is_alive():
			dead_node = _att_node
		elif not _def_real.is_alive():
			dead_node = _def_node
		if dead_node != null:
			var dir := 1.0 if dead_node == _att_node else -1.0
			var dt := create_tween().set_parallel(true)
			dt.tween_property(dead_node, "rotation", dir * PI / 2.0, 0.4)
			dt.tween_property(dead_node, "modulate:a", 0.0, 0.4)
			await get_tree().create_timer(0.45).timeout
		else:
			await get_tree().create_timer(0.35).timeout
	# 谢幕
	var out := create_tween()
	out.tween_property(_root, "modulate:a", 0.0, 0.22)
	await get_tree().create_timer(0.24).timeout
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


# ==================== 构建 ====================

func _rebuild_bg(ground_color: Color) -> void:
	for c in _stage.get_children():
		c.queue_free()
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
	# 地面装饰草丛
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var grass_col := ground_color.darkened(0.22)
	for i in 14:
		var gx := rng.randf_range(30, 1250)
		var gy := rng.randf_range(460, 690)
		var tri := PackedVector2Array([
			Vector2(gx, gy), Vector2(gx + 4, gy - 12), Vector2(gx + 8, gy)])
		var g := Polygon2D.new()
		g.polygon = tri
		g.color = grass_col
		_stage.add_child(g)


func _setup_units() -> void:
	_att_node = _make_fighter(_att_real, false)
	_def_node = _make_fighter(_def_real, true)
	_att_node.position = Vector2(-200, FEET_Y)
	_def_node.position = Vector2(1480, FEET_Y)
	_stage.add_child(_att_node)
	_stage.add_child(_def_node)


func _make_fighter(u: Unit, face_left: bool) -> Unit:
	var c := Unit.new()
	c.display_name = u.display_name
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
	c.scale = Vector2(-UNIT_SCALE if face_left else UNIT_SCALE, UNIT_SCALE)
	return c


func _setup_labels(wi: int) -> void:
	for c in _ui.get_children():
		if c is Label and c.get_meta("perm", false) == false:
			c.queue_free()
	# 名字
	if _att_name == null:
		_att_name = _make_ui_label(Vector2(60, 28), 30, HORIZONTAL_ALIGNMENT_LEFT)
		_def_name = _make_ui_label(Vector2(1220, 28), 30, HORIZONTAL_ALIGNMENT_RIGHT)
		_att_wpn = _make_ui_label(Vector2(60, 66), 20, HORIZONTAL_ALIGNMENT_LEFT)
		_def_wpn = _make_ui_label(Vector2(1220, 66), 20, HORIZONTAL_ALIGNMENT_RIGHT)
		_att_name.set_meta("perm", true)
		_def_name.set_meta("perm", true)
		_att_wpn.set_meta("perm", true)
		_def_wpn.set_meta("perm", true)
		_build_hp_bars()
	_att_name.text = tr(_att_real.display_name)
	_def_name.text = tr(_def_real.display_name)
	var dist: int = GameData.dist(_att_real.grid_pos, _def_real.grid_pos)
	_att_wpn.text = tr(_att_real.weapon(wi)["name"])
	_def_wpn.text = tr(_def_real.weapon(maxi(0, _def_real.counter_weapon(dist)))["name"])


func _make_ui_label(pos: Vector2, size: int, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	if align != HORIZONTAL_ALIGNMENT_LEFT:
		l.position -= Vector2(240, 0)
		l.size = Vector2(240, size + 10)
		l.horizontal_alignment = align
	_ui.add_child(l)
	return l


func _build_hp_bars() -> void:
	_att_hp_fill = _make_hp_bar(Vector2(60, 630), true)
	_def_hp_fill = _make_hp_bar(Vector2(1280 - 60 - HP_BAR_W, 630), false)


func _make_hp_bar(pos: Vector2, left_side: bool) -> ColorRect:
	var name_l := _make_ui_label(pos + Vector2(0, -34), 20, HORIZONTAL_ALIGNMENT_LEFT if left_side else HORIZONTAL_ALIGNMENT_RIGHT)
	name_l.set_meta("perm", true)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.position = pos
	bg.size = Vector2(HP_BAR_W, 16)
	_ui.add_child(bg)
	var fill := ColorRect.new()
	fill.color = Color(0.3, 0.9, 0.3)
	fill.position = pos + Vector2(2, 2)
	fill.size = Vector2(HP_BAR_W - 4, 12)
	_ui.add_child(fill)
	var num := _make_ui_label(pos + Vector2(HP_BAR_W + 12, -6), 22, HORIZONTAL_ALIGNMENT_LEFT)
	num.set_meta("perm", true)
	if left_side:
		_att_hp_label = num
	else:
		_def_hp_label = num
	return fill


# ==================== 演出 ====================

func _slide_in() -> void:
	if _skip:
		_att_node.position.x = ATT_X
		_def_node.position.x = DEF_X
		return
	var t := create_tween().set_parallel(true)
	t.tween_property(_att_node, "position:x", ATT_X, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_def_node, "position:x", DEF_X, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.42).timeout


## 单次攻击演出：按武器流派 + 是否暴击分支
func _strike(ev: Dictionary) -> void:
	var striker: Unit = _att_node if ev["side"] == "a" else _def_node
	var victim: Unit = _def_node if ev["side"] == "a" else _att_node
	var dir: float = 1.0 if ev["side"] == "a" else -1.0
	if ev.get("crit", false):
		await _strike_crit(striker, victim, ev, dir)
		return
	match striker.weapon_kind():
		"bow":
			await _strike_bow(striker, victim, ev, dir)
		"axe":
			await _strike_melee(striker, victim, ev, dir, "axe")
		"lance":
			await _strike_melee(striker, victim, ev, dir, "lance")
		_:
			await _strike_melee(striker, victim, ev, dir, "sword")


## 近战通用：剑=快斩 / 枪=蓄力突刺 / 斧=跳劈
func _strike_melee(striker: Unit, victim: Unit, ev: Dictionary, dir: float, style: String) -> void:
	var start_x: float = striker.position.x
	var start_y: float = striker.position.y
	var victim_x: float = victim.position.x
	var approach_time := 0.13
	# 流派起手式
	match style:
		"sword":
			pass  # 直接快斩
		"lance":
			# 先后撤蓄力再长突
			var back := create_tween()
			back.tween_property(striker, "position:x", start_x - dir * 26.0, 0.10)
			await get_tree().create_timer(0.12).timeout
			approach_time = 0.15
		"axe":
			# 跃起
			var hop := create_tween()
			hop.tween_property(striker, "position:y", start_y - 40.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			await get_tree().create_timer(0.14).timeout
	var t := create_tween()
	t.tween_property(striker, "position:x", victim_x - dir * 110.0, approach_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if style == "axe":
		t.parallel().tween_property(striker, "position:y", start_y, approach_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(approach_time + 0.02).timeout
	_impact(striker, victim, ev, dir, style, false)
	await get_tree().create_timer(0.24).timeout
	# 归位
	var back2 := create_tween()
	back2.tween_property(striker, "position:x", start_x, 0.16)
	await get_tree().create_timer(0.18).timeout


## 弓手：原地拉弓, 箭矢飞行
func _strike_bow(striker: Unit, victim: Unit, ev: Dictionary, dir: float) -> void:
	# 拉弓蓄力（微微后仰）
	var draw := create_tween()
	draw.tween_property(striker, "position:x", striker.position.x - dir * 10.0, 0.14)
	Audio.play_sfx("bow", randf_range(0.95, 1.05))
	await get_tree().create_timer(0.16).timeout
	if _skip:
		_apply_damage(ev)
		return
	# 箭矢
	var arrow := ColorRect.new()
	arrow.color = Color(0.95, 0.88, 0.70)
	arrow.size = Vector2(22, 3)
	var from := striker.position + Vector2(dir * 30, -60)
	var to := victim.position + Vector2(-dir * 20, -55)
	arrow.position = from
	arrow.rotation = (to - from).angle()
	arrow.pivot_offset = Vector2(11, 1.5)
	_stage.add_child(arrow)
	var fly := create_tween()
	fly.tween_property(arrow, "position", to, 0.16).set_trans(Tween.TRANS_LINEAR)
	await get_tree().create_timer(0.16).timeout
	arrow.queue_free()
	_impact(striker, victim, ev, dir, "bow", false)
	await get_tree().create_timer(0.22).timeout
	# 归位
	var back := create_tween()
	back.tween_property(striker, "position:x", striker.position.x + dir * 10.0, 0.12)


## 暴击：金色蓄力慢动作 + 重击
func _strike_crit(striker: Unit, victim: Unit, ev: Dictionary, dir: float) -> void:
	var start_x: float = striker.position.x
	var victim_x: float = victim.position.x
	# 蓄力：全身金光 + 大字
	striker.modulate = Color(1.6, 1.3, 0.5)
	_big_text(tr("必 杀 !"), Color(1.0, 0.85, 0.25))
	await get_tree().create_timer(0.34).timeout
	striker.modulate = Color.WHITE
	# 慢速突进（压迫感）
	var t := create_tween()
	t.tween_property(striker, "position:x", victim_x - dir * 110.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.32).timeout
	_impact(striker, victim, ev, dir, "crit", true)
	await get_tree().create_timer(0.36).timeout
	var back2 := create_tween()
	back2.tween_property(striker, "position:x", start_x, 0.18)
	await get_tree().create_timer(0.20).timeout


## 命中/未命中结算 + 打击特效
func _impact(striker: Unit, victim: Unit, ev: Dictionary, dir: float, style: String, is_crit: bool) -> void:
	var victim_x: float = victim.position.x
	if _skip:
		_apply_damage(ev)
		return
	if not ev["landed"]:
		Audio.play_sfx("miss")
		_damage_label(victim, "MISS", Color(0.85, 0.85, 0.9), 1.0)
		var dg := create_tween()
		dg.tween_property(victim, "position:x", victim_x + dir * 30.0, 0.08)
		dg.tween_property(victim, "position:x", victim_x, 0.12)
		return
	_apply_damage(ev)
	if is_crit:
		Audio.play_sfx("crit")
	else:
		Audio.play_sfx(striker.weapon_kind(), randf_range(0.95, 1.05))
	_flash_unit(victim)
	_shake(is_crit)
	# 打击特效：斩击弧线（颜色随使用者）
	match style:
		"sword", "crit":
			_slash_effect(victim.position + Vector2(0, -50), striker.hair_color.lightened(0.55), is_crit)
		"lance":
			_thrust_effect(victim.position + Vector2(0, -50), dir)
		"axe":
			_slash_effect(victim.position + Vector2(0, -50), Color(0.95, 0.9, 0.8), is_crit)
		"bow":
			_spark_effect(victim.position + Vector2(0, -50), Color(0.95, 0.85, 0.5), 6)
	_spark_effect(victim.position + Vector2(0, -50), Color(1.0, 0.75, 0.35), 16 if is_crit else 8)
	_damage_label(victim, "-%d" % ev["dmg"], Color(1.0, 0.35, 0.20) if is_crit else Color(1.0, 0.5, 0.4), 1.6 if is_crit else 1.0)
	# 打击停顿 + 击退
	await get_tree().create_timer(0.05 if not is_crit else 0.10).timeout
	var kb := create_tween()
	var kb_dist := 34.0 if is_crit else 22.0
	kb.tween_property(victim, "position:x", victim_x + dir * kb_dist, 0.08)
	kb.tween_property(victim, "position:x", victim_x, 0.12)


func _apply_damage(ev: Dictionary) -> void:
	if not ev["landed"]:
		return
	var real_victim: Unit = _def_real if ev["side"] == "a" else _att_real
	real_victim.take_damage(ev["dmg"])


func _flash_unit(victim: Unit) -> void:
	victim.modulate = Color(3.0, 3.0, 3.0)
	var t := create_tween()
	t.tween_property(victim, "modulate", Color.WHITE, 0.25)


func _shake(strong := false) -> void:
	var t := create_tween()
	var amp := 11.0 if strong else 6.0
	for i in 6 if strong else 4:
		t.tween_property(_stage, "position", Vector2(randi_range(-amp, amp), randi_range(-amp * 0.7, amp * 0.7)), 0.03)
	t.tween_property(_stage, "position", Vector2.ZERO, 0.05)


## 斩击弯月弧
func _slash_effect(pos: Vector2, color: Color, big := false) -> void:
	var s := 1.5 if big else 1.0
	var slash := Polygon2D.new()
	slash.polygon = PackedVector2Array([
		Vector2(-34, -16) * s, Vector2(-4, -4) * s, Vector2(34, -22) * s, Vector2(10, 2) * s,
		Vector2(30, 16) * s, Vector2(-2, 10) * s, Vector2(-30, 20) * s, Vector2(-10, 0) * s])
	slash.color = Color(color.r, color.g, color.b, 0.95)
	slash.position = pos
	_stage.add_child(slash)
	var t := create_tween().set_parallel(true)
	t.tween_property(slash, "scale", Vector2(1.25, 1.25), 0.18)
	t.tween_property(slash, "modulate:a", 0.0, 0.18)
	t.finished.connect(slash.queue_free)


## 突刺直线
func _thrust_effect(pos: Vector2, dir: float) -> void:
	var line := ColorRect.new()
	line.color = Color(0.95, 0.95, 1.0, 0.95)
	line.size = Vector2(56, 4)
	line.position = pos + Vector2(-28 if dir > 0 else -28 + 56, -2)
	line.scale.x = dir
	_stage.add_child(line)
	var t := create_tween().set_parallel(true)
	t.tween_property(line, "scale:x", dir * 1.4, 0.14)
	t.tween_property(line, "modulate:a", 0.0, 0.14)
	t.finished.connect(line.queue_free)


## 火花粒子
func _spark_effect(pos: Vector2, color: Color, n: int) -> void:
	for i in n:
		var p := ColorRect.new()
		var sz := randf_range(2.5, 5.0)
		p.color = color
		p.size = Vector2(sz, sz)
		p.position = pos
		_stage.add_child(p)
		var ang := randf_range(0, TAU)
		var dist := randf_range(24, 60)
		var t := create_tween().set_parallel(true)
		t.tween_property(p, "position", pos + Vector2(cos(ang), sin(ang)) * dist, randf_range(0.18, 0.3))
		t.tween_property(p, "modulate:a", 0.0, 0.3)
		t.finished.connect(p.queue_free)


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
	l.position = Vector2(0, 130)
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


func _damage_label(victim: Unit, text: String, color: Color, scale := 1.0) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 42)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.position = victim.position + Vector2(-40, -190)
	l.scale = Vector2(scale, scale)
	l.pivot_offset = Vector2(40, 20)
	_ui.add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 50, 0.7)
	t.tween_property(l, "modulate:a", 0.0, 0.7)
	t.finished.connect(l.queue_free)


func _update_bars() -> void:
	var ra: float = clampf(float(_att_real.hp) / float(maxi(1, _att_real.max_hp)), 0.0, 1.0)
	var rd: float = clampf(float(_def_real.hp) / float(maxi(1, _def_real.max_hp)), 0.0, 1.0)
	_att_hp_fill.color = _hp_color(ra)
	_def_hp_fill.color = _hp_color(rd)
	_att_hp_label.text = "%d/%d" % [_att_real.hp, _att_real.max_hp]
	_def_hp_label.text = "%d/%d" % [_def_real.hp, _def_real.max_hp]
	# 平滑消减
	var t := create_tween().set_parallel(true)
	t.tween_property(_att_hp_fill, "size:x", (HP_BAR_W - 4) * ra, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_def_hp_fill, "size:x", (HP_BAR_W - 4) * rd, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.3, 0.9, 0.3)
	if ratio > 0.25:
		return Color(0.95, 0.8, 0.2)
	return Color(0.9, 0.25, 0.2)
