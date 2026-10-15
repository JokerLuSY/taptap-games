extends Node
## 记住标题画面选的语言。文案表是 locale/ui.csv（keys,zh_CN,en），
## 由 Godot 导入为 Translation，并在 project.godot 的 locale/translations 里登记。

signal locale_changed(code: String)

const CFG_PATH := "user://settings.cfg"
const DEFAULT_CODE := "zh_CN"

var code := DEFAULT_CODE


func _init() -> void:
	code = _saved_code()
	TranslationServer.set_locale(code)


func toggle() -> void:
	set_code("en" if code.begins_with("zh") else DEFAULT_CODE)


func set_code(next: String) -> void:
	if next != "en" and next != "zh_CN":
		next = DEFAULT_CODE
	code = next
	TranslationServer.set_locale(code)
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)
	cfg.set_value("locale", "code", code)
	cfg.save(CFG_PATH)
	locale_changed.emit(code)


func _saved_code() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		return DEFAULT_CODE
	var saved := str(cfg.get_value("locale", "code", DEFAULT_CODE))
	if saved != "en" and saved != "zh_CN":
		return DEFAULT_CODE
	return saved
