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
}

const MUSIC := {
	"map": "res://audio/bgm_map.wav",
	"combat": "res://audio/bgm_combat.wav",
}

const POOL_SIZE := 10

var _streams := {}
var _sfx_pool: Array = []
var _music_player: AudioStreamPlayer
var _current_music := ""


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -9.0
	add_child(_music_player)
	for k in SFX:
		_streams[k] = load(SFX[k])
	for k in MUSIC:
		var s: AudioStream = load(MUSIC[k])
		if s is AudioStreamWAV:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_streams[k] = s


func play_sfx(sfx_name: String, pitch := 1.0) -> void:
	if not _streams.has(sfx_name):
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = _streams[sfx_name]
			p.pitch_scale = pitch
			p.play()
			return
	# 全忙则抢占最旧的一个
	_sfx_pool[0].stream = _streams[sfx_name]
	_sfx_pool[0].pitch_scale = pitch
	_sfx_pool[0].play()


func play_music(music_name: String) -> void:
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
