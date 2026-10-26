class_name HudRTS
extends Hud7
## Demo 1 HUD (M10, D-0044; readability pass D-0045), laid out like Warcraft 3 and
## Legion TD (Jared's reference). A slim see-through top bar: resources with icons
## on the left, the beat bar in the middle (what each beat asks for, a playhead,
## the judgment and the streak under it), level and pause on the right. One short
## bottom panel: the next wave as creep pictures on the left, the selected tower in
## the middle (with its step strip), the command card on the right (pictures, key
## badges, costs). B then a letter picks a build, as in WC3; the number keys still
## work. Q, E and Space are never taken by the HUD. Key hints and run stats live on
## the pause screen; each wave ends with a small summary card.

const BOTTOM_H := 132.0
const TOP_H := 40.0
const CARD := Vector2(96, 34)
## B-chain letters (Jared: "B then E, B then F, B then T").
const BUILD_LETTERS := {KEY_W: "wall", KEY_C: "kick", KEY_S: "bass", KEY_F: "slow", KEY_V: "poison", KEY_L: "lightning", KEY_G: "light"}
const BUILD_ORDER := ["wall", "kick", "bass", "slow", "poison", "lightning", "light"]
## Type scale: one display font, three sizes (Claude's review: "pick one system").
const TITLE := 18
const BODY := 14
const CAPTION := 12

var root: Control
var top_bar: PanelContainer
var bottom: PanelContainer
var grid: GridContainer
var upgrade_cmd: Button
var res_labels := {}
var level_label: Label
var xp_bar: ColorRect
var xp_back: ColorRect
var beat_bar: HudParts.BeatBar
var judgment: Label
var judgment_ms: Label
var streak_label: Label
var info_title: Label
var info_icons: HBoxContainer
var info_body: Label
var song_label: Label
var placeholder: Label
var step_strip: HudParts.StepStrip
var key_badges := {}  # Button -> Label
var cost_labels := {}
var boss_box: PanelContainer
var boss_hp: ColorRect
var boss_posture: ColorRect
var boss_label: Label
var message: Label
var wave_card: PanelContainer
var wave_card_title: Label
var wave_card_body: Label
var wave_card_time := 0.0
var pause_box: Control
var pause_stats: Label
var tree_lines: HudParts.TreeLines
var tree_dim: ColorRect
var build_armed := false
var _icons := {}
var _logged := 0
var _gold_at_start := 0
var _xp_at_start := 0.0
var _level_at_start := 1
var _was_active := false


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
	_build_top()
	_build_bottom()
	_build_middle()
	_build_tree()
	# Demo 1 (M12): the run log goes to the clipboard so friends can paste it back.
	var copy := _button(endless_button.get_parent(), Vector2(150, 40), func():
		DisplayServer.clipboard_set("\n".join(game.run_lines()))
		game._say("Run log copied"))
	copy.text = "Copy run log"
	_bar.visible = false
	tip.add_theme_font_size_override("font_size", CAPTION)
	tip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	tip.add_theme_constant_override("outline_size", 4)
	root.move_child(tip, root.get_child_count() - 1)
	for box in [wave_card, pause_box, draft_box, end_box, tree_dim, tree_box]:
		root.move_child(box, root.get_child_count() - 1)
	_refresh()


func _label(size: int, color := UiTheme.TEXT, heading := false) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if heading:
		l.add_theme_font_override("font", UiTheme.heading_font())
	return l


func _icon(name: String) -> Texture2D:
	if not _icons.has(name):
		var path := "res://assets/icons/%s.png" % name
		_icons[name] = load(path) if ResourceLoader.exists(path) else null
	return _icons[name]


# --- Top bar ---------------------------------------------------------------------------

func _build_top() -> void:
	top_bar = PanelContainer.new()
	var glass := UiTheme.box(Color(0.06, 0.07, 0.09, 0.55), UiTheme.EDGE * Color(1, 1, 1, 0.6), 0, 0, 6.0)
	glass.border_width_bottom = 2
	glass.shadow_size = 0
	top_bar.add_theme_stylebox_override("panel", glass)
	top_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(top_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	top_bar.add_child(row)
	for k in ["gold", "health", "wave", "shield", "restore"]:
		row.add_child(HudParts.Icon.new(k))
		var l := _label(TITLE, UiTheme.TEXT, true)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		l.add_theme_constant_override("outline_size", 4)
		row.add_child(l)
		res_labels[k] = l
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(10, 1)
		row.add_child(gap)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 2)
	lv.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(lv)
	level_label = _label(BODY, Color(0.6, 1.0, 0.7), true)
	lv.add_child(level_label)
	xp_back = ColorRect.new()
	xp_back.color = Color(1, 1, 1, 0.15)
	xp_back.custom_minimum_size = Vector2(150, 6)
	lv.add_child(xp_back)
	xp_bar = ColorRect.new()
	xp_bar.color = Color(0.6, 1.0, 0.7)
	xp_back.add_child(xp_bar)
	# System button up here, out of the command card (Gemini's review).
	remove_child_safe(pause_button)
	pause_button.custom_minimum_size = Vector2(70, 28)
	pause_button.add_theme_font_size_override("font_size", CAPTION)
	row.add_child(pause_button)
	beat_bar = HudParts.BeatBar.new(game)
	root.add_child(beat_bar)


# --- Bottom panel ------------------------------------------------------------------------

func _build_bottom() -> void:
	bottom = PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL, UiTheme.EDGE, 2, 0, 8.0))
	root.add_child(bottom)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bottom.add_child(row)
	# Left: the next wave as pictures (the minimap slot until multiplayer).
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UiTheme.box(Color(0.05, 0.06, 0.08), Color(0.3, 0.26, 0.2), 1, 4, 6.0))
	left.custom_minimum_size = Vector2(290, 0)
	row.add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 2)
	left.add_child(lv)
	info_title = _label(BODY, UiTheme.GOLD, true)
	lv.add_child(info_title)
	info_icons = HBoxContainer.new()
	info_icons.add_theme_constant_override("separation", 2)
	lv.add_child(info_icons)
	info_body = _label(CAPTION, Color(1, 1, 1, 0.8))
	lv.add_child(info_body)
	song_label = _label(CAPTION, Color(1, 1, 1, 0.5))
	song_label.clip_text = true
	song_label.custom_minimum_size = Vector2(270, 0)
	lv.add_child(song_label)
	# Middle: the selected tower, text on the left, its buttons on the right.
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid)
	remove_child_safe(panel)
	mid.add_child(panel)
	_compact_panel()
	placeholder = _label(BODY, Color(1, 1, 1, 0.5))
	placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.text = "Click a tower to see its type and upgrades. Build from the card on the right: click, press the number, or B then the letter."
	mid.add_child(placeholder)
	# Right: the command card.
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	row.add_child(grid)
	for type in BUILD_ORDER:
		if build_buttons.has(type):
			_card(build_buttons[type], true)
			var tex := _icon(("tower_" + type) if type != "wall" else "wall")
			if tex != null:
				build_buttons[type].icon = tex
	upgrade_cmd = Button.new()
	upgrade_cmd.focus_mode = Control.FOCUS_NONE
	upgrade_cmd.pressed.connect(_on_upgrade)
	_card(upgrade_cmd, true)
	for b in [wave_button, restore_button, tree_button]:
		_card(b, true)
	# Start wave is the main action: it looks like it.
	var gold := UiTheme.box(Color(0.42, 0.32, 0.1), UiTheme.GOLD, 2, 5, 4.0)
	wave_button.add_theme_stylebox_override("normal", gold)
	wave_button.add_theme_stylebox_override("hover", UiTheme.box(Color(0.55, 0.42, 0.14), Color.WHITE, 2, 5, 4.0))


## The tower panel: title and step strip, two lines of text, buttons to the right.
func _compact_panel() -> void:
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.custom_minimum_size = Vector2.ZERO
	var vb: VBoxContainer = panel_title.get_parent()
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	panel.remove_child(vb)
	panel.add_child(hb)
	var text_col := VBoxContainer.new()
	text_col.add_theme_constant_override("separation", 3)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(text_col)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(buttons)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	text_col.add_child(head)
	vb.remove_child(panel_title)
	head.add_child(panel_title)
	panel_title.add_theme_font_override("font", UiTheme.heading_font())
	panel_title.add_theme_font_size_override("font_size", BODY + 1)
	panel_title.add_theme_color_override("font_color", UiTheme.GOLD)
	step_strip = HudParts.StepStrip.new(game)
	step_strip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(step_strip)
	vb.remove_child(panel_body)
	text_col.add_child(panel_body)
	panel_body.custom_minimum_size = Vector2(200, 0)
	panel_body.add_theme_font_size_override("font_size", CAPTION + 1)
	for r in [fork_row, panel_row]:
		vb.remove_child(r)
		buttons.add_child(r)
	for b in [upgrade_button, sell_button, fork_a_button, branch_button]:
		b.add_theme_font_size_override("font_size", CAPTION)
	upgrade_button.custom_minimum_size = Vector2(136, 34)
	sell_button.custom_minimum_size = Vector2(90, 34)
	fork_a_button.custom_minimum_size = Vector2(112, 34)
	branch_button.custom_minimum_size = Vector2(112, 34)
	fork_row.add_theme_constant_override("separation", 4)
	vb.queue_free()


func remove_child_safe(c: Node) -> void:
	if c.get_parent() != null:
		c.get_parent().remove_child(c)


## A command card button: picture left, two lines of text, a key badge in the corner.
func _card(b: Button, badge: bool) -> void:
	remove_child_safe(b)
	b.custom_minimum_size = CARD
	b.clip_text = false
	b.expand_icon = false
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("icon_max_width", 26)
	b.add_theme_constant_override("h_separation", 4)
	b.add_theme_font_size_override("font_size", CAPTION)
	b.add_theme_constant_override("line_spacing", -4)
	grid.add_child(b)
	if badge:
		var k := _label(10, Color(1, 1, 1, 0.85), true)
		k.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		k.add_theme_constant_override("outline_size", 3)
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		k.position = Vector2(CARD.x - 23, 2)
		k.size = Vector2(19, 12)
		k.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(k)
		key_badges[b] = k


# --- Middle of the screen -----------------------------------------------------------------

func _build_middle() -> void:
	judgment = _label(26, Color.WHITE, true)
	judgment.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	judgment.add_theme_constant_override("outline_size", 7)
	judgment.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judgment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(judgment)
	judgment_ms = _label(CAPTION, Color(1, 1, 1, 0.85))
	judgment_ms.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	judgment_ms.add_theme_constant_override("outline_size", 4)
	judgment_ms.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judgment_ms.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(judgment_ms)
	streak_label = _label(BODY, UiTheme.GOLD, true)
	streak_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	streak_label.add_theme_constant_override("outline_size", 4)
	streak_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(streak_label)
	boss_box = PanelContainer.new()
	boss_box.add_theme_stylebox_override("panel", UiTheme.box(Color(0.075, 0.085, 0.11, 0.7), Color(0.7, 0.25, 0.35), 2, 4, 5.0))
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(boss_box)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 3)
	boss_box.add_child(bv)
	boss_label = _label(CAPTION + 1, Color(1, 0.75, 0.8), true)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(boss_label)
	var hp_back := ColorRect.new()
	hp_back.color = Color(1, 1, 1, 0.1)
	hp_back.custom_minimum_size = Vector2(380, 10)
	bv.add_child(hp_back)
	boss_hp = ColorRect.new()
	boss_hp.color = Color(0.9, 0.25, 0.4)
	hp_back.add_child(boss_hp)
	var po_back := ColorRect.new()
	po_back.color = Color(1, 1, 1, 0.08)
	po_back.custom_minimum_size = Vector2(380, 5)
	bv.add_child(po_back)
	boss_posture = ColorRect.new()
	boss_posture.color = Color(1.0, 0.9, 0.3)
	po_back.add_child(boss_posture)
	message = _label(BODY, Color(1, 0.6, 0.5))
	message.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	message.add_theme_constant_override("outline_size", 5)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(message)
	# The wave-clear card: what that wave took, in one glance.
	wave_card = PanelContainer.new()
	wave_card.add_theme_stylebox_override("panel", UiTheme.box(Color(0.075, 0.085, 0.11, 0.9), UiTheme.GOLD, 2, 6, 12.0))
	wave_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wave_card.visible = false
	root.add_child(wave_card)
	var wv := VBoxContainer.new()
	wv.add_theme_constant_override("separation", 4)
	wave_card.add_child(wv)
	wave_card_title = _label(22, UiTheme.GOLD, true)
	wave_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wv.add_child(wave_card_title)
	wave_card_body = _label(BODY)
	wave_card_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wv.add_child(wave_card_body)
	# The pause screen: dims the board, holds the controls and the run's numbers.
	pause_box = ColorRect.new()
	(pause_box as ColorRect).color = Color(0, 0, 0, 0.55)
	pause_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_box.visible = false
	root.add_child(pause_box)
	var pc := CenterContainer.new()
	pc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_box.add_child(pc)
	var pp := PanelContainer.new()
	pp.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL, UiTheme.EDGE, 2, 8, 18.0))
	pc.add_child(pp)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 10)
	pp.add_child(pv)
	pv.add_child(UiTheme.heading("Paused", 30))
	pause_stats = _label(BODY, UiTheme.TEXT)
	pv.add_child(pause_stats)
	var keys := _label(BODY, Color(1, 1, 1, 0.85))
	keys.text = "Q, E   play the note on its tower\nSpace   parry, tap again quickly to counter\n1 to 7, or B then a letter   build\nU / I   upgrade or pick a fork   F   Restore a locked tower\nTab   talents   [ ]   change song   F11   full screen\nP   resume   Esc twice   leave the run"
	pv.add_child(keys)
	var resume := _button(pv, Vector2(160, 40), func(): game.toggle_pause())
	resume.text = "Resume  (P)"


# --- The talent tree, redrawn (D-0045) ---------------------------------------------------------

const TREE_COL := 196.0
const TREE_GAP := 30.0
const TREE_ROW := 66.0
const TREE_NODE_H := 40.0


func _build_tree() -> void:
	# Swap Hud7's grid of buttons for the drawn tree: same buttons and refresh, new layout.
	var old := tree_box
	tree_nodes.clear()
	area_points.clear()
	old.queue_free()
	tree_dim = ColorRect.new()
	tree_dim.color = Color(0, 0, 0, 0.6)
	tree_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tree_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	tree_dim.visible = false
	root.add_child(tree_dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var tp := PanelContainer.new()
	tp.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL, UiTheme.EDGE, 2, 8, 14.0))
	center.add_child(tp)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 6)
	tp.add_child(tv)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	tv.add_child(head)
	tree_title = _label(TITLE, Color(0.6, 1.0, 0.7), true)
	tree_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tree_title)
	_button(head, Vector2(130, 32), func(): game.toggle_tree()).text = "Close  (Tab)"
	var areas: Array = TalentTree.AREAS
	var width := areas.size() * TREE_COL + (areas.size() - 1) * TREE_GAP + 2 * 56.0
	var canvas := Control.new()
	canvas.custom_minimum_size = Vector2(width, 44 + 4 * TREE_ROW)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(canvas)
	tree_lines = HudParts.TreeLines.new(game)
	tree_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(tree_lines)
	var nodes: Dictionary = TalentTree.nodes()
	var col_x := {}
	for i in areas.size():
		col_x[areas[i]] = 56.0 + i * (TREE_COL + TREE_GAP)
	var placed := {}
	for area in areas:
		var x0: float = col_x[area]
		var name := _label(BODY + 1, TalentTree.AREA_COLORS[area], true)
		name.text = TalentTree.AREA_NAMES[area]
		name.position = Vector2(x0, 0)
		name.size = Vector2(TREE_COL, 20)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		canvas.add_child(name)
		area_points[area] = _label(10, Color(1, 1, 1, 0.6))
		area_points[area].position = Vector2(x0, 20)
		area_points[area].size = Vector2(TREE_COL, 14)
		area_points[area].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		canvas.add_child(area_points[area])
		var rows: Array = TalentTree.layout(area)
		var spine: Array = []
		for r in rows.size():
			var y := 44.0 + r * TREE_ROW
			var ids: Array = rows[r]
			if r == 1:
				ids = ids.filter(func(id): return not nodes[id].get("shared", false))
			var w := 62.0 if ids.size() == 3 else (TREE_COL if r == 3 else 92.0)
			var total := ids.size() * w + (ids.size() - 1) * 5.0
			for k in ids.size():
				var id: String = ids[k]
				var b := _node_button(area + ":" + id, id, nodes[id], Vector2(w, TREE_NODE_H))
				b.position = Vector2(x0 + (TREE_COL - total) * 0.5 + k * (w + 5.0), y)
				b.size = Vector2(w, TREE_NODE_H)
				_style_node(b, [area], r == 3)
				canvas.add_child(b)
			spine.append(Vector2(x0 + TREE_COL * 0.5, y + TREE_NODE_H * 0.5))
		tree_lines.spines[area] = spine
	# Shared nodes, once each, between the two areas they belong to. The ring's last
	# pair (Defence and Rhythm) sits past Defence's right edge.
	for i in areas.size():
		var a: String = areas[i]
		var b_area: String = areas[(i + 1) % areas.size()]
		var sid := ""
		for id in nodes:
			var n: Dictionary = nodes[id]
			if n.get("shared", false) and n["areas"].has(a) and n["areas"].has(b_area):
				sid = id
		if sid == "" or placed.has(sid):
			continue
		placed[sid] = true
		var y := 44.0 + TREE_ROW
		var cx: float = col_x[a] + TREE_COL + TREE_GAP * 0.5
		var w := 104.0
		if i == areas.size() - 1:
			cx = col_x[a] + TREE_COL + 6.0 + w * 0.5 - 50.0
		var btn := _node_button("shared:" + sid, sid, nodes[sid], Vector2(w, TREE_NODE_H))
		btn.position = Vector2(cx - w * 0.5, y)
		btn.size = Vector2(w, TREE_NODE_H)
		_style_node(btn, [a, b_area], false)
		canvas.add_child(btn)
		var mid := Vector2(cx, y + TREE_NODE_H * 0.5)
		tree_lines.links.append([mid, a, b_area, tree_lines.spines[a][1], tree_lines.spines[b_area][1]])
	var foot := _label(CAPTION, Color(1, 1, 1, 0.55))
	foot.text = "Numbers on a line: points the area needs to open the next row. A node between two areas counts for both. Hover a node for what it does."
	tv.add_child(foot)
	tree_box = center
	tree_box.visible = false


func _style_node(b: Button, areas: Array, capstone: bool) -> void:
	var col: Color = TalentTree.AREA_COLORS[areas[0]]
	var edge2: Color = TalentTree.AREA_COLORS[areas[-1]]
	var normal := UiTheme.box(Color(0.13, 0.14, 0.17), col * Color(1, 1, 1, 0.8), 3 if capstone else 2, 6 if capstone else 5, 4.0)
	if areas.size() > 1:
		normal.border_color = col.lerp(edge2, 0.5)
		normal.border_width_top = 3
	var hover := UiTheme.box(Color(0.2, 0.21, 0.25), Color.WHITE, 2, 5, 4.0)
	var disabled := UiTheme.box(Color(0.09, 0.1, 0.12), col * Color(1, 1, 1, 0.3), 2, 5, 4.0)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_font_size_override("font_size", CAPTION if not capstone else BODY)


# --- Every frame --------------------------------------------------------------------------

func _layout() -> void:
	if root == null:
		return
	var view := get_viewport().get_visible_rect().size
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(view.x, TOP_H)
	bottom.position = Vector2(0, view.y - BOTTOM_H)
	bottom.size = Vector2(view.x, BOTTOM_H)
	beat_bar.position = Vector2(view.x * 0.5 - HudParts.BeatBar.W * 0.5, (TOP_H - HudParts.BeatBar.H) * 0.5)
	var y := TOP_H + 4.0
	boss_box.position = Vector2(view.x * 0.5 - boss_box.size.x * 0.5, y)
	if boss_box.visible:
		y += boss_box.size.y + 2.0
	judgment.size = Vector2(view.x, 32)
	judgment.position = Vector2(0, y)
	judgment_ms.size = Vector2(view.x, 16)
	judgment_ms.position = Vector2(0, y + 32)
	streak_label.position = Vector2(view.x * 0.5 + HudParts.BeatBar.W * 0.5 + 10.0, (TOP_H - 22) * 0.5)
	message.size = Vector2(view.x, 22)
	message.position = Vector2(0, view.y - BOTTOM_H - 30.0)
	wave_card.position = Vector2(view.x * 0.5 - wave_card.size.x * 0.5, y + 52.0)
	tip.position = Vector2(14, view.y - BOTTOM_H - 22.0)


func mouse_over_ui() -> bool:
	if root == null:
		return false
	var m := get_viewport().get_mouse_position()
	if draft_box.visible or end_box.visible or tree_box.visible or pause_box.visible:
		return true
	return top_bar.get_global_rect().has_point(m) or bottom.get_global_rect().has_point(m)


func _process(delta: float) -> void:
	wave_card_time = maxf(0.0, wave_card_time - delta)
	super._process(delta)


func _refresh() -> void:
	if root == null:
		return
	super._refresh()
	_refresh_top()
	_refresh_info()
	_refresh_judgment()
	_refresh_wave_card()
	placeholder.visible = not panel.visible
	tree_dim.visible = tree_box.visible
	message.text = game._message if game._message_time > 0.0 else ""
	pause_box.visible = game.paused and not game.tree_open and game.state == "playing"
	if pause_box.visible:
		pause_stats.text = _stats_line()


func _stats_line() -> String:
	var notes: int = game.stat_total("notes")
	var hits: int = game.stat_total("hits")
	var thrown: int = game.m4_stats["pulses"] + game.m4_stats["arrows"] + game.m5_stats["bolts"] + game.m6_stats["stomps"]
	var parried: int = game.m4_stats["parried"] + game.m5_stats["parries"] + game.m6_stats["stomp_parries"]
	return "This run: notes %d/%d   Perfects %d   parries %d/%d   counters %d/%d" % [hits, notes, game.stat_total("perfects"), parried, thrown, game.m7_stats["counter_hits"], game.m7_stats["counters"]]


func _refresh_top() -> void:
	var wave_text := ("%d (endless)" % game.wave) if game.endless or game.wave > game.last_wave else ("%d / %d" % [maxi(game.wave, 1) if game.wave_active else game.wave, game.last_wave])
	res_labels["gold"].text = str(game.gold)
	res_labels["health"].text = str(game.health)
	res_labels["wave"].text = wave_text
	res_labels["shield"].text = "%d/%d" % [game.shields, game.shield_cap]
	res_labels["restore"].text = "%d/%d" % [game.restore_charges, game.restore_cap()]
	level_label.text = "Level %d" % game.level
	xp_bar.size = Vector2(xp_back.size.x * clampf(game.xp / game.xp_to_next(), 0.0, 1.0), xp_back.size.y)
	boss_box.visible = game.boss_alive()
	if boss_box.visible:
		var boss: Dictionary = game.boss
		boss_label.text = ("THE CROWNED BOSS" if boss.get("second", false) else "THE BOSS") + "     posture %d%%     breaks %d" % [roundi(game.posture), game.m5_stats["breaks"]]
		boss_hp.size = Vector2(boss_hp.get_parent().size.x * clampf(boss["hp"] / boss["max_hp"], 0.0, 1.0), 10)
		boss_posture.size = Vector2(boss_posture.get_parent().size.x * clampf(game.posture / game.POSTURE_MAX, 0.0, 1.0), 5)


## The judgment under the beat bar: one word, the timing small under it.
func _refresh_judgment() -> void:
	var text := ""
	var color: Color = game._feedback_color
	if game.crescendo > 0.0:
		text = "CRESCENDO  %.1f" % game.crescendo
		color = UiTheme.GOLD
	elif game._feedback_time > 0.0 and game._feedback != "PAUSED":
		text = game._feedback
	judgment.text = text
	judgment.add_theme_color_override("font_color", color)
	judgment.modulate.a = 1.0 if game.crescendo > 0.0 else clampf(game._feedback_time / 0.3, 0.0, 1.0)
	judgment_ms.text = game.feedback_ms if text != "" and game.crescendo <= 0.0 else ""
	judgment_ms.modulate.a = judgment.modulate.a
	var s: int = game.streak
	streak_label.text = ("Streak %d" % s + ("   x%d" % (game.intensity + 1) if game.intensity > 0 else "")) if s >= 2 else ""


## A wave ends: show what it took for a few seconds (the per-wave log, D-0041).
func _refresh_wave_card() -> void:
	if game.wave_active and not _was_active:
		_gold_at_start = game.gold
		_level_at_start = game.level
	_was_active = game.wave_active
	if game.wave_log.size() > _logged:
		_logged = game.wave_log.size()
		var line: String = game.wave_log[-1]
		var parts := line.split("  ", false)
		wave_card_title.text = "WAVE %d CLEAR" % game.wave
		var body := "   ".join(parts.slice(1)).replace("hp -0", "no health lost").replace("hp -", "health lost ")
		var gained: int = game.gold - _gold_at_start
		if gained > 0:
			body += "\ngold +%d" % gained
		if game.level > _level_at_start:
			body += "   level up: %d" % game.level
		wave_card_body.text = body
		wave_card_time = 4.5
	elif game.wave_log.size() < _logged:
		_logged = game.wave_log.size()  # A new run.
	wave_card.visible = wave_card_time > 0.0 and not game.wave_active and game.get("drafting") != true
	wave_card.modulate.a = clampf(wave_card_time / 0.5, 0.0, 1.0)


func _refresh_info() -> void:
	var next: int = game.wave + (0 if game.wave_active else 1)
	var show: int = next if not game.wave_active else game.wave + 1
	info_title.text = ("Next: wave %d" % show) + ("   (wave %d running)" % game.wave if game.wave_active else "")
	var key := str(show)
	if info_icons.get_meta("wave", "") != key:
		info_icons.set_meta("wave", key)
		for c in info_icons.get_children():
			c.queue_free()
		var counts := {}
		var order: Array[String] = []
		for g in WaveScript.groups(show):
			if not counts.has(g["kind"]):
				counts[g["kind"]] = 0
				order.append(g["kind"])
			counts[g["kind"]] += g["count"]
		if game.boss_waves.has(show):
			order.push_front("boss2" if game.is_boss2_wave(show) else "boss")
			counts[order[0]] = 1
		for k in order.slice(0, 8):
			var cell := VBoxContainer.new()
			cell.add_theme_constant_override("separation", -4)
			var tr := TextureRect.new()
			tr.texture = _icon("creep_" + k)
			tr.custom_minimum_size = Vector2(34, 34)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.tooltip_text = k.capitalize()
			cell.add_child(tr)
			var n := _label(CAPTION, Color(1, 0.4, 0.45) if k.begins_with("boss") else UiTheme.TEXT, true)
			n.text = "BOSS" if k.begins_with("boss") else "x%d" % counts[k]
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(n)
			info_icons.add_child(cell)
	var hp_text := "%.0f HP each" % game.creep_hp_at(show)
	if game.wave_active:
		info_body.text = hp_text
	else:
		info_body.text = "%s.  N or the gold button starts it." % hp_text
	if not game.pending.is_empty():
		info_body.text += "\nLocked card: %s" % game.card_name(game.pending["id"])
	song_label.text = "Song: %s   [ ] switch" % game.songs[game.song_index]["name"]


func _refresh_panel() -> void:
	super._refresh_panel()
	if not panel.visible:
		return
	var type := _panel_type()
	step_strip.type = type if game.is_tower(type) else ""
	step_strip.visible = game.is_tower(type)
	if type == "wall" or not game.is_tower(type):
		return
	var cell: Vector2i = game.selected_cell
	var has_tower: bool = game.structures.has(cell)
	var rank: int = game.type_rank.get(type, 0)
	var branch: int = game.type_branch.get(type, 0)
	var spec: Dictionary = game.tower_spec(cell) if has_tower else game.type_spec(type)
	panel_title.text = "%s  x%d   rung %d/5%s" % [game.tower_name(type), game.towers_of(type), rank, ("  " + game.BRANCHES[type][branch - 1][0]) if branch > 0 else ""]
	var stats := "Damage %.0f   Range %.1f" % [spec["damage"], spec["range"]]
	if spec.get("splash", 0.0) > 0.0:
		stats += "   Splash %.1f" % spec["splash"]
	if spec.has("slow"):
		stats += "   Slows %.1f s" % spec["slow"]
	var body := stats + "\nNote: " + note_text(type)
	if not game.unlocked.has(type):
		body += "\nLOCKED: " + game.unlock_text(type)
	elif has_tower and game.suppressed.has(cell):
		body += "\nLocked for %.1f s. F to Restore." % game.suppressed[cell]
	elif rank == 2:
		var br: Array = game.BRANCHES[type]
		body += "\nFork: %s or %s" % [br[0][0], br[1][0]]
	panel_body.text = body
	panel_body.tooltip_text = "Upgrades apply to every %s on the board." % game.tower_name(type)


func _refresh_bar() -> void:
	var playing: bool = game.state == "playing"
	for type in build_buttons:
		var b: Button = build_buttons[type]
		var spec: Dictionary = game.builds[type]
		var locked: bool = not game.unlocked.has(type)
		var short: int = spec["cost"] - game.gold
		var name: String = "Wall %d/%d" % [game.wall_count(), game.wall_limit] if type == "wall" and game.wall_limit > 0 else game.tower_name(type)
		if locked:
			b.text = "%s\nlocked" % name
		elif short > 0:
			b.text = "%s\n%dg  (-%d)" % [name, spec["cost"], short]
		else:
			b.text = "%s\n%dg" % [name, spec["cost"]]
		if key_badges.has(b):
			key_badges[b].text = _letter(type) if build_armed else _key(type)
		b.button_pressed = game.selected == type and game.build_mode
		b.disabled = not playing or locked or short > 0
		b.tooltip_text = _build_tooltip(type)
		b.modulate = Color(1.0, 0.95, 0.7) if build_armed and not locked else (Color(0.6, 0.6, 0.65) if locked else Color.WHITE)
		b.add_theme_color_override("font_disabled_color", Color(1, 0.55, 0.5) if short > 0 and not locked else Color(0.55, 0.55, 0.55))
	wave_button.text = ("Wave %d\nrunning" % game.wave) if game.wave_active else "Start\nwave"
	wave_button.disabled = game.wave_active or not playing or game.get("drafting") == true
	restore_button.text = "Restore\n%d/%d" % [game.restore_charges, game.restore_cap()]
	restore_button.disabled = not playing or game.restore_charges <= 0 or game.suppressed.is_empty()
	pause_button.text = "Resume" if game.paused else "Pause"
	pause_button.disabled = not playing
	tree_button.text = "Talents" + ("\n+%d" % game.points if game.points > 0 else "")
	tree_button.modulate = Color(0.6, 1.0, 0.7) if game.points > 0 else Color.WHITE
	tree_button.disabled = not playing
	for pair in [[wave_button, "N"], [restore_button, "F"], [tree_button, "Tab"], [upgrade_cmd, "U"]]:
		if key_badges.has(pair[0]):
			key_badges[pair[0]].text = pair[1]
	var type := _panel_type()
	upgrade_cmd.text = "Upgrade\n-"
	upgrade_cmd.disabled = true
	upgrade_cmd.icon = null
	if type != "" and game.is_tower(type) and game.unlocked.has(type) and game.type_rank.get(type, 0) < 5:
		var cost: int = game.type_upgrade_cost(type)
		upgrade_cmd.icon = _icon("tower_" + type)
		upgrade_cmd.text = ("Fork\nU / I" if game.type_rank.get(type, 0) == 2 else "Upgrade\n%dg" % cost)
		upgrade_cmd.disabled = not playing or game.gold < cost or game.type_rank.get(type, 0) == 2
		upgrade_cmd.tooltip_text = "%s rung %d: %s" % [game.tower_name(type), game.type_rank.get(type, 0) + 1, game.rung_text(type, game.type_rank.get(type, 0) + 1)]


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


## One line over the board at most, and never the talent nag (the green Talents
## button already says it; Claude's review counted it three times).
func _tip() -> String:
	if build_armed:
		return "Build: W wall, C Cannon, S Splash, F Frost, V Poison, L Lightning, G Light.  Esc backs out."
	if game.tree_open or game.get("drafting") == true or game.paused:
		return ""
	if game.build_mode and game.selected != "":
		return "Click to place %s. Right click or Esc to stop building." % game.tower_name(game.selected)
	return ""


## Locked talents stay readable: the dark disabled style says "not yet", not a fade.
func _refresh_tree() -> void:
	super._refresh_tree()
	if not game.tree_open:
		return
	for key in tree_nodes:
		var b: Button = tree_nodes[key]
		if b.disabled and b.modulate.a < 0.9:
			b.modulate = Color(1, 1, 1, 0.85) if b.modulate.a > 0.3 else Color(1, 1, 1, 0.6)
