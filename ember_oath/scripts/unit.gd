class_name Unit
extends Node2D
## 棋盘单位：GBA 火纹风地图小人（3/4 俯视、描边、阴阳面、待机浮动）

const TILE := 64

var unit_id := ""
var display_name := ""
var class_label := ""
var faction := "enemy"          # player / enemy
var level := 1
var xp := 0
var max_hp := 20
var hp := 20
var pwr := 5
var skl := 5
var spd := 5
var dfn := 3
var res := 1                    # 魔防：挡魔法伤害
var mov := 5
var con := 6                    # 体格：救出时被救者体格 ≤ 救出者的救出值
var weapons: Array = []         # weapon id 列表
var weapon_uses: Array = []     # 与 weapons 一一对应的剩余耐久（-1 = 不会坏）
var items: Array = []           # item id 列表
var item_uses: Array = []       # 与 items 一一对应的剩余次数
var wexp := {}                  # 武器经验 {类型: 点数}，按 GameData.RANK_EXP 换算成 E~S
var growths := {"hp": 50, "pwr": 30, "skl": 30, "spd": 30, "dfn": 20, "res": 20}
var stationary := false         # 不移动（守点 BOSS）
var hold := false               # 守点：我方进入威胁范围前不动
var is_boss := false
var grid_pos := Vector2i.ZERO
var has_acted := false
var body_color := Color(0.5, 0.5, 0.6)
var support_with := {}            # 已解锁的支援: {伙伴 unit_id: 等级}
var carrying: Unit = null         # 救出：背着的同伴
var carried_by: Unit = null       # 被谁背着（被背期间不在地图上）
const OFF_MAP := Vector2i(-1000, -1000)

# 外观
var hair_style := "short"       # ponytail / short / spiky / hood
var hair_color := Color(0.30, 0.24, 0.18)
var armor_color := Color(0.5, 0.5, 0.6)
var skin_color := Color(1.0, 0.86, 0.72)
var scar := false

# 待机动画
var _t := 0.0
var _phase := 0.0

# 地图移动表现：朝向（下/上/左/右）、走路中、已行动灰度过渡
var facing := Vector2i.DOWN
var walking := false
var _walk_t := 0.0
var _dim := 0.0

# 绘制开关（战斗特写的克隆体会关掉光环和 HP 条；有像素帧时整段程序绘制关掉）
var draw_ring := true
var draw_hp_bar := true
var suppress_draw := false

const OUTLINE := Color(0.13, 0.11, 0.15)

# ---- 像素地图小人（原创 GBA 火纹风，源文件 tools/pixelart/fe_art.py） ----
# 每张表 4 行：0 待机（3 帧）/ 1 向下走 / 2 向上走 / 3 侧走（朝左，朝右水平翻转），每行 4 格。
# 整只按阵营上色：<名字>_blue.png = 我方，<名字>_red.png = 敌方。×4 放大，脚踩在格子底边。
const SPRITE_DIR := "res://art/units/fe/"
const SPRITE_BY_ID := {
	"tia": "tia",
	"balto": "balto",
	"brock": "boss",
	"marco": "boss",
	"scout1": "scout",
	"harlo": "harlo",
	"nina": "nina",
	"kain": "kain",
	"edric": "edric",
	"noya": "noya",
	"silas": "silas",
	"hawk": "hawk",
	"barrett": "barrett",
	"cyril": "cyril",
	"sparrow": "sparrow",
	"august": "barrett",
	"lorenz": "knight",
	# ---- 第二篇 ----
	"lance": "knight",
	"gwen": "knight",
	"oscar": "barrett",
	"mira": "church",
	"victor": "mage",
	"bruno": "bandit",
	"selene": "pegasus",
	"gareth": "gareth",
	"hagen": "harlo",
	"liss": "archer",
	"shuo": "scout",
	"gerard": "knight",
	"ivy": "mage",
	"ivan": "church",
	"vera": "hawk",
	"gray": "merc",
	"talia": "noya",
	"benedict": "mage",
	"kira": "pegasus",
	"rock": "barrett",
	"edmund": "knight",
	"seven": "seven",
	# ---- 第三篇 ----
	"orion": "orion",
	"owen": "owen",
	"lilith": "lilith",
	"roland": "roland",
	"hector": "barrett",
	"werner": "mage",
	"raven": "scout",
	"marcus": "mage",
	"zero": "puppet",
	"alban": "mage",
	"morgan": "morgan",
}
const SPRITE_BY_PREFIX := [["mage", "mage"], ["bandit", "bandit"], ["archer", "archer"], ["church", "church"], ["knight", "knight"], ["merc", "merc"], ["soldier", "church"], ["armor", "barrett"], ["pegasus", "pegasus"], ["puppet", "puppet"], ["pirate", "bandit"], ["darkmage", "mage"], ["graycloak", "scout"], ["cleric", "noya"], ["sniper", "archer"], ["paladin", "knight"], ["general", "barrett"], ["sage", "mage"], ["brodden", "merc"], ["thief", "sparrow"], ["fighter", "harlo"], ["myrm", "scout"]]
## 战斗面板上的名册中文名。章节若已经写了中文 name 则保留；只有空名或把 id 当名字时才补。
const ROSTER_NAME := {
	"harlo": "哈洛",
	"nina": "妮娜",
	"kain": "凯因",
	"edric": "艾德里克",
	"noya": "诺雅",
	"silas": "塞拉斯",
	"hawk": "霍克",
	"barrett": "巴雷特",
}
## 杂兵按 id 前缀。步兵的章节名是「圣焰教会兵」（见第四章与 game_flow）。
const ROSTER_NAME_PREFIX := [
	["church", "圣焰教会兵"],
	["knight", "圣焰骑士"],
	["merc", "黑烬佣兵"],
]
const SPRITE_PX := 4.0
const SPRITE_FOOT := 30.0       # 脚底离格子中心的距离（格子半高 32，留 2px）
const WALK_FPS := 10.0
## GBA 火纹的待机节奏：站 → 吸气 → 站 → 吸气（[帧, 秒]）
const IDLE_SEQ := [[0, 0.5], [1, 0.14], [2, 0.5], [1, 0.14]]
const WAITED_SHADER := preload("res://shaders/unit_waited.gdshader")

var sprite_sheet := ""
var _team := ""
var _sprite: Sprite2D


static func roster_display_name(id: String) -> String:
	if ROSTER_NAME.has(id):
		return str(ROSTER_NAME[id])
	for rule in ROSTER_NAME_PREFIX:
		if id.begins_with(str(rule[0])):
			return str(rule[1])
	return ""


func setup(def: Dictionary) -> void:
	if def.get("fights", false):
		set_meta("fights", true)
	unit_id = def.get("id", "")
	var given := str(def.get("name", ""))
	var canon := roster_display_name(unit_id)
	if canon != "" and (given.is_empty() or given == unit_id):
		display_name = canon
	else:
		display_name = given if not given.is_empty() else "?"
	class_label = def.get("class", "")
	faction = def.get("faction", "enemy")
	level = def.get("level", 1)
	max_hp = def.get("hp", 20)
	hp = max_hp
	pwr = def.get("pwr", 5)
	skl = def.get("skl", 5)
	spd = def.get("spd", 5)
	dfn = def.get("dfn", 3)
	var cls := GameData.class_data(class_label)
	# 魔防缺省：魔法职业高一些，其他取守备的一半
	res = int(def.get("res", dfn + 2 if cls.get("magic", false) else int(dfn / 2) + 1))
	mov = def.get("mov", 5)
	con = int(def.get("con", cls.get("con", 6)))
	weapons = def.get("weapons", []).duplicate()
	weapon_uses = []
	var wu_in: Array = def.get("weapon_uses", [])
	for i in weapons.size():
		weapon_uses.append(int(wu_in[i]) if i < wu_in.size() else max_uses(weapons[i]))
	items = def.get("items", []).duplicate()
	item_uses = []
	var iu_in: Array = def.get("item_uses", [])
	for i in items.size():
		item_uses.append(int(iu_in[i]) if i < iu_in.size() else max_uses(items[i]))
	_init_wexp(def.get("wexp", {}), cls)
	if def.has("growths"):
		growths = def["growths"].duplicate()
		if not growths.has("res"):
			growths["res"] = 20
	stationary = def.get("stationary", false)
	hold = def.get("hold", false)
	is_boss = def.get("boss", false)
	grid_pos = def.get("pos", Vector2i.ZERO)
	body_color = def.get("color", Color(0.5, 0.5, 0.6))
	armor_color = def.get("armor", body_color)
	hair_style = def.get("hair", "short")
	hair_color = def.get("hair_color", Color(0.30, 0.24, 0.18))
	skin_color = def.get("skin", Color(1.0, 0.86, 0.72))
	scar = def.get("scar", false)
	position = tile_center()
	_phase = float((grid_pos.x * 7 + grid_pos.y * 13) % 10) / 10.0 * TAU
	_setup_sprite(str(def.get("sprite", SPRITE_BY_CLASS.get(str(def.get("class", "")), _sprite_for_id(unit_id, str(def.get("class", "")))))))


## 按职业换形态（与炎龙融合的莫尔甘）
const SPRITE_BY_CLASS := {"炎龙": "dragon"}
## id、前缀都没登记的单位（各章的首领、临时杂兵）按职业挑一套通用小人；地图和战斗特写共用这张表
const SHEET_BY_CLASS := {
	"骑士": "knight", "圣骑士": "knight", "领主骑士": "knight", "重甲兵": "barrett", "将军": "barrett",
	"天马骑士": "pegasus", "隼骑士": "pegasus", "魔道士": "mage", "贤者": "mage", "暗法师": "mage", "德鲁伊": "mage",
	"修女": "noya", "司祭": "noya", "修士": "noya", "弓箭手": "archer", "狙击手": "archer", "佣兵": "merc", "勇者": "merc",
	"剑士": "scout", "剑圣": "scout", "刺客": "scout", "盗贼": "sparrow", "山贼": "bandit", "山贼头目": "boss",
	"海盗": "bandit", "战士": "harlo", "勇士": "harlo", "狂战士": "bandit", "枪兵": "church", "枪斗士": "church",
	"灰烬傀儡": "puppet",
}


static func _sprite_for_id(id: String, cls := "") -> String:
	if SPRITE_BY_ID.has(id):
		return SPRITE_BY_ID[id]
	for rule in SPRITE_BY_PREFIX:
		if id.begins_with(rule[0]):
			return rule[1]
	return str(SHEET_BY_CLASS.get(cls, ""))


## 有像素帧就挂一个 Sprite2D 子节点；缺图时保留程序 Q 版
func _setup_sprite(sheet: String) -> void:
	sprite_sheet = ""
	_team = ""
	if _sprite != null:
		_sprite.queue_free()
		_sprite = null
	if sheet.is_empty() or not ResourceLoader.exists(SPRITE_DIR + sheet + "_blue.png"):
		return
	sprite_sheet = sheet
	_sprite = Sprite2D.new()
	_sprite.name = "MapSprite"
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(SPRITE_PX, SPRITE_PX)
	var mat := ShaderMaterial.new()
	mat.shader = WAITED_SHADER
	mat.set_shader_parameter("outline_color", Color(0, 0, 0, 0))
	_sprite.material = mat
	add_child(_sprite)
	_update_sprite_frame()


func has_sprite() -> bool:
	return _sprite != null


## 当前用的阵营色表："blue" / "red"（说得转阵营后会自动换）
func sprite_team() -> String:
	return _team


func _apply_team_texture() -> void:
	var team := "blue" if is_player() else ("green" if is_npc() else "red")
	if team == _team:
		return
	var path := SPRITE_DIR + sprite_sheet + "_" + team + ".png"
	if team == "green" and not ResourceLoader.exists(path):
		team = "red"
		path = SPRITE_DIR + sprite_sheet + "_red.png"
	if not ResourceLoader.exists(path):
		return
	_team = team
	_sprite.texture = load(path)
	_sprite.hframes = 4
	_sprite.vframes = 4
	var fw := _sprite.texture.get_width() / 4.0
	var fh := _sprite.texture.get_height() / 4.0
	_sprite.position = Vector2(-fw * SPRITE_PX / 2.0, SPRITE_FOOT - fh * SPRITE_PX)


func _update_sprite_frame() -> void:
	if _sprite == null:
		return
	_apply_team_texture()
	if _sprite.texture == null:
		return
	var row := 0
	var col := 0
	var flip := false
	if walking:
		match facing:
			Vector2i.UP:
				row = 2
			Vector2i.LEFT, Vector2i.RIGHT:
				row = 3
				flip = facing == Vector2i.RIGHT
			_:
				row = 1
		col = int(_walk_t * WALK_FPS) % 4
	elif not has_acted:
		col = _idle_frame()
	_sprite.flip_h = flip
	_sprite.frame = row * 4 + col
	var mat := _sprite.material as ShaderMaterial
	mat.set_shader_parameter("amount", _dim)
	var fw := 1.0 / _sprite.hframes
	var fh := 1.0 / _sprite.vframes
	mat.set_shader_parameter("frame_uv", Vector4(col * fw, row * fh, (col + 1) * fw, (row + 1) * fh))


func _idle_frame() -> int:
	var total := 0.0
	for step in IDLE_SEQ:
		total += float(step[1])
	var t := fmod(_t + _phase * 0.2, total)
	for step in IDLE_SEQ:
		t -= float(step[1])
		if t < 0.0:
			return int(step[0])
	return 0


## 阵营色：蓝 = 我方，红 = 敌方，金 = 头目
func team_color() -> Color:
	if is_boss:
		return Color(1.0, 0.78, 0.22)
	return Color(0.35, 0.62, 1.0) if is_player() else Color(1.0, 0.32, 0.28)


func is_player() -> bool:
	return faction == "player"


## 中立（绿色）：不归任何一方行动，谁也打不了它，只能对话招募
func is_flying() -> bool:
	return GameData.is_flying(class_label)


## 第三方友军（绿色、会在友军阶段自己移动攻击敌人，敌人也会打它）
func is_ally_fighter() -> bool:
	return is_npc() and bool(get_meta("fights", false))


func is_npc() -> bool:
	return faction == "npc"


func is_alive() -> bool:
	return hp > 0


## 在地图上（活着且没被人背着）
func on_map() -> bool:
	return is_alive() and carried_by == null


## 救出值：步行 = 体格 - 1，骑马 = 25 - 体格，飞行 = 20 - 体格
func aid() -> int:
	var cls := GameData.class_data(class_label)
	if cls.get("flying", false):
		return 20 - con
	if cls.get("mounted", false):
		return 25 - con
	return con - 1


func can_carry(t: Unit) -> bool:
	return t != null and t != self and carrying == null and t.carrying == null and t.con <= aid()


## 背着人时技巧、速度减半
func eff_skl() -> int:
	return skl / 2 if carrying != null else skl


func eff_spd() -> int:
	return spd / 2 if carrying != null else spd


## 把 t 背起来：t 离开地图（隐藏、移到图外），不能被打、不能行动
func pick_up(t: Unit) -> void:
	carrying = t
	t.carried_by = self
	t.grid_pos = OFF_MAP
	t.visible = false
	t.has_acted = true
	queue_redraw()


## 把背着的人放到 p
func put_down(p: Vector2i) -> Unit:
	var t := carrying
	if t == null:
		return null
	carrying = null
	t.carried_by = null
	t.grid_pos = p
	t.position = t.tile_center()
	t.visible = true
	t.modulate.a = 1.0
	t.has_acted = true
	queue_redraw()
	return t


func weapon(idx := 0) -> Dictionary:
	if weapons.is_empty():
		return {"name": "--", "type": "none", "mt": 0, "hit": 0, "crit": 0, "rng": []}
	return GameData.WEAPONS[weapons[idx]]


# ==================== 武器等级与耐久 ====================

static func max_uses(id: String) -> int:
	if GameData.WEAPONS.has(id):
		return int(GameData.WEAPONS[id].get("uses", -1))
	if GameData.ITEMS.has(id):
		return int(GameData.ITEMS[id].get("uses", 1))
	return 1


## 初始武器经验：存档里有就用存档；没有就按职业的初始等级，并保证开场带着的武器都拿得动
func _init_wexp(saved, cls: Dictionary) -> void:
	wexp = {}
	if saved is Dictionary and not (saved as Dictionary).is_empty():
		for k in saved:
			wexp[str(k)] = int(saved[k])
		return
	var ranks: Dictionary = cls.get("ranks", {})
	for t in ranks:
		wexp[t] = int(GameData.RANK_EXP[ranks[t]])
	for id in weapons:
		var w: Dictionary = GameData.WEAPONS.get(id, {})
		var r := str(w.get("rank", "E"))
		if r == "prf" or w.is_empty():
			continue
		wexp[w["type"]] = maxi(int(wexp.get(w["type"], 0)), int(GameData.RANK_EXP[r]))


## 某类武器的当前等级字母（"" = 不会用）
func rank_letter(type: String) -> String:
	return GameData.rank_of(int(wexp.get(type, 0)))


## 能不能用第 idx 把武器：专属看名单，其余看武器等级。敌方不受等级限制。
func can_use(idx: int) -> bool:
	if idx < 0 or idx >= weapons.size():
		return false
	return can_use_id(weapons[idx])


func can_use_id(id: String) -> bool:
	var w: Dictionary = GameData.WEAPONS.get(id, {})
	if w.is_empty():
		return false
	var r := str(w.get("rank", "E"))
	if r == "prf":
		return unit_id in w.get("prf", [])
	if not is_player():
		return true
	return GameData.rank_index(rank_letter(w["type"])) >= GameData.rank_index(r)


## 用一次武器 / 杖：耐久 -1，用完就从手里拿掉。返回坏掉的武器名（没坏返回 ""）
func use_weapon(idx: int) -> String:
	if idx < 0 or idx >= weapons.size():
		return ""
	if int(weapon_uses[idx]) < 0:
		return ""
	weapon_uses[idx] = int(weapon_uses[idx]) - 1
	if int(weapon_uses[idx]) > 0:
		return ""
	var name: String = GameData.WEAPONS[weapons[idx]]["name"]
	weapons.remove_at(idx)
	weapon_uses.remove_at(idx)
	return name


## 涨武器经验，升级了返回新等级字母（没升返回 ""）
func gain_wexp(type: String, n: int) -> String:
	if n <= 0 or type == "" or type == "none":
		return ""
	var before := rank_letter(type)
	if before == "":
		return ""
	wexp[type] = mini(int(wexp.get(type, 0)) + n, int(GameData.RANK_EXP["S"]))
	var after := rank_letter(type)
	return after if after != before else ""


## 把武器提到最前（装备）
func equip(idx: int) -> void:
	if idx <= 0 or idx >= weapons.size():
		return
	var id = weapons[idx]
	var u = weapon_uses[idx]
	weapons.remove_at(idx)
	weapon_uses.remove_at(idx)
	weapons.insert(0, id)
	weapon_uses.insert(0, u)


## 拿到一件东西（武器或道具），uses 缺省为满耐久。背包上限 5 件，满了返回 false
const BAG_LIMIT := 5


func inventory_size() -> int:
	return weapons.size() + items.size()


func give(id: String, uses := -2) -> bool:
	if inventory_size() >= BAG_LIMIT:
		return false
	var u := max_uses(id) if uses == -2 else uses
	if GameData.WEAPONS.has(id):
		weapons.append(id)
		weapon_uses.append(u)
	else:
		items.append(id)
		item_uses.append(u)
	return true


## 剧情 / 访问得到的东西：背包满了就送进道具库
func receive(id: String) -> void:
	if not give(id):
		Campaign.convoy.append([id, max_uses(id)])


## 用掉一次道具，用完从背包拿掉
func use_item(idx: int) -> void:
	item_uses[idx] = int(item_uses[idx]) - 1
	if int(item_uses[idx]) <= 0:
		items.remove_at(idx)
		item_uses.remove_at(idx)


func uses_text(idx: int) -> String:
	var u := int(weapon_uses[idx])
	if u < 0:
		return "--"
	return "%d/%d" % [u, max_uses(weapons[idx])]


func weapon_kind() -> String:
	for i in weapons.size():
		if can_use(i):
			return GameData.WEAPONS[weapons[i]]["type"]
	if weapons.is_empty():
		return "sword"
	return GameData.WEAPONS[weapons[0]]["type"]


func weapon_ranges() -> Array:
	var out: Array = []
	for w in weapons:
		if GameData.WEAPONS[w]["type"] == "staff":
			continue
		for r in GameData.WEAPONS[w]["rng"]:
			if r not in out:
				out.append(r)
	return out


func can_hit(d: int, idx := 0) -> bool:
	if not can_use(idx):
		return false
	var w: Dictionary = GameData.WEAPONS[weapons[idx]]
	if w["type"] == "staff":
		return false
	return d in w["rng"]


## 有没有能拿来攻击的武器（只带杖的治疗者不能攻击）
func can_attack() -> bool:
	for i in weapons.size():
		if GameData.WEAPONS[weapons[i]]["type"] != "staff" and can_use(i):
			return true
	return false


## 治疗杖的索引，没有为 -1
func heal_staff() -> int:
	for i in weapons.size():
		if GameData.WEAPONS[weapons[i]]["type"] == "staff" and can_use(i):
			return i
	return -1


## 治疗量 = 杖的回复量 + 力（当魔力用）
func heal_amount() -> int:
	var i := heal_staff()
	if i < 0:
		return 0
	return int(GameData.WEAPONS[weapons[i]]["mt"]) + pwr


## 防守时自动选用能打到 dist 的武器, 返回索引(-1 = 无法反击)
func counter_weapon(d: int) -> int:
	for i in weapons.size():
		if can_hit(d, i):
			return i
	return -1


func take_damage(n: int) -> void:
	hp = clampi(hp - n, 0, max_hp)
	queue_redraw()


func heal(n: int) -> void:
	hp = clampi(hp + n, 0, max_hp)
	queue_redraw()


## 剧情转职：等级重置为 1，经验清零，保留当前能力并加上 bonus。不消耗道具。
func promote(to_class: String, bonus: Dictionary, new_weapons: Array = []) -> void:
	class_label = to_class
	level = 1
	xp = 0
	var add_hp := int(bonus.get("hp", 0))
	max_hp += add_hp
	hp = mini(hp + add_hp, max_hp)
	pwr += int(bonus.get("pwr", 0))
	skl += int(bonus.get("skl", 0))
	spd += int(bonus.get("spd", 0))
	dfn += int(bonus.get("dfn", 0))
	res += int(bonus.get("res", 0))
	mov += int(bonus.get("mov", 0))
	if not new_weapons.is_empty():
		var old_ids := weapons.duplicate()
		var old_uses := weapon_uses.duplicate()
		weapons = new_weapons.duplicate()
		weapon_uses = []
		for id in weapons:
			var k := old_ids.find(id)
			weapon_uses.append(int(old_uses[k]) if k >= 0 else max_uses(id))
	var cls := GameData.class_data(to_class)
	con = int(cls.get("con", con))
	var ranks: Dictionary = cls.get("ranks", {})
	for t in ranks:
		wexp[t] = maxi(int(wexp.get(t, 0)), int(GameData.RANK_EXP[ranks[t]]))
	queue_redraw()


## 返回升级信息（空 dict = 未升级）
func gain_xp(n: int) -> Dictionary:
	# Lv20 封顶：满级后经验不再累计（基础职业用转职道具后从 Lv1 重新练）
	if level >= 20:
		xp = 0
		return {}
	xp += n
	if xp < 100:
		return {}
	xp -= 100
	level += 1
	var gains := {}
	for k in growths:
		if randf() * 100.0 < growths[k]:
			gains[k] = 1
			match k:
				"hp":
					max_hp += 1
					hp += 1
				"pwr":
					pwr += 1
				"skl":
					skl += 1
				"spd":
					spd += 1
				"dfn":
					dfn += 1
				"res":
					res += 1
	queue_redraw()
	return {"level": level, "gains": gains}


func tile_center() -> Vector2:
	return Vector2(grid_pos) * TILE + Vector2(TILE / 2.0, TILE / 2.0)


func to_save() -> Dictionary:
	return {
		"id": unit_id,
		"name": display_name,
		"class": class_label,
		"faction": faction,
		"level": level,
		"xp": xp,
		"max_hp": max_hp,
		"hp": hp,
		"pwr": pwr,
		"skl": skl,
		"spd": spd,
		"dfn": dfn,
		"res": res,
		"mov": mov,
		"con": con,
		"weapons": weapons.duplicate(),
		"weapon_uses": weapon_uses.duplicate(),
		"items": items.duplicate(),
		"item_uses": item_uses.duplicate(),
		"wexp": wexp.duplicate(),
		"growths": growths.duplicate(),
		"stationary": stationary,
		"hold": hold,
		"boss": is_boss,
		"pos": [grid_pos.x, grid_pos.y],
		"has_acted": has_acted,
		"support_with": support_with.duplicate(),
		"carried_by": carried_by.unit_id if carried_by != null else "",
		"color": body_color.to_html(false),
		"armor": armor_color.to_html(false),
		"hair": hair_style,
		"hair_color": hair_color.to_html(false),
		"skin": skin_color.to_html(false),
		"scar": scar,
		"alive": is_alive(),
		"retreated": bool(get_meta("retreated", false)),
		"sprite": sprite_sheet,
		"fights": bool(get_meta("fights", false)),
	}


func apply_save(data: Dictionary) -> void:
	var pos_raw = data.get("pos", [0, 0])
	var pos := Vector2i.ZERO
	if typeof(pos_raw) == TYPE_ARRAY and pos_raw.size() >= 2:
		pos = Vector2i(int(pos_raw[0]), int(pos_raw[1]))
	var growths_in = data.get("growths", {})
	var def := {
		"id": str(data.get("id", "")),
		"name": str(data.get("name", "?")),
		"class": str(data.get("class", "")),
		"faction": str(data.get("faction", "enemy")),
		"level": int(data.get("level", 1)),
		"hp": int(data.get("max_hp", 20)),
		"pwr": int(data.get("pwr", 5)),
		"skl": int(data.get("skl", 5)),
		"spd": int(data.get("spd", 5)),
		"dfn": int(data.get("dfn", 3)),
		"mov": int(data.get("mov", 5)),
		"weapons": data.get("weapons", []),
		"weapon_uses": data.get("weapon_uses", []),
		"items": data.get("items", []),
		"item_uses": data.get("item_uses", []),
		"wexp": data.get("wexp", {}),
		"stationary": bool(data.get("stationary", false)),
		"hold": bool(data.get("hold", false)),
		"boss": bool(data.get("boss", false)),
		"pos": pos,
		"color": _html_color(str(data.get("color", "")), Color(0.5, 0.5, 0.6)),
		"armor": _html_color(str(data.get("armor", "")), Color(0.5, 0.5, 0.6)),
		"hair": str(data.get("hair", "short")),
		"hair_color": _html_color(str(data.get("hair_color", "")), Color(0.30, 0.24, 0.18)),
		"skin": _html_color(str(data.get("skin", "")), Color(1.0, 0.86, 0.72)),
		"scar": bool(data.get("scar", false)),
	}
	if growths_in is Dictionary and not (growths_in as Dictionary).is_empty():
		def["growths"] = growths_in
	if str(data.get("sprite", "")) != "":
		def["sprite"] = str(data["sprite"])
	if bool(data.get("fights", false)):
		def["fights"] = true
	if data.has("res"):
		def["res"] = int(data["res"])
	if data.has("con"):
		def["con"] = int(data["con"])
	setup(def)
	hp = clampi(int(data.get("hp", max_hp)), 0, max_hp)
	xp = int(data.get("xp", 0))
	has_acted = bool(data.get("has_acted", false))
	var sw = data.get("support_with", {})
	support_with = sw.duplicate() if sw is Dictionary else {}
	if bool(data.get("retreated", false)):
		set_meta("retreated", true)
	if not bool(data.get("alive", hp > 0)):
		hp = 0
		visible = false
		modulate.a = 0.0
	queue_redraw()


func _html_color(hex: String, fallback: Color) -> Color:
	if hex.is_empty():
		return fallback
	return Color.html(hex)


# ==================== 绘制 ====================

func _process(delta: float) -> void:
	if suppress_draw:
		return
	_t += delta
	if _bubble != null and _bubble.visible:
		_bubble.position.y = sin(_t * 3.2) * 2.0
	if walking:
		_walk_t += delta
	# 已行动：平滑过渡到灰暗（GBA 火纹式），复位时再亮回来
	var target := 1.0 if has_acted and is_alive() else 0.0
	_dim = move_toward(_dim, target, delta * 5.0)
	if _sprite != null:
		_update_sprite_frame()
	else:
		var g := lerpf(1.0, 0.52, _dim)
		self_modulate = Color(g, g, g * 1.06, 1.0)
	queue_redraw()


# ---- 对话气泡：我方有人能跟这个人【对话】/【说得】时，头顶冒一个气泡（battle.refresh_talk_marks） ----
var _bubble: Node2D = null


func set_talk_mark(on: bool) -> void:
	if not on and _bubble == null:
		return
	if _bubble == null:
		_bubble = Node2D.new()
		_bubble.z_index = 5
		_bubble.draw.connect(_draw_bubble)
		add_child(_bubble)
		_bubble.queue_redraw()
	_bubble.visible = on


func has_talk_mark() -> bool:
	return _bubble != null and _bubble.visible


func _draw_bubble() -> void:
	var r := Rect2(Vector2(6, -66), Vector2(26, 18))
	var ink := Color(0.12, 0.1, 0.16)
	_bubble.draw_colored_polygon(PackedVector2Array([Vector2(10, -49), Vector2(18, -49), Vector2(9, -42)]), Color(1, 1, 1))
	_bubble.draw_polyline(PackedVector2Array([Vector2(10, -48), Vector2(9, -42), Vector2(18, -48)]), ink, 2.0)
	_bubble.draw_rect(r, Color(1, 1, 1))
	_bubble.draw_rect(r, ink, false, 2.0)
	for i in 3:
		_bubble.draw_circle(Vector2(12 + i * 7, -57), 2.0, ink)


## 按移动方向转身；d 为一格的位移（零向量不变）
func face(d: Vector2i) -> void:
	if d == Vector2i.ZERO:
		return
	if absi(d.x) >= absi(d.y):
		facing = Vector2i(signi(d.x), 0)
	else:
		facing = Vector2i(0, signi(d.y))
	queue_redraw()


func set_walking(on: bool) -> void:
	walking = on
	if not on:
		_walk_t = 0.0
	queue_redraw()


## 选中时的小弹跳
func hop() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.08, 0.88), 0.06)
	t.tween_property(self, "scale", Vector2(0.96, 1.08), 0.08)
	t.tween_property(self, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	if suppress_draw:
		return
	var bob := sin(_t * 2.6 + _phase) * 1.3
	if walking:
		# 走路：每步一次上下颠
		bob = -absf(sin(_walk_t * 14.0)) * 3.0
	# ---- 地面阴影 + 阵营光环（不浮动） ----
	if draw_ring:
		var ring_col: Color = Color(0.3, 0.55, 1.0) if is_player() else Color(1.0, 0.35, 0.3)
		if is_boss:
			ring_col = Color(1.0, 0.75, 0.2)
		draw_set_transform(Vector2(0, 26), 0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, 18, Color(0, 0, 0, 0.28))
		# 像素小人整只已是阵营色，不再画光环；程序 Q 版兜底才画
		if _sprite == null:
			draw_set_transform(Vector2(0, 20), 0, Vector2(1.0, 0.42))
			draw_arc(Vector2.ZERO, 20, 0, TAU, 28, ring_col, 3.0)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# ---- 人物：有像素帧时由 MapSprite 子节点画，这里只画环和 HP 条 ----
	if _sprite != null:
		_draw_hp()
		return
	# ---- 程序 Q 版（整体随 bob 浮动；朝左时镜像） ----
	var sx := -1.0 if facing == Vector2i.LEFT else 1.0
	draw_set_transform(Vector2(0, bob), 0, Vector2(sx, 1.0))
	if facing == Vector2i.UP:
		# 背身：武器在身后先画，头部只露后脑
		_draw_weapon()
		_draw_boots()
		_draw_torso()
		_draw_head_back()
	else:
		_draw_boots()
		_draw_torso()
		_draw_head()
		_draw_weapon()
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	_draw_hp()


func _draw_hp() -> void:
	if carrying != null and draw_hp_bar:
		var c := team_color()
		var base := Vector2(16, -44)
		draw_line(base, base + Vector2(0, 14), Color(0.15, 0.12, 0.1), 2.0)
		draw_colored_polygon(PackedVector2Array([base, base + Vector2(10, 4), base + Vector2(0, 8)]), c)
		draw_polyline(PackedVector2Array([base, base + Vector2(10, 4), base + Vector2(0, 8)]), Color(0.1, 0.08, 0.1), 1.0)
	if draw_hp_bar:
		var w := 44.0
		var ratio := float(hp) / float(maxi(1, max_hp))
		var bar_col: Color = Color(0.3, 0.9, 0.3) if ratio > 0.5 else (Color(0.95, 0.8, 0.2) if ratio > 0.25 else Color(0.9, 0.25, 0.2))
		draw_rect(Rect2(-w / 2, 26, w, 6), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w / 2 + 1, 27, (w - 2) * ratio, 4), bar_col)


func _draw_boots() -> void:
	var boot := armor_color.darkened(0.5)
	# 走路时左右脚交替抬起
	var lift := 0.0
	if walking:
		lift = sin(_walk_t * 14.0) * 2.5
	var ly := 11.0 - maxf(0.0, lift)
	var ry := 11.0 - maxf(0.0, -lift)
	draw_rect(Rect2(-8.5, ly, 7, 7), OUTLINE)
	draw_rect(Rect2(1.5, ry, 7, 7), OUTLINE)
	draw_rect(Rect2(-7.5, ly + 0.8, 5, 5.6), boot)
	draw_rect(Rect2(2.5, ry + 0.8, 5, 5.6), boot)


func _draw_torso() -> void:
	# 描边层（略大的梯形）
	var torso_o := PackedVector2Array([
		Vector2(-11.5, -7.5), Vector2(11.5, -7.5), Vector2(13.5, 12.5), Vector2(-13.5, 12.5)])
	draw_colored_polygon(torso_o, OUTLINE)
	# 本体
	var torso := PackedVector2Array([
		Vector2(-10, -6), Vector2(10, -6), Vector2(12, 11), Vector2(-12, 11)])
	draw_colored_polygon(torso, armor_color)
	# 阴阳面：右暗左亮
	var shade := PackedVector2Array([
		Vector2(3, -6), Vector2(10, -6), Vector2(12, 11), Vector2(3, 11)])
	draw_colored_polygon(shade, armor_color.darkened(0.25))
	var light := PackedVector2Array([
		Vector2(-10, -6), Vector2(0, -6), Vector2(0, 11), Vector2(-12, 11)])
	draw_colored_polygon(light, armor_color.lightened(0.15))
	# 腰带
	draw_line(Vector2(-11.6, 4), Vector2(11.6, 4), OUTLINE, 2.2)
	# 肩部高光
	draw_line(Vector2(-9, -5), Vector2(2, -5), armor_color.lightened(0.35), 1.6)


func _draw_head() -> void:
	# 头（描边圈 + 皮肤）
	draw_circle(Vector2(0, -13), 11.8, OUTLINE)
	draw_circle(Vector2(0, -13), 10.8, skin_color)
	# 发型（3/4 视角：发团盖住头顶, 露出下半张脸）
	match hair_style:
		"ponytail", "short":
			draw_circle(Vector2(0, -16), 11.2, OUTLINE)
			draw_circle(Vector2(0, -16), 10.2, hair_color)
			draw_circle(Vector2(0, -10.5), 8.6, skin_color)
			# 头顶高光
			draw_arc(Vector2(-2.5, -19), 4.5, PI * 0.85, PI * 1.55, 8, hair_color.lightened(0.35), 2.0)
			if hair_style == "ponytail":
				draw_line(Vector2(9, -21), Vector2(18, -6), OUTLINE, 6.5)
				draw_line(Vector2(9, -21), Vector2(18, -6), hair_color, 4.0)
				draw_circle(Vector2(18, -5), 3.8, OUTLINE)
				draw_circle(Vector2(18, -5), 2.5, hair_color)
			else:
				# 胡子
				draw_rect(Rect2(-5, -8.5, 10, 3), OUTLINE)
				draw_rect(Rect2(-4.2, -8, 8.4, 1.8), hair_color)
		"spiky":
			var spikes := PackedVector2Array([
				Vector2(-11, -15), Vector2(-8, -27), Vector2(-4, -18), Vector2(1, -29),
				Vector2(5, -19), Vector2(9, -26), Vector2(11, -15), Vector2(7, -11),
				Vector2(-7, -11)])
			draw_colored_polygon(spikes, hair_color)
			var closed := spikes + PackedVector2Array([spikes[0]])
			draw_polyline(closed, OUTLINE, 2.0)
		"hood":
			var hood := PackedVector2Array([
				Vector2(0, -28), Vector2(12.5, -14), Vector2(11.5, -4), Vector2(6, -8),
				Vector2(-6, -8), Vector2(-11.5, -4), Vector2(-12.5, -14)])
			draw_colored_polygon(hood, armor_color.darkened(0.10))
			var closed := hood + PackedVector2Array([hood[0]])
			draw_polyline(closed, OUTLINE, 2.0)
			# 兜帽内阴影
			draw_arc(Vector2(0, -13), 7, PI * 1.1, PI * 1.9, 8, skin_color.darkened(0.25), 2.4)
	# 眼睛
	draw_circle(Vector2(-3.5, -10), 1.4, OUTLINE)
	draw_circle(Vector2(3.5, -10), 1.4, OUTLINE)
	if scar:
		draw_line(Vector2(-7, -16), Vector2(-2, -8), Color(0.60, 0.20, 0.15), 1.6)
	if is_boss:
		var crown := PackedVector2Array([
			Vector2(-6, -22), Vector2(-3, -28), Vector2(0, -22), Vector2(3, -28), Vector2(6, -22)])
		draw_polyline(crown, OUTLINE, 4.5)
		draw_polyline(crown, Color(1.0, 0.8, 0.2), 2.5)


## 背身头部：整颗头被头发 / 兜帽盖住，不画五官
func _draw_head_back() -> void:
	draw_circle(Vector2(0, -13), 11.8, OUTLINE)
	var cap := armor_color.darkened(0.10) if hair_style == "hood" else hair_color
	draw_circle(Vector2(0, -13), 10.8, cap)
	draw_arc(Vector2(-2.5, -17), 5.0, PI * 0.85, PI * 1.55, 8, cap.lightened(0.30), 2.0)
	match hair_style:
		"ponytail":
			draw_line(Vector2(0, -8), Vector2(0, 4), OUTLINE, 6.5)
			draw_line(Vector2(0, -8), Vector2(0, 4), hair_color, 4.0)
		"spiky":
			var spikes := PackedVector2Array([
				Vector2(-11, -15), Vector2(-8, -27), Vector2(-4, -18), Vector2(1, -29),
				Vector2(5, -19), Vector2(9, -26), Vector2(11, -15)])
			draw_polyline(spikes, OUTLINE, 3.0)
			draw_colored_polygon(spikes, hair_color)
	if is_boss:
		var crown := PackedVector2Array([
			Vector2(-6, -22), Vector2(-3, -28), Vector2(0, -22), Vector2(3, -28), Vector2(6, -22)])
		draw_polyline(crown, OUTLINE, 4.5)
		draw_polyline(crown, Color(1.0, 0.8, 0.2), 2.5)


func _draw_weapon() -> void:
	var steel := Color(0.85, 0.87, 0.92)
	var wood := Color(0.45, 0.32, 0.20)
	var gold := Color(0.85, 0.70, 0.30)
	match weapon_kind():
		"sword":
			var blade := steel
			if not weapons.is_empty() and str(weapons[0]) == "ember_blade":
				blade = Color(1.0, 0.55, 0.22)
			draw_rect(Rect2(12.4, -11, 4.4, 18), OUTLINE)
			draw_rect(Rect2(13.2, -10, 2.8, 16), blade)
			var tip := PackedVector2Array([Vector2(13.2, -10), Vector2(16, -10), Vector2(14.6, -14)])
			draw_colored_polygon(tip, OUTLINE)
			var tip_in := PackedVector2Array([Vector2(13.8, -10), Vector2(15.5, -10), Vector2(14.6, -12.8)])
			draw_colored_polygon(tip_in, blade)
			draw_rect(Rect2(10.5, 6, 8, 3.4), OUTLINE)
			draw_rect(Rect2(11.3, 6.7, 6.4, 2), gold)
			draw_rect(Rect2(13.8, 9.4, 1.8, 5), wood)
		"lance":
			draw_line(Vector2(15, 12), Vector2(15, -14), OUTLINE, 4.2)
			draw_line(Vector2(15, 12), Vector2(15, -14), wood, 2.4)
			var tip := PackedVector2Array([Vector2(15, -21), Vector2(12.2, -13), Vector2(17.8, -13)])
			draw_colored_polygon(tip, OUTLINE)
			var tip_in := PackedVector2Array([Vector2(15, -19.4), Vector2(13.2, -13.8), Vector2(16.8, -13.8)])
			draw_colored_polygon(tip_in, steel)
		"axe":
			draw_line(Vector2(15, 12), Vector2(15, -10), OUTLINE, 4.2)
			draw_line(Vector2(15, 12), Vector2(15, -10), wood, 2.4)
			var head := PackedVector2Array([Vector2(15, -11), Vector2(23, -8), Vector2(23, -1), Vector2(15, -4)])
			draw_colored_polygon(head, OUTLINE)
			var head_in := PackedVector2Array([Vector2(15.8, -9.6), Vector2(21.6, -7.4), Vector2(21.6, -2.4), Vector2(15.8, -4.8)])
			draw_colored_polygon(head_in, steel)
		"staff":
			draw_line(Vector2(15, 12), Vector2(15, -12), OUTLINE, 4.2)
			draw_line(Vector2(15, 12), Vector2(15, -12), wood, 2.4)
			draw_circle(Vector2(15, -14), 4.2, OUTLINE)
			draw_circle(Vector2(15, -14), 3.0, Color(0.75, 0.95, 1.0))
		"bow":
			draw_arc(Vector2(17, 0), 10, -PI / 2, PI / 2, 12, OUTLINE, 4.2)
			draw_arc(Vector2(17, 0), 10, -PI / 2, PI / 2, 12, wood, 2.4)
			draw_line(Vector2(17, -10), Vector2(17, 10), Color(0.9, 0.9, 0.85), 1.2)
