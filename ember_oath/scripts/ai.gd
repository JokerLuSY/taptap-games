class_name EnemyAI
## 敌方 AI：能打到就打（优先高期望伤害 / 能击杀的目标），否则向最近目标靠拢

## 返回 {"move_to": Vector2i, "target": Unit 或 null, "weapon": int, "heal": Unit 或 null}
static func choose(u: Unit, board: Board, players: Array) -> Dictionary:
	var alive: Array = players.filter(func(p) -> bool: return p.on_map())
	if alive.is_empty():
		return {"move_to": u.grid_pos, "target": null, "weapon": 0}
	if not u.can_attack():
		return _choose_healer(u, board, alive)
	if u.hold and not _threatened(u, board, alive):
		return {"move_to": u.grid_pos, "target": null, "weapon": 0}
	if u.stationary:
		var t := _best_target_from(u, u.grid_pos, alive, board)
		return {"move_to": u.grid_pos, "target": t, "weapon": _best_weapon_vs(u, u.grid_pos, t, board) if t != null else 0}

	var move: Dictionary = board.move_range(u)
	# 1) 找能攻击的位置 + 目标
	var best_score := -9999.0
	var best_tile := u.grid_pos
	var best_target: Unit = null
	for tile in move.keys():
		for p in alive:
			var d: int = GameData.dist(tile, p.grid_pos)
			for wi in u.weapons.size():
				if not board.can_hit_from(u, d, wi):
					continue
				var f: Dictionary = Combat.forecast(u, p, wi, board, tile)
				var score: float = f["a_dmg"] * f["a_hit"] / 100.0
				if f["a_dmg"] >= p.hp:
					score += 100.0  # 能击杀
				score -= f["d_dmg"] * 0.3
				if score > best_score:
					best_score = score
					best_tile = tile
					best_target = p
	if best_target != null:
		return {"move_to": best_tile, "target": best_target, "weapon": _best_weapon_vs(u, best_tile, best_target, board)}

	# 2) 否则向最近目标靠拢
	var target: Unit = _nearest(u.grid_pos, alive)
	var best2 := u.grid_pos
	var best_d := 9999
	for tile in move.keys():
		var dd: int = GameData.dist(tile, target.grid_pos)
		if dd < best_d:
			best_d = dd
			best2 = tile
	return {"move_to": best2, "target": null, "weapon": 0}


static func _best_target_from(u: Unit, tile: Vector2i, players: Array, board: Board) -> Unit:
	var best: Unit = null
	var bs := -1.0
	for p in players:
		var d: int = GameData.dist(tile, p.grid_pos)
		for wi in u.weapons.size():
			if not board.can_hit_from(u, d, wi):
				continue
			var f: Dictionary = Combat.forecast(u, p, wi, board, tile)
			var s: float = f["a_dmg"] * f["a_hit"] / 100.0
			if f["a_dmg"] >= p.hp:
				s += 100.0
			if s > bs:
				bs = s
				best = p
	return best


static func _best_weapon_vs(u: Unit, tile: Vector2i, target: Unit, board: Board) -> int:
	var best := 0
	var bs := -1.0
	for wi in u.weapons.size():
		if not board.can_hit_from(u, GameData.dist(tile, target.grid_pos), wi):
			continue
		var f: Dictionary = Combat.forecast(u, target, wi, board, tile)
		var s: float = f["a_dmg"] * f["a_hit"] / 100.0
		if s > bs:
			bs = s
			best = wi
	return best


static func _nearest(from: Vector2i, units: Array) -> Unit:
	var best: Unit = null
	var bd := 9999
	for p in units:
		var d: int = GameData.dist(from, p.grid_pos)
		if d < bd:
			bd = d
			best = p
	return best


## 守点单位：我方有人进入它的威胁范围（移动范围 + 射程）之前不动
static func _threatened(u: Unit, board: Board, players: Array) -> bool:
	var area := board.full_attack_area(u, board.move_range(u))
	for p in players:
		if area.has(p.grid_pos):
			return true
	return false


## 治疗者：能治就治伤得最重的同伴；没人可治就躲在同伴身后、离我方远一点
static func _choose_healer(u: Unit, board: Board, players: Array) -> Dictionary:
	var allies: Array = []
	for v in board.units:
		if v != u and v.is_alive() and v.faction == u.faction:
			allies.append(v)
	var move: Dictionary = board.move_range(u)
	var best_tile := u.grid_pos
	var best_target: Unit = null
	var best_missing := 0
	for tile in move.keys():
		for v in allies:
			var missing: int = v.max_hp - v.hp
			if missing > best_missing and GameData.dist(tile, v.grid_pos) == 1:
				best_missing = missing
				best_tile = tile
				best_target = v
	if best_target != null:
		return {"move_to": best_tile, "target": null, "weapon": 0, "heal": best_target}
	if allies.is_empty():
		return {"move_to": u.grid_pos, "target": null, "weapon": 0}
	var best_score := -9999.0
	for tile in move.keys():
		var ally: Unit = _nearest(tile, allies)
		var foe: Unit = _nearest(tile, players)
		var score := -float(GameData.dist(tile, ally.grid_pos)) + 0.6 * float(mini(GameData.dist(tile, foe.grid_pos), 6))
		if score > best_score:
			best_score = score
			best_tile = tile
	return {"move_to": best_tile, "target": null, "weapon": 0}
