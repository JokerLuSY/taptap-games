class_name Combat
## 战斗计算：预览与结算（不直接扣血，由 battle 按事件逐个结算）

static var force_crit := false   # 测试用: 强制全部暴击
static var no_support := false   # 竞技场：单挑不算地图上队友的支援加成

## 特效（威力 ×3）：弓打飞行、破甲剑打重甲、拒马枪打骑马（GBA 火纹）、守护之火打炎龙
static func effective_mt(w: Dictionary, target: Unit) -> int:
	if w["type"] == "bow" and target.is_flying():
		return int(w["mt"]) * 3
	var slay := str(w.get("slay", ""))
	if slay == "armor" and target.class_label in ["重甲兵", "将军", "王子", "苍狼王"]:
		return int(w["mt"]) * 3
	if slay == "mounted" and bool(GameData.class_data(target.class_label).get("mounted", false)):
		return int(w["mt"]) * 3
	if slay == "dragon" and target.class_label == "炎龙":
		return int(w["mt"]) * 3
	return int(w["mt"])


## from_pos: 攻击方出手位置（默认当前格，AI 评估时传目标格）
static func forecast(att: Unit, def: Unit, wpn_idx: int, board: Board, from_pos := Vector2i(-1, -1)) -> Dictionary:
	var a_pos: Vector2i = att.grid_pos if from_pos.x < 0 else from_pos
	var w: Dictionary = att.weapon(wpn_idx)
	var d: int = GameData.dist(a_pos, def.grid_pos)
	var tri: int = GameData.triangle_dir(w["type"], def.weapon(maxi(0, def.counter_weapon(d)))["type"])
	# 魔法打魔防，物理打守备；地形守备两种都加
	var d_def: int = def.res if w.get("magic", false) else def.dfn
	var tb_d: Dictionary = board.terrain_bonus(def, def.grid_pos)
	var tb_a: Dictionary = board.terrain_bonus(att, a_pos)
	var a_dmg: int = maxi(0, effective_mt(w, def) + att.pwr + (1 if tri == 1 else 0) - d_def - tb_d["dfn"])
	var a_hit: int = clampi(w["hit"] + att.eff_skl() * 2 + tri * 10 - def.eff_spd() * 2 - tb_d["avo"], 0, 100)
	# 居高临下: 高度占优方 +10 命中 +1 伤害
	var lv_a: int = board.level_at(a_pos)
	var lv_d: int = board.level_at(def.grid_pos)
	if lv_a > lv_d:
		a_hit = clampi(a_hit + 10, 0, 100)
		a_dmg += 1
	# 支援加成：3 格内的已支援伙伴按等级叠加（C ±5 / B ±10 / A ±15 且必杀 +5）
	var sup_a: Dictionary = Supports.bonus(att, [] if no_support else board.units)
	var sup_d: Dictionary = Supports.bonus(def, [] if no_support else board.units)
	a_hit = clampi(a_hit + int(sup_a["hit"]) - int(sup_d["avo"]), 0, 100)
	var a_times: int = 2 if att.eff_spd() - def.eff_spd() >= 4 else 1
	var a_crit: int = clampi(att.eff_skl() / 2 + w.get("crit", 0) + int(sup_a["crit"]), 0, 100)
	# 防守方反击（自动选用能打到的武器）
	var d_wi: int = def.counter_weapon(d)
	var d_dmg := 0
	var d_hit := 0
	var d_times := 0
	var d_crit := 0
	if d_wi >= 0:
		var dw: Dictionary = def.weapon(d_wi)
		var tri2: int = GameData.triangle_dir(dw["type"], w["type"])
		var a_def: int = att.res if dw.get("magic", false) else att.dfn
		d_dmg = maxi(0, effective_mt(dw, att) + def.pwr + (1 if tri2 == 1 else 0) - a_def - tb_a["dfn"])
		d_hit = clampi(dw["hit"] + def.eff_skl() * 2 + tri2 * 10 - att.eff_spd() * 2 - tb_a["avo"], 0, 100)
		if lv_d > lv_a:
			d_hit = clampi(d_hit + 10, 0, 100)
			d_dmg += 1
		d_hit = clampi(d_hit + int(sup_d["hit"]) - int(sup_a["avo"]), 0, 100)
		d_times = 2 if def.eff_spd() - att.eff_spd() >= 4 else 1
		d_crit = clampi(def.eff_skl() / 2 + dw.get("crit", 0) + int(sup_d["crit"]), 0, 100)
	return {
		"a_dmg": a_dmg, "a_hit": a_hit, "a_times": a_times, "a_crit": a_crit,
		"d_can": d_wi >= 0, "d_dmg": d_dmg, "d_hit": d_hit, "d_times": d_times, "d_crit": d_crit,
	}


## 生成攻击事件序列: [{side, dmg, hit, crit, landed, killed}]，不修改实际 HP
static func resolve(att: Unit, def: Unit, wpn_idx: int, board: Board) -> Array:
	var f: Dictionary = forecast(att, def, wpn_idx, board)
	var order: Array = []
	if force_crit:
		order.append({"side": "a", "dmg": f["a_dmg"] * 3, "hit": f["a_hit"], "crit": true})
	else:
		order.append({"side": "a", "dmg": f["a_dmg"], "hit": f["a_hit"], "crit": _roll_crit(f["a_crit"])})
		if order[0]["crit"]:
			order[0]["dmg"] = f["a_dmg"] * 3
	if f["d_can"]:
		var dcrit: bool = force_crit or _roll_crit(f["d_crit"])
		order.append({"side": "d", "dmg": f["d_dmg"] * (3 if dcrit else 1), "hit": f["d_hit"], "crit": dcrit})
	if f["a_times"] == 2:
		var acrit2: bool = force_crit or _roll_crit(f["a_crit"])
		order.append({"side": "a", "dmg": f["a_dmg"] * (3 if acrit2 else 1), "hit": f["a_hit"], "crit": acrit2})
	elif f["d_can"] and f["d_times"] == 2:
		var dcrit2: bool = force_crit or _roll_crit(f["d_crit"])
		order.append({"side": "d", "dmg": f["d_dmg"] * (3 if dcrit2 else 1), "hit": f["d_hit"], "crit": dcrit2})
	var hp_a := att.hp
	var hp_d := def.hp
	var events: Array = []
	for ev in order:
		if (hp_d if ev["side"] == "a" else hp_a) <= 0:
			break
		ev["landed"] = randi_range(1, 100) <= ev["hit"]
		if ev["landed"]:
			if ev["side"] == "a":
				hp_d = maxi(0, hp_d - ev["dmg"])
			else:
				hp_a = maxi(0, hp_a - ev["dmg"])
		ev["killed"] = (hp_d <= 0) if ev["side"] == "a" else (hp_a <= 0)
		events.append(ev)
		if ev["killed"]:
			break
	return events


static func _roll_crit(rate: int) -> bool:
	return randi_range(1, 100) <= rate


## 经验：按实际强度等级算（上级职业 +20 级，剧情觉醒见 GameData.level_bonus），否则上级打杂兵经验暴涨、没转职的主角打上级敌人只拿 1 点
static func xp_gain(att: Unit, def: Unit, killed: bool) -> int:
	var la := att.level + GameData.level_bonus(att.class_label)
	var ld := def.level + GameData.level_bonus(def.class_label)
	var base: int = clampi(10 + (ld - la) * 3, 1, 60)
	if killed:
		base += 15
		if def.is_boss:
			base += 25
	if la > ld:
		base = maxi(1, base - (la - ld) * 3)
	return base
