class_name UnitStatus
extends Control
## 单位能力画面（火纹式）：点敌人看过威胁范围后再点一次，或点已经行动过的我方单位时打开。
## 左边立绘、名字、职业、等级、HP；中间各项能力和数值条；右边战斗数值（攻击 / 命中 / 必杀 / 回避）、
## 持有的武器道具、武器等级。点任意处或按返回关闭。

signal closed

const STAT_MAX := 30.0              # 数值条满格（GBA 火纹基础职业的能力上限）
const PANEL_POS := Vector2(140, 64)
const PANEL_SIZE := Vector2(1000, 592)

var battle = null
var unit: Unit = null


func open(b, u: Unit) -> void:
	battle = b
	unit = u
	name = "UnitStatus"
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var team := _team_color()
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.12, 0.97)
	sb.border_color = team
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	p.add_theme_stylebox_override("panel", sb)
	p.position = PANEL_POS
	p.size = PANEL_SIZE
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	_build_left(p, team)
	_build_stats(p)
	_build_right(p)
	var foot := _label(p, Vector2(0, PANEL_SIZE.y - 34), 16, Color(0.7, 0.72, 0.78))
	foot.size.x = PANEL_SIZE.x
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.text = tr("点任意处关闭")
	Audio.play_sfx("select")


## 松手时才关：按下和松开都被这个窗口吃掉，不会漏到地图上变成一次点击
var _pressed_here := false   # 长按打开时，那根手指的松开不能把画面立刻关掉


func _gui_input(event: InputEvent) -> void:
	if PointerInput.is_primary_press(event):
		_pressed_here = true
		accept_event()
	elif PointerInput.is_primary_release(event):
		accept_event()
		if _pressed_here:
			close()


func close() -> void:
	if is_queued_for_deletion():
		return
	Audio.play_sfx("cancel")
	closed.emit()
	queue_free()


func _team_color() -> Color:
	if unit.is_player():
		return Color(0.45, 0.65, 1.0)
	if unit.is_npc():
		return Color(0.45, 0.85, 0.5)
	return Color(1.0, 0.45, 0.4)


# ---------------- 左：立绘 / 名字 / 等级 / HP ----------------

func _build_left(p: Panel, team: Color) -> void:
	var frame := Panel.new()
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color(0.16, 0.18, 0.26)
	fsb.border_color = team.darkened(0.2)
	fsb.set_border_width_all(2)
	fsb.set_corner_radius_all(6)
	frame.add_theme_stylebox_override("panel", fsb)
	frame.position = Vector2(28, 28)
	frame.size = Vector2(204, 204)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(frame)
	var key: String = battle._unit_portrait_key(unit) if battle != null else ""
	if key != "" and ResourceLoader.exists("res://art/portraits/px/%s.png" % key):
		var tex := TextureRect.new()
		tex.texture = load("res://art/portraits/px/%s.png" % key)
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.position = Vector2(6, 6)
		tex.size = Vector2(192, 192)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(tex)
	var side := tr("我方") if unit.is_player() else (tr("中立") if unit.is_npc() else tr("敌方"))
	var nm := _label(p, Vector2(28, 244), 30, team.lightened(0.25))
	nm.text = tr(unit.display_name)
	var tag := _label(p, Vector2(28, 286), 18, Color(0.82, 0.84, 0.9))
	var tags: Array = [side]
	if unit.is_boss:
		tags.append(tr("首领"))
	if unit.stationary:
		tags.append(tr("原地不动"))
	tag.text = "  ·  ".join(PackedStringArray(tags))
	var cls := _label(p, Vector2(28, 318), 22, Color(0.95, 0.92, 0.8))
	cls.text = tr(unit.class_label)
	var lv := _label(p, Vector2(28, 352), 22, Color(0.95, 0.92, 0.8))
	lv.text = tr("Lv %d    EXP %d") % [unit.level, unit.xp] if unit.level < 20 else tr("Lv %d    EXP --") % unit.level
	var hp := _label(p, Vector2(28, 392), 24, Color(1, 1, 1))
	hp.text = "HP  %d / %d" % [unit.hp, unit.max_hp]
	_bar(p, Vector2(28, 426), 204, float(unit.hp) / maxf(1.0, float(unit.max_hp)), Color(0.4, 0.9, 0.45))
	if unit.carrying != null:
		var c := _label(p, Vector2(28, 448), 16, Color(1.0, 0.85, 0.55))
		c.text = tr("背着：%s（技、速减半）") % tr(unit.carrying.display_name)
	var sup := support_lines()
	if not sup.is_empty():
		var sh := _label(p, Vector2(28, 474), 18, Color(1.0, 0.86, 0.5))
		sh.text = tr("支援")
		var sl := _label(p, Vector2(28, 500), 17, Color(0.92, 0.9, 0.95))
		sl.text = "\n".join(PackedStringArray(sup.slice(0, 3)))


## 这个人的支援关系：「兰斯  C」「葛温  —」。只列名单里认识（在场或在名单上）的人
func support_lines() -> Array:
	var out: Array = []
	if not unit.is_player():
		return out
	for key in Supports.PAIRS:
		var pair: Array = String(key).split("|")
		if not unit.unit_id in pair:
			continue
		var pid: String = pair[1] if pair[0] == unit.unit_id else pair[0]
		var nm := ""
		var other = battle.get_unit(pid) if battle != null else null
		if other != null:
			nm = other.display_name
		elif Campaign.roster.has(pid) and Campaign.alive_in_story(pid):
			nm = str(Campaign.roster[pid].get("name", ""))
		if nm == "":
			continue
		var r := Supports.rank_of(unit, pid)
		out.append("%s  %s" % [tr(nm), r if r != "" else "—"])
	return out


# ---------------- 中：能力 ----------------

func _build_stats(p: Panel) -> void:
	var x := 268.0
	var head := _label(p, Vector2(x, 28), 20, Color(1.0, 0.86, 0.5))
	head.text = tr("能力")
	var rows := [
		[tr("力量"), unit.pwr, true], [tr("技巧"), unit.skl, true], [tr("速度"), unit.spd, true],
		[tr("守备"), unit.dfn, true], [tr("魔防"), unit.res, true],
		[tr("移动"), unit.mov, false], [tr("体格"), unit.con, false], [tr("救出"), unit.aid(), false],
	]
	var y := 66.0
	for r in rows:
		var l := _label(p, Vector2(x, y), 20, Color(0.85, 0.88, 0.95))
		l.text = str(r[0])
		var v := _label(p, Vector2(x + 76, y), 22, Color(1, 1, 1))
		v.text = str(r[1])
		v.size.x = 36
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if r[2]:
			_bar(p, Vector2(x + 124, y + 12), 170, float(r[1]) / STAT_MAX, Color(0.95, 0.75, 0.35))
		y += 42.0


# ---------------- 右：战斗数值 / 持有物 / 武器等级 ----------------

func _build_right(p: Panel) -> void:
	var x := 630.0
	var head := _label(p, Vector2(x, 28), 20, Color(1.0, 0.86, 0.5))
	head.text = tr("战斗")
	var b := battle_stats()
	var pairs := [[tr("攻击"), b["atk"]], [tr("命中"), b["hit"]], [tr("必杀"), b["crit"]], [tr("回避"), b["avo"]]]
	for i in pairs.size():
		var px := x + (i % 2) * 170.0
		var py := 64.0 + (i / 2) * 36.0
		var l := _label(p, Vector2(px, py), 20, Color(0.85, 0.88, 0.95))
		l.text = str(pairs[i][0])
		var v := _label(p, Vector2(px + 64, py), 22, Color(1, 1, 1))
		v.text = str(pairs[i][1])
	var rng := _label(p, Vector2(x, 140), 18, Color(0.8, 0.82, 0.88))
	rng.text = tr("射程 %s") % b["range"]
	var head2 := _label(p, Vector2(x, 178), 20, Color(1.0, 0.86, 0.5))
	head2.text = tr("持有物")
	var y := 212.0
	for i in unit.weapons.size():
		var w: Dictionary = GameData.WEAPONS[unit.weapons[i]]
		var l := _label(p, Vector2(x, y), 20, Color(1, 1, 1) if unit.can_use(i) else Color(0.6, 0.6, 0.62))
		l.text = ("E " if i == 0 else "   ") + tr(w["name"])
		var u_ := _label(p, Vector2(x + 250, y), 20, Color(0.9, 0.9, 0.9))
		u_.text = unit.uses_text(i)
		y += 30.0
	for i in unit.items.size():
		var it: Dictionary = GameData.ITEMS.get(unit.items[i], {"name": unit.items[i]})
		var l := _label(p, Vector2(x, y), 20, Color(0.9, 0.95, 0.85))
		l.text = "   " + tr(str(it["name"]))
		var u_ := _label(p, Vector2(x + 250, y), 20, Color(0.9, 0.9, 0.9))
		u_.text = str(int(unit.item_uses[i])) if i < unit.item_uses.size() else ""
		y += 30.0
	if unit.weapons.is_empty() and unit.items.is_empty():
		var l := _label(p, Vector2(x, y), 20, Color(0.6, 0.6, 0.62))
		l.text = tr("（无）")
		y += 30.0
	var ranks: Array = []
	for t in GameData.WEAPON_TYPES:
		var r := unit.rank_letter(t)
		if r != "":
			ranks.append("%s %s" % [tr(GameData.TYPE_NAMES[t]), r])
	if not ranks.is_empty():
		var head3 := _label(p, Vector2(x, maxf(y + 10.0, 420.0)), 20, Color(1.0, 0.86, 0.5))
		head3.text = tr("武器等级")
		var rl := _label(p, Vector2(x, maxf(y + 10.0, 420.0) + 34.0), 20, Color(1, 1, 1))
		rl.text = "   ".join(PackedStringArray(ranks))


## 火纹式的战斗数值：用第一把（装备中的）武器算。攻击 = 威力 + 力，命中 = 武器命中 + 技×2，
## 必杀 = 技÷2 + 武器必杀，回避 = 速×2 + 脚下地形回避
func battle_stats() -> Dictionary:
	var avo := unit.eff_spd() * 2
	if battle != null and battle.board != null:
		avo += int(battle.board.terrain_bonus(unit, unit.grid_pos)["avo"])
	if unit.weapons.is_empty() or unit.weapon(0)["type"] == "staff":
		return {"atk": "--", "hit": "--", "crit": "--", "avo": avo, "range": "--"}
	var w: Dictionary = unit.weapon(0)
	var rs: Array = w["rng"]
	var rtxt := str(rs[0]) if rs.size() == 1 else "%d-%d" % [rs[0], rs[rs.size() - 1]]
	return {
		"atk": int(w["mt"]) + unit.pwr,
		"hit": int(w["hit"]) + unit.eff_skl() * 2,
		"crit": unit.eff_skl() / 2 + int(w.get("crit", 0)),
		"avo": avo,
		"range": rtxt,
	}


# ---------------- 工具 ----------------

func _label(parent: Control, pos: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _bar(parent: Control, pos: Vector2, width: float, ratio: float, color: Color) -> void:
	var bg := ColorRect.new()
	bg.position = pos
	bg.size = Vector2(width, 10)
	bg.color = Color(0.2, 0.22, 0.3)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	var fg := ColorRect.new()
	fg.position = pos
	fg.size = Vector2(width * clampf(ratio, 0.0, 1.0), 10)
	fg.color = color
	fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fg)
