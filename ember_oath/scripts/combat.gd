class_name Combat
## 战斗计算：预览与结算（不直接扣血，由 battle 按事件逐个结算）

static var force_crit := false   # 测试用: 强制全部暴击

## from_pos: 攻击方出手位置（默认当前格，AI 评估时传目标格）
static func forecast(att: Unit, def: Unit, wpn_idx: int, board: Board, from_pos := Vector2i(-1, -1)) -> Dictionary:
	var a_pos: Vector2i = att.grid_pos if from_pos.x < 0 else from_pos
	var w: Dictionary = att.weapon(wpn_idx)
	var d: int = GameData.dist(a_pos, def.grid_pos)
	var tri: int = GameData.triangle_dir(w["type"], def.weapon()["type"])
	var a_dmg: int = maxi(0, w["mt"] + att.pwr + (1 if tri == 1 else 0) - def.dfn - board.terrain(def.grid_pos)["dfn"])
	var a_hit: int = clampi(w["hit"] + att.skl * 2 + tri * 10 - def.spd * 2 - board.terrain(def.grid_pos)["avo"], 0, 100)
	# 居高临下: 高度占优方 +10 命中 +1 伤害
	var lv_a: int = board.level_at(a_pos)
	var lv_d: int = board.level_at(def.grid_pos)
	if lv_a > lv_d:
		a_hit = clampi(a_hit + 10, 0, 100)
		a_dmg += 1
	# 支援加成: 已解锁支援的伙伴相邻时 +5 命中 +5 回避
	var sup_a := 5 if _support_adjacent(att, board) else 0
	var sup_d := 5 if _support_adjacent(def, board) else 0
	a_hit = clampi(a_hit + sup_a - sup_d, 0, 100)
	var a_times: int = 2 if att.spd - def.spd >= 4 else 1
	var a_crit: int = clampi(att.skl / 2 + w.get("crit", 0), 0, 100)
	# 防守方反击（自动选用能打到的武器）
	var d_wi: int = def.counter_weapon(d)
	var d_dmg := 0
	var d_hit := 0
	var d_times := 0
	var d_crit := 0
	if d_wi >= 0:
		var dw: Dictionary = def.weapon(d_wi)
		var tri2: int = GameData.triangle_dir(dw["type"], w["type"])
		d_dmg = maxi(0, dw["mt"] + def.pwr + (1 if tri2 == 1 else 0) - att.dfn - board.terrain(a_pos)["dfn"])
		d_hit = clampi(dw["hit"] + def.skl * 2 + tri2 * 10 - att.spd * 2 - board.terrain(a_pos)["avo"], 0, 100)
		if lv_d > lv_a:
			d_hit = clampi(d_hit + 10, 0, 100)
			d_dmg += 1
		d_hit = clampi(d_hit + sup_d - sup_a, 0, 100)
		d_times = 2 if def.spd - att.spd >= 4 else 1
		d_crit = clampi(def.skl / 2 + dw.get("crit", 0), 0, 100)
	return {
		"a_dmg": a_dmg, "a_hit": a_hit, "a_times": a_times, "a_crit": a_crit,
		"d_can": d_wi >= 0, "d_dmg": d_dmg, "d_hit": d_hit, "d_times": d_times, "d_crit": d_crit,
	}


## 该单位是否有已解锁支援的伙伴在相邻格
static func _support_adjacent(u: Unit, board: Board) -> bool:
	if u.support_with.is_empty():
		return false
	for partner_id in u.support_with:
		for v in board.units:
			if v.unit_id == partner_id and v.is_alive() and GameData.dist(u.grid_pos, v.grid_pos) == 1:
				return true
	return false


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


static func xp_gain(att: Unit, def: Unit, killed: bool) -> int:
	var base: int = clampi(10 + (def.level - att.level) * 3, 1, 60)
	if killed:
		base += 15
		if def.is_boss:
			base += 25
	if att.level > def.level:
		base = maxi(1, base - (att.level - def.level) * 3)
	return base
