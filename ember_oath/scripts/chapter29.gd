class_name Chapter29
extends Part3Chapter
## 第二十九章「八百年」：神殿深处的封印回廊。莫尔甘用一具灰烬身体（残影）亲自挡在封印之门前，说出八百年的真相。
## 残影打不死：HP 降到一半以下（或被打倒）就退进封印之门。
## 缇娅 × 七号「名字」对话（七号在队、还没聊过时，真结局条件）。
## 胜利：击退莫尔甘。败北：三主角阵亡。

const CHAPTER_TITLE := "第二十九章 · 八百年"
const VICTORY_TITLE := "第二十九章 · 完"
const VICTORY_SUB := "八百年的谎，只用了一个晚上就说完了。"
const DEFEAT_SUB := "封印之门前，灰落了一地。满月照常升起……"
const BG := ""

## 34×24。神殿深处南北向的封印回廊，被两道台阶（城门格）分成三段；两侧立着八座圣器像（石柱），
## 东西各有三个壁龛（增援从壁龛里出来）。北端是封印之门（王座 K），莫尔甘的残影站在门前。
const MAP := [
	"##################################",
	"########SSSSSSSSKKSSSSSSSS########",
	"########SSSSSSSSSSSSSSSSSS########",
	"##ESSSSSSISSSSSSSSSSSSSSISSSSSSE##",
	"##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##",
	"##SSSSSSSSSSZSSSSSSSSZSSSSSSSSSS##",
	"########SISSSSSSSSSSSSSSIS########",
	"########SSSSSSSSSSSSSSSSSS########",
	"########SSSSSSSSSSSSSSSSSS########",
	"#############GGGGGGGG#############",
	"########SSSSSSSSSSSSSSSSSS########",
	"##ESSSSSSSSSSSSSSSSSSSSSSSSSSSSE##",
	"##SSSSSSSISSSSSSSSSSSSSSISSSSSSS##",
	"##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##",
	"########SSSZSSSSSSSSSSZSSS########",
	"########SSSSSSSSSSSSSSSSSS########",
	"#############GGGGGGGG#############",
	"########SSSSSSSSSSSSSSSSSS########",
	"##ESSSSSSSSSSSSSSSSSSSSSSSSSSSSE##",
	"##SSSSSSSISSSSSSSSSSSSSSISSSSSSS##",
	"##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##",
	"########SSSSSSSSSSSSSSSSSS########",
	"########SSSSSSSSSSSSSSSSSS########",
	"################GG################",
]

const LEVELS := []                # 全图同一高度

const MORGAN_RETREAT_PCT := 0.5

const UNITS := [
	# 我方（名单为空的单章测试用）
	{"id": "edric", "faction": "player", "pos": Vector2i(16, 21)},
	{"id": "tia", "faction": "player", "pos": Vector2i(17, 21)},
	{"id": "gareth", "faction": "player", "pos": Vector2i(15, 21)},
	{"id": "seven", "faction": "player", "pos": Vector2i(18, 21)},
	{"id": "silas", "faction": "player", "pos": Vector2i(16, 22)},
	{"id": "owen", "faction": "player", "pos": Vector2i(17, 22)},
	{"id": "roland", "faction": "player", "pos": Vector2i(15, 22)},
	{"id": "balto", "faction": "player", "pos": Vector2i(18, 22)},
	{"id": "orion", "faction": "player", "pos": Vector2i(14, 21)},
	{"id": "lilith", "faction": "player", "pos": Vector2i(19, 21)},
	{"id": "noya", "faction": "player", "pos": Vector2i(14, 22)},
	{"id": "vera", "faction": "player", "pos": Vector2i(19, 22)},
	# 第一段（南）
	{"id": "puppet1", "pos": Vector2i(11, 18), "hold": true},
	{"id": "puppet2", "pos": Vector2i(22, 18), "hold": true},
	{"id": "fighter1", "pos": Vector2i(16, 18), "hold": true},
	{"id": "sniper1", "pos": Vector2i(13, 19), "hold": true},
	{"id": "sniper2", "pos": Vector2i(20, 19), "hold": true},
	{"id": "myrm1", "pos": Vector2i(10, 15), "hold": true},
	{"id": "myrm2", "pos": Vector2i(23, 15), "hold": true},
	# 第二段（中）：台阶上的重甲
	{"id": "general1", "pos": Vector2i(16, 15), "hold": true},
	{"id": "general2", "pos": Vector2i(17, 15), "hold": true},
	{"id": "sage1", "pos": Vector2i(13, 11), "hold": true},
	{"id": "sage2", "pos": Vector2i(20, 11), "hold": true},
	{"id": "paladin1", "pos": Vector2i(10, 13), "hold": true},
	{"id": "paladin2", "pos": Vector2i(23, 13), "hold": true},
	{"id": "puppet3", "pos": Vector2i(16, 12), "hold": true},
	{"id": "puppet4", "pos": Vector2i(17, 12), "hold": true},
	# 第三段（北）
	{"id": "darkmage1", "pos": Vector2i(14, 7), "hold": true},
	{"id": "darkmage2", "pos": Vector2i(19, 7), "hold": true},
	{"id": "general3", "pos": Vector2i(11, 4), "hold": true},
	{"id": "general4", "pos": Vector2i(22, 4), "hold": true},
	{"id": "cleric1", "pos": Vector2i(15, 3)},
	{"id": "graycloak1", "pos": Vector2i(18, 3), "hold": true},
	# 莫尔甘·残影：灰烬做的身体。打不死，HP 降到一半就退进封印之门
	{"id": "morgan", "name": "莫尔甘", "class": "德鲁伊", "faction": "enemy", "level": 20,
		"hp": 80, "pwr": 23, "skl": 20, "spd": 16, "dfn": 16, "res": 22, "mov": 5,
		"weapons": ["fenrir", "nosferatu"], "boss": true, "stationary": true,
		"pos": Vector2i(16, 2), "color": Color(0.85, 0.82, 0.90),
		"hair": "hood", "hair_color": Color(0.90, 0.90, 0.92), "armor": Color(0.92, 0.88, 0.98)},
]

## 第 2、4、6 回合：两侧壁龛里醒来傀儡与亲卫
const WAVES := {
	2: [{"id": "puppet_r1", "pos": Vector2i(3, 19)}, {"id": "puppet_r2", "pos": Vector2i(30, 19)}],
	4: [{"id": "puppet_r3", "pos": Vector2i(3, 12)}, {"id": "puppet_r4", "pos": Vector2i(30, 12)},
		{"id": "darkmage_r1", "pos": Vector2i(4, 12)}, {"id": "darkmage_r2", "pos": Vector2i(29, 12)}],
	6: [{"id": "paladin_r1", "pos": Vector2i(3, 4)}, {"id": "paladin_r2", "pos": Vector2i(30, 4)}],
}

const DEPLOY := [Vector2i(13, 21), Vector2i(20, 21), Vector2i(13, 22), Vector2i(20, 22), Vector2i(12, 21), Vector2i(21, 21),
	Vector2i(12, 22), Vector2i(21, 22), Vector2i(11, 21), Vector2i(22, 21), Vector2i(11, 22), Vector2i(22, 22)]


func chapter_id() -> String:
	return "ch29"


func stage() -> int:
	return 6


func deploy_limit() -> int:
	return 12


func extra_deploy_slots() -> Array:
	return DEPLOY


func extra_slots() -> Array:
	return DEPLOY


func foes() -> Dictionary:
	return {
		"puppet": foe("puppet", 20, {"hp": 50, "pwr": 17, "dfn": 18}), "fighter": foe("fighter", 11),
		"sniper": foe("sniper", 10), "myrm": foe("myrm", 11),
		"general": foe("general", 11, {"weapons": ["silver_lance"]}), "sage": foe("sage", 11, {"weapons": ["bolganone"]}),
		"paladin": foe("paladin", 11, {"weapons": ["silver_lance", "steel_sword"]}),
		"darkmage": foe("darkmage", 20, {"weapons": ["nosferatu"]}), "cleric": foe("cleric", 10),
		"graycloak": foe("graycloak", 10),
	}


func shop_items() -> Array:
	return ["vulnerary", "elixir", "silver_sword", "killing_edge", "silver_lance", "killer_lance", "silver_axe", "silver_bow",
		"bolganone", "divine", "fenrir", "mend_staff"]


func is_won() -> bool:
	return flags.get("repelled", false)


func win_condition() -> String:
	return tr("击退莫尔甘（让他的 HP 降到一半以下）")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if _wave(t, WAVES):
		if t == 2:
			await battle.play_dialogue(_wave2())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())


func on_before_combat(att, def) -> void:
	if "morgan" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var other = def if att.unit_id == "morgan" else att
		await battle.play_dialogue(_boss(other.unit_id))


## 残影受伤到一半以下（或被打倒）：说出八百年的真相，退进封印之门
func on_after_combat(_att, _def, _def_died: bool) -> void:
	var m = battle.get_unit("morgan")
	if m == null or flags.get("repelled", false):
		return
	if m.is_alive() and m.hp > int(m.max_hp * MORGAN_RETREAT_PCT):
		return
	flags["repelled"] = true
	await battle.play_dialogue(_truth())
	if m.is_alive():
		_leave_map(m)
	battle.notify(tr("莫尔甘退进了封印之门"))


func talks() -> Array:
	var out: Array = [["silas", "lilith", "silas_lilith_29"], ["balto", "tia", "balto_tia_29"]]
	if _name_talk_ok():
		out.append_array(_name_talk())
	return out


func talk_lines(key: String) -> Array:
	match key:
		"seven_name":
			return _name_lines()
		"silas_lilith_29":
			return [
				_l("塞拉斯", C_SILAS, "……你身上的灰，是工坊的配方？"),
				_l("莉莉丝", C_LILITH, "审判官大人要审判我吗？「被灰污染的异端」。"),
				_l("塞拉斯", C_SILAS, "不。审判官的名单上，从今往后只写一个名字。"),
				_l("莉莉丝", C_LILITH, "……那就好。我还以为要排队呢。"),
			]
	return [
		_l("巴尔托", C_BALTO, "丫头。我抱你出那座城的那天，你娘最后跟我说了一句话。"),
		_l("缇娅", C_TIA, "……我娘？"),
		_l("巴尔托", C_BALTO, "她说：「别告诉她，她的血是钥匙。告诉她，她的火是暖的。」"),
		_l("缇娅", C_TIA, "……"),
		_l("巴尔托", C_BALTO, "我瞒了你十几年前半句。后半句……现在告诉你了。"),
		_l("缇娅", C_TIA, "……嗯。是暖的。我知道。"),
	]


func on_talked(key: String, _u, _partner) -> void:
	if key == "seven_name":
		_on_name_talked()


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	Campaign.flags["morgan_truth"] = true


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "封印回廊。两侧立着八座圣器像，每一座的脚下，都积着八百年的灰。"),
		_l("", C_NARR, "回廊尽头，封印之门前，站着一个白衣的老人。"),
		_l("莫尔甘", C_MORGAN, "来了啊。比我想的早一天。"),
		_l("艾德里克", C_EDRIC, "莫尔甘……八百年前的大司祭，也是你。"),
		_l("莫尔甘", C_MORGAN, "书库的书，看完了？……那本书我锁了八百年，一直舍不得烧。人总是想留下点什么，证明自己活过。"),
		_l("缇娅", C_TIA, "「我还活着」——写了一整页的，也是你吧。"),
		_l("莫尔甘", C_MORGAN, "……是。巫女的后人，你比你的祖先还会戳人。"),
		_l("莫尔甘", C_MORGAN, "这具身体是临时做的，打碎了也无妨。来吧——让我看看，你们够不够资格听完这个故事。"),
	]
	if _here("seven"):
		lines.append(_l("七号", C_SEVEN, "……大司祭。"))
		lines.append(_l("莫尔甘", C_MORGAN, "七号。不，你已经不是七号了。……三天还没到，你的核倒是很结实。"))
	return lines


func _turn2_hint() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "莫尔甘站在封印之门前不动。打掉他一半的血，他就撑不住这具身体了。"),
		_l("艾德里克", C_EDRIC, "小心他的暗魔法——会吸血。"),
	]


func _wave2() -> Array:
	return [
		_l("莫尔甘", C_MORGAN, "壁龛里的孩子们，醒一醒。客人来了。"),
	]


func _boss(foe_id: String) -> Array:
	var lines: Array = []
	match foe_id:
		"tia":
			lines.append(_l("莫尔甘", C_MORGAN, "艾琳也是这样看着我的。……八百年了，那双眼睛还是一样讨厌。"))
		"edric":
			lines.append(_l("莫尔甘", C_MORGAN, "埃德蒙的儿子。你父亲是我见过最固执的人——变成傀儡之后，还在梦里喊你的名字。"))
			lines.append(_l("艾德里克", C_EDRIC, "……那你就记住这个名字。"))
		"seven":
			lines.append(_l("莫尔甘", C_MORGAN, "我的作品，向我举起了爪子。……也好。这才是活的东西。"))
		"silas":
			lines.append(_l("莫尔甘", C_MORGAN, "塞拉斯。你的老师刮字的时候在哭，你知道吗？他是我最好的审判官。"))
		_:
			lines.append(_l("莫尔甘", C_MORGAN, "八百年，我见过太多拿着剑冲上来的人。他们现在都在灰里。"))
	return lines


func _truth() -> Array:
	var lines: Array = [
		_l("", C_NARR, "莫尔甘的身体裂开了。灰从裂缝里往外漏，他却笑了。"),
		_l("莫尔甘", C_MORGAN, "够了。你们有资格听了。"),
		_l("莫尔甘", C_MORGAN, "八百年前，我是第一任大司祭。我看着人们一代代老去、死去。我不想死。"),
		_l("莫尔甘", C_MORGAN, "神殿底下睡着炎龙。它的火，能让人不灭。……守着它的，是一个叫艾琳的女孩。"),
		_l("莫尔甘", C_MORGAN, "她不肯给我。我就自己去拿。……龙醒了，世界烧了一半。"),
		_l("莫尔甘", C_MORGAN, "艾琳用自己的命，把龙锁了回去。八个蠢货替她拿着钥匙——就是你们手里的圣器。"),
		_l("莫尔甘", C_MORGAN, "我被龙火烧成了灰。可我没有死。龙火给了我一半的「不灭」：我成了灰，却还醒着。"),
		_l("莫尔甘", C_MORGAN, "我花了一百年，学会把自己装进灰做的身体里。又花了七百年，建起教会，把她写成罪人。"),
		_l("莫尔甘", C_MORGAN, "让人们恨火、怕火，把火种都交到我手里。……再满大陆地找她的血脉。"),
	]
	if _here("tia"):
		lines.append(_l("缇娅", C_TIA, "灰岩村的火……"))
		lines.append(_l("莫尔甘", C_MORGAN, "是为了把你逼出来。你养父藏得太好了。"))
	lines.append_array([
		_l("莫尔甘", C_MORGAN, "巫女的血是锁，也是钥匙。明晚满月，我会用它打开封印，把龙火装进我自己。"),
		_l("莫尔甘", C_MORGAN, "不再是灰。是火。……永远不灭的火。"),
	])
	if _here("tia"):
		lines.append(_l("缇娅", C_TIA, "你要的不是不灭。你只是……怕死。怕了八百年。"))
	lines.append_array([
		_l("莫尔甘", C_MORGAN, "……也许吧。可怕死，有什么错？"),
		_l("莫尔甘", C_MORGAN, "明晚，封印台。来不来，随你们。"),
		_l("", C_NARR, "灰做的身体塌了下去。封印之门，无声地开了一道缝。"),
	])
	return lines


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "回廊里只剩下八座圣器像，和一地的灰。"),
		_l("加雷斯", C_GARETH, "……为了不死，烧了半个世界，骗了八百年。"),
	]
	if _here("silas"):
		lines.append(_l("塞拉斯", C_SILAS, "我追捕了一辈子「异端」。……原来真正的异端，一直坐在大圣堂的最高处。"))
	if _here("owen"):
		lines.append(_l("欧文", C_OWEN, "「火不可封，唯可守。」……八英雄早就知道，封印只是拖延。"))
	if _here("roland"):
		lines.append(_l("罗兰", C_ROLAND, "领主大人追查的，就是这个吧。……他一个人，查到了这里。"))
	if _here("seven"):
		lines.append(_l("七号", C_SEVEN, "他也是灰。……和我一样，是灰。"))
		lines.append(_l("缇娅", C_TIA, "不一样。你选了为什么而烧。他没有。"))
	lines.append_array([
		_l("艾德里克", C_EDRIC, "明晚，满月。……封印台。"),
		_l("缇娅", C_TIA, "嗯。去把八百年前的火，好好地看一眼。"),
	])
	return lines


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "temple", "from": "temple", "lines": [
		_moon(1),
		_l("", CB_NARR, "书库的北边，是通往封印台的回廊。八百年前，八英雄从这里走进去，没有一个人走出来。"),
	]}


func epilogue() -> Array:
	var camp: Array = [
		_l("", CB_NARR, "决战前夜。神殿外的山坡上，一行人点起了最后一堆营火。"),
		_l("加雷斯", C_GARETH, "喂，打完了干什么？我先说：回布罗登，请所有人吃烤全羊。"),
		_l("艾德里克", C_EDRIC, "我回菲恩城，把父亲的剑挂回书房。……然后，去灰岩村。"),
		_l("缇娅", C_TIA, "那我回灰岩村。哈洛说房子盖了十七间，我要去数一数。"),
	]
	if _here("seven") or Campaign.flags.get("seven_joined", false):
		camp.append(_l("七号", CB_SEVEN, "……我，不知道要去哪里。"))
		camp.append(_l("缇娅", C_TIA, "那就跟我回去。灰岩村冬天很冷——正好需要一点火。"))
	camp.append(_l("", CB_NARR, "月亮升起来了。还差一点点，就圆了。"))
	return [
		{"title": "神殿外 · 决战前夜", "mood": "camp", "lines": camp},
	]
