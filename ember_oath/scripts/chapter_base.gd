class_name ChapterBase
extends RefCounted
## 章节脚本的公共底子：事件钩子的默认实现、胜负条件、对话 / 说得 / 支援的通用流程、旗标存读。
## 每章继承它，写自己的 MAP / LEVELS / UNITS / BG / CHAPTER_TITLE 等常量，再按需覆盖钩子。
## 钩子都可能被 battle `await`，所以默认实现也写成协程。

## 支援对在全战役通用：相邻累计 points_to_c 回合后解锁 C 级
const SUPPORT_PAIRS := {
	"tia|balto": {"points_to_c": 6},
}

var battle = null
var visited := {}
var flags := {}                   # 本章剧情旗标（随检查点存档）
var f_support := {}               # {支援对 key: 本章已解锁}


# ==================== 章节信息（子类覆盖） ====================

func chapter_id() -> String:
	return ""


## id 前缀 → 模板（只写 id 和 pos 的单位套模板）
func templates() -> Dictionary:
	return {}


## 任一阵亡即败北
func lose_ids() -> Array:
	return ["tia", "balto"]


## 名单里在队、但本章 UNITS 没写位置的我方单位，依次放到这些格子
func extra_slots() -> Array:
	return []


## 生成单位前改名单状态（例如剧情让某人离队）：{unit_id: status}
func before_spawn_status() -> Dictionary:
	return {}


## 章节胜利后改名单状态：{unit_id: status}
func after_victory_status() -> Dictionary:
	return {}


## 撤离点等目标格（地图上金框标出）
func goal_tiles() -> Array:
	return []


## 胜利判定。默认：敌人全灭。
func is_won() -> bool:
	for u in battle.units:
		if not u.is_player() and u.is_alive() and not u.get_meta("ally", false):
			return false
	return true


func supports() -> Dictionary:
	return SUPPORT_PAIRS


func win_condition() -> String:
	return tr("击败所有敌人")


func lose_condition() -> String:
	return tr("缇娅或巴尔托阵亡")


# ==================== 事件钩子 ====================

func on_battle_start() -> void:
	if false:
		await battle.play_dialogue([])


func on_turn_start(_t: int) -> void:
	if false:
		await battle.play_dialogue([])


func on_before_combat(_att, _def) -> void:
	if false:
		await battle.play_dialogue([])


func on_after_combat(_att, _def, _def_died: bool) -> void:
	if false:
		await battle.play_dialogue([])


func on_visit(_u, pos: Vector2i) -> void:
	visited[pos] = true
	if false:
		await battle.play_dialogue([])


## 我方单位每次行动结束后（撤离等判定之前）
func on_action_end(_u) -> void:
	if false:
		await battle.play_dialogue([])


func on_victory() -> void:
	if false:
		await battle.play_dialogue([])


func on_defeat() -> void:
	if false:
		await battle.play_dialogue([])


# ==================== 对话（我方两人相邻，各一次） ====================

## [[a_id, b_id, key], ...]
func talks() -> Array:
	return []


func talk_lines(_key: String) -> Array:
	return []


func on_talked(_key: String, _u, _partner) -> void:
	if false:
		await battle.play_dialogue([])


func get_talk_partner(u):
	for t in talks():
		var key: String = t[2]
		if flags.get("talk_" + key, false):
			continue
		var pid := ""
		if u.unit_id == t[0]:
			pid = t[1]
		elif u.unit_id == t[1]:
			pid = t[0]
		else:
			continue
		var p = battle.get_unit(pid)
		if p != null and p.is_alive() and p.is_player() and GameData.dist(u.grid_pos, p.grid_pos) == 1:
			return p
	return null


func on_talk(u) -> void:
	var p = get_talk_partner(u)
	if p == null:
		return
	for t in talks():
		if u.unit_id in [t[0], t[1]] and p.unit_id in [t[0], t[1]]:
			var key: String = t[2]
			flags["talk_" + key] = true
			await battle.play_dialogue(talk_lines(key))
			await on_talked(key, u, p)
			return


# ==================== 说得（我方走到敌人身边） ====================

## {敌方 unit_id: [可说得的我方 unit_id, ...]}
func recruits() -> Dictionary:
	return {}


func recruit_lines(_target_id: String, _by_id: String) -> Array:
	return []


func on_recruited(_t, _by) -> void:
	if false:
		await battle.play_dialogue([])


func get_recruit_target(u):
	var table := recruits()
	for rid in table:
		if not u.unit_id in table[rid]:
			continue
		var t = battle.get_unit(rid)
		if t != null and t.is_alive() and not t.is_player() and GameData.dist(u.grid_pos, t.grid_pos) == 1:
			return t
	return null


func on_recruit(u) -> void:
	var t = get_recruit_target(u)
	if t == null:
		return
	await battle.play_dialogue(recruit_lines(t.unit_id, u.unit_id))
	t.faction = "player"
	t.stationary = false
	t.has_acted = true
	t.queue_redraw()
	battle.notify(tr("%s 成为同伴了！") % tr(t.display_name))
	await on_recruited(t, u)


# ==================== 支援 ====================

func get_support_partner(u):
	var table := supports()
	for key in table:
		if f_support.get(key, false):
			continue
		var pair: Array = String(key).split("|")
		if u.unit_id not in pair:
			continue
		var pid: String = pair[1] if pair[0] == u.unit_id else pair[0]
		if u.support_with.has(pid):
			continue
		if battle.support_points.get(key, 0) < table[key]["points_to_c"]:
			continue
		var p = battle.get_unit(pid)
		if p != null and p.is_alive() and GameData.dist(u.grid_pos, p.grid_pos) == 1:
			return p
	return null


func on_support(u) -> void:
	var partner = get_support_partner(u)
	if partner == null:
		return
	var key := ""
	for k in supports():
		var pair: Array = String(k).split("|")
		if u.unit_id in pair and partner.unit_id in pair:
			key = k
	f_support[key] = true
	await battle.play_dialogue(support_lines(key))
	u.support_with[partner.unit_id] = "C"
	partner.support_with[u.unit_id] = "C"
	battle.notify(tr("%s 与 %s 的支援提升到 C！（相邻时 命中/回避 +5）") % [tr(u.display_name), tr(partner.display_name)])


func support_lines(key: String) -> Array:
	if key != "tia|balto":
		return []
	var c_tia := Color(1.0, 0.62, 0.45)
	var c_balto := Color(0.62, 0.78, 1.0)
	return [
		_l("缇娅", c_tia, "巴尔托，你说……我的亲生父母，到底是什么样的人？"),
		_l("巴尔托", c_balto, "……现在问这个做什么。"),
		_l("缇娅", c_tia, "那些山贼是冲我来的，对吧？你别当我傻。"),
		_l("巴尔托", c_balto, "…………等这阵风头过了，我会把一切都告诉你。"),
		_l("缇娅", c_tia, "哼，又拿这句话搪塞我。……算了，反正你答应我了，不许耍赖。"),
		_l("巴尔托", c_balto, "（叹气）……嗯，我答应你。"),
	]


# ==================== 存读 ====================

func export_flags() -> Dictionary:
	var visited_out: Array = []
	for k in visited:
		visited_out.append([int(k.x), int(k.y)])
	return {"visited": visited_out, "flags": flags.duplicate(true), "f_support": f_support.duplicate()}


func import_flags(data: Dictionary) -> void:
	visited = {}
	var raw = data.get("visited", [])
	if raw is Array:
		for pair in raw:
			if typeof(pair) == TYPE_ARRAY and pair.size() >= 2:
				visited[Vector2i(int(pair[0]), int(pair[1]))] = true
	var fl = data.get("flags", {})
	flags = fl.duplicate(true) if fl is Dictionary else {}
	var fs = data.get("f_support", {})
	f_support = fs.duplicate() if fs is Dictionary else {}


# ==================== 工具 ====================

func _l(n: String, c: Color, t: String) -> Dictionary:
	# 名字保留中文键，对话框显示时再 tr()，立绘表才能对上。
	return {"name": n, "color": c, "text": tr(t)}


## 合并模板：只写 id 和 pos 的单位按 id 前缀套模板；const 字典只读，逐键拷贝到新字典
static func expand_with(defs: Array, tmpls: Dictionary) -> Array:
	var out: Array = []
	for d in defs:
		var full := {}
		var id: String = d.get("id", "")
		var best := ""
		for prefix in tmpls:
			if id.begins_with(prefix) and String(prefix).length() > best.length():
				best = prefix
		if best != "":
			var tmpl: Dictionary = tmpls[best]
			for k in tmpl:
				full[k] = tmpl[k]
		for k in d:
			full[k] = d[k]
		out.append(full)
	return out
