class_name Unit
extends Node2D
## 棋盘单位：GBA 火纹风地图小人（3/4 俯视、描边、阴阳面、待机浮动）

const TILE := 64

var unit_id := ""
var display_name := ""
var class_label := ""
var faction := "enemy"          # player / enemy
var level := 1
var xp := 0
var max_hp := 20
var hp := 20
var pwr := 5
var skl := 5
var spd := 5
var dfn := 3
var mov := 5
var weapons: Array = []         # weapon id 列表
var items: Array = []           # item id 列表
var growths := {"hp": 50, "pwr": 30, "skl": 30, "spd": 30, "dfn": 20}
var stationary := false         # 不移动（守点 BOSS）
var is_boss := false
var grid_pos := Vector2i.ZERO
var has_acted := false
var body_color := Color(0.5, 0.5, 0.6)
var support_with := {}            # 已解锁的支援: {伙伴 unit_id: 等级}

# 外观
var hair_style := "short"       # ponytail / short / spiky / hood
var hair_color := Color(0.30, 0.24, 0.18)
var armor_color := Color(0.5, 0.5, 0.6)
var skin_color := Color(1.0, 0.86, 0.72)
var scar := false

# 待机动画
var _t := 0.0
var _phase := 0.0

# 绘制开关（战斗特写的克隆体会关掉光环和 HP 条；有像素帧时整段程序绘制关掉）
var draw_ring := true
var draw_hp_bar := true
var suppress_draw := false

const OUTLINE := Color(0.13, 0.11, 0.15)


func setup(def: Dictionary) -> void:
	unit_id = def.get("id", "")
	display_name = def.get("name", "?")
	class_label = def.get("class", "")
	faction = def.get("faction", "enemy")
	level = def.get("level", 1)
	max_hp = def.get("hp", 20)
	hp = max_hp
	pwr = def.get("pwr", 5)
	skl = def.get("skl", 5)
	spd = def.get("spd", 5)
	dfn = def.get("dfn", 3)
	mov = def.get("mov", 5)
	weapons = def.get("weapons", []).duplicate()
	items = def.get("items", []).duplicate()
	if def.has("growths"):
		growths = def["growths"]
	stationary = def.get("stationary", false)
	is_boss = def.get("boss", false)
	grid_pos = def.get("pos", Vector2i.ZERO)
	body_color = def.get("color", Color(0.5, 0.5, 0.6))
	armor_color = def.get("armor", body_color)
	hair_style = def.get("hair", "short")
	hair_color = def.get("hair_color", Color(0.30, 0.24, 0.18))
	skin_color = def.get("skin", Color(1.0, 0.86, 0.72))
	scar = def.get("scar", false)
	position = tile_center()
	_phase = float((grid_pos.x * 7 + grid_pos.y * 13) % 10) / 10.0 * TAU


func is_player() -> bool:
	return faction == "player"


func is_alive() -> bool:
	return hp > 0


func weapon(idx := 0) -> Dictionary:
	return GameData.WEAPONS[weapons[idx]]


func weapon_kind() -> String:
	if weapons.is_empty():
		return "sword"
	return GameData.WEAPONS[weapons[0]]["type"]


func weapon_ranges() -> Array:
	var out: Array = []
	for w in weapons:
		for r in GameData.WEAPONS[w]["rng"]:
			if r not in out:
				out.append(r)
	return out


func can_hit(d: int, idx := 0) -> bool:
	return d in GameData.WEAPONS[weapons[idx]]["rng"]


## 防守时自动选用能打到 dist 的武器, 返回索引(-1 = 无法反击)
func counter_weapon(d: int) -> int:
	for i in weapons.size():
		if can_hit(d, i):
			return i
	return -1


func take_damage(n: int) -> void:
	hp = clampi(hp - n, 0, max_hp)
	queue_redraw()


func heal(n: int) -> void:
	hp = clampi(hp + n, 0, max_hp)
	queue_redraw()


## 剧情转职：等级重置为 1，经验清零，保留当前能力并加上 bonus。不消耗道具。
func promote(to_class: String, bonus: Dictionary, new_weapons: Array = []) -> void:
	class_label = to_class
	level = 1
	xp = 0
	var add_hp := int(bonus.get("hp", 0))
	max_hp += add_hp
	hp = mini(hp + add_hp, max_hp)
	pwr += int(bonus.get("pwr", 0))
	skl += int(bonus.get("skl", 0))
	spd += int(bonus.get("spd", 0))
	dfn += int(bonus.get("dfn", 0))
	mov += int(bonus.get("mov", 0))
	if not new_weapons.is_empty():
		weapons = new_weapons.duplicate()
	queue_redraw()


## 返回升级信息（空 dict = 未升级）
func gain_xp(n: int) -> Dictionary:
	xp += n
	if xp < 100:
		return {}
	xp -= 100
	level += 1
	var gains := {}
	for k in growths:
		if randf() * 100.0 < growths[k]:
			gains[k] = 1
			match k:
				"hp":
					max_hp += 1
					hp += 1
				"pwr":
					pwr += 1
				"skl":
					skl += 1
				"spd":
					spd += 1
				"dfn":
					dfn += 1
	queue_redraw()
	return {"level": level, "gains": gains}


func tile_center() -> Vector2:
	return Vector2(grid_pos) * TILE + Vector2(TILE / 2.0, TILE / 2.0)


func to_save() -> Dictionary:
	return {
		"id": unit_id,
		"name": display_name,
		"class": class_label,
		"faction": faction,
		"level": level,
		"xp": xp,
		"max_hp": max_hp,
		"hp": hp,
		"pwr": pwr,
		"skl": skl,
		"spd": spd,
		"dfn": dfn,
		"mov": mov,
		"weapons": weapons.duplicate(),
		"items": items.duplicate(),
		"growths": growths.duplicate(),
		"stationary": stationary,
		"boss": is_boss,
		"pos": [grid_pos.x, grid_pos.y],
		"has_acted": has_acted,
		"support_with": support_with.duplicate(),
		"color": body_color.to_html(false),
		"armor": armor_color.to_html(false),
		"hair": hair_style,
		"hair_color": hair_color.to_html(false),
		"skin": skin_color.to_html(false),
		"scar": scar,
		"alive": is_alive(),
	}


func apply_save(data: Dictionary) -> void:
	var pos_raw = data.get("pos", [0, 0])
	var pos := Vector2i.ZERO
	if typeof(pos_raw) == TYPE_ARRAY and pos_raw.size() >= 2:
		pos = Vector2i(int(pos_raw[0]), int(pos_raw[1]))
	var growths_in = data.get("growths", {})
	var def := {
		"id": str(data.get("id", "")),
		"name": str(data.get("name", "?")),
		"class": str(data.get("class", "")),
		"faction": str(data.get("faction", "enemy")),
		"level": int(data.get("level", 1)),
		"hp": int(data.get("max_hp", 20)),
		"pwr": int(data.get("pwr", 5)),
		"skl": int(data.get("skl", 5)),
		"spd": int(data.get("spd", 5)),
		"dfn": int(data.get("dfn", 3)),
		"mov": int(data.get("mov", 5)),
		"weapons": data.get("weapons", []),
		"items": data.get("items", []),
		"stationary": bool(data.get("stationary", false)),
		"boss": bool(data.get("boss", false)),
		"pos": pos,
		"color": _html_color(str(data.get("color", "")), Color(0.5, 0.5, 0.6)),
		"armor": _html_color(str(data.get("armor", "")), Color(0.5, 0.5, 0.6)),
		"hair": str(data.get("hair", "short")),
		"hair_color": _html_color(str(data.get("hair_color", "")), Color(0.30, 0.24, 0.18)),
		"skin": _html_color(str(data.get("skin", "")), Color(1.0, 0.86, 0.72)),
		"scar": bool(data.get("scar", false)),
	}
	if growths_in is Dictionary and not (growths_in as Dictionary).is_empty():
		def["growths"] = growths_in
	setup(def)
	hp = clampi(int(data.get("hp", max_hp)), 0, max_hp)
	xp = int(data.get("xp", 0))
	has_acted = bool(data.get("has_acted", false))
	var sw = data.get("support_with", {})
	support_with = sw.duplicate() if sw is Dictionary else {}
	if not bool(data.get("alive", hp > 0)):
		hp = 0
		visible = false
		modulate.a = 0.0
	queue_redraw()


func _html_color(hex: String, fallback: Color) -> Color:
	if hex.is_empty():
		return fallback
	return Color.html(hex)


# ==================== 绘制 ====================

func _process(delta: float) -> void:
	if suppress_draw:
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	if suppress_draw:
		return
	var bob := sin(_t * 2.6 + _phase) * 1.3
	# ---- 地面阴影 + 阵营光环（不浮动） ----
	if draw_ring:
		var ring_col: Color = Color(0.3, 0.55, 1.0) if is_player() else Color(1.0, 0.35, 0.3)
		if is_boss:
			ring_col = Color(1.0, 0.75, 0.2)
		draw_set_transform(Vector2(0, 20), 0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 15, Color(0, 0, 0, 0.30))
		draw_arc(Vector2.ZERO, 20, 0, TAU, 28, ring_col, 3.0)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# ---- 人物（整体随 bob 浮动） ----
	draw_set_transform(Vector2(0, bob), 0, Vector2.ONE)
	_draw_boots()
	_draw_torso()
	_draw_head()
	_draw_weapon()
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# ---- HP 条（不浮动） ----
	if draw_hp_bar:
		var w := 44.0
		var ratio := float(hp) / float(maxi(1, max_hp))
		var bar_col: Color = Color(0.3, 0.9, 0.3) if ratio > 0.5 else (Color(0.95, 0.8, 0.2) if ratio > 0.25 else Color(0.9, 0.25, 0.2))
		draw_rect(Rect2(-w / 2, 26, w, 6), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w / 2 + 1, 27, (w - 2) * ratio, 4), bar_col)
	# 已行动变暗
	if has_acted:
		draw_circle(Vector2(0, -2), 27, Color(0.15, 0.15, 0.20, 0.45))


func _draw_boots() -> void:
	var boot := armor_color.darkened(0.5)
	draw_rect(Rect2(-8.5, 11, 7, 7), OUTLINE)
	draw_rect(Rect2(1.5, 11, 7, 7), OUTLINE)
	draw_rect(Rect2(-7.5, 11.8, 5, 5.6), boot)
	draw_rect(Rect2(2.5, 11.8, 5, 5.6), boot)


func _draw_torso() -> void:
	# 描边层（略大的梯形）
	var torso_o := PackedVector2Array([
		Vector2(-11.5, -7.5), Vector2(11.5, -7.5), Vector2(13.5, 12.5), Vector2(-13.5, 12.5)])
	draw_colored_polygon(torso_o, OUTLINE)
	# 本体
	var torso := PackedVector2Array([
		Vector2(-10, -6), Vector2(10, -6), Vector2(12, 11), Vector2(-12, 11)])
	draw_colored_polygon(torso, armor_color)
	# 阴阳面：右暗左亮
	var shade := PackedVector2Array([
		Vector2(3, -6), Vector2(10, -6), Vector2(12, 11), Vector2(3, 11)])
	draw_colored_polygon(shade, armor_color.darkened(0.25))
	var light := PackedVector2Array([
		Vector2(-10, -6), Vector2(0, -6), Vector2(0, 11), Vector2(-12, 11)])
	draw_colored_polygon(light, armor_color.lightened(0.15))
	# 腰带
	draw_line(Vector2(-11.6, 4), Vector2(11.6, 4), OUTLINE, 2.2)
	# 肩部高光
	draw_line(Vector2(-9, -5), Vector2(2, -5), armor_color.lightened(0.35), 1.6)


func _draw_head() -> void:
	# 头（描边圈 + 皮肤）
	draw_circle(Vector2(0, -13), 11.8, OUTLINE)
	draw_circle(Vector2(0, -13), 10.8, skin_color)
	# 发型（3/4 视角：发团盖住头顶, 露出下半张脸）
	match hair_style:
		"ponytail", "short":
			draw_circle(Vector2(0, -16), 11.2, OUTLINE)
			draw_circle(Vector2(0, -16), 10.2, hair_color)
			draw_circle(Vector2(0, -10.5), 8.6, skin_color)
			# 头顶高光
			draw_arc(Vector2(-2.5, -19), 4.5, PI * 0.85, PI * 1.55, 8, hair_color.lightened(0.35), 2.0)
			if hair_style == "ponytail":
				draw_line(Vector2(9, -21), Vector2(18, -6), OUTLINE, 6.5)
				draw_line(Vector2(9, -21), Vector2(18, -6), hair_color, 4.0)
				draw_circle(Vector2(18, -5), 3.8, OUTLINE)
				draw_circle(Vector2(18, -5), 2.5, hair_color)
			else:
				# 胡子
				draw_rect(Rect2(-5, -8.5, 10, 3), OUTLINE)
				draw_rect(Rect2(-4.2, -8, 8.4, 1.8), hair_color)
		"spiky":
			var spikes := PackedVector2Array([
				Vector2(-11, -15), Vector2(-8, -27), Vector2(-4, -18), Vector2(1, -29),
				Vector2(5, -19), Vector2(9, -26), Vector2(11, -15), Vector2(7, -11),
				Vector2(-7, -11)])
			draw_colored_polygon(spikes, hair_color)
			var closed := spikes + PackedVector2Array([spikes[0]])
			draw_polyline(closed, OUTLINE, 2.0)
		"hood":
			var hood := PackedVector2Array([
				Vector2(0, -28), Vector2(12.5, -14), Vector2(11.5, -4), Vector2(6, -8),
				Vector2(-6, -8), Vector2(-11.5, -4), Vector2(-12.5, -14)])
			draw_colored_polygon(hood, armor_color.darkened(0.10))
			var closed := hood + PackedVector2Array([hood[0]])
			draw_polyline(closed, OUTLINE, 2.0)
			# 兜帽内阴影
			draw_arc(Vector2(0, -13), 7, PI * 1.1, PI * 1.9, 8, skin_color.darkened(0.25), 2.4)
	# 眼睛
	draw_circle(Vector2(-3.5, -10), 1.4, OUTLINE)
	draw_circle(Vector2(3.5, -10), 1.4, OUTLINE)
	if scar:
		draw_line(Vector2(-7, -16), Vector2(-2, -8), Color(0.60, 0.20, 0.15), 1.6)
	if is_boss:
		var crown := PackedVector2Array([
			Vector2(-6, -22), Vector2(-3, -28), Vector2(0, -22), Vector2(3, -28), Vector2(6, -22)])
		draw_polyline(crown, OUTLINE, 4.5)
		draw_polyline(crown, Color(1.0, 0.8, 0.2), 2.5)


func _draw_weapon() -> void:
	var steel := Color(0.85, 0.87, 0.92)
	var wood := Color(0.45, 0.32, 0.20)
	var gold := Color(0.85, 0.70, 0.30)
	match weapon_kind():
		"sword":
			var blade := steel
			if not weapons.is_empty() and str(weapons[0]) == "ember_blade":
				blade = Color(1.0, 0.55, 0.22)
			draw_rect(Rect2(12.4, -11, 4.4, 18), OUTLINE)
			draw_rect(Rect2(13.2, -10, 2.8, 16), blade)
			var tip := PackedVector2Array([Vector2(13.2, -10), Vector2(16, -10), Vector2(14.6, -14)])
			draw_colored_polygon(tip, OUTLINE)
			var tip_in := PackedVector2Array([Vector2(13.8, -10), Vector2(15.5, -10), Vector2(14.6, -12.8)])
			draw_colored_polygon(tip_in, blade)
			draw_rect(Rect2(10.5, 6, 8, 3.4), OUTLINE)
			draw_rect(Rect2(11.3, 6.7, 6.4, 2), gold)
			draw_rect(Rect2(13.8, 9.4, 1.8, 5), wood)
		"lance":
			draw_line(Vector2(15, 12), Vector2(15, -14), OUTLINE, 4.2)
			draw_line(Vector2(15, 12), Vector2(15, -14), wood, 2.4)
			var tip := PackedVector2Array([Vector2(15, -21), Vector2(12.2, -13), Vector2(17.8, -13)])
			draw_colored_polygon(tip, OUTLINE)
			var tip_in := PackedVector2Array([Vector2(15, -19.4), Vector2(13.2, -13.8), Vector2(16.8, -13.8)])
			draw_colored_polygon(tip_in, steel)
		"axe":
			draw_line(Vector2(15, 12), Vector2(15, -10), OUTLINE, 4.2)
			draw_line(Vector2(15, 12), Vector2(15, -10), wood, 2.4)
			var head := PackedVector2Array([Vector2(15, -11), Vector2(23, -8), Vector2(23, -1), Vector2(15, -4)])
			draw_colored_polygon(head, OUTLINE)
			var head_in := PackedVector2Array([Vector2(15.8, -9.6), Vector2(21.6, -7.4), Vector2(21.6, -2.4), Vector2(15.8, -4.8)])
			draw_colored_polygon(head_in, steel)
		"bow":
			draw_arc(Vector2(17, 0), 10, -PI / 2, PI / 2, 12, OUTLINE, 4.2)
			draw_arc(Vector2(17, 0), 10, -PI / 2, PI / 2, 12, wood, 2.4)
			draw_line(Vector2(17, -10), Vector2(17, 10), Color(0.9, 0.9, 0.85), 1.2)
