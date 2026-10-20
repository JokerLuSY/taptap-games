class_name Chapter16
extends ChapterBase
## 第十六章「地牢深处」：第二篇的高潮。黑石地牢里牢门（O）很多，只有盗贼（或带钥匙的人）能开；小雀不在时开场给 3 把钥匙。
## 西侧牢房关着埃德蒙的老骑士团长杰拉德，东侧牢房关着西里尔的老师艾薇：开门后谁走过去【对话】都能救出入队。
## 中央大厅里，莫尔甘最完美的傀儡「七号」初次登场：和缇娅交过手（且没被击杀），这一回合结束时就会撤退；不交手，第 8 回合也会撤走。
## 最深处是已被改造成灰烬傀儡的埃德蒙。胜利：击败埃德蒙。他身上带着从教会夺回的「月之镜」。

const CHAPTER_TITLE := "第十六章 · 地牢深处"
const VICTORY_TITLE := "第十六章 · 完"
const VICTORY_SUB := "黑石地牢的最深处，一盏灯，亮了一整夜。"
const DEFEAT_SUB := "地牢的门，又一次关上了。这一次，没有人再来推开它……"
const BG := ""

## 34×24。南边是地牢大门（我方进来的地方）和前厅；东西两条长走廊往北，两侧都是牢房（牢门 O）。
## 走廊在第 11 行往里通进中央大厅（七号守在这儿），大厅北面的窄道通到最深处的石室（埃德蒙，锁链 = 两座王座 K 当装饰）。
## 近路：前厅正北的两扇铁门直通大厅；东西两间看守室各有两扇门，开了能绕过大厅直接进最深处的石室。
## 牢房：西 (8,9) 杰拉德、东 (25,9) 艾薇、东 (31~32,8~10) 埃德蒙原来的牢房；四间牢房里有宝箱。
const MAP := [
	"##################################",
	"###########SSSSSKKSSSSS###########",
	"###########SISSSSSSSSIS###########",
	"#QS#SS#SSS#SSSSSSSSSSSS#SSS#SS#SQ#",
	"#SSOSSOSSSOSISSSSSSSSISOSSSOSSOSS#",
	"#SS#SS#SSS#SSSSSSSSSSSS#SSS#SS#SS#",
	"####SS##########SS##########SS####",
	"####SS##########SS##########SS####",
	"#SS#SS#SSS##SSSSSSSSSS##SSS#SS#SS#",
	"#SSOSSOSSS##SISSSSSSIS##SSSOSSOSS#",
	"#SS#SS######SSSSSSSSSS######SS#SS#",
	"####SSSSSSSSSSSISSISSSSSSSSSSS####",
	"####SS######SSSISSISSS######SS####",
	"#SS#SS#SSS##SSSSSSSSSS##SSS#SS#SS#",
	"#SSOSSOSSS##SISSSSSSIS##SSSOSSOSS#",
	"#SS#SS#SSQ##SSSSSSSSSS##QSS#SS#SS#",
	"####SS##########SS##########SS####",
	"####SS##########OO##########SS####",
	"####SSSSSSSSSSSSSSSSSSSSSSSSSS####",
	"####SS####SISSSSSSSSSSIS####SS####",
	"####SSSSSSSSSSSSSSSSSSSSSSSSSS####",
	"####SSSSSSSISSSSSSSSSSISSSSSSS####",
	"##########SSSSSSSSSSSSSS##########",
	"################GG################",
]

const LEVELS := []                # 全图同一高度

const CHESTS := {Vector2i(1, 3): "sage_crest", Vector2i(9, 15): "elixir", Vector2i(32, 3): "hero_crest", Vector2i(24, 15): "killer_lance"}
const DOOR_EDMUND_CELL := Vector2i(30, 9)    # 埃德蒙原来的牢房（空的，墙上刻着字）
const DOOR_GERARD := Vector2i(6, 9)
const DOOR_IVY := Vector2i(27, 9)
const SEVEN_LEAVES := 8           # 七号没和缇娅交手：第 8 回合开始撤走
const RESCUE := ["gerard", "ivy"]

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_TIA := Color(1.0, 0.62, 0.45)
const C_GARETH := Color(0.95, 0.8, 0.45)
const C_SPARROW := Color(0.95, 0.85, 0.45)
const C_VICTOR := Color(0.75, 0.65, 0.95)
const C_CYRIL := Color(1.0, 0.72, 0.42)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_LANCE := Color(0.8, 0.9, 0.75)
const C_OSCAR := Color(0.8, 0.82, 0.9)
const C_GERARD := Color(0.75, 0.8, 0.95)
const C_IVY := Color(1.0, 0.8, 0.6)
const C_SEVEN := Color(0.7, 0.68, 0.72)
const C_EDMUND := Color(0.7, 0.82, 1.0)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_NARR := Color(0.82, 0.82, 0.88)

const _PUPPET := {"name": "灰烬傀儡", "class": "灰烬傀儡", "faction": "enemy", "level": 15,
	"hp": 38, "pwr": 14, "skl": 11, "spd": 9, "dfn": 14, "res": 5, "mov": 4,
	"weapons": ["ash_claw"], "color": Color(0.42, 0.40, 0.44),
	"hair": "hood", "armor": Color(0.38, 0.36, 0.40)}
const _SOLDIER := {"name": "地牢守卫", "class": "枪兵", "faction": "enemy", "level": 14,
	"hp": 33, "pwr": 12, "skl": 11, "spd": 11, "dfn": 10, "res": 4, "mov": 5,
	"weapons": ["steel_lance", "javelin"], "color": Color(0.55, 0.52, 0.50),
	"hair": "short", "hair_color": Color(0.30, 0.26, 0.22), "armor": Color(0.50, 0.48, 0.46)}
const _ARMOR := {"name": "地牢狱卒", "class": "重甲兵", "faction": "enemy", "level": 15,
	"hp": 38, "pwr": 15, "skl": 9, "spd": 5, "dfn": 17, "res": 4, "mov": 4,
	"weapons": ["steel_lance"], "color": Color(0.50, 0.48, 0.46),
	"hair": "short", "hair_color": Color(0.22, 0.20, 0.18), "armor": Color(0.46, 0.44, 0.42)}
const _ARCHER := {"name": "地牢弓兵", "class": "弓箭手", "faction": "enemy", "level": 14,
	"hp": 30, "pwr": 12, "skl": 14, "spd": 12, "dfn": 6, "res": 5, "mov": 5,
	"weapons": ["steel_bow"], "color": Color(0.58, 0.54, 0.48),
	"hair": "hood", "armor": Color(0.54, 0.50, 0.44)}
const _DARK := {"name": "灰烬术士", "class": "暗法师", "faction": "enemy", "level": 15,
	"hp": 30, "pwr": 14, "skl": 10, "spd": 10, "dfn": 6, "res": 12, "mov": 5,
	"weapons": ["flux"], "color": Color(0.36, 0.32, 0.42),
	"hair": "hood", "armor": Color(0.32, 0.28, 0.38)}
const _MAGE := {"name": "教会魔道士", "class": "魔道士", "faction": "enemy", "level": 14,
	"hp": 27, "pwr": 13, "skl": 11, "spd": 11, "dfn": 5, "res": 11, "mov": 5,
	"weapons": ["elfire"], "color": Color(0.92, 0.88, 0.78),
	"hair": "hood", "armor": Color(0.90, 0.86, 0.74)}
const _CLERIC := {"name": "地牢修女", "class": "修女", "faction": "enemy", "level": 14,
	"hp": 26, "pwr": 12, "skl": 10, "spd": 12, "dfn": 4, "res": 13, "mov": 5,
	"weapons": ["mend_staff"], "items": ["vulnerary"], "color": Color(0.86, 0.84, 0.80),
	"hair": "hood", "armor": Color(0.82, 0.80, 0.76)}
const _GRAY := {"name": "灰袍众", "class": "探子", "faction": "enemy", "level": 15,
	"hp": 31, "pwr": 12, "skl": 16, "spd": 17, "dfn": 7, "res": 6, "mov": 6,
	"weapons": ["steel_sword"], "color": Color(0.52, 0.52, 0.56),
	"hair": "hood", "armor": Color(0.46, 0.46, 0.50)}

const UNITS := [
	# 我方：地牢前厅（名单为空直接开打时用这些数值）
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 16,
		"hp": 34, "pwr": 14, "skl": 17, "spd": 17, "dfn": 11, "res": 7, "mov": 5,
		"weapons": ["rapier"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(16, 20), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "tia", "name": "缇娅", "class": "炎刃使", "faction": "player", "level": 10,
		"hp": 39, "pwr": 16, "skl": 18, "spd": 20, "dfn": 11, "res": 6, "mov": 5,
		"weapons": ["ember_blade", "iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35, "res": 30},
		"pos": Vector2i(17, 20), "color": Color(0.95, 0.40, 0.22),
		"hair": "ponytail", "hair_color": Color(1.0, 0.42, 0.12), "armor": Color(0.72, 0.28, 0.16)},
	{"id": "gareth", "name": "加雷斯", "class": "王子", "faction": "player", "level": 12,
		"hp": 36, "pwr": 14, "skl": 10, "spd": 9, "dfn": 13, "res": 3, "mov": 5,
		"weapons": ["wolf_axe", "hand_axe"], "items": ["vulnerary"],
		"growths": {"hp": 90, "pwr": 60, "skl": 40, "spd": 30, "dfn": 45, "res": 20},
		"pos": Vector2i(15, 20), "color": Color(0.75, 0.55, 0.30),
		"hair": "spiky", "hair_color": Color(0.62, 0.38, 0.18), "armor": Color(0.55, 0.42, 0.30)},
	{"id": "sparrow", "pos": Vector2i(18, 20), "name": "小雀", "class": "盗贼", "faction": "player", "level": 13,
		"hp": 27, "pwr": 9, "skl": 15, "spd": 19, "dfn": 6, "res": 6, "mov": 6, "weapons": ["iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 50, "pwr": 30, "skl": 50, "spd": 65, "dfn": 15, "res": 25}},
	{"id": "noya", "pos": Vector2i(16, 21), "name": "诺雅", "class": "修女", "faction": "player", "level": 14,
		"hp": 27, "pwr": 13, "skl": 10, "spd": 14, "dfn": 5, "res": 14, "mov": 5, "weapons": ["heal_staff", "mend_staff"],
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15, "res": 45}},
	{"id": "victor", "pos": Vector2i(17, 21), "name": "维克多", "class": "暗法师", "faction": "player", "level": 15,
		"hp": 30, "pwr": 14, "skl": 11, "spd": 10, "dfn": 7, "res": 13, "mov": 5, "weapons": ["flux"],
		"growths": {"hp": 55, "pwr": 50, "skl": 40, "spd": 35, "dfn": 25, "res": 45}},
	{"id": "kain", "pos": Vector2i(15, 21), "name": "凯因", "class": "佣兵", "faction": "player", "level": 16,
		"hp": 36, "pwr": 14, "skl": 18, "spd": 19, "dfn": 9, "res": 5, "mov": 5, "weapons": ["steel_sword", "iron_sword"],
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25, "res": 20}},
	{"id": "cyril", "pos": Vector2i(18, 21), "name": "西里尔", "class": "魔道士", "faction": "player", "level": 13,
		"hp": 29, "pwr": 14, "skl": 12, "spd": 13, "dfn": 6, "res": 12, "mov": 5, "weapons": ["fire", "thunder"],
		"growths": {"hp": 50, "pwr": 55, "skl": 45, "spd": 50, "dfn": 15, "res": 45}},
	{"id": "liss", "pos": Vector2i(14, 21), "name": "莉丝", "class": "弓箭手", "faction": "player", "level": 13,
		"hp": 29, "pwr": 12, "skl": 15, "spd": 14, "dfn": 6, "res": 5, "mov": 5, "weapons": ["steel_bow", "iron_bow"],
		"growths": {"hp": 60, "pwr": 40, "skl": 55, "spd": 50, "dfn": 20, "res": 30}},
	{"id": "hagen", "pos": Vector2i(19, 21), "name": "哈根", "class": "战士", "faction": "player", "level": 13,
		"hp": 40, "pwr": 15, "skl": 10, "spd": 10, "dfn": 9, "res": 2, "mov": 5, "weapons": ["steel_axe", "hand_axe"],
		"growths": {"hp": 80, "pwr": 50, "skl": 35, "spd": 30, "dfn": 30, "res": 10}},
	# 牢房里的人（中立）：开门后谁走过去【对话】都能救出
	{"id": "gerard", "name": "杰拉德", "class": "骑士", "faction": "npc", "level": 14,
		"hp": 36, "pwr": 13, "skl": 11, "spd": 10, "dfn": 12, "res": 4, "mov": 7,
		"weapons": ["steel_lance", "javelin"],
		"growths": {"hp": 60, "pwr": 35, "skl": 35, "spd": 30, "dfn": 30, "res": 15},
		"pos": Vector2i(8, 9), "color": Color(0.55, 0.58, 0.70),
		"hair": "short", "hair_color": Color(0.78, 0.78, 0.80), "armor": Color(0.58, 0.60, 0.70), "scar": true},
	{"id": "ivy", "name": "艾薇", "class": "魔道士", "faction": "npc", "level": 14,
		"hp": 27, "pwr": 13, "skl": 12, "spd": 11, "dfn": 5, "res": 12, "mov": 5,
		"weapons": ["elfire", "thunder"], "wexp": {"anima": 71},
		"growths": {"hp": 45, "pwr": 50, "skl": 45, "spd": 45, "dfn": 15, "res": 50},
		"pos": Vector2i(25, 9), "color": Color(0.62, 0.36, 0.30),
		"hair": "hood", "hair_color": Color(0.85, 0.85, 0.88), "armor": Color(0.58, 0.34, 0.28)},
	# 敌方：前厅两侧、东西走廊
	{"id": "graycloak1", "pos": Vector2i(6, 18), "hold": true},
	{"id": "graycloak2", "pos": Vector2i(27, 18), "hold": true, "items": ["door_key"]},
	{"id": "soldier1", "pos": Vector2i(4, 15), "hold": true},
	{"id": "puppet1", "pos": Vector2i(5, 9)},
	{"id": "archer1", "pos": Vector2i(4, 4), "hold": true},
	{"id": "darkmage1", "pos": Vector2i(8, 4), "hold": true},
	{"id": "soldier2", "pos": Vector2i(29, 15), "hold": true},
	{"id": "puppet2", "pos": Vector2i(28, 9)},
	{"id": "archer2", "pos": Vector2i(29, 4), "hold": true},
	{"id": "mage1", "pos": Vector2i(25, 4), "hold": true, "items": ["vulnerary"]},
	# 中央大厅
	{"id": "puppet3", "pos": Vector2i(13, 11), "hold": true},
	{"id": "puppet4", "pos": Vector2i(20, 11), "hold": true},
	{"id": "darkmage2", "pos": Vector2i(14, 14), "hold": true},
	{"id": "cleric1", "pos": Vector2i(19, 14)},
	# 七号：莫尔甘最完美的傀儡。我方进入威胁范围前不动
	{"id": "seven", "name": "七号", "class": "灰烬傀儡", "faction": "enemy", "level": 18,
		"hp": 45, "pwr": 16, "skl": 18, "spd": 20, "dfn": 10, "res": 8, "mov": 6,
		"weapons": ["ash_claw"], "boss": true, "hold": true,
		"pos": Vector2i(16, 9), "color": Color(0.30, 0.28, 0.34),
		"hair": "hood", "hair_color": Color(0.20, 0.20, 0.22), "armor": Color(0.26, 0.24, 0.30)},
	# 最深处的石室
	{"id": "armor1", "pos": Vector2i(17, 7), "hold": true},
	{"id": "puppet5", "pos": Vector2i(13, 3), "hold": true},
	{"id": "darkmage3", "pos": Vector2i(20, 3), "hold": true},
	# 埃德蒙：被改造成灰烬傀儡的菲恩领主。站在锁链前不动
	{"id": "edmund", "name": "埃德蒙", "class": "圣骑士", "faction": "enemy", "level": 8,
		"hp": 50, "pwr": 17, "skl": 16, "spd": 14, "dfn": 14, "res": 8, "mov": 8,
		"weapons": ["silver_lance"], "boss": true, "stationary": true,
		"pos": Vector2i(16, 3), "color": Color(0.36, 0.40, 0.52),
		"hair": "short", "hair_color": Color(0.55, 0.58, 0.66), "armor": Color(0.40, 0.42, 0.50)},
]

## 增援：3 走廊北头又放出两具傀儡；5 灰袍众从地牢大门追进来
const WAVES := {
	3: [{"id": "puppet_r1", "pos": Vector2i(4, 3)}, {"id": "puppet_r2", "pos": Vector2i(29, 3)}],
	5: [{"id": "graycloak_r1", "pos": Vector2i(16, 22)}, {"id": "graycloak_r2", "pos": Vector2i(17, 22)}, {"id": "soldier_r1", "pos": Vector2i(15, 22)}],
}


func chapter_id() -> String:
	return "ch16"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 8


func extra_deploy_slots() -> Array:
	return [Vector2i(13, 21), Vector2i(20, 21), Vector2i(14, 22), Vector2i(19, 22), Vector2i(14, 20), Vector2i(19, 20)]


func templates() -> Dictionary:
	return {"puppet": _PUPPET, "soldier": _SOLDIER, "armor": _ARMOR, "archer": _ARCHER, "darkmage": _DARK,
		"mage": _MAGE, "cleric": _CLERIC, "graycloak": _GRAY}


## 三主角（名单里没有加雷斯时不算）
func lose_ids() -> Array:
	var out := ["edric", "tia"]
	if battle != null and battle.get_unit("gareth") != null and battle.get_unit("gareth").is_player():
		out.append("gareth")
	return out


func extra_slots() -> Array:
	return [Vector2i(13, 21), Vector2i(20, 21), Vector2i(14, 22), Vector2i(19, 22), Vector2i(14, 20), Vector2i(19, 20),
		Vector2i(13, 20), Vector2i(20, 20), Vector2i(15, 22), Vector2i(18, 22), Vector2i(13, 22), Vector2i(20, 22),
		Vector2i(12, 20), Vector2i(21, 20), Vector2i(12, 22), Vector2i(21, 22), Vector2i(16, 22), Vector2i(17, 22),
		Vector2i(12, 21), Vector2i(21, 21)]


func chests() -> Dictionary:
	return CHESTS


func shop_items() -> Array:
	return ["vulnerary", "elixir", "door_key", "steel_sword", "armorslayer", "steel_lance", "steel_axe", "steel_bow", "elfire", "flux", "mend_staff"]


func is_won() -> bool:
	var e = battle.get_unit("edmund")
	return e != null and not e.is_alive()


func win_condition() -> String:
	return tr("击败埃德蒙")


func lose_condition() -> String:
	if battle != null and lose_ids().has("gareth"):
		return tr("艾德里克、缇娅或加雷斯阵亡")
	return tr("艾德里克或缇娅阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	# 小雀没出击：开场把 3 把钥匙交给艾德里克（整备之后，按实际出击的人判断）
	if t == 1 and not flags.get("keys_given", false):
		flags["keys_given"] = true
		if not _here("sparrow"):
			var e = battle.get_unit("edric")
			if e != null:
				for i in 3:
					e.receive("door_key")
			await battle.play_dialogue(_keys())
			battle.notify(tr("艾德里克 得到了 3 把钥匙"))
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
		if t == 5:
			await battle.play_dialogue(_wave5())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())
	# 七号：和缇娅交过手 → 这一回合结束时撤退；一直没交手 → 第 8 回合撤走
	if _seven_on_map():
		if flags.get("seven_met_tia", false):
			await _seven_retreat(true)
		elif t >= SEVEN_LEAVES:
			await _seven_retreat(false)


## 我方回合的最后一个人行动完：七号这回合和缇娅交过手，就在敌方回合之前撤走
func on_action_end(_u) -> void:
	if not _seven_on_map() or not flags.get("seven_met_tia", false):
		return
	for v in battle.units:
		if v.is_player() and v.on_map() and not v.has_acted:
			return
	await _seven_retreat(true)


func _seven_on_map() -> bool:
	var s = battle.get_unit("seven")
	return s != null and s.is_alive() and s.visible


func _seven_retreat(spared: bool) -> void:
	var s = battle.get_unit("seven")
	if s == null:
		return
	await battle.play_dialogue(_seven_leaves_tia() if spared else _seven_leaves())
	flags["seven_gone"] = true
	Campaign.flags["seven_16_spared"] = spared
	battle.units.erase(s)
	s.queue_free()
	battle.notify(tr("七号撤退了"))
	battle._update_hover_info()


func on_before_combat(att, def) -> void:
	var ids := [att.unit_id, def.unit_id]
	if "seven" in ids:
		if "tia" in ids and not flags.get("seven_tia_talk", false):
			flags["seven_tia_talk"] = true
			await battle.play_dialogue(_seven_tia())
		elif not flags.get("seven_talk", false):
			flags["seven_talk"] = true
			await battle.play_dialogue(_seven_first())
	if "edmund" in ids:
		var other = def if att.unit_id == "edmund" else att
		if other.unit_id == "edric" and not flags.get("edmund_edric", false):
			flags["edmund_edric"] = true
			await battle.play_dialogue(_edmund_edric())
		elif other.unit_id == "gerard" and not flags.get("edmund_gerard", false):
			flags["edmund_gerard"] = true
			await battle.play_dialogue(_edmund_gerard())
		elif not flags.get("edmund_talk", false):
			flags["edmund_talk"] = true
			await battle.play_dialogue(_edmund_first())


func on_after_combat(att, def, def_died: bool) -> void:
	var ids := [att.unit_id, def.unit_id]
	if "seven" in ids and "tia" in ids:
		var s = battle.get_unit("seven")
		if s != null and s.is_alive():
			flags["seven_met_tia"] = true
	if def.unit_id == "seven" and def_died:
		flags["seven_killed"] = true
		flags["seven_gone"] = true
		Campaign.flags["seven_16_spared"] = false
		await battle.play_dialogue(_seven_falls())
	if def.unit_id == "edmund" and def_died:
		await battle.play_dialogue(_edmund_death())
		# 七号在演出里出手后离开（还在地图上的话）
		var s7 = battle.get_unit("seven")
		if s7 != null and s7.is_alive():
			if flags.get("seven_met_tia", false):
				Campaign.flags["seven_16_spared"] = true
			flags["seven_gone"] = true
			battle.units.erase(s7)
			s7.visible = false
			s7.queue_free()


func on_door(_u, pos: Vector2i) -> void:
	if pos == DOOR_GERARD and _npc("gerard"):
		await battle.play_dialogue(_gerard_door())
		battle.hint(tr("走到杰拉德身边【对话】，救他出来"))
	elif pos == DOOR_IVY and _npc("ivy"):
		await battle.play_dialogue(_ivy_door())
		battle.hint(tr("走到艾薇身边【对话】，救她出来"))
	elif pos == DOOR_EDMUND_CELL and not flags.get("edmund_cell", false):
		flags["edmund_cell"] = true
		await battle.play_dialogue(_edmund_cell())


## 杰拉德、艾薇：开了牢门，谁走过去都能【对话】（整备界面不提示「需要谁出击」）
func recruits() -> Dictionary:
	if battle == null or battle.state == battle.S.PREP:
		return {}
	var ids := _player_ids()
	return {"gerard": ids, "ivy": ids}


func recruit_lines(target_id: String, by_id: String) -> Array:
	if target_id == "gerard":
		return _gerard_recruit(by_id)
	return _ivy_recruit(by_id)


func on_recruited(t, _by) -> void:
	t.stationary = false
	t.hold = false


func talks() -> Array:
	return [["cyril", "ivy", "cyril_ivy"], ["edric", "gerard", "edric_gerard"]]


func talk_lines(key: String) -> Array:
	if key == "cyril_ivy":
		return [
			_l("西里尔", C_CYRIL, "……老师。"),
			_l("艾薇", C_IVY, "西里尔。你这孩子，背着那几本破书跑了半个大陆，还是跑到牢里来了。"),
			_l("西里尔", C_CYRIL, "是您教我的：「火种藏不住的时候，就把它交给会走路的人。」"),
			_l("艾薇", C_IVY, "那你交出去了吗？"),
			_l("西里尔", C_CYRIL, "交出去了。交给了一个身上本来就有火的姑娘。"),
			_l("艾薇", C_IVY, "……好。那老婆子这把骨头，也陪你们烧到最后吧。"),
		]
	return [
		_l("杰拉德", C_GERARD, "少主。……您长高了。上一次见您，您还够不着马镫。"),
		_l("艾德里克", C_EDRIC, "杰拉德。父亲出发去调查圣器的时候，你也在吗？"),
		_l("杰拉德", C_GERARD, "在。领主大人只带了我和十个骑士。在圣都郊外，我们被灰袍众伏击了。"),
		_l("杰拉德", C_GERARD, "领主大人让我们先走，他一个人断后。……是我没用，连他被带到哪儿都没能查清，自己也被抓了进来。"),
		_l("艾德里克", C_EDRIC, "不，你活下来了。……父亲一定也希望你活着。"),
		_l("杰拉德", C_GERARD, "少主……这条命，从今天起是您的。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	var relics: Array = []
	var raw = Campaign.flags.get("relics", [])
	if raw is Array:
		relics = raw.duplicate()
	if not "moon_mirror" in relics:
		relics.append("moon_mirror")
	Campaign.flags["relics"] = relics
	Campaign.flags["edmund_dead"] = true
	# 七号：交过手且没被击杀才算「放过」
	Campaign.flags["seven_16_spared"] = flags.get("seven_met_tia", false) and not flags.get("seven_killed", false)


func on_defeat() -> void:
	var g = battle.get_unit("gareth")
	if g != null and g.is_player() and not g.is_alive():
		await battle.play_dialogue(_defeat_gareth())
		return
	var e = battle.get_unit("edric")
	if e != null and not e.is_alive():
		await battle.play_dialogue(_defeat_edric())
	else:
		await battle.play_dialogue(_defeat_tia())


# ==================== 工具 ====================

func _here(id: String) -> bool:
	var u = battle.get_unit(id)
	return u != null and u.is_alive() and u.is_player()


func _npc(id: String) -> bool:
	var u = battle.get_unit(id)
	return u != null and u.is_alive() and u.is_npc()


func _player_ids() -> Array:
	var out: Array = []
	for u in battle.units:
		if u.is_player() and u.is_alive():
			out.append(u.unit_id)
	return out


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "黑石地牢。整座建筑是从一块黑色的山岩里凿出来的，连火把的光都像是被石头吃掉了。"),
		_l("", C_NARR, "门洞里吹出来的风，带着一股烧过的灰的味道。"),
		_l("加雷斯", C_GARETH, "……这味道。跟圣都地底下一样。"),
	]
	if _here("sparrow"):
		lines.append(_l("小雀", C_SPARROW, "里面全是牢门。……门交给我，你们管打架。"))
	if _here("victor"):
		lines.append(_l("维克多", C_VICTOR, "这里是教会最早的「培养所」。我在研究所的档案里见过它的名字——比圣都那间大得多。"))
	lines.append(_l("艾德里克", C_EDRIC, "父亲在最深处。……我能感觉到。"))
	lines.append(_l("缇娅", C_TIA, "牢房里还关着别的人。能救的，我们都救。"))
	lines.append(_l("", C_NARR, "地牢深处，传来锁链拖过石板的声音。"))
	return lines


func _keys() -> Array:
	if Campaign.alive_in_story("sparrow"):
		return [
			_l("艾德里克", C_EDRIC, "小雀不在。……出发前，她塞给我三把钥匙。"),
			_l("艾德里克", C_EDRIC, "「地牢的锁跟圣都的是一个铁匠打的，这三把够你用了。」——她是这么说的。"),
		]
	return [
		_l("加雷斯", C_GARETH, "没有会开锁的人？……拿着。布罗登的密探从地牢的狱卒那儿弄来的，三把。"),
		_l("艾德里克", C_EDRIC, "……谢谢。省着用。"),
	]


func _turn2_hint() -> Array:
	var lines: Array = []
	if _here("sparrow"):
		lines.append(_l("小雀", C_SPARROW, "牢门站旁边就能【开门】。西边、东边的牢房里好像都关着人——还有箱子！"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "带钥匙的人站到牢门旁边就能【开门】。西边、东边的牢房里，好像还关着人。"))
	lines.append(_l("缇娅", C_TIA, "开了门，走到里面的人身边【对话】，就能带他们走。谁去都行。"))
	return lines


func _wave5() -> Array:
	return [
		_l("灰袍众", C_ENEMY, "大门已经封死了！一个也别想从地牢里出去！"),
		_l("加雷斯", C_GARETH, "退路没了？正好。本来也没打算往回走！"),
	]


func _seven_first() -> Array:
	return [
		_l("七号", C_SEVEN, "……"),
		_l("", C_NARR, "戴着面具的人一句话也没说。他的指尖上，灰烬凝成了爪子。"),
	]


func _seven_tia() -> Array:
	return [
		_l("七号", C_SEVEN, "……"),
		_l("缇娅", C_TIA, "你……是什么人？你身上的味道，和那些傀儡一样，可又不一样。"),
		_l("七号", C_SEVEN, "……火。"),
		_l("缇娅", C_TIA, "什么？"),
		_l("七号", C_SEVEN, "……你身上的，是火。……命令：排除。"),
	]


func _seven_leaves_tia() -> Array:
	return [
		_l("七号", C_SEVEN, "……这团火，是什么？"),
		_l("缇娅", C_TIA, "你……在问我？"),
		_l("七号", C_SEVEN, "……"),
		_l("", C_NARR, "面具人后退一步，像被什么东西烫到了似的，消失在了地牢的阴影里。"),
	]


func _seven_leaves() -> Array:
	return [
		_l("七号", C_SEVEN, "……时间到了。"),
		_l("", C_NARR, "面具人转过身，消失在了地牢的阴影里。"),
	]


func _seven_falls() -> Array:
	return [
		_l("七号", C_SEVEN, "……"),
		_l("", C_NARR, "面具人的身体碎成了一地灰。……可那堆灰，还在微微地动。"),
	]


func _gerard_door() -> Array:
	return [
		_l("杰拉德", C_GERARD, "……门开了？这铁门，三个月没开过了。"),
	]


func _ivy_door() -> Array:
	return [
		_l("艾薇", C_IVY, "哟，来的不是狱卒。……年轻人，老婆子腿麻了，过来扶一把？"),
	]


func _gerard_recruit(by_id: String) -> Array:
	var lines: Array = []
	if by_id == "edric":
		lines.append(_l("杰拉德", C_GERARD, "那把细剑……少主？！艾德里克少主！"))
		lines.append(_l("艾德里克", C_EDRIC, "杰拉德！父亲的骑士团长……你还活着！"))
	else:
		lines.append(_l("杰拉德", C_GERARD, "你们是……不是教会的人。菲恩家的纹章？少主也来了吗？"))
	lines.append(_l("杰拉德", C_GERARD, "我是杰拉德，埃德蒙大人的骑士团长。……领主大人，就在这座地牢的最深处。"))
	lines.append(_l("杰拉德", C_GERARD, "每天夜里，我都听见锁链的声音。还有……领主大人的声音。可那声音，说的都不是人话。"))
	lines.append(_l("杰拉德", C_GERARD, "给我一杆枪。我要亲眼去看。"))
	return lines


func _ivy_recruit(by_id: String) -> Array:
	var lines: Array = []
	if by_id == "cyril":
		lines.append(_l("艾薇", C_IVY, "……西里尔？你这孩子，怎么跑到这种地方来了！"))
		lines.append(_l("西里尔", C_CYRIL, "老师！您说过您要去南边的……原来是被关在这里！"))
	else:
		lines.append(_l("艾薇", C_IVY, "你们是来救人的？……这年头，还有人往地牢里跑，真稀奇。"))
	lines.append(_l("艾薇", C_IVY, "老婆子叫艾薇，教了一辈子不该教的魔法。教会说我「私藏火种」——没说错，我藏了一辈子。"))
	lines.append(_l("艾薇", C_IVY, "这地牢里干的事，我听了三个月。……我老了，可我的火还没灭。带上我。"))
	return lines


func _edmund_cell() -> Array:
	return [
		_l("", C_NARR, "空荡荡的牢房。石墙上，有人用指甲刻下了一行字。"),
		_l("艾德里克", C_EDRIC, "……是父亲的字。"),
		_l("", C_NARR, "「艾德里克，不要来。」"),
		_l("", C_NARR, "字的下面，还有一行，刻得歪歪扭扭，像是刻字的人已经快握不住手了——"),
		_l("", C_NARR, "「……可如果你来了，替我照顾好那个孩子。」"),
	]


func _edmund_first() -> Array:
	return [
		_l("埃德蒙", C_EDMUND, "……入侵者。……排除。"),
		_l("", C_NARR, "那人的银枪上，缠着灰色的余烬。动作和骑士一模一样——只是没有一点犹豫。"),
	]


func _edmund_edric() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "父亲！是我，艾德里克！"),
		_l("埃德蒙", C_EDMUND, "……入侵者。……排除。"),
		_l("艾德里克", C_EDRIC, "您教我握剑的时候说过：骑士的剑，是用来守护的。……您现在，在守护什么？！"),
		_l("埃德蒙", C_EDMUND, "……守……护……"),
		_l("埃德蒙", C_EDMUND, "……艾……德……"),
		_l("", C_NARR, "银枪顿了一下。下一瞬间，灰烬又一次吞没了那双眼睛。"),
		_l("埃德蒙", C_EDMUND, "……排除。"),
		_l("艾德里克", C_EDRIC, "……好。那就由我来——把您从这里带出去！"),
	]


func _edmund_gerard() -> Array:
	return [
		_l("杰拉德", C_GERARD, "领主大人！是我，杰拉德！您不记得了吗？！"),
		_l("埃德蒙", C_EDMUND, "……入侵者。"),
		_l("杰拉德", C_GERARD, "……对不起，领主大人。这一枪，是骑士团长替您挡的最后一枪。"),
	]


func _edmund_death() -> Array:
	var lines: Array = [
		_l("", C_NARR, "银枪落地。埃德蒙单膝跪倒，身上的灰烬像雪一样往下落。"),
		_l("艾德里克", C_EDRIC, "父亲！"),
	]
	if flags.get("seven_killed", false):
		lines.append(_l("", C_NARR, "就在这时，地上那堆灰烬忽然重新聚拢——碎掉的面具人，又站了起来。"))
	elif flags.get("seven_gone", false):
		lines.append(_l("", C_NARR, "就在这时，石室的阴影里，那个撤走的面具人又出现了。"))
	else:
		lines.append(_l("", C_NARR, "就在这时，七号动了。快得连影子都跟不上。"))
	lines.append(_l("七号", C_SEVEN, "……命令：排除菲恩家的继承人。"))
	lines.append(_l("", C_NARR, "灰烬之爪刺向艾德里克的胸口——"))
	lines.append(_l("", C_NARR, "——被一只手挡住了。"))
	lines.append(_l("埃德蒙", C_EDMUND, "……别碰……我的儿子。"))
	lines.append(_l("七号", C_SEVEN, "……！"))
	lines.append(_l("", C_NARR, "爪子穿过了埃德蒙的胸膛。面具人怔了一瞬，抽回手，退进了黑暗里。"))
	lines.append(_l("艾德里克", C_EDRIC, "父亲……父亲！您认得我了？！"))
	lines.append(_l("埃德蒙", C_EDMUND, "艾德里克……长大了啊。……听好，我没有……多少时间了。"))
	lines.append(_l("埃德蒙", C_EDMUND, "八百年前……失控的不是巫女……是初代大司祭。"))
	lines.append(_l("埃德蒙", C_EDMUND, "教会……篡改了历史。圣器……不是用来封印火的……"))
	if _here("tia"):
		lines.append(_l("埃德蒙", C_EDMUND, "那孩子……红头发的那孩子……她的血，是钥匙……也是锁……"))
	else:
		lines.append(_l("埃德蒙", C_EDMUND, "巫女的……那孩子的血，是钥匙……也是锁……"))
	lines.append(_l("埃德蒙", C_EDMUND, "月之镜……在我身上……别让……他们……"))
	lines.append(_l("艾德里克", C_EDRIC, "父亲？……父亲！"))
	lines.append(_l("", C_NARR, "埃德蒙的手垂了下去。灰烬从他身上散尽了。留下的，是一张安静的、终于像他自己的脸。"))
	return lines


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "地牢里安静下来了。只剩下火把燃烧的声音。"),
		_l("", C_NARR, "艾德里克跪在父亲身边，很久没有动。"),
		_l("缇娅", C_TIA, "……艾德里克。"),
		_l("艾德里克", C_EDRIC, "他最后……认出我了。缇娅，他认出我了。"),
		_l("缇娅", C_TIA, "嗯。……他挡在你前面的时候，一点都不像傀儡。是父亲的样子。"),
		_l("", C_NARR, "缇娅在他身边坐下。没有再说话，只是把手放在他的肩上。"),
	]
	if _here("gerard"):
		lines.append(_l("杰拉德", C_GERARD, "领主大人……骑士团长杰拉德，送您最后一程。"))
	if _here("victor"):
		lines.append(_l("维克多", C_VICTOR, "「失控的不是巫女，是初代大司祭」……「她的血，是钥匙，也是锁」……"))
		lines.append(_l("维克多", C_VICTOR, "埃德蒙大人用最后一口气，把他查到的东西交给了我们。……我会把这些话一个字一个字地记下来。"))
	elif _here("cyril"):
		lines.append(_l("西里尔", C_CYRIL, "「教会篡改了历史」……我在大书库看到的那页被刮掉的字，就是这个。"))
	if _here("gareth"):
		lines.append(_l("加雷斯", C_GARETH, "……艾德里克。我说过，你推门的时候，我会站在你旁边。……我还在。"))
	lines.append(_l("", C_NARR, "埃德蒙的怀里，一面巴掌大的银镜，映着火把的光。"))
	lines.append(_l("艾德里克", C_EDRIC, "月之镜……教会偷走的圣器。父亲把它夺回来了，一直藏在身上。"))
	lines.append(_l("艾德里克", C_EDRIC, "……我会把剩下的事做完。父亲没走完的路，我替他走完。"))
	return lines


func _defeat_edric() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "父亲……对不起……我……没能带您……回家……"),
		_l("", C_NARR, "黑石地牢的锁链，又多锁住了一个人。"),
	]


func _defeat_tia() -> Array:
	return [
		_l("缇娅", C_TIA, "火……被……灰……"),
		_l("", C_NARR, "火光熄灭了。地牢里，只剩下灰。"),
	]


func _defeat_gareth() -> Array:
	return [
		_l("加雷斯", C_GARETH, "艾德里克……别回头……往前……"),
		_l("", C_NARR, "布罗登的苍狼倒在了地牢冰冷的石板上。"),
	]


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "prison", "from": "valley", "lines": [
		_l("", CB_NARR, "黑石地牢。教会把「不能见光的人」关在这里，再也不放出来。"),
		_l("", CB_NARR, "艾德里克的寻父之旅，走到了最深处。"),
	]}


func epilogue() -> Array:
	var seven: Array = [
		_l("莫尔甘", CB_MORGAN, "埃德蒙死了。月之镜，也回到了菲恩家那孩子的手里。"),
		_l("七号", CB_SEVEN, "……任务，失败。"),
		_l("莫尔甘", CB_MORGAN, "不。月之镜迟早会回到神殿来——他们会亲手把它送来的。"),
	]
	if flags.get("seven_killed", false):
		seven.append(_l("莫尔甘", CB_MORGAN, "碎成那样，还能自己爬回来。……你果然是我最好的作品。"))
	seven.append(_l("莫尔甘", CB_MORGAN, "……只是，七号。你迟疑了一瞬。"))
	seven.append(_l("七号", CB_SEVEN, "……没有。"))
	seven.append(_l("莫尔甘", CB_MORGAN, "是吗。"))
	seven.append(_l("", CB_NARR, "面具底下，七号的手指，还残留着埃德蒙胸口的温度。"))
	return [
		{"title": "黑石地牢 · 最深处", "mood": "dungeon", "lines": [
			_l("", CB_NARR, "天快亮的时候，他们把埃德蒙抬出了地牢。"),
			_l("", CB_NARR, "艾德里克一路没有回头。缇娅走在他身边，也没有回头。"),
		]},
		{"title": "圣都 · 大圣堂", "mood": "church", "lines": seven},
	]
