extends Node
## 战斗特写样张：几组对阵各截一张命中瞬间，用来目测角色大小、站位、刀光。
## 用法（窗口模式才能截图）: godot --path ember_oath res://tools/combat_gallery.tscn
## 输出到 res://tools/shots/gallery_*.png

const PAIRS := [
	["tia", "bandit1", false], ["tia", "bandit1", true],
	["scout1", "tia", false], ["scout1", "tia", true],
	["bandit1", "tia", false], ["bandit1", "tia", true],
	["brock", "balto", false], ["brock", "balto", true],
	["archer1", "tia", false], ["archer1", "tia", true],
	["balto", "bandit1", false], ["balto", "bandit1", true],
]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/shots/"))
	var defs := {}
	for d in Chapter1.expand(Chapter1.UNITS) + Chapter1.expand(Chapter2.UNITS):
		defs[d["id"]] = d
	var i := 0
	for pair in PAIRS:
		var att := _unit(defs[pair[0]], Vector2i(4, 4))
		var def := _unit(defs[pair[1]], Vector2i(5, 4) if att.weapon_kind() != "bow" else Vector2i(6, 4))
		var scene := CombatScene.new()
		add_child(scene)
		var ev := {"side": "a", "dmg": 3, "hit": 90, "crit": pair[2], "landed": true, "killed": false}
		var fc := {"a_hit": 90, "a_dmg": 3, "a_crit": 5, "a_times": 1, "d_can": true, "d_hit": 70, "d_dmg": 4, "d_crit": 2, "d_times": 1}
		scene.play(att, def, 0, [ev], ".", fc)
		await get_tree().create_timer(0.7).timeout
		if i == 0:
			_shot("gallery_idle.png")
		await scene._att_node.impact
		await get_tree().process_frame
		await get_tree().process_frame
		_shot("gallery_%02d_%s_%s.png" % [i, pair[0], "crit" if pair[2] else "normal"])
		while scene.active:
			await get_tree().process_frame
		scene.queue_free()
		att.free()
		def.free()
		i += 1
	print("GALLERY DONE")
	get_tree().quit()


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
