extends Node
## 离屏渲染验证: 以 1080x2400(长屏手机比例)视口截图, 检查内容是否完整居中

func _ready() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(main)
	for i in 8:
		await get_tree().process_frame
	var vp: Vector2 = main.get_viewport_rect().size
	var stage: Control = main.get("_stage")
	var lines := PackedStringArray()
	lines.append("viewport=%.0f x %.0f" % [vp.x, vp.y])
	lines.append("stage_scale=%.4f pos=%s" % [stage.scale.x, stage.position])
	var stage_rect := Rect2(stage.position, main.DESIGN_SIZE * stage.scale)
	lines.append("stage_rect=%s" % stage_rect)
	var fails := 0
	for n in ["TitleLabel", "TipLabel", "StartLabel", "LangButton"]:
		var node := main.find_child(n, true, false)
		if node == null:
			lines.append("MISSING %s" % n)
			fails += 1
			continue
		var r: Rect2 = node.get_global_rect()
		var inside := Rect2(Vector2.ZERO, vp).encloses(r)
		lines.append("%s rect=%s inside=%s text=%s" % [n, r, inside, node.text])
		if not inside:
			fails += 1
	var wheel = main.get("_wheel")
	lines.append("wheel_pos=%s" % wheel.position)
	lines.append("RESULT %s" % ("PASS" if fails == 0 else "FAIL(%d)" % fails))
	var f := FileAccess.open("res://tools/shots/layout_report.txt", FileAccess.WRITE)
	f.store_string("\n".join(lines))
	print("\n".join(lines))
	get_tree().quit()
