class_name HudRTS
extends Hud7
## Demo 1 HUD (M10, D-0044), laid out like Warcraft 3 and Legion TD (Jared's
## reference): resources along the top, the bar strip and boss bar under them,
## and one bottom panel with the wave preview on the left (the minimap slot), the
## selected tower in the middle and the command card on the right (4 x 3, every
## button shows its key). B then a letter picks a build, as in WC3; the number keys
## still work. Q, E and Space are never taken by the HUD. Everything M7's HUD did
## (forks, the draft, the tree, the end screen) is still here, restyled.

const BOTTOM_H := 168.0
const TOP_H := 44.0
## B-chain letters (Jared: "B then E, B then F, B then T").
const BUILD_LETTERS := {KEY_W: "wall", KEY_C: "kick", KEY_S: "bass", KEY_F: "slow", KEY_V: "poison", KEY_L: "lightning", KEY_G: "light"}

var root: Control
var top_bar: PanelContainer
var bottom: PanelContainer
var grid: GridContainer
var upgrade_cmd: Button
var res_label: Label
var stats_label: Label
var level_label: Label
var xp_bar: ColorRect
var xp_back: ColorRect
var title_label: Label
var info_title: Label
var info_body: Label
var hint_body: Label
var placeholder: Label
var strip: HBoxContainer
var strip_cells: Array[Label] = []
var boss_box: PanelContainer
var boss_hp: ColorRect
var boss_posture: ColorRect
var boss_label: Label
var feedback: Label
var message: Label
var build_armed := false


func _ready() -> void:
	super._ready()
	root = Control.new()
	root.name = "Root"
	root.theme = UiTheme.get_theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	for ch in get_children():
		if ch != root and ch is Control:
			remove_child(ch)
			root.add_child(ch)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.custom_minimum_size = Vector2(330, 0)
	panel_body.custom_minimum_size = Vector2(330, 0)
	_build_top()
	_build_bottom()
	_build_middle()
	# Demo 1 (M12): the run log goes to the clipboard so friends can paste it back.
	var copy := _button(endless_button.get_parent(), Vector2(150, 40), func():
		DisplayServer.clipboard_set("\n".join(game.run_lines()))
		game._say("Run log copied"))
	copy.text = "Copy run log"
	_bar.visible = false
	tip.add_theme_font_size_override("font_size", 13)
	tip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	tip.add_theme_constant_override("outline_size", 4)
	root.move_child(tip, root.get_child_count() - 1)
	for box in [draft_box, end_box, tree_box]:
		root.move_child(box, root.get_child_count() - 1)
	_refresh()


func _label(size: int, color := UiTheme.TEXT) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _build_top() -> void:
	top_bar = PanelContainer.new()
	top_bar.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL_SOFT, UiTheme.EDGE, 2, 0, 8.0))
	root.add_child(top_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	top_bar.add_child(row)
	res_label = _label(16)
	res_label.add_theme_font_override("font", UiTheme.heading_font())
	row.add_child(res_label)
	title_label = _label(15, UiTheme.GOLD)
	title_label.add_theme_font_override("font", UiTheme.heading_font())
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(title_label)
	stats_label = _label(13, Color(1, 1, 1, 0.8))
	row.add_child(stats_label)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 2)
	row.add_child(lv)
	level_label = _label(13, Color(0.6, 1.0, 0.7))
	lv.add_child(level_label)
	xp_back = ColorRect.new()
	xp_back.color = Color(1, 1, 1, 0.12)
	xp_back.custom_minimum_size = Vector2(130, 5)
	lv.add_child(xp_back)
	xp_bar = ColorRect.new()
	xp_bar.color = Color(0.6, 1.0, 0.7)
	xp_back.add_child(xp_bar)


func _build_bottom() -> void:
	bottom = PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL, UiTheme.EDGE, 2, 0, 10.0))
	root.add_child(bottom)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	bottom.add_child(row)
	# Left: the wave preview (the minimap slot until multiplayer).
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UiTheme.box(Color(0.05, 0.06, 0.08), Color(0.3, 0.26, 0.2), 1, 4, 8.0))
	left.custom_minimum_size = Vector2(300, 0)
	row.add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 3)
	left.add_child(lv)
	info_title = UiTheme.heading("", 17)
	lv.add_child(info_title)
	info_body = _label(13)
	info_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_body.custom_minimum_size = Vector2(280, 0)
	lv.add_child(info_body)
	hint_body = _label(11, Color(1, 1, 1, 0.55))
	hint_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_body.custom_minimum_size = Vector2(280, 0)
	lv.add_child(hint_body)
	# Middle: the selected tower's panel, or a hint when nothing is selected.
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid)
	remove_child_safe(panel)
	mid.add_child(panel)
	placeholder = _label(13, Color(1, 1, 1, 0.55))
	placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mid.add_child(placeholder)
	# Right: the command card.
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	row.add_child(grid)
	for type in ["wall", "kick", "bass", "slow", "poison", "lightning", "light"]:
		if build_buttons.has(type):
			_card(build_buttons[type])
	upgrade_cmd = Button.new()
	upgrade_cmd.focus_mode = Control.FOCUS_NONE
	upgrade_cmd.pressed.connect(_on_upgrade)
	_card(upgrade_cmd)
	for b in [wave_button, restore_button, tree_button, pause_button]:
		_card(b)


func remove_child_safe(c: Node) -> void:
	if c.get_parent() != null:
		c.get_parent().remove_child(c)


func _card(b: Button) -> void:
	remove_child_safe(b)
	b.custom_minimum_size = Vector2(92, 46)
	b.clip_text = false
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_constant_override("line_spacing", -3)
	grid.add_child(b)


func _build_middle() -> void:
	strip = HBoxContainer.new()
	strip.add_theme_constant_override("separation", 4)
	root.add_child(strip)
	for i in 4:
		var l := _label(14)
		l.add_theme_font_override("font", UiTheme.heading_font())
		l.custom_minimum_size = Vector2(84, 24)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		strip.add_child(l)
		strip_cells.append(l)
	boss_box = PanelContainer.new()
	boss_box.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL_SOFT, Color(0.7, 0.25, 0.35), 2, 4, 6.0))
	root.add_child(boss_box)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 3)
	boss_box.add_child(bv)
	boss_label = _label(13, Color(1, 0.75, 0.8))
	boss_label.add_theme_font_override("font", UiTheme.heading_font())
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(boss_label)
	var hp_back := ColorRect.new()
	hp_back.color = Color(1, 1, 1, 0.1)
	hp_back.custom_minimum_size = Vector2(420, 12)
	bv.add_child(hp_back)
	boss_hp = ColorRect.new()
	boss_hp.color = Color(0.9, 0.25, 0.4)
	hp_back.add_child(boss_hp)
	var po_back := ColorRect.new()
	po_back.color = Color(1, 1, 1, 0.08)
	po_back.custom_minimum_size = Vector2(420, 6)
	bv.add_child(po_back)
	boss_posture = ColorRect.new()
	boss_posture.color = Color(1.0, 0.9, 0.3)
	po_back.add_child(boss_posture)
	feedback = _label(22)
	feedback.add_theme_font_override("font", UiTheme.heading_font())
	feedback.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	feedback.add_theme_constant_override("outline_size", 6)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(feedback)
	message = _label(15, Color(1, 0.55, 0.45))
	message.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	message.add_theme_constant_override("outline_size", 5)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(message)


func _layout() -> void:
	if root == null:
		return
	var view := get_viewport().get_visible_rect().size
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(view.x, TOP_H)
	bottom.position = Vector2(0, view.y - BOTTOM_H)
	bottom.size = Vector2(view.x, BOTTOM_H)
	strip.position = Vector2(view.x * 0.5 - strip.size.x * 0.5, TOP_H + 6.0)
	boss_box.position = Vector2(view.x * 0.5 - boss_box.size.x * 0.5, TOP_H + 36.0)
	feedback.size = Vector2(view.x, 30)
	feedback.position = Vector2(0, TOP_H + (100.0 if boss_box.visible else 40.0))
	message.size = Vector2(view.x, 24)
	message.position = Vector2(0, view.y - BOTTOM_H - 52.0)
	tip.position = Vector2(14, view.y - BOTTOM_H - 24.0)


func mouse_over_ui() -> bool:
	if root == null:
		return false
	var m := get_viewport().get_mouse_position()
	if draft_box.visible or end_box.visible or tree_box.visible:
		return true
	return top_bar.get_global_rect().has_point(m) or bottom.get_global_rect().has_point(m)


func _refresh() -> void:
	if root == null:
		return
	super._refresh()
	_refresh_top()
	_refresh_info()
	_refresh_strip()
	placeholder.visible = not panel.visible
	placeholder.text = "Select a tower (click it) to see its type's upgrades, or pick a build on the right: click its button, press its number, or B then its letter."
	feedback.text = game._feedback if game._feedback_time > 0.0 else ""
	feedback.add_theme_color_override("font_color", game._feedback_color)
	feedback.modulate.a = clampf(game._feedback_time / 0.3, 0.0, 1.0)
	message.text = game._message if game._message_time > 0.0 else ""


func _refresh_top() -> void:
	var wave_label := ("Wave %d (endless)" % game.wave) if game.endless or game.wave > game.last_wave else ("Wave %d / %d" % [maxi(game.wave, 1) if game.wave_active else game.wave, game.last_wave])
	res_label.text = "Gold %d     Health %d     %s     Shields %d/%d     Restores %d/%d" % [game.gold, game.health, wave_label, game.shields, game.shield_cap, game.restore_charges, game.restore_cap()]
	title_label.text = "PAUSED" if game.paused else ("CRESCENDO  %.1f s" % game.crescendo if game.crescendo > 0.0 else "")
	var notes: int = game.stat_total("notes")
	var hits: int = game.stat_total("hits")
	var thrown: int = game.m4_stats["pulses"] + game.m4_stats["arrows"] + game.m5_stats["bolts"] + game.m6_stats["stomps"]
	var parried: int = game.m4_stats["parried"] + game.m5_stats["parries"] + game.m6_stats["stomp_parries"]
	stats_label.text = "Notes %d/%d   Perfects %d   Parries %d/%d   Counters %d/%d" % [hits, notes, game.stat_total("perfects"), parried, thrown, game.m7_stats["counter_hits"], game.m7_stats["counters"]]
	level_label.text = "Level %d%s" % [game.level, ("   %d point%s (Tab)" % [game.points, "" if game.points == 1 else "s"]) if game.points > 0 else ""]
	xp_bar.size = Vector2(xp_back.size.x * clampf(game.xp / game.xp_to_next(), 0.0, 1.0), xp_back.size.y)
	boss_box.visible = game.boss_alive()
	if boss_box.visible:
		var boss: Dictionary = game.boss
		boss_label.text = ("THE CROWNED BOSS" if boss.get("second", false) else "THE BOSS") + "   %d   posture %d%%   breaks %d" % [maxi(int(boss["hp"]), 0), roundi(game.posture), game.m5_stats["breaks"]]
		boss_hp.size = Vector2(boss_hp.get_parent().size.x * clampf(boss["hp"] / boss["max_hp"], 0.0, 1.0), 12)
		boss_posture.size = Vector2(boss_posture.get_parent().size.x * clampf(game.posture / game.POSTURE_MAX, 0.0, 1.0), 6)


func _refresh_info() -> void:
	var next: int = game.wave + (0 if game.wave_active else 1)
	if game.wave_active:
		info_title.text = "Wave %d" % game.wave
		info_body.text = "%s\nNext: %s" % [game.wave_summary(game.wave), game.wave_summary(game.wave + 1)]
	else:
		info_title.text = "Next: wave %d" % next
		info_body.text = "%s\n%.0f HP each.  Start it with N or the button." % [game.wave_summary(next), game.creep_hp_at(next)]
	if not game.pending.is_empty():
		info_body.text += "\nLocked card: %s (%s)" % [game.card_name(game.pending["id"]), game.card_condition(game.pending["id"])]
	var song: String = game.songs[game.song_index]["name"]
	var hints := "Song: %s   [ ] switch\n" % song
	if Prefs.get_value("key_hints"):
		hints += "Q/E notes   Space parry, tap again to counter\nF Restore   B build   Tab talents   Esc x2 leave"
	hint_body.text = hints


## The bar strip (D-0041): what each beat of the bar asks for, the live beat lit.
func _refresh_strip() -> void:
	var show: bool = game.wave_active and game.state == "playing"
	strip.visible = show
	if not show:
		return
	var beat: float = game.clock.beat_length()
	var cur := posmod(floori(game.beat_time() / beat), 4)
	var labels: Array = ["1 parry"]
	for i in 3:
		labels.append("%d %s" % [i + 2, game._wave_pattern[i].replace(".", "-")])
	if game.boss_alive():
		labels = ["1 parry", "2 -", "3 Q", "4 -"] if game.crescendo <= 0.0 else ["CRES", "CEN", "DO", "!"]
	for i in 4:
		var l := strip_cells[i]
		l.text = labels[i]
		var col := Color(1.0, 0.6, 0.35) if i > 0 else Color(1.0, 0.9, 0.3)
		if i > 0 and not game.boss_alive() and game._wave_pattern[i - 1] == "E":
			col = Color(0.7, 0.45, 1.0)
		var lit := i == cur
		var sb := UiTheme.box(col * Color(1, 1, 1, 0.5 if lit else 0.14), col * Color(1, 1, 1, 0.95 if lit else 0.4), 2, 4, 2.0)
		l.add_theme_stylebox_override("normal", sb)
		l.add_theme_color_override("font_color", Color(1, 1, 1, 1.0 if lit else 0.65))


func _key(type: String) -> String:
	for k in game.build_keys:
		if game.build_keys[k] == type:
			return OS.get_keycode_string(k)
	return ""


func _letter(type: String) -> String:
	for k in BUILD_LETTERS:
		if BUILD_LETTERS[k] == type:
			return OS.get_keycode_string(k)
	return ""


func _refresh_bar() -> void:
	var playing: bool = game.state == "playing"
	for type in build_buttons:
		var b: Button = build_buttons[type]
		var spec: Dictionary = game.builds[type]
		var key := ("[%s]" % _letter(type)) if build_armed else _key(type)
		var locked: bool = not game.unlocked.has(type)
		if locked:
			b.text = "%s\nlocked" % game.tower_name(type)
		else:
			b.text = "%s\n%s  %dg" % [game.tower_name(type), key, spec["cost"]]
			if type == "wall" and game.wall_limit > 0:
				b.text = "Wall %d/%d\n%s  %dg" % [game.wall_count(), game.wall_limit, key, spec["cost"]]
			elif game.type_rank.get(type, 0) > 0:
				b.text = "%s r%d\n%s  %dg" % [game.tower_name(type), game.type_rank[type], key, spec["cost"]]
		b.button_pressed = game.selected == type and game.build_mode
		b.disabled = not playing or locked or game.gold < spec["cost"]
		b.tooltip_text = _build_tooltip(type)
		b.modulate = Color(1.0, 0.95, 0.7) if build_armed and not locked else Color.WHITE
	wave_button.text = ("Wave %d\nrunning" % game.wave) if game.wave_active else "Start wave\nN"
	wave_button.disabled = game.wave_active or not playing or game.get("drafting") == true
	restore_button.text = "Restore %d/%d\nF" % [game.restore_charges, game.restore_cap()]
	restore_button.disabled = not playing or game.restore_charges <= 0 or game.suppressed.is_empty()
	pause_button.text = "Resume\nP" if game.paused else "Pause\nP"
	pause_button.disabled = not playing
	tree_button.text = "Talents%s\nTab" % ("  +%d" % game.points if game.points > 0 else "")
	tree_button.modulate = Color(0.6, 1.0, 0.7) if game.points > 0 else Color.WHITE
	tree_button.disabled = not playing
	var type := _panel_type()
	upgrade_cmd.text = "Upgrade\nU"
	upgrade_cmd.disabled = true
	if type != "" and game.is_tower(type) and game.unlocked.has(type) and game.type_rank.get(type, 0) < 5:
		var cost: int = game.type_upgrade_cost(type)
		upgrade_cmd.text = ("Fork\nU / I" if game.type_rank.get(type, 0) == 2 else "Upgrade\nU  %dg" % cost)
		upgrade_cmd.disabled = not playing or game.gold < cost or game.type_rank.get(type, 0) == 2
		upgrade_cmd.tooltip_text = "%s rung %d: %s" % [game.tower_name(type), game.type_rank.get(type, 0) + 1, game.rung_text(type, game.type_rank.get(type, 0) + 1)]


func _build_tooltip(type: String) -> String:
	if type == "wall":
		return "Wall: blocks the path, creeps reroute live. Key 1, or B then W."
	var spec: Dictionary = game.type_spec(type)
	var text := "%s  %dg\nDamage %.0f   Range %.1f\nIts note: %s\nKey %s, or B then %s." % [game.tower_name(type), game.builds[type]["cost"], spec["damage"], spec["range"], note_text(type), _key(type), _letter(type)]
	if not game.unlocked.has(type):
		text += "\nLOCKED: " + game.unlock_text(type)
	return text


## B then a letter picks a build (WC3 style). Esc or B again backs out.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if game.state != "playing" or game.paused or game.get("drafting") == true:
		build_armed = false
		return
	if event.keycode == KEY_B:
		build_armed = not build_armed
		get_viewport().set_input_as_handled()
		return
	if not build_armed:
		return
	if BUILD_LETTERS.has(event.keycode):
		var type: String = BUILD_LETTERS[event.keycode]
		build_armed = false
		get_viewport().set_input_as_handled()
		if not game.unlocked.has(type):
			game._say("%s is locked: %s" % [game.tower_name(type), game.unlock_text(type)])
			return
		game.selected = type
		game.build_mode = true
		game.selected_cell = Vector2i(-1, -1)
		return
	if event.keycode == KEY_ESCAPE:
		build_armed = false
		get_viewport().set_input_as_handled()


func _tip() -> String:
	if build_armed:
		return "Build: W wall, C Cannon, S Splash, F Frost, V Poison, L Lightning, G Light.  Esc backs out."
	return super._tip()
