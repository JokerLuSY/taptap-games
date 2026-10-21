class_name ChapterBase
extends RefCounted
## 章节脚本的公共底子：事件钩子的默认实现、胜负条件、对话 / 说得 / 支援的通用流程、旗标存读。
## 每章继承它，写自己的 MAP / LEVELS / UNITS / BG / CHAPTER_TITLE 等常量，再按需覆盖钩子。
## 钩子都可能被 battle `await`，所以默认实现也写成协程。

## 幕后角色的台词色（各章敌方视角的场景共用）
const CB_NARR := Color(0.82, 0.82, 0.88)
const CB_MORGAN := Color(0.85, 0.7, 1.0)
const CB_SILAS := Color(0.95, 0.92, 1.0)
const CB_VERA := Color(0.95, 0.6, 0.55)
const CB_GRAY := Color(0.75, 0.7, 0.68)
const CB_EDMUND := Color(0.7, 0.82, 1.0)
const CB_EDRIC := Color(0.55, 0.85, 1.0)
const CB_SEVEN := Color(0.7, 0.68, 0.72)
const CB_LANCE := Color(0.8, 0.9, 0.75)
const CB_ENEMY := Color(1.0, 0.55, 0.5)

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


## 章节胜利奖金（第一篇靠访问和宝箱；第二篇、第三篇收入不够武器损耗，补一笔）
func victory_gold() -> int:
	var n: int = battle.chapter_number() if battle != null else 0
	if n >= 23:
		return 2000
	if n >= 8:
		return 800
	return 0


## 剧情必需的第三方（绿色）友军：玩家整章没和他【对话】也要在胜利时归队写进名单，否则后面的章节会缺人
func must_join_on_victory() -> Array:
	return []


## 章节胜利后改名单状态：{unit_id: status}
func after_victory_status() -> Dictionary:
	return {}


# ==================== 出击准备（整备） ====================

## "" 不开整备；"pick" 只选人；"full" 选人 + 布阵 + 物品 + 商店
func prep_mode() -> String:
	return ""


## 本章出击上限
func deploy_limit() -> int:
	return 99


## 必须出击的单位（缺省 = 倒下就败北的那几位）
func forced_ids() -> Array:
	return lose_ids()


## 除开场站位外，额外能部署的格子
func extra_deploy_slots() -> Array:
	return []


## 出击准备里有没有竞技场（默认按 Arena.CHAPTERS 里的章节号）
func has_arena() -> bool:
	return battle != null and Arena.open_in(battle.chapter_number())


## 商店卖的东西
func shop_items() -> Array:
	return ["vulnerary", "iron_sword", "steel_sword", "iron_lance", "iron_axe", "iron_bow", "fire", "heal_staff"]


## 地图上的商店：{格子: [物品 id, ...]}。格子是 V（道具店）或 Y（武器店）
func shops() -> Dictionary:
	return {}


## 宝箱内容：{格子: 物品 id}。盗贼站上去开
func chests() -> Dictionary:
	return {}


## 撤离点等目标格（地图上金框标出）
func goal_tiles() -> Array:
	return []


## 目标格在地形窗里的说明（撤离点 / 祭坛 / 王座……）
func goal_label() -> String:
	return "撤离点"


## 胜利判定。默认：敌人全灭。
func is_won() -> bool:
	for u in battle.units:
		if not u.is_player() and not u.is_npc() and u.is_alive() and not u.get_meta("ally", false):
			return false
	return true


## 战斗特写背景的章节色调（白色 = 原色）。按章节 id 查，章节脚本也可以自己覆盖。
const COMBAT_TINTS := {
	"ch1": Color(1.0, 0.94, 0.86),      # 清晨
	"ch2": Color(0.86, 0.66, 0.6),      # 火场之夜
	"ch4": Color(0.64, 0.7, 0.92),      # 夜里，白色火把
	"ch5": Color(1.0, 0.82, 0.68),      # 黄昏的渡口
	"ch6": Color(0.78, 0.84, 1.0),      # 雪夜
}


func combat_tint() -> Color:
	return COMBAT_TINTS.get(chapter_id(), Color.WHITE)


func supports() -> Dictionary:
	return Supports.PAIRS


## 全篇最后一章：胜利后不再提示「后续章节制作中」
func is_final() -> bool:
	return false


func win_condition() -> String:
	return tr("击败所有敌人")


func lose_condition() -> String:
	return tr("缇娅或巴尔托阵亡")


# ==================== 事件钩子 ====================

func on_battle_start() -> void:
	if false:
		await battle.play_dialogue([])


## 开场：大陆地图 + 旁白。{"place": 地点 id, "from": 来处 id, "lines": [...]}；空字典 = 不放
func prologue() -> Dictionary:
	return {}


## 尾声：胜利后放的场景（敌方视角、远方的另一条线）。[{"title": 地点, "mood": 氛围, "lines": [...]}]
func epilogue() -> Array:
	return []


## 读档回到本章检查点后（地图已按 MAP 重建）：把剧情改过的地形等补回来
func on_resume() -> void:
	pass


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


## 打开了一扇牢门（battle.open_door 之后）
func on_door(_u, _pos: Vector2i) -> void:
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
	var back := Campaign.status_of(t.unit_id) == "away"
	if back:
		Campaign.set_status(t.unit_id, "active")
	t.stationary = false
	t.has_acted = true
	t.queue_redraw()
	battle.notify((tr("%s 回到了队伍！") if back else tr("%s 成为同伴了！")) % tr(t.display_name))
	battle._update_hover_info()
	await on_recruited(t, u)
	battle.refresh_talk_marks()


# ==================== 支援 ====================

## u 身边有能聊下一档支援的伙伴（点数够、本章这一对还没聊过）→ 返回伙伴
func get_support_partner(u):
	for key in supports():
		if f_support.get(key, false):
			continue
		var pair: Array = String(key).split("|")
		if u.unit_id not in pair:
			continue
		var pid: String = pair[1] if pair[0] == u.unit_id else pair[0]
		var nxt := Supports.next_rank(Supports.rank_of(u, pid))
		if nxt == "":
			continue
		if battle.support_points.get(key, 0) < Supports.need_points(key, nxt):
			continue
		var p = battle.get_unit(pid)
		if p != null and p.on_map() and p.is_player() and GameData.dist(u.grid_pos, p.grid_pos) == 1:
			return p
	return null


func on_support(u) -> void:
	var partner = get_support_partner(u)
	if partner == null:
		return
	var key := Supports.key_of(u.unit_id, partner.unit_id)
	var nxt := Supports.next_rank(Supports.rank_of(u, partner.unit_id))
	f_support[key] = true
	await battle.play_dialogue(Supports.lines(key, nxt))
	u.support_with[partner.unit_id] = nxt
	partner.support_with[u.unit_id] = nxt
	var b: Dictionary = Supports.BONUS[nxt]
	var extra := tr("，必杀 +%d") % b["crit"] if int(b["crit"]) > 0 else ""
	battle.notify(tr("%s 与 %s 的支援提升到 %s！（3 格内 命中/回避 +%d%s）") % [tr(u.display_name), tr(partner.display_name), nxt, b["hit"], extra])


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
