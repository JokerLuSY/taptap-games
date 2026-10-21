extends Node
## 玩家偏好（autoload: GameSettings）：战斗动画开关、敌方回合速度。
## 和音量、语言一起存 user://settings.cfg 的 [game] 段，跨存档生效。

signal changed

const PATH := "user://settings.cfg"
## 敌方回合「快速」时各种停顿、走路乘的系数
const FAST_FACTOR := 0.35

var battle_anim := true
var fast_enemy := false


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	battle_anim = bool(cfg.get_value("game", "battle_anim", true))
	fast_enemy = bool(cfg.get_value("game", "fast_enemy", false))


func set_battle_anim(v: bool) -> void:
	battle_anim = v
	_save()


func set_fast_enemy(v: bool) -> void:
	fast_enemy = v
	_save()


## 敌方 / 友军回合的时间系数
func enemy_speed() -> float:
	return FAST_FACTOR if fast_enemy else 1.0


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("game", "battle_anim", battle_anim)
	cfg.set_value("game", "fast_enemy", fast_enemy)
	cfg.save(PATH)
	changed.emit()
