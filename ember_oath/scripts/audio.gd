extends Node
## 全局音频管理器（autoload: Audio）
## play_sfx("sword") / play_music("map") / stop_music()

const SFX := {
	"cursor": "res://audio/cursor.wav",
	"select": "res://audio/select.wav",
	"cancel": "res://audio/cancel.wav",
	"move": "res://audio/move.wav",
	"sword": "res://audio/sword.wav",
	"lance": "res://audio/lance.wav",
	"axe": "res://audio/axe.wav",
	"bow": "res://audio/bow.wav",
	"miss": "res://audio/miss.wav",
	"crit": "res://audio/crit.wav",
	"heal": "res://audio/heal.wav",
	"coin": "res://audio/coin.wav",
	"phase": "res://audio/phase.wav",
	"talk": "res://audio/talk.wav",
	"reinforce": "res://audio/reinforce.wav",
	"levelup": "res://audio/levelup.wav",
	"victory": "res://audio/victory.wav",
	"defeat": "res://audio/defeat.wav",
	"hit": "res://audio/hit.wav",
	# 以下由 tools/generate_audio.py extra 合成
	"awaken": "res://audio/awaken_stinger.wav",
	"fire": "res://audio/sfx_fire.wav",
	"promote": "res://audio/sfx_promote.wav",
}

const LOOPS := {
	"fire": "res://audio/fire_loop.wav",
}

## map = 第一篇地图；map2 / map3 = 第二、三篇；boss = 首领战特写；story = 剧情场景；finale = 终章
const MUSIC := {
	"map": "res://audio/bgm_map.wav",
	"map2": "res://audio/bgm_map2.wav",
	"map3": "res://audio/bgm_map3.wav",
	"combat": "res://audio/bgm_combat.wav",
	"boss": "res://audio/bgm_boss.wav",
	"story": "res://audio/bgm_story.wav",
	"finale": "res://audio/bgm_finale.wav",
}

## 当前章节的地图曲：play_music("map") 时实际放哪一首（战斗特写结束、剧情结束都回到它）
var map_track := "map"

const POOL_SIZE := 10
const SETTINGS_PATH := "user://settings.cfg"
## 100 = 现有混音（BGM 在 -9 dB 上，音效为 0 dB）。
const BGM_BASE_DB := -9.0

var bgm_percent := 100.0
var sfx_percent := 100.0

var _streams := {}
var _sfx_pool: Array = []
var _music_player: AudioStreamPlayer
var _loop_player: AudioStreamPlayer
var _current_music := ""
var _current_loop := ""


func _ready() -> void:
	_load_volumes()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	_loop_player = AudioStreamPlayer.new()
	_loop_player.volume_db = -12.0
	add_child(_loop_player)
	_apply_bgm()
	_apply_sfx()
	for k in SFX:
		_streams[k] = load(SFX[k])
	for k in MUSIC:
		var s: AudioStream = load(MUSIC[k])
		if s is AudioStreamWAV:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = int(s.get_length() * s.mix_rate)
		_streams[k] = s
	for k in LOOPS:
		var loop_stream: AudioStream = load(LOOPS[k])
		if loop_stream is AudioStreamWAV:
			loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_streams["loop:" + k] = loop_stream


func play_sfx(sfx_name: String, pitch := 1.0) -> void:
	if not _streams.has(sfx_name):
		return
	for p in _sfx_pool:
		if not p.playing:
			_play_on(p, sfx_name, pitch)
			return
	# 全忙则抢占最旧的一个
	_play_on(_sfx_pool[0], sfx_name, pitch)


func set_bgm_percent(v: float) -> void:
	bgm_percent = clampf(v, 0.0, 100.0)
	_apply_bgm()
	_save_volumes()


func set_sfx_percent(v: float) -> void:
	sfx_percent = clampf(v, 0.0, 100.0)
	_apply_sfx()
	_save_volumes()


func _play_on(p: AudioStreamPlayer, sfx_name: String, pitch: float) -> void:
	p.stream = _streams[sfx_name]
	p.pitch_scale = pitch
	p.volume_db = _bus_db(sfx_percent)
	p.play()


func _apply_bgm() -> void:
	if _music_player == null:
		return
	_music_player.volume_db = BGM_BASE_DB + _bus_db(bgm_percent)


func _apply_sfx() -> void:
	var db := _bus_db(sfx_percent)
	for p in _sfx_pool:
		p.volume_db = db


func _bus_db(percent: float) -> float:
	if percent <= 0.001:
		return -80.0
	return linear_to_db(percent / 100.0)


func _load_volumes() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	bgm_percent = clampf(float(cfg.get_value("audio", "bgm", 100.0)), 0.0, 100.0)
	sfx_percent = clampf(float(cfg.get_value("audio", "sfx", 100.0)), 0.0, 100.0)


func _save_volumes() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "bgm", bgm_percent)
	cfg.set_value("audio", "sfx", sfx_percent)
	cfg.save(SETTINGS_PATH)


func play_music(music_name: String) -> void:
	if music_name == "map":
		music_name = map_track
	if _current_music == music_name and _music_player.playing:
		return
	if not _streams.has(music_name):
		return
	_current_music = music_name
	_music_player.stream = _streams[music_name]
	_music_player.play()


func stop_music() -> void:
	_current_music = ""
	_music_player.stop()


func play_loop(loop_name: String) -> void:
	var key := "loop:" + loop_name
	if _current_loop == loop_name and _loop_player.playing:
		return
	if not _streams.has(key) or _streams[key] == null:
		return
	_current_loop = loop_name
	_loop_player.stream = _streams[key]
	_loop_player.play()


func stop_loop() -> void:
	_current_loop = ""
	_loop_player.stop()
