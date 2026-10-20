class_name SceneCard
extends Control
## 剧情场景卡：战场以外的场景（敌方视角、远方的另一条线）用一张全屏氛围底 + 地点标题，台词走 battle 的对话框。
## mood 决定底色和点缀：church 圣堂（金色微光、窗格）、camp 营地（火光）、castle 城堡（冷蓝）、dungeon 地下（暗紫、铁栏）、
## night 夜路（深蓝、星点）。

const MOODS := {
	"church": [Color(0.16, 0.10, 0.20), Color(0.42, 0.30, 0.14), Color(1.0, 0.85, 0.45)],
	"camp": [Color(0.12, 0.06, 0.05), Color(0.42, 0.14, 0.06), Color(1.0, 0.5, 0.2)],
	"castle": [Color(0.06, 0.10, 0.18), Color(0.20, 0.30, 0.42), Color(0.7, 0.85, 1.0)],
	"dungeon": [Color(0.06, 0.04, 0.08), Color(0.20, 0.12, 0.24), Color(0.7, 0.5, 1.0)],
	"night": [Color(0.03, 0.05, 0.12), Color(0.10, 0.16, 0.30), Color(0.9, 0.9, 1.0)],
}

var mood := "church"
var _t := 0.0
var _seed := 0


func setup(title: String, scene_mood: String) -> void:
	name = "SceneCard"
	mood = scene_mood if MOODS.has(scene_mood) else "night"
	_seed = title.hash()
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := Label.new()
	t.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	t.text = title
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", MOODS[mood][2])
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	t.add_theme_constant_override("outline_size", 8)
	t.position = Vector2(SafeArea.MARGIN_X, SafeArea.MARGIN_Y)
	add_child(t)
	var line := ColorRect.new()
	line.color = Color(MOODS[mood][2], 0.6)
	line.position = Vector2(SafeArea.MARGIN_X, SafeArea.MARGIN_Y + 46)
	line.size = Vector2(320, 2)
	add_child(line)


func intro() -> void:
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.45)
	await t.finished


func outro() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	await t.finished


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c0: Color = MOODS[mood][0]
	var c1: Color = MOODS[mood][1]
	var hi: Color = MOODS[mood][2]
	# 竖向渐变底
	for i in 24:
		var y := i * 30.0
		draw_rect(Rect2(0, y, 1280, 31), c0.lerp(c1, float(i) / 23.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	match mood:
		"church":
			# 高窗透下来的光柱
			for k in 3:
				var x := 340.0 + k * 300.0
				var a := 0.10 + 0.05 * sin(_t * 1.2 + k)
				draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 60, 0), Vector2(x + 160, 720), Vector2(x + 40, 720)]), Color(hi, a))
				draw_rect(Rect2(x, 40, 60, 120), Color(hi, 0.25))
				draw_rect(Rect2(x + 28, 40, 4, 120), c0)
		"camp", "night":
			for k in 40:
				var p := Vector2(rng.randf() * 1280, rng.randf() * 720)
				if mood == "camp":
					p.y = 720 - fmod(p.y + _t * (20 + k), 720)
				var a := 0.3 + 0.3 * sin(_t * 3.0 + k)
				draw_circle(p, 1.5 + rng.randf() * 2.0, Color(hi, a))
			if mood == "camp":
				draw_circle(Vector2(640, 760), 340, Color(hi, 0.12 + 0.04 * sin(_t * 6.0)))
		"castle":
			for k in 6:
				var x := 120.0 + k * 200.0
				draw_rect(Rect2(x, 220, 70, 500), Color(c1.lightened(0.1), 0.5))
				draw_rect(Rect2(x + 20, 260, 30, 60), Color(hi, 0.18 + 0.06 * sin(_t * 2.0 + k)))
		"dungeon":
			for k in 26:
				var x := 40.0 + k * 48.0
				draw_rect(Rect2(x, 120, 6, 600), Color(0.05, 0.04, 0.06, 0.8))
			draw_rect(Rect2(0, 120, 1280, 8), Color(0.05, 0.04, 0.06, 0.8))
			draw_circle(Vector2(640, 300), 260, Color(hi, 0.06 + 0.03 * sin(_t * 2.0)))
	# 暗角
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.0))
	for i in 10:
		draw_rect(Rect2(-i * 6, -i * 6, 1280 + i * 12, 720 + i * 12), Color(0, 0, 0, 0.06), false, 40.0)
