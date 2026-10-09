extends Control
## 主菜单: 新游戏 / 继续 / 退出

var _click_sfx: AudioStreamPlayer


func _ready() -> void:
	GameState.stop_hint_timers()

	var bg := TextureRect.new()
	bg.texture = load("res://art/bg/menu_bg.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_click_sfx = AudioStreamPlayer.new()
	_click_sfx.stream = load("res://audio/click.wav")
	add_child(_click_sfx)

	var layout := VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 40)
	add_child(layout)

	var title := Label.new()
	title.text = GameState.ui_text("game_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 110)
	title.add_theme_color_override("font_color", Color(1.0, 0.87, 0.62))
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = GameState.ui_text("subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 40)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.79, 0.9))
	layout.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 260)
	layout.add_child(spacer)

	var btn_new := _make_button(GameState.ui_text("menu_new"))
	btn_new.pressed.connect(_on_new_game)
	layout.add_child(btn_new)

	var btn_continue := _make_button(GameState.ui_text("menu_continue"))
	btn_continue.disabled = not SaveManager.has_save()
	btn_continue.pressed.connect(_on_continue)
	layout.add_child(btn_continue)

	var btn_exit := _make_button(GameState.ui_text("menu_exit"))
	btn_exit.pressed.connect(_on_exit)
	layout.add_child(btn_exit)

	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = GameState.ui_text("confirm_overwrite")
	confirm.ok_button_text = GameState.ui_text("yes")
	confirm.cancel_button_text = GameState.ui_text("no")
	confirm.confirmed.connect(_start_new)
	add_child(confirm)
	_confirm = confirm


var _confirm: ConfirmationDialog


func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(460, 120)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 48)
	b.pressed.connect(_click_sfx.play)
	return b


func _on_new_game() -> void:
	if SaveManager.has_save():
		_confirm.popup_centered()
	else:
		_start_new()


func _start_new() -> void:
	SaveManager.clear_save()
	GameState.start_new_game()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_continue() -> void:
	GameState.continue_game()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_exit() -> void:
	get_tree().quit()
