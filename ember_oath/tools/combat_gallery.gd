extends Node
## 战斗特写样张：几组对阵各截一张命中瞬间，用来目测角色大小、站位、刀光；
## 再给每套条带截一张「全部动作」总表（一行一个动作，逐帧排开），检查切帧和脚底锚点。
## 用法（窗口模式才能截图）: godot --path ember_oath res://tools/combat_gallery.tscn
## 输出到 res://tools/shots/gallery_*.png 和 res://tools/shots/sheet_<条带>.png

const PAIRS := [
	["tia", "bandit1", false], ["tia", "bandit1", true],
	["scout1", "tia", false], ["scout1", "tia", true],
	["bandit1", "tia", false], ["bandit1", "tia", true],
	["brock", "balto", false], ["brock", "balto", true],
	["archer1", "tia", false], ["archer1", "tia", true],
	["balto", "bandit1", false], ["balto", "bandit1", true],
	["mage1", "balto", false], ["mage1", "balto", true],
]
## 第 2–5 章的新角色：章节数据由另一处维护，这里用最小的单位定义直接对打（[攻方, 守方, 必杀]）
const NEW_DEFS := {
	"harlo": ["player", "iron_axe"], "nina": ["player", "iron_bow"], "kain": ["player", "iron_sword"],
	"edric": ["player", "rapier"], "noya": ["player", "heal_staff"],
	"church1": ["enemy", "iron_lance"], "knight1": ["enemy", "iron_lance"], "silas": ["enemy", "silver_lance"],
	"merc1": ["enemy", "iron_sword"], "hawk": ["enemy", "steel_sword"], "barrett": ["enemy", "steel_lance"],
}
const NEW_PAIRS := [
	["harlo", "merc1", false], ["harlo", "merc1", true],
	["nina", "church1", false], ["nina", "church1", true],
	["kain", "merc1", false], ["kain", "merc1", true],
	["edric", "hawk", false], ["edric", "hawk", true],
	["noya", "bandit1", false], ["noya", "bandit1", true],
	["church1", "kain", false], ["church1", "kain", true],
	["knight1", "edric", false], ["knight1", "edric", true],
	["silas", "harlo", false], ["silas", "harlo", true],
	["merc1", "kain", false], ["merc1", "kain", true],
	["hawk", "edric", false], ["hawk", "edric", true],
	["barrett", "kain", false], ["barrett", "kain", true],
]
const SHEET_ANIMS := ["idle", "run", "attack", "crit", "hit", "death"]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/shots/"))
	var defs := {}
	for d in Chapter1.expand(Chapter1.UNITS) + Chapter1.expand(Chapter2.UNITS):
		defs[d["id"]] = d
	defs["mage1"] = {"id": "mage1", "name": "教会魔道士", "class": "魔道士", "faction": "enemy", "level": 5,
		"hp": 19, "pwr": 6, "skl": 5, "spd": 5, "dfn": 2, "res": 6, "mov": 5, "weapons": ["fire"]}
	for id in NEW_DEFS:
		var spec: Array = NEW_DEFS[id]
		defs[id] = {"id": id, "name": id, "class": "", "faction": spec[0], "level": 1,
			"hp": 24, "pwr": 6, "skl": 6, "spd": 6, "dfn": 4, "mov": 5, "weapons": [spec[1]]}
	var i := 0
	for pair in PAIRS + NEW_PAIRS:
		if not defs.has(pair[0]) or not defs.has(pair[1]):
			print("GALLERY SKIP ", pair)
			continue
		await _shoot_pair(defs, pair, i)
		i += 1
	for key in CombatFighter.SETS:
		await _shoot_sheet(key)
	print("GALLERY DONE")
	get_tree().quit()


func _shoot_pair(defs: Dictionary, pair: Array, i: int) -> void:
	var att := _unit(defs[pair[0]], Vector2i(4, 4))
	var def := _unit(defs[pair[1]], Vector2i(5, 4) if att.weapon_kind() != "bow" else Vector2i(6, 4))
	var scene := CombatScene.new()
	add_child(scene)
	var ev := {"side": "a", "dmg": 3, "hit": 90, "crit": pair[2], "landed": true, "killed": false}
	var fc := {"a_hit": 90, "a_dmg": 3, "a_crit": 5, "a_times": 1, "d_can": true, "d_hit": 70, "d_dmg": 4, "d_crit": 2, "d_times": 1}
	scene.play(att, def, 0, [ev], ".", fc)
	await get_tree().create_timer(0.7).timeout
	if i == 0:
		await _shot("gallery_idle.png")
	await scene._att_node.impact
	await get_tree().process_frame
	await get_tree().process_frame
	await _shot("gallery_%02d_%s_%s.png" % [i, pair[0], "crit" if pair[2] else "normal"])
	while scene.active:
		await get_tree().process_frame
	scene.queue_free()
	att.free()
	def.free()


## 一套条带的全部动作：一行一个动作，该动作的每一帧依次排开（原尺寸 1 倍，脚底对齐行线）
func _shoot_sheet(key: String) -> void:
	var sf := CombatFighter.frames_for(key)
	if sf == null:
		return
	var cfg: Dictionary = CombatFighter.SETS[key]
	var feet: Vector2 = cfg["feet"]
	var fw: int = (cfg["frame"] as Vector2i).x
	var root := Node2D.new()
	var bg := ColorRect.new()
	bg.color = Color(0.38, 0.52, 0.32)
	bg.size = Vector2(1280, 720)
	root.add_child(bg)
	add_child(root)
	var row_h := 118.0
	for r in SHEET_ANIMS.size():
		var anim: String = SHEET_ANIMS[r]
		var y := 108.0 + r * row_h
		var line := ColorRect.new()
		line.color = Color(0.22, 0.32, 0.18)
		line.position = Vector2(0, y)
		line.size = Vector2(1280, 2)
		root.add_child(line)
		var label := Label.new()
		label.text = anim
		label.position = Vector2(4, y - row_h + 12)
		root.add_child(label)
		if not sf.has_animation(anim):
			continue
		var n := sf.get_frame_count(anim)
		var pitch := minf(float(fw) - 40.0, 1180.0 / float(n))
		for f in n:
			var s := Sprite2D.new()
			s.texture = sf.get_frame_texture(anim, f)
			s.centered = false
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = Vector2(70.0 + f * pitch + float(fw) * 0.5, y) - feet
			root.add_child(s)
	await _shot("sheet_%s.png" % key)
	root.queue_free()


func _unit(d: Dictionary, pos: Vector2i) -> Unit:
	var u := Unit.new()
	var dd := d.duplicate()
	dd["pos"] = pos
	u.setup(dd)
	return u


func _shot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://tools/shots/" + file_name))
