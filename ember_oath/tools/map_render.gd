extends Node
## 整张地图渲染成 PNG（开发用，看大地图布局）：地形 + 开场单位 + 标记。
## 运行：Godot --path . res://tools/map_render.tscn [-- 2 3]，输出 tools/shots/map_chN.png。
## 环境变量 NOUNITS=1 时只画地形。标记：绿框 = 额外出击格 / 名单补位格，金框 = 目标格，红框带回合数 = 增援 / 波次出现的格子。

const TILE := 64


func _ready() -> void:
	var which: Array = []
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			which.append(int(a))
	if which.is_empty():
		which = [1, 2, 3, 4, 5]
	for idx in which:
		await _render(idx)
	get_tree().quit()


func _render(idx: int) -> void:
	var script: Script = load("res://scripts/chapter%d.gd" % idx)
	var ch = script.new()
	var consts: Dictionary = script.get_script_constant_map()
	var map: Array = consts["MAP"]
	var vp := SubViewport.new()
	vp.size = Vector2i(map[0].length() * TILE, map.size() * TILE)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	add_child(vp)
	var board := Board.new()
	board.units = []
	vp.add_child(board)
	board.view_size = Vector2(vp.size)
	board.theme = str(consts.get("THEME", ""))
	board.load_map(map, consts.get("LEVELS", []), "")
	board.goal_tiles = ch.goal_tiles()
	for def in ChapterBase.expand_with(consts.get("UNITS", []), ch.templates()):
		if not def.has("pos") or OS.has_environment("NOUNITS"):
			continue
		var u := Unit.new()
		u.setup(def)
		board.add_child(u)
		board.units.append(u)
	var marks := _Marks.new()
	marks.z_index = 20
	marks.slots = ch.extra_slots() + ch.extra_deploy_slots()
	marks.goals = ch.goal_tiles()
	for key in ["REINFORCEMENTS", "WAVES"]:
		var wv = consts.get(key, null)
		if wv is Array:
			for d in wv:
				marks.spawns.append([d["pos"], "R"])
		elif wv is Dictionary:
			for t in wv:
				for d in wv[t]:
					marks.spawns.append([d["pos"], str(t)])
	board.add_child(marks)
	for i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	var out := "res://tools/shots/map_ch%d.png" % idx
	img.save_png(ProjectSettings.globalize_path(out))
	print("map render: %s %dx%d" % [out, map[0].length(), map.size()])
	vp.queue_free()


class _Marks extends Node2D:
	var slots: Array = []
	var goals: Array = []
	var spawns: Array = []

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		for p in slots:
			draw_rect(Rect2(Vector2(p) * TILE + Vector2(3, 3), Vector2(TILE - 6, TILE - 6)), Color(0.3, 1.0, 0.4), false, 3.0)
		for p in goals:
			draw_rect(Rect2(Vector2(p) * TILE + Vector2(3, 3), Vector2(TILE - 6, TILE - 6)), Color(1.0, 0.85, 0.2), false, 3.0)
		for s in spawns:
			var p: Vector2i = s[0]
			draw_rect(Rect2(Vector2(p) * TILE + Vector2(6, 6), Vector2(TILE - 12, TILE - 12)), Color(1.0, 0.3, 0.3), false, 3.0)
			draw_string(f, Vector2(p) * TILE + Vector2(10, 26), s[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.4, 0.4))
		# 坐标刻度：每 5 格一个数字
		var w := 0
		var h := 0
		var b := get_parent() as Board
		if b != null:
			w = b.width
			h = b.height
		for x in w:
			draw_string(f, Vector2(x * TILE + 2, 12), str(x), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.9))
		for y in h:
			draw_string(f, Vector2(2, y * TILE + 26), str(y), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.9))
