class_name PrepScreen
extends Control
## 出击准备（整备）：选人、布阵、物品（交换 / 道具库）、商店、招募提示。
## 浮在地图右侧安全区内（半透明小窗），地图照常全屏显示，布阵时直接点地图；信息窗这时停到左边。
## 数据都在 battle 上：prep_pool（本章可出击的我方单位）、deployed（出击中）、deploy_slots（可部署格）。

signal done

const PANEL_SIZE := Vector2(320, 624)
const PANEL_POS := Vector2(1280 - 64 - 320, 48)

var battle = null
var _panel: Panel
var _body: VBoxContainer
var _scroll: ScrollContainer
var _mode := "menu"
var _cur: Unit = null            # 物品 / 商店里正在看的单位
var _give_idx := -1              # 物品：选中要交出去的那件（weapons 在前、items 在后的总序号）
var _deploy_pick: Unit = null    # 布阵：点中的单位


func setup(b) -> void:
	battle = b
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = Panel.new()
	_panel.position = PANEL_POS
	_panel.size = PANEL_SIZE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.15, 0.94)
	sb.border_color = Color(0.85, 0.72, 0.38)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(12, 10)
	_scroll.size = PANEL_SIZE - Vector2(24, 20)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.custom_minimum_size = Vector2(PANEL_SIZE.x - 36, 0)
	_body.add_theme_constant_override("separation", 6)
	_scroll.add_child(_body)
	_cur = battle.deployed[0] if not battle.deployed.is_empty() else null
	show_menu()


# ==================== 小工具 ====================

func _clear() -> void:
	for c in _body.get_children():
		c.queue_free()


func _title(text: String) -> void:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.text = text
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(1.0, 0.86, 0.5))
	_body.add_child(l)


func _text(text: String, size := 17, color := Color(0.92, 0.92, 0.95)) -> void:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(PANEL_SIZE.x - 40, 0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_body.add_child(l)


func _button(text: String, cb: Callable, enabled := true, h := 44.0) -> Button:
	var b := Button.new()
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.text = text
	b.disabled = not enabled
	b.custom_minimum_size = Vector2(PANEL_SIZE.x - 40, h)
	b.pressed.connect(cb)
	_body.add_child(b)
	return b


func _row(buttons: Array) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	for spec in buttons:
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = spec[0]
		b.disabled = not spec[2]
		b.custom_minimum_size = Vector2((PANEL_SIZE.x - 40 - 6 * (buttons.size() - 1)) / buttons.size(), 40)
		b.pressed.connect(spec[1])
		h.add_child(b)
	_body.add_child(h)


func _unit_line(u: Unit) -> String:
	return "%s  Lv%d %s" % [tr(u.display_name), u.level, tr(u.class_label)]


## 单位的全部物品（武器在前、道具在后）：[{id, uses, weapon}]
static func inventory(u: Unit) -> Array:
	var out: Array = []
	for i in u.weapons.size():
		out.append({"id": u.weapons[i], "uses": int(u.weapon_uses[i]), "weapon": true, "idx": i})
	for i in u.items.size():
		out.append({"id": u.items[i], "uses": int(u.item_uses[i]), "weapon": false, "idx": i})
	return out


static func item_name(id: String) -> String:
	if GameData.WEAPONS.has(id):
		return GameData.WEAPONS[id]["name"]
	return GameData.ITEMS.get(id, {}).get("name", id)


static func uses_label(id: String, uses: int) -> String:
	if uses < 0:
		return "--"
	return "%d/%d" % [uses, Unit.max_uses(id)]


## 从单位身上拿走第 k 件（inventory 序号），返回 [id, uses]
static func take_out(u: Unit, k: int) -> Array:
	var e: Dictionary = inventory(u)[k]
	if e["weapon"]:
		u.weapons.remove_at(e["idx"])
		u.weapon_uses.remove_at(e["idx"])
	else:
		u.items.remove_at(e["idx"])
		u.item_uses.remove_at(e["idx"])
	return [e["id"], e["uses"]]


# ==================== 主菜单 ====================

func show_menu() -> void:
	_mode = "menu"
	battle.board.clear_highlights()
	_clear()
	_title(tr("出击准备"))
	_text(tr("出击 %d / %d 人   金钱 %d G") % [battle.deployed.size(), battle.deploy_limit(), battle.gold])
	var hints: Array = battle.recruit_hints()
	if not hints.is_empty():
		_text(tr("【招募提示】"), 17, Color(0.6, 0.9, 1.0))
		for h in hints:
			_text("· " + h, 16, Color(0.75, 0.92, 1.0))
	_button(tr("选择出击"), show_pick, battle.prep_mode() == "full" or battle.prep_mode() == "pick")
	_button(tr("布阵"), show_deploy, battle.prep_mode() == "full")
	_button(tr("物品"), show_items, battle.prep_mode() == "full")
	_button(tr("商店"), show_shop, battle.prep_mode() == "full" and not battle.shop_items().is_empty())
	_button(tr("开始战斗"), _on_start, not battle.deployed.is_empty(), 52.0)


func _on_start() -> void:
	battle.board.clear_highlights()
	done.emit()


# ==================== 选人 ====================

func show_pick() -> void:
	_mode = "pick"
	_clear()
	_title(tr("选择出击（%d / %d）") % [battle.deployed.size(), battle.deploy_limit()])
	var forced: Array = battle.forced_ids()
	for u in battle.prep_pool:
		var on: bool = u in battle.deployed
		var lock: bool = u.unit_id in forced
		var tag := tr("必须出击") if lock else (tr("出击") if on else tr("待命"))
		var full: bool = battle.deployed.size() >= battle.deploy_limit()
		var b := _button("%s  [%s]" % [_unit_line(u), tag], func() -> void: _toggle(u), not lock and (on or not full))
		if on:
			b.modulate = Color(0.75, 0.95, 1.0)
	_button(tr("返回"), show_menu)


func _toggle(u: Unit) -> void:
	battle.set_deployed(u, not (u in battle.deployed))
	show_pick()


# ==================== 布阵 ====================

func show_deploy() -> void:
	_mode = "deploy"
	_deploy_pick = null
	_clear()
	_title(tr("布阵"))
	_text(tr("点一名出击的同伴，再点蓝色格子：空格就移过去，有人就互换位置。可以先看看敌人的危险范围（T）。"))
	_button(tr("完成"), show_menu)
	_highlight_slots()


func _highlight_slots() -> void:
	var tiles := {}
	for p in battle.deploy_slots:
		tiles[p] = true
	var pick := {}
	if _deploy_pick != null:
		pick[_deploy_pick.grid_pos] = true
	battle.board.show_move(tiles, pick)


func in_deploy() -> bool:
	return _mode == "deploy"


## 布阵模式下的地图点击（battle 转过来）
func on_map_click(p: Vector2i) -> void:
	if _mode != "deploy":
		return
	var u: Unit = battle.board.unit_at(p)
	if _deploy_pick == null:
		if u != null and u in battle.deployed:
			_deploy_pick = u
			Audio.play_sfx("select")
			_highlight_slots()
		return
	if not battle.deploy_slots.has(p):
		return
	battle.swap_deploy(_deploy_pick, p)
	Audio.play_sfx("move")
	_deploy_pick = null
	_highlight_slots()


# ==================== 物品 ====================

func show_items() -> void:
	_mode = "items"
	_give_idx = -1
	if _cur == null or not (_cur in battle.prep_pool):
		_cur = battle.prep_pool[0]
	_clear()
	_title(tr("物品"))
	_unit_tabs(show_items)
	_text(_unit_line(_cur) + "   %d/%d" % [_cur.inventory_size(), Unit.BAG_LIMIT], 18, Color(1.0, 0.95, 0.8))
	var inv := inventory(_cur)
	if inv.is_empty():
		_text(tr("（什么也没带）"), 16, Color(0.7, 0.7, 0.75))
	for k in inv.size():
		var e: Dictionary = inv[k]
		var kk: int = k
		_text("%s %s" % [tr(item_name(e["id"])), uses_label(e["id"], e["uses"])], 17)
		_row([[tr("交给…"), func() -> void: _choose_receiver(kk), true], [tr("存入道具库"), func() -> void: _to_convoy(kk), true]])
	_text(tr("—— 道具库（%d 件）——") % Campaign.convoy.size(), 17, Color(0.85, 0.85, 0.6))
	for i in Campaign.convoy.size():
		var c: Array = Campaign.convoy[i]
		var ii: int = i
		_button("%s %s  → %s" % [tr(item_name(c[0])), uses_label(c[0], int(c[1])), tr("取出")], func() -> void: _from_convoy(ii), _cur.inventory_size() < Unit.BAG_LIMIT, 38.0)
	_button(tr("返回"), show_menu)


func _unit_tabs(refresh: Callable) -> void:
	var h := HFlowContainer.new()
	h.custom_minimum_size = Vector2(PANEL_SIZE.x - 40, 0)
	for u in battle.prep_pool:
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = tr(u.display_name)
		b.toggle_mode = true
		b.button_pressed = u == _cur
		b.custom_minimum_size = Vector2(68, 36)
		var uu: Unit = u
		b.pressed.connect(func() -> void:
			_cur = uu
			refresh.call())
		h.add_child(b)
	_body.add_child(h)


func _choose_receiver(k: int) -> void:
	_give_idx = k
	_clear()
	var e: Dictionary = inventory(_cur)[k]
	_title(tr("把%s交给谁？") % tr(item_name(e["id"])))
	for u in battle.prep_pool:
		if u == _cur:
			continue
		var uu: Unit = u
		_button("%s  %d/%d" % [_unit_line(u), u.inventory_size(), Unit.BAG_LIMIT], func() -> void: _give_to(uu), u.inventory_size() < Unit.BAG_LIMIT)
	_button(tr("取消"), show_items)


func _give_to(to: Unit) -> void:
	var it := take_out(_cur, _give_idx)
	to.give(it[0], it[1])
	Audio.play_sfx("select")
	show_items()


func _to_convoy(k: int) -> void:
	var it := take_out(_cur, k)
	Campaign.convoy.append(it)
	Audio.play_sfx("select")
	show_items()


func _from_convoy(i: int) -> void:
	var c: Array = Campaign.convoy[i]
	if _cur.give(c[0], int(c[1])):
		Campaign.convoy.remove_at(i)
		Audio.play_sfx("select")
	show_items()


# ==================== 商店 ====================

func show_shop() -> void:
	_mode = "shop"
	if _cur == null or not (_cur in battle.prep_pool):
		_cur = battle.prep_pool[0]
	_clear()
	_title(tr("商店   %d G") % battle.gold)
	_unit_tabs(show_shop)
	_text(tr("买给：%s（背包满了就送进道具库）") % tr(_cur.display_name), 16)
	for id in battle.shop_items():
		var price := GameData.item_price(id)
		var iid: String = id
		_button("%s  %d G" % [tr(item_name(id)), price], func() -> void: _buy(iid), battle.gold >= price, 38.0)
	_text(tr("—— 卖出（半价）——"), 17, Color(0.85, 0.85, 0.6))
	var inv := inventory(_cur)
	for k in inv.size():
		var e: Dictionary = inv[k]
		var kk: int = k
		var val := sell_price(e["id"], e["uses"])
		_button("%s %s  +%d G" % [tr(item_name(e["id"])), uses_label(e["id"], e["uses"]), val], func() -> void: _sell(kk), val > 0, 38.0)
	_button(tr("返回"), show_menu)


## 卖价：原价一半，按剩余耐久折算；专属武器不能卖
static func sell_price(id: String, uses: int) -> int:
	var full := GameData.item_price(id)
	if full <= 0:
		return 0
	var mx := Unit.max_uses(id)
	if mx <= 0:
		return full / 2
	return int(full * 0.5 * float(maxi(uses, 0)) / float(mx))


func _buy(id: String) -> void:
	var price := GameData.item_price(id)
	if battle.gold < price:
		return
	battle.gold -= price
	if not _cur.give(id):
		Campaign.convoy.append([id, Unit.max_uses(id)])
		battle.notify(tr("%s 的背包满了，%s 送进了道具库") % [tr(_cur.display_name), tr(item_name(id))])
	Audio.play_sfx("coin")
	battle.update_topbar()
	show_shop()


func _sell(k: int) -> void:
	var e: Dictionary = inventory(_cur)[k]
	var val := sell_price(e["id"], e["uses"])
	take_out(_cur, k)
	battle.gold += val
	Audio.play_sfx("coin")
	battle.update_topbar()
	show_shop()
