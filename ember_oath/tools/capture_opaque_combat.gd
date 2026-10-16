extends Node
## 窗口模式拍必杀实机帧：草地 / 森林中景上的挥砍，以及草地时间轴上的镀金与命中。
## 不进冒烟。无头时直接退出。

const OUT_DIR := "/opt/cursor/artifacts/combat_opaque"


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("capture_opaque_combat 需要窗口模式")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await _shoot_still("grass_crit_strike", ".")
	await _shoot_still("forest_crit_strike", "F")
	await _shoot_live("grass_crit_live", ".")
	get_tree().quit(0)


func _shoot_still(file_name: String, terrain_char: String) -> void:
	var vp := _viewport()
	var scene := CombatScene.new()
	vp.add_child(scene)
	var tia := _make_tia()
	var bandit := _make_bandit()
	scene._att_real = tia
	scene._def_real = bandit
	scene._rebuild_bg(CombatScene.GROUND_COLORS.get(terrain_char, CombatScene.GROUND_COLORS["."]), terrain_char)
	scene._setup_units()
	scene._att_node.position = Vector2(CombatScene.DEF_X - 110.0, CombatScene.FEET_Y)
	scene._def_node.position = Vector2(CombatScene.DEF_X, CombatScene.FEET_Y)
	scene._use_crit_frames(scene._att_node, true)
	scene._set_pose(scene._att_node, CombatScene.POSE_STRIKE)
	scene._set_hit_pose(scene._def_node)
	scene.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	_save(vp, file_name)
	scene.free()
	tia.free()
	bandit.free()
	vp.free()


func _shoot_live(file_name: String, terrain_char: String) -> void:
	var vp := _viewport()
	var scene := CombatScene.new()
	vp.add_child(scene)
	var tia := _make_tia()
	var bandit := _make_bandit()
	var ev := {"side": "a", "crit": true, "dmg": 1, "landed": true}
	scene.play(tia, bandit, 0, [ev], terrain_char)
	# 0.12 白闪 + 0.42 入场 + 0.16 进入必杀镀金，身体应是实心金色。
	await get_tree().create_timer(0.70).timeout
	_save(vp, file_name + "_charge")
	# 再 0.50 进入慢速突进末、挥砍命中（1.20）。震屏前尽量卡在这一拍。
	await get_tree().create_timer(0.50).timeout
	_save(vp, file_name + "_strike")
	if scene.active:
		scene.skip()
	if scene.active:
		await scene.finished
	scene.free()
	tia.free()
	bandit.free()
	vp.free()


func _viewport() -> SubViewport:
	var host := SubViewportContainer.new()
	host.size = Vector2(1280, 720)
	host.position = Vector2.ZERO
	add_child(host)
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.disable_3d = true
	host.add_child(vp)
	return vp


func _save(vp: SubViewport, file_name: String) -> void:
	var img := vp.get_texture().get_image()
	var path := OUT_DIR + "/" + file_name + ".png"
	var err := img.save_png(path)
	print("截图 %s %dx%d err=%d" % [path, img.get_width(), img.get_height(), err])


func _make_tia() -> Unit:
	var u := Unit.new()
	u.setup({
		"id": "tia", "name": "缇娅", "class": "剑士", "faction": "player",
		"hp": 18, "pwr": 5, "skl": 6, "spd": 7, "dfn": 3,
		"weapons": ["iron_sword"], "pos": Vector2i(3, 4),
		"hair": "ponytail", "hair_color": Color(0.72, 0.28, 0.16),
	})
	return u


func _make_bandit() -> Unit:
	var u := Unit.new()
	u.setup({
		"id": "bandit1", "name": "山贼", "class": "山贼", "faction": "enemy",
		"hp": 20, "pwr": 4, "skl": 3, "spd": 3, "dfn": 2,
		"weapons": ["iron_axe"], "pos": Vector2i(4, 4),
		"hair": "spiky", "hair_color": Color(0.35, 0.22, 0.12),
	})
	return u
