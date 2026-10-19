class_name CombatFighter
extends Node2D
## 战斗特写里的一名角色：原创 GBA 火纹风横版条带（tools/pixelart/fe_combat.py 生成）。
## 节点原点就是脚底中心；条带原生全部朝右，朝左时整个节点 scale.x = -1。

signal impact            # 攻击动画走到出手帧（刀落下 / 放箭 / 枪刺出那一帧）

const ROOT := "res://art/combat/fe/"
## 每套条带：单帧尺寸、脚底锚点（帧内像素）、整数放大倍数、出手距离、各动作 [帧率, 出手帧]。
## 帧数按贴图宽度 / 帧宽自动算。数据由生成器写进 CombatSets，不在这里手改。
const SETS := CombatSets.SETS
const LOOPING := ["idle", "run"]
const SHADER := preload("res://shaders/combat_fighter.gdshader")

static var _frames_cache := {}

var set_key := ""
var weapon_kind := "sword"
var face_left := false
var sprite: AnimatedSprite2D
var _impact_frame := -1
var _impact_sent := false


## 返回 false 表示这套条带缺图，调用方应换兜底
func setup(key: String, kind: String, left: bool, tint := Color.WHITE) -> bool:
	set_key = key
	weapon_kind = kind
	face_left = left
	var sf := frames_for(key)
	if sf == null:
		return false
	var cfg: Dictionary = SETS[key]
	var px: int = cfg["scale"]
	sprite = AnimatedSprite2D.new()
	sprite.name = "Body"
	sprite.sprite_frames = sf
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(px, px)
	sprite.position = -(cfg["feet"] as Vector2) * px
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("tint", tint)
	sprite.material = mat
	add_child(sprite)
	sprite.frame_changed.connect(_on_frame_changed)
	scale = Vector2(-1.0 if left else 1.0, 1.0)
	play_loop("idle")
	return true


static func has_set(key: String) -> bool:
	return SETS.has(key) and ResourceLoader.exists(ROOT + key + "/idle.png")


## 每套条带只切一次，所有战斗共用
static func frames_for(key: String) -> SpriteFrames:
	if _frames_cache.has(key):
		return _frames_cache[key]
	if not has_set(key):
		return null
	var cfg: Dictionary = SETS[key]
	var fs: Vector2i = cfg["frame"]
	var sf := SpriteFrames.new()
	for anim in cfg["anims"]:
		var path: String = ROOT + key + "/" + anim + ".png"
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		var n := maxi(1, tex.get_width() / fs.x)
		sf.add_animation(anim)
		sf.set_animation_speed(anim, float(cfg["anims"][anim][0]))
		sf.set_animation_loop(anim, anim in LOOPING)
		for i in n:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * fs.x, 0, fs.x, fs.y)
			at.filter_clip = true
			sf.add_frame(anim, at)
	_frames_cache[key] = sf
	return sf


func has_anim(anim: String) -> bool:
	return sprite != null and sprite.sprite_frames.has_animation(anim)


func play_loop(anim: String) -> void:
	if not has_anim(anim):
		return
	_impact_frame = -1
	sprite.play(anim)


## 播一遍并等它结束。出手帧到了会先发 impact
func play_once(anim: String) -> void:
	if sprite == null:
		# 缺图兜底（程序 Q 版）：下一帧直接算出手，调用方 await impact 不会挂住
		await get_tree().process_frame
		impact.emit()
		return
	if not has_anim(anim):
		anim = "attack" if has_anim("attack") else "idle"
	var cfg: Dictionary = SETS[set_key]
	_impact_frame = int(cfg["anims"].get(anim, [0, -1])[1])
	_impact_sent = false
	sprite.play(anim)
	sprite.frame = 0
	await sprite.animation_finished
	if _impact_frame >= 0 and not _impact_sent:
		_impact_sent = true
		impact.emit()


## 攻击动作名：必杀用第二套招式；长枪兵有专门的突刺
func attack_anim(crit: bool) -> String:
	if crit and has_anim("crit"):
		return "crit"
	if weapon_kind == "lance" and has_anim("thrust"):
		return "thrust"
	return "attack"


func _on_frame_changed() -> void:
	if _impact_frame >= 0 and not _impact_sent and sprite.frame >= _impact_frame:
		_impact_sent = true
		impact.emit()


## 动作播完停在最后一帧（受击 / 阵亡用）
func is_playing(anim: String) -> bool:
	return sprite != null and sprite.animation == anim and sprite.is_playing()


func current_anim() -> String:
	return "" if sprite == null else str(sprite.animation)


func flash(amount := 1.0, time := 0.22) -> void:
	if sprite == null:
		return
	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("flash", amount)
	var t := create_tween()
	t.tween_method(func(v: float) -> void: mat.set_shader_parameter("flash", v), amount, 0.0, time)


## 残影：复制当前帧留在原地，染色后淡出（主角必杀用）
func ghost(tint: Color) -> void:
	if sprite == null or get_parent() == null:
		return
	var g := Sprite2D.new()
	g.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	g.centered = false
	g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g.scale = sprite.scale * scale
	g.position = position + sprite.position * scale
	g.modulate = tint
	g.z_index = z_index - 1
	get_parent().add_child(g)
	var t := g.create_tween()
	t.tween_property(g, "modulate:a", 0.0, 0.3)
	t.finished.connect(g.queue_free)


func set_glow(c: Color) -> void:
	if sprite != null:
		(sprite.material as ShaderMaterial).set_shader_parameter("glow", c)
