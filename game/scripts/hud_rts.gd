class_name HudRTS
extends Hud7
## Demo 1 HUD (M10, D-0044; readability pass D-0045; round 2 D-0046), laid out
## like Warcraft 3 and Legion TD (Jared's reference). A slim see-through top bar:
## resources with icons on the left, the streak in the middle, pause on the right;
## the judgment word sits under it. One bottom panel: the next wave as creep
## pictures on the left; in the middle the selected tower, then the game controls
## as round buttons (Talents, Restore, Start wave) and a WoW-style XP bar under
## them (Jared's layout); the build card on the right holds only the wall, the
## towers and Upgrade. UI slice A (D-0062): B opens build mode and B again closes
## it, the mouse wheel picks the tower, the number keys still work; a tag by the
## cursor shows the price and your gold; hovering a tower shows X sell and U upgrade. Q, E and Space are never taken by the HUD. Every tooltip is
## instant and laid out by Explain. Key hints and run stats live on the pause
## screen; each wave ends with a small summary card.

const BOTTOM_H := 100.0
const SLOT := 56.0  # A build slot and a game control are the same square (T-038).
const TOP_H := 40.0
const CARD := Vector2(96, 34)
## The old B-then-letter chain, retired by D-0062 (B then the mouse wheel).
const BUILD_LETTERS := {KEY_W: "wall", KEY_C: "kick", KEY_S: "bass", KEY_F: "slow", KEY_V: "poison", KEY_L: "lightning", KEY_G: "light"}
const BUILD_ORDER := ["wall", "kick", "bass", "slow", "poison", "lightning", "light"]
## The note on one line for the tower panel; the tooltip has the whole story.
const SHORT_NOTES := {"kick": "snipe x4 (x8 Perfect)", "bass": "wave x2 within 2 tiles", "slow": "freeze within 2 tiles", "poison": "spread poison within 2 tiles", "lightning": "storm on every creep", "light": "towers in its light fire"}
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
var xp: HudParts.XPBar  # Retired by the XP line (T-038).
var xp_line: HudKit.Track
var xp_level: Label
var slot_badges := {}  # type -> the slot's badges
var rich: HudParts.RichTip
var round_buttons := {}  # "talents" / "restore" / "start" -> Button
var restore_count: Label
var levelup_label: Label
var levelup_time := 0.0
var _shake := 0.0
var _seen_level_ups := 0
var judgment: Label
var judgment_ms: Label
var streak_label: Label
var info_title: Label
var info_icons: HBoxContainer
var info_body: Label
var song_label: Label
var placeholder: Label
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
var build_armed := false  # The old B-then-letter chain; always off since D-0062.
var cursor_tag: PanelContainer
var cursor_title: Label
var cursor_body: Label
var hover_box: PanelContainer
var hover_title: Label
var hover_body: Label
var _corner_alpha := 1.0
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
	_bar.visible = false
	tip.add_theme_font_size_override("font_size", CAPTION)
	tip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	tip.add_theme_constant_override("outline_size", 4)
	root.move_child(tip, root.get_child_count() - 1)
	for box in [wave_card, pause_box, draft_box, end_box, tree_dim, tree_box]:
		root.move_child(box, root.get_child_count() - 1)
	_hook_tips()
	if game is LevelRun:
		_build_level_panels()
	_build_results()
	_restyle_tree_panel()
	_build_cursor()
	for box in [tree_dim, tree_box]:
		root.move_child(box, root.get_child_count() - 1)
	game.build_mode = false  # Build mode opens with B or a number key (D-0062).
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
	# One slab for the whole header (the scan: numbers floating on the grass were hard
	# to read): slate glass, a crisp bottom edge, the same family as the cursor card.
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color(HudCard.SLATE, 0.86)
	glass.border_color = HudCard.EDGE
	glass.border_width_bottom = 1
	glass.content_margin_left = 10
	glass.content_margin_right = 8
	glass.content_margin_top = 4
	glass.content_margin_bottom = 4
	glass.shadow_color = Color(0, 0, 0, 0.35)
	glass.shadow_size = 6
	glass.shadow_offset = Vector2(0, 3)
	top_bar.add_theme_stylebox_override("panel", glass)
	top_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(top_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	top_bar.add_child(row)
	# Each number sits in its own chip with its icon. Shields and Restores live at the
	# camp now (D-0062), so the header keeps gold, health and where the night is.
	for k in ["gold", "health", "wave", "shield", "restore"]:
		var chip := PanelContainer.new()
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(1, 1, 1, 0.04)
		cs.border_color = HudCard.EDGE.lightened(0.08)
		cs.set_border_width_all(1)
		cs.set_corner_radius_all(6)
		cs.content_margin_left = 6
		cs.content_margin_right = 9
		cs.content_margin_top = 0
		cs.content_margin_bottom = 0
		chip.add_theme_stylebox_override("panel", cs)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(chip)
		var cr := HBoxContainer.new()
		cr.add_theme_constant_override("separation", 5)
		chip.add_child(cr)
		cr.add_child(HudParts.Icon.new(k))
		var l := _label(BODY + 2, UiTheme.TEXT, true)
		cr.add_child(l)
		res_labels[k] = l
		chip.visible = not k in ["shield", "restore"]
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	# System button up here, out of the command card (Gemini's review).
	remove_child_safe(pause_button)
	pause_button.custom_minimum_size = Vector2(80, 26)
	pause_button.add_theme_font_size_override("font_size", CAPTION)
	# Same shape language as the chips and keycaps.
	for st in [["normal", Color("1c2430"), Color("2c3644")], ["hover", Color("263142"), Color("6b7a8f")], ["pressed", Color("141a23"), Color("38bdf8")], ["disabled", Color("12171e"), Color("1e293b")]]:
		var b := StyleBoxFlat.new()
		b.bg_color = st[1]
		b.border_color = st[2]
		b.set_border_width_all(1)
		b.border_width_bottom = 2
		b.set_corner_radius_all(6)
		b.set_content_margin_all(4)
		pause_button.add_theme_stylebox_override(st[0], b)
	row.add_child(pause_button)


# --- Bottom bar (T-038, Jared's go 2026-11-03) ------------------------------------------------

## One slim slate bar: the next push on the left, the build strip in the middle, the
## game controls on the right, the XP line along its top edge. The old inspect panel
## is gone: a clicked tower pins its card by the tower instead.
func _build_bottom() -> void:
	bottom = PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(HudKit.SLATE, 0.97)
	bs.border_color = HudKit.EDGE
	bs.border_width_top = 1
	bs.content_margin_left = 14
	bs.content_margin_right = 14
	bs.content_margin_top = 14
	bs.content_margin_bottom = 10
	bs.shadow_color = Color(0, 0, 0, 0.4)
	bs.shadow_size = 10
	bs.shadow_offset = Vector2(0, -2)
	bottom.add_theme_stylebox_override("panel", bs)
	root.add_child(bottom)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	bottom.add_child(row)
	# Left: the next push as tokens.
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 3)
	left.custom_minimum_size = Vector2(330, 0)
	row.add_child(left)
	info_title = HudKit.label("", 12, HudKit.TEXT, true, 1)
	left.add_child(info_title)
	info_icons = HBoxContainer.new()
	info_icons.add_theme_constant_override("separation", 10)
	left.add_child(info_icons)
	info_body = HudKit.label("", 11, HudKit.MUTED)
	left.add_child(info_body)
	song_label = HudKit.label("", 11, HudKit.MUTED)
	song_label.visible = false  # The song lives in the top slab now.
	left.add_child(song_label)
	var fill_l := Control.new()
	fill_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill_l)
	# Middle: the build strip, one row of square slots.
	grid = GridContainer.new()
	grid.columns = BUILD_ORDER.size()
	grid.add_theme_constant_override("h_separation", 8)
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(grid)
	for type in BUILD_ORDER:
		if build_buttons.has(type):
			_slot(build_buttons[type], type)
	var fill_r := Control.new()
	fill_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill_r)
	# Right: the game controls, square like the slots, each with a real keycap.
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	controls.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(controls)
	round_buttons["talents"] = _square(controls, "talents", "Tab", func(): game.toggle_tree())
	round_buttons["restore"] = _square(controls, "restore_big", "F", func(): game._press_restore())
	round_buttons["start"] = _square(controls, "start", "N", func(): game.start_wave())
	restore_count = HudKit.label("", 10, HudKit.TEXT, true)
	restore_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	restore_count.position = Vector2(SLOT - 30.0, SLOT - 16.0)
	restore_count.size = Vector2(26, 12)
	round_buttons["restore"].add_child(restore_count)
	# The old pieces live on, hidden: the HUD logic still reads them.
	upgrade_cmd = Button.new()
	upgrade_cmd.visible = false
	upgrade_cmd.pressed.connect(_on_upgrade)
	row.add_child(upgrade_cmd)
	remove_child_safe(panel)
	root.add_child(panel)
	panel.visible = false
	placeholder = Label.new()
	placeholder.visible = false
	root.add_child(placeholder)
	for b in [wave_button, restore_button, tree_button]:
		remove_child_safe(b)
		b.visible = false
	# The XP line along the bar's top edge, with the level at its left end.
	xp_line = HudKit.Track.new(6.0)
	root.add_child(xp_line)
	xp_level = HudKit.label("", 10, HudKit.TEXT, true, 1)
	root.add_child(xp_level)


## A build slot: the tower's picture clean in the centre, its key top-left, its price
## bottom-right, an accent underline, the wall count top-right.
func _slot(b: Button, type: String) -> void:
	remove_child_safe(b)
	grid.add_child(b)
	b.custom_minimum_size = Vector2(SLOT, SLOT)
	b.text = ""
	b.focus_mode = Control.FOCUS_NONE
	b.icon = _tower_icon(type)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 34)
	_slot_style(b, type, false)
	var badges := {}
	var line := ColorRect.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.color = HudCard.ACCENTS.get(type, Color.WHITE)
	line.position = Vector2(8, SLOT - 4)
	line.size = Vector2(SLOT - 16, 2)
	b.add_child(line)
	badges["line"] = line
	var key := HudKit.keycap(_key(type), 10)
	key.position = Vector2(-5, -7)
	b.add_child(key)
	badges["key"] = key
	var cost := HudKit.coin_pill("0")
	b.add_child(cost)
	badges["cost"] = cost
	var count := HudKit.label("", 10, HudKit.TEXT, true)
	count.position = Vector2(SLOT - 34, 2)
	count.size = Vector2(30, 12)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_child(count)
	badges["count"] = count
	var lock := HudKit.Glyph.new("lock", HudKit.MUTED, 18.0)
	lock.position = Vector2(SLOT - 22, 4)
	b.add_child(lock)
	badges["lock"] = lock
	slot_badges[type] = badges


func _slot_style(b: Button, type: String, picked: bool) -> void:
	var accent: Color = HudCard.ACCENTS.get(type, Color.WHITE)
	var base := HudKit.flat(HudKit.RAISED, Color("2c3644"), 8, 1, 10.0)
	base.border_width_bottom = 2
	if picked:
		base = HudKit.flat(Color(accent, 0.18), accent, 8, 2, 10.0)
		base.shadow_color = Color(accent, 0.45)
		base.shadow_size = 8
	var hover := HudKit.flat(Color("263142"), accent.lerp(Color.WHITE, 0.3), 8, 1, 10.0)
	hover.border_width_bottom = 2
	var off := HudKit.flat(Color("12171e"), HudKit.EDGE, 8, 1, 10.0)
	b.add_theme_stylebox_override("normal", base)
	b.add_theme_stylebox_override("pressed", base)
	b.add_theme_stylebox_override("hover_pressed", base)
	b.add_theme_stylebox_override("hover", base if picked else hover)
	b.add_theme_stylebox_override("disabled", off)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.set_meta("picked", picked)


## A game control: the same square as a build slot, a drawn icon, a keycap.
func _square(parent: Control, icon: String, key: String, action: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(SLOT, SLOT)
	_square_style(b, false)
	b.pressed.connect(action)
	parent.add_child(b)
	var ic := HudParts.Icon.new(icon)
	ic.custom_minimum_size = Vector2(SLOT * 0.5, SLOT * 0.5)
	ic.size = ic.custom_minimum_size
	ic.position = (Vector2(SLOT, SLOT) - ic.size) * 0.5
	b.add_child(ic)
	var k := HudKit.keycap(key, 10)
	k.position = Vector2(-5, -7)
	b.add_child(k)
	return b


func _square_style(b: Button, glow: bool) -> void:
	var base := HudKit.flat(HudKit.RAISED, Color("2c3644"), 8, 1, 6.0)
	base.border_width_bottom = 2
	if glow:
		base = HudKit.flat(Color(HudKit.GREEN, 0.12), Color(HudKit.GREEN, 0.7), 8, 1, 6.0)
		base.border_width_bottom = 2
		base.shadow_color = Color(HudKit.GREEN, 0.25)
		base.shadow_size = 6
	var hover := HudKit.flat(Color("263142"), Color("6b7a8f"), 8, 1, 6.0)
	hover.border_width_bottom = 2
	b.add_theme_stylebox_override("normal", base)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", HudKit.flat(Color("141a23"), HudKit.SKY, 8, 1, 6.0))
	b.add_theme_stylebox_override("disabled", HudKit.flat(Color("12171e"), HudKit.EDGE, 8, 1, 6.0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func remove_child_safe(c: Node) -> void:
	if c.get_parent() != null:
		c.get_parent().remove_child(c)


## A creep in the next push: a round token, its count, its HP under it.
func _token(kind: String, count: int, hp: float) -> Control:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 1)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var boss := kind.begins_with("boss")
	var disc := PanelContainer.new()
	disc.custom_minimum_size = Vector2(40, 40)
	disc.add_theme_stylebox_override("panel", HudKit.flat(HudKit.RAISED, HudKit.RED if boss else Color("2c3644"), 20, 1, 3.0))
	disc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.add_child(disc)
	var tr := TextureRect.new()
	tr.texture = _icon("creep_" + kind)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(32, 32)
	tr.tooltip_text = kind.capitalize()
	disc.add_child(tr)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", HudKit.flat(HudKit.SLATE, HudKit.RED if boss else Color("6b7a8f"), 7, 1, 1.0))
	badge.position = Vector2(20, -8)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bl := HudKit.label("BOSS" if boss else "x%d" % count, 9, HudKit.RED if boss else Color.WHITE, true)
	bl.add_theme_constant_override("line_spacing", -2)
	badge.add_child(bl)
	tr.add_child(badge)
	var hl := HudKit.label("%d hp" % roundi(hp) if hp > 0.0 else "", 10, HudKit.MUTED, true)
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(hl)
	return cell


func _kind_hp(kind: String, tier: int) -> float:
	if kind.begins_with("boss"):
		return 0.0
	return game.creep_hp_at(tier) * game.CREEP_KINDS.get(kind, {"hp": 1.0})["hp"]


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
	# A level up: one line over the controls, and the Talents button shakes once.
	levelup_label = _label(TITLE, Color(0.6, 1.0, 0.7), true)
	levelup_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	levelup_label.add_theme_constant_override("outline_size", 6)
	levelup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	levelup_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(levelup_label)
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
	keys.text = "Q, E   play the note on its tower\nSpace   parry, tap again quickly to counter\nB   build mode on and off; mouse wheel picks the tower   1 to 7   pick a tower\nClick builds one; Shift-click keeps building   right click or Esc stops\nHover a tower: X sells, U / I upgrades or picks a fork   F   Restore a locked tower\nTab   talents   [ ]   change song   F11   full screen\nP   resume   Esc twice   leave the run"
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
	tree_dim.color = Color(0, 0, 0, 0.35)  # The run plays on behind it (D-0046).
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
	foot.text = "The run keeps playing while this is open; Q, E and Space still work. Numbers on a line: points the area needs to open the next row. A node between two areas counts for both."
	tv.add_child(foot)
	tree_box = center
	tree_box.visible = false


func _style_node(b: Button, areas: Array, capstone: bool) -> void:
	var col: Color = TalentTree.AREA_COLORS[areas[0]]
	var edge2: Color = TalentTree.AREA_COLORS[areas[-1]]
	# The same parts as the HUD (T-038): a raised slate cap, the area's colour as its edge.
	var normal := HudKit.flat(Color(col, 0.08).blend(Color(HudKit.RAISED, 0.92)), Color(col, 0.7), 8 if capstone else 6, 2 if capstone else 1, 4.0)
	normal.border_width_bottom = 3 if capstone else 2
	if areas.size() > 1:
		normal.border_color = col.lerp(edge2, 0.5)
		normal.border_width_top = 2
	var hover := HudKit.flat(Color("263142"), col.lerp(Color.WHITE, 0.5), 6, 1, 4.0)
	hover.border_width_bottom = 2
	var disabled := HudKit.flat(Color("12171e"), Color(col, 0.25), 6, 1, 4.0)
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
	if xp_line != null:
		xp_line.position = Vector2(60, view.y - BOTTOM_H + 3)
		xp_line.size = Vector2(view.x - 72, 6)
		xp_level.position = Vector2(10, view.y - BOTTOM_H - 1)
		xp_level.size = Vector2(view.x, 14)
		xp_line.modulate = bottom.modulate
		xp_level.modulate = bottom.modulate
	var y := TOP_H + 4.0
	boss_box.position = Vector2(view.x * 0.5 - boss_box.size.x * 0.5, y)
	if boss_box.visible:
		y += boss_box.size.y + 2.0
	judgment.size = Vector2(view.x, 32)
	judgment.position = Vector2(0, y)
	judgment_ms.size = Vector2(view.x, 16)
	judgment_ms.position = Vector2(0, y + 32)
	streak_label.size = Vector2(240, 22)
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak_label.position = Vector2(view.x * 0.5 - 120.0, (TOP_H - 22) * 0.5)
	message.size = Vector2(view.x, 22)
	message.position = Vector2(0, view.y - BOTTOM_H - 30.0)
	levelup_label.size = Vector2(view.x, 26)
	levelup_label.position = Vector2(0, view.y - BOTTOM_H - 62.0)
	wave_card.position = Vector2(view.x * 0.5 - wave_card.size.x * 0.5, y + 52.0)
	tip.position = Vector2(14, view.y - BOTTOM_H - 22.0)


func mouse_over_ui() -> bool:
	if root == null:
		return false
	var m := get_viewport().get_mouse_position()
	if draft_box.visible or end_box.visible or tree_box.visible or pause_box.visible or (results_box != null and results_box.visible):
		return true
	if hover_box != null and hover_box.visible and hover_box.pinned and hover_box.get_global_rect().has_point(m):
		return true
	return top_bar.get_global_rect().has_point(m) or bottom.get_global_rect().has_point(m)


func _process(delta: float) -> void:
	wave_card_time = maxf(0.0, wave_card_time - delta)
	_tick_fill(delta)
	levelup_time = maxf(0.0, levelup_time - delta)
	_shake = maxf(0.0, _shake - delta)
	super._process(delta)
	if root == null:
		return
	_refresh_cursor()
	_fade_corners(delta)
	# Level up: a line, one shake of the Talents button, then a soft glow until spent.
	if game.level_ups != _seen_level_ups:
		_seen_level_ups = game.level_ups
		if game.level > 1:
			levelup_time = 2.5
			_shake = 0.7
			levelup_label.text = "LEVEL %d     a talent point to spend  (Tab)" % game.level
	levelup_label.visible = levelup_time > 0.0
	levelup_label.modulate.a = clampf(levelup_time / 0.5, 0.0, 1.0)
	var tb: Button = round_buttons["talents"]
	var icon: Control = tb.get_child(0)
	icon.position = (tb.size - icon.size) * 0.5 + Vector2(sin(_shake * 60.0) * 5.0 * (_shake / 0.7), 0)
	# A soft green when points wait, not a neon pulse (T-038).
	var glow: bool = game.points > 0
	if tb.get_meta("glow", false) != glow:
		tb.set_meta("glow", glow)
		_square_style(tb, glow)
	_refresh_results(delta)


func _refresh() -> void:
	if root == null:
		return
	super._refresh()
	_refresh_top()
	_refresh_info()
	_refresh_judgment()
	_refresh_wave_card()
	panel.visible = false  # The pinned tower card replaces the inspect panel (T-038).
	if game is LevelRun:
		_refresh_level_panels()
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
	if game is LevelRun:
		var sec: Dictionary = game.current_section()
		wave_text = game.songs[game.song_index]["name"] + "     " + "%s   bar %d/%d" % [sec["name"].to_upper(), clampi(floori(game.song_bar()) + 1, 1, game.night["bars"]), game.night["bars"]] if not sec.is_empty() else ("count-off" if game.started else "ready")
	res_labels["wave"].text = wave_text
	res_labels["shield"].text = "%d/%d" % [game.shields, game.shield_cap]
	res_labels["restore"].text = "%d/%d" % [game.restore_charges, game.restore_cap()]
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
	# D-0062: the word is drawn where it happened (Indicators), not up here.
	judgment.visible = false
	judgment_ms.visible = false
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
		wave_card_title.text = game.clear_title() if game is LevelRun else "WAVE %d CLEAR" % game.wave
		var body := "   ".join(parts.slice(1)).replace("hp -0", "no health lost").replace("hp -", "health lost ")
		var gained: int = game.gold - _gold_at_start
		if gained > 0:
			body += "\ngold +%d" % gained
		if game.level > _level_at_start:
			body += "\nLEVEL %d     %d talent point%s to spend  (Tab)" % [game.level, game.points, "" if game.points == 1 else "s"]
		wave_card_body.text = body
		wave_card_time = 4.5
	elif game.wave_log.size() < _logged:
		_logged = game.wave_log.size()  # A new run.
	wave_card.visible = wave_card_time > 0.0 and not game.wave_active and game.get("drafting") != true
	wave_card.modulate.a = clampf(wave_card_time / 0.5, 0.0, 1.0)


func _refresh_info() -> void:
	if game is LevelRun:
		_refresh_level_info()
		return
	var show: int = game.wave + 1
	info_title.text = ("NEXT   WAVE %d" % show) + ("     wave %d running" % game.wave if game.wave_active else "")
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
			counts[g["kind"]] += game.group_count(g["kind"], g["count"])
		if game.boss_waves.has(show):
			order.push_front("boss2" if game.is_boss2_wave(show) else "boss")
			counts[order[0]] = 1
		for k in order.slice(0, 7):
			info_icons.add_child(_token(k, counts[k], _kind_hp(k, show)))
	info_body.text = "" if game.wave_active else "N or the play button starts it."
	if not game.pending.is_empty():
		info_body.text += ("  " if info_body.text != "" else "") + "Locked card: %s" % game.card_name(game.pending["id"])
	song_label.text = game.songs[game.song_index]["name"]


## The song level: the next push as tokens, and when it comes.
func _refresh_level_info() -> void:
	var push: Dictionary = game.next_push()
	var now: Dictionary = game.current_section()
	var name: String = String(push.get("name", "the morning")).to_upper()
	if not game.started:
		info_title.text = "NEXT   " + name
	elif not now.is_empty() and now["kind"] == "lull":
		var left := ""
		if push.has("start"):
			var bars := maxi(0, int(ceil(push["start"] - game.song_bar())))
			left = "   in %d bar%s" % [bars, "" if bars == 1 else "s"]
		info_title.text = "LULL: BUILD NOW     NEXT   %s%s" % [name, left]
	else:
		info_title.text = "NEXT   %s" % name
	var key := "level:" + str(push.get("name", ""))
	if info_icons.get_meta("wave", "") != key:
		info_icons.set_meta("wave", key)
		for c in info_icons.get_children():
			c.queue_free()
		var counts := {}
		var order: Array[String] = []
		if push.get("boss", false):
			order.append("boss")
			counts["boss"] = 1
		for g in push.get("groups", []):
			if not counts.has(g["kind"]):
				counts[g["kind"]] = 0
				order.append(g["kind"])
			counts[g["kind"]] += g["count"]
		for k in order.slice(0, 7):
			info_icons.add_child(_token(k, counts[k], _kind_hp(k, push.get("tier", 1))))
	if push.is_empty():
		info_body.text = "The last push is out. Hold until the song ends."
	elif not game.started:
		info_body.text = "N or the play button starts the night."
	else:
		info_body.text = ""
	song_label.text = game.songs[game.song_index]["name"]


## While placing, the cursor card is the one place for the tower's numbers (the
## scan: two panels for one tower); the bottom inspect panel clears.
func _panel_type() -> String:
	if game.build_mode:
		return ""
	return super._panel_type()


func _refresh_panel() -> void:
	super._refresh_panel()
	if not panel.visible:
		return
	var type := _panel_type()
	if type == "wall" or not game.is_tower(type):
		return
	var cell: Vector2i = game.selected_cell
	var has_tower: bool = game.structures.has(cell)
	var rank: int = game.type_rank.get(type, 0)
	var branch: int = game.type_branch.get(type, 0)
	var spec: Dictionary = game.tower_spec(cell) if has_tower else game.type_spec(type)
	panel_title.text = "%s  x%d   rung %d/5%s" % [game.tower_name(type), game.towers_of(type), rank, ("  " + game.BRANCHES[type][branch - 1][0]) if branch > 0 else ""]
	var stats := "Damage %.0f   Range %.1f" % [spec["damage"] * game.damage_scale(), spec["range"]]
	if type == "light":
		stats = "Boost +%d%% damage to towers within %.1f tiles" % [roundi(game.light_boost() * 100.0), game.light_radius()]
	if spec.get("splash", 0.0) > 0.0:
		stats += "   Splash %.1f" % spec["splash"]
	if spec.has("slow"):
		stats += "   Slows %.1f s" % spec["slow"]
	var body: String = stats + "\nNote: " + SHORT_NOTES.get(type, "")
	if not game.unlocked.has(type):
		body = stats + "\nLocked. To unlock: " + game.unlock_text(type)
	elif has_tower and game.suppressed.has(cell):
		body = stats + "\nLocked for %.1f s. F to Restore." % game.suppressed[cell]
	elif rank == 2:
		var br: Array = game.BRANCHES[type]
		body = stats + "\nFork: %s or %s (hover them)" % [br[0][0], br[1][0]]
	panel_body.text = body
	# One line on the buttons; the rung's effect is in the line above and the tooltip.
	upgrade_button.text = upgrade_button.text.split("\n")[0]



func _refresh_bar() -> void:
	var playing: bool = game.state == "playing"
	for type in build_buttons:
		var b: Button = build_buttons[type]
		if not slot_badges.has(type):
			continue
		var bd: Dictionary = slot_badges[type]
		var spec: Dictionary = game.builds[type]
		var locked: bool = not game.unlocked.has(type)
		var cost: int = spec["cost"]
		var short: bool = cost > game.gold
		var picked: bool = game.selected == type and game.build_mode
		if b.get_meta("picked", false) != picked:
			_slot_style(b, type, picked)
		b.button_pressed = picked
		b.text = ""
		b.disabled = not playing or locked
		b.modulate = Color(1, 1, 1, 0.45) if locked else Color.WHITE
		bd["lock"].visible = locked
		bd["line"].visible = not locked
		bd["key"].get_child(0).get_child(0).text = _key(type)
		var pill: PanelContainer = bd["cost"]
		pill.visible = not locked
		var pl: Label = pill.get_child(0).get_child(1)
		pl.text = str(cost)
		var tint := HudKit.RED if short else HudKit.GREEN
		pl.add_theme_color_override("font_color", tint)
		var ps := HudKit.flat(Color(HudKit.SLATE, 0.95), Color(tint, 0.55), 9, 1, 1.0)
		ps.content_margin_left = 3
		ps.content_margin_right = 6
		pill.add_theme_stylebox_override("panel", ps)
		pill.reset_size()
		pill.position = Vector2(SLOT - pill.size.x + 7, SLOT - pill.size.y + 7)
		bd["count"].text = ("%d/%d" % [game.wall_count(), game.wall_limit]) if type == "wall" and game.wall_limit > 0 else ""
	var start: Button = round_buttons["start"]
	start.disabled = game.wave_active or not playing or game.get("drafting") == true
	if game is LevelRun:
		start.disabled = game.started or not playing
	round_buttons["restore"].disabled = not playing or game.restore_charges <= 0 or game.suppressed.is_empty()
	restore_count.text = "%d/%d" % [game.restore_charges, game.restore_cap()]
	round_buttons["talents"].disabled = not playing
	pause_button.text = "Resume" if game.paused else "Pause"
	pause_button.disabled = not playing
	# The XP line and its level.
	if xp_line != null:
		xp_line.value = clampf(game.xp / maxf(game.xp_to_next(), 1.0), 0.0, 1.0)
		xp_level.text = "LV %d" % game.level + ("   %d talent point%s  (Tab)" % [game.points, "" if game.points == 1 else "s"] if game.points > 0 else "")
		xp_level.add_theme_color_override("font_color", HudKit.GREEN if game.points > 0 else HudKit.TEXT)


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


## Every tooltip in the HUD: instant, laid out by Explain (D-0046).
func _hook_tips() -> void:
	rich = HudParts.RichTip.new()
	root.add_child(rich)
	for type in build_buttons:
		var t: String = type
		rich.hook(build_buttons[t], func(): return Explain.tower(game, t, "Key %s, or B and the mouse wheel" % _key(t)))
	rich.hook(upgrade_cmd, func():
		var type := _panel_type()
		return Explain.tower(game, type, "U upgrades every %s on the board" % game.tower_name(type)) if type != "" and game.is_tower(type) else "")
	rich.hook(panel_body, func():
		var type := _panel_type()
		return Explain.tower(game, type) if type != "" and game.builds.has(type) else "")
	for i in [1, 2]:
		var bi: int = i
		rich.hook(fork_a_button if bi == 1 else branch_button, func():
			var type := _panel_type()
			if type == "" or not game.BRANCHES.has(type):
				return ""
			var br: Array = game.BRANCHES[type][bi - 1]
			var what: String = br[1]
			return "\n".join([Explain.title(br[0], Explain.GOLD, "fork, key %s" % ("U" if bi == 1 else "I")),
				Explain.c(Explain.WHITE, what[0].to_upper() + what.substr(1) + "."),
				Explain.c(Explain.GREY, "Applies to every %s. The other branch closes for this run." % game.tower_name(type))]))
	for k in round_buttons:
		var which: String = k
		rich.hook(round_buttons[which], func(): return Explain.control(game, which))
	for key in tree_nodes:
		var id: String = key.split(":")[1]
		rich.hook(tree_nodes[key], func(): return Explain.talent(TalentTree.nodes()[id], TalentTree.ranks(id, game.owned), TalentTree.available(id, game.owned), game.points))


## Build mode (UI slice A, D-0062, Jared's notes): B opens it with the last tower
## picked and B again closes it; the mouse wheel cycles the unlocked towers; 1 to 7
## pick one directly. A click builds one and closes build mode, Shift-click keeps
## building; right click or Esc close it without selling anything. Out of build mode,
## X sells the tower under the cursor and U / I upgrade its type.
func _unhandled_input(event: InputEvent) -> void:
	if game.state != "playing" or game.paused or game.get("drafting") == true or game.tree_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k == KEY_B:
			if game.build_mode:
				_stop_building()
			else:
				_start_building(game.selected)
			get_viewport().set_input_as_handled()
		elif game.build_keys.has(k):
			_start_building(game.build_keys[k])
			get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE and game.build_mode:
			_stop_building()
			get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE and game.structures.has(game.selected_cell):
			game.selected_cell = Vector2i(-1, -1)  # Esc unpins the tower card first.
			get_viewport().set_input_as_handled()
		elif k == KEY_X:
			var cell := _hover_cell()
			if game.structures.has(cell):
				game.sell(cell)
			get_viewport().set_input_as_handled()
		elif k == KEY_U or k == KEY_I:
			var cell := _hover_cell()
			if game.structures.has(cell) and game.is_tower(game.structures[cell]["type"]):
				game.selected_cell = cell  # The sim's U / I then upgrade the hovered type.
		return
	if not (event is InputEventMouseButton and event.pressed and game.build_mode):
		return
	if mouse_over_ui():
		return
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
			_cycle(-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
			get_viewport().set_input_as_handled()
		MOUSE_BUTTON_RIGHT:
			_stop_building()
			get_viewport().set_input_as_handled()
		MOUSE_BUTTON_LEFT:
			var cell: Vector2i = game.cell_at(event.position)
			if game.structures.has(cell) and not _swaps(cell):
				return  # A click on a tower picks it, as before.
			if game.try_place(cell, game.selected) and not event.shift_pressed:
				_stop_building()
			get_viewport().set_input_as_handled()


func _start_building(type: String) -> void:
	if game.builds.has(type) and not game.unlocked.has(type):
		game._say("%s is locked: %s" % [game.tower_name(type), game.unlock_text(type)])
		return
	if not game.builds.has(type):
		type = "wall"
	game.selected = type
	game.build_mode = true
	game.selected_cell = Vector2i(-1, -1)


func _stop_building() -> void:
	game.build_mode = false


## The wheel: the next unlocked build in card order, round and round.
func _cycle(dir: int) -> void:
	var open: Array = BUILD_ORDER.filter(func(t): return game.builds.has(t) and game.unlocked.has(t))
	if open.is_empty():
		return
	var i: int = open.find(game.selected)
	game.selected = open[posmod(i + dir, open.size())] if i >= 0 else open[0]


func _swaps(cell: Vector2i) -> bool:
	return game.has_method("wall_swap") and game.wall_swap(cell, game.selected)


func _hover_cell() -> Vector2i:
	if mouse_over_ui():
		return Vector2i(-1, -1)
	return game.cell_at(get_viewport().get_mouse_position())


# --- The cursor tag and the hover menu (D-0062) ----------------------------------------------

func _build_cursor() -> void:
	cursor_tag = HudCard.new()
	hover_box = HudCard.new()
	for card in [cursor_tag, hover_box]:
		root.add_child(card)
	for box in [tree_dim, tree_box, draft_box, end_box]:
		root.move_child(box, root.get_child_count() - 1)


## The build's numbers as data (DMG / RNG / one trait) from its live spec; its note
## is a separate trait line.
func _stats_of(type: String) -> Array:
	if type == "wall":
		return []
	var spec: Dictionary = game.type_spec(type)
	var dmg: float = spec.get("damage", 0.0) * game.damage_scale()
	var rng := "%.1f" % spec.get("range", 0.0)
	match type:
		"kick":
			return [["DMG", str(roundi(dmg))], ["RNG", rng], ["TARGET", "Nearest"]]
		"bass":
			return [["DMG", str(roundi(dmg))], ["RNG", rng], ["SPLASH", "%.1f" % spec.get("splash", 0.0)]]
		"slow":
			return [["DMG", str(roundi(dmg))], ["RNG", rng], ["SLOW", "%.1fs" % spec.get("slow", 0.0)]]
		"poison":
			return [["DMG", str(roundi(dmg))], ["RNG", rng], ["EFFECT", "Poison"]]
		"lightning":
			return [["DMG", str(roundi(dmg))], ["RNG", rng], ["TARGET", "Chain"]]
		"light":
			return [["BOOST", "+%d%%" % roundi(game.light_boost() * 100.0)], ["RADIUS", "%.1f" % game.light_radius()]]
	return [["DMG", str(roundi(dmg))], ["RNG", rng]]


func _trait_of(type: String) -> String:
	if type == "wall":
		return "Blocks the path; creeps walk around it. A tower built on a wall replaces it."
	return ("Note: " + SHORT_NOTES[type]) if SHORT_NOTES.has(type) else ""


func _tower_title(type: String) -> String:
	return game.tower_name(type) + ("" if type == "wall" else " tower")


func _tower_icon(type: String) -> Texture2D:
	return _icon(("tower_" + type) if type != "wall" else "wall")


## Next to the cursor (Jared: "all that information next to the cursor, not in the
## top"; card styled to his spec of 2026-11-03): in build mode the tower, its role, a
## cost pill green or red, what it does, and the controls as keycaps; over a placed
## tower, sell and upgrade as keycaps.
func _refresh_cursor() -> void:
	var busy: bool = game.state != "playing" or game.paused or game.tree_open or game.get("drafting") == true
	var m := get_viewport().get_mouse_position()
	var pin: Vector2i = game.selected_cell if game.structures.has(game.selected_cell) and not game.build_mode else Vector2i(-1, -1)
	if not busy and hover_box.visible and hover_box.pinned and pin.x >= 0 and hover_box.get_global_rect().grow(6).has_point(m):
		_fill_tower_card(pin, true)  # Keep the pinned card while the mouse is on it.
		return
	cursor_tag.visible = false
	hover_box.visible = false
	if busy:
		return
	if mouse_over_ui():
		if pin.x >= 0:
			_show_pinned(pin)
		return
	var cell: Vector2i = game.cell_at(m)
	if game.build_mode and game.builds.has(game.selected):
		var type: String = game.selected
		var swap := _swaps(cell)
		var cost: int = game.build_cost_at(cell, type) if game.has_method("build_cost_at") else game.builds[type]["cost"]
		cursor_tag.set_accent(HudCard.ACCENTS.get(type, Color.WHITE))
		cursor_tag.set_head(_tower_icon(type), _tower_title(type), HudCard.ROLES.get(type, ""))
		cursor_tag.set_cost(cost, game.gold >= cost, game.gold - cost)
		cursor_tag.set_stats(_stats_of(type))
		var body := _trait_of(type)
		if swap:
			body += "\nOn this wall: its %dg counts toward the tower." % game.builds["wall"]["cost"]
		cursor_tag.set_body(body)
		cursor_tag.set_keys([[["Shift", "L-Click"], "Chain"], [["Scroll"], "Swap"], [["B"], "Cancel"]])
		_place_by_cursor(cursor_tag, m)
		return
	if not game.structures.has(cell) or cell == pin:
		if pin.x >= 0:
			_show_pinned(pin)
		return
	_fill_tower_card(cell, false)
	_place_by_cursor(hover_box, m)


## A clicked tower's card stays by the tower, with buttons for mouse players (T-038).
func _show_pinned(cell: Vector2i) -> void:
	_fill_tower_card(cell, true)
	var at: Vector2 = game.view.screen_at(View3D.world(Vector2(cell), 1.0)) if game.get("view") != null else get_viewport().get_mouse_position()
	_place_by_cursor(hover_box, at)


func _fill_tower_card(cell: Vector2i, pinned: bool) -> void:
	var s: Dictionary = game.structures[cell]
	var type: String = s["type"]
	var refund := int(s.get("paid", game.builds[type]["cost"]) * game.SELL_REFUND)
	hover_box.set_accent(HudCard.ACCENTS.get(type, Color.WHITE))
	var role: String = HudCard.ROLES.get(type, "")
	var keys: Array = [[["X"], "Sell +%dg" % refund, HudCard.GREEN]]
	if game.is_tower(type) and game.unlocked.has(type):
		var rank: int = game.type_rank.get(type, 0)
		role += "   rung %d/5" % rank
		if rank >= 5:
			keys.append([[], "Top rung"])
		elif rank == 2 and game.BRANCHES.has(type):
			var br: Array = game.BRANCHES[type]
			keys.append([["U"], br[0][0]])
			keys.append([["I"], br[1][0]])
		else:
			var cost: int = game.type_upgrade_cost(type)
			keys.append([["U"], "Upgrade %dg" % cost, Color("d6dde6") if game.gold >= cost else HudCard.RED])
	hover_box.set_head(_tower_icon(type), _tower_title(type), role)
	hover_box.set_cost(-1, true)
	hover_box.set_stats(_stats_of(type) if game.is_tower(type) else [])
	hover_box.set_body("")
	hover_box.set_keys([] if pinned else keys)
	var acts: Array = []
	if pinned:
		var c := cell
		acts.append(["Sell +%dg" % refund, func(): game.sell(c), true, "secondary"])
		if game.is_tower(type) and game.unlocked.has(type):
			var rank: int = game.type_rank.get(type, 0)
			if rank == 2 and game.BRANCHES.has(type):
				var br: Array = game.BRANCHES[type]
				acts.append([br[0][0], func(): game.upgrade_type(type, 1), true, "secondary"])
				acts.append([br[1][0], func(): game.upgrade_type(type, 2), true, "secondary"])
			elif rank < 5:
				var cost: int = game.type_upgrade_cost(type)
				acts.append(["Upgrade %dg" % cost, func(): game.upgrade_type(type), game.gold >= cost, "primary"])
	hover_box.set_actions(acts, str(cell) + ":" + str(acts.map(func(a): return [a[0], a[2]])))
	hover_box.visible = true


func _place_by_cursor(box: Control, m: Vector2) -> void:
	box.visible = true
	box.reset_size()
	var view := get_viewport().get_visible_rect().size
	var p := m + Vector2(22, 18)
	if p.x + box.size.x > view.x - 8.0:
		p.x = m.x - box.size.x - 14.0
	if p.y + box.size.y > view.y - BOTTOM_H - 4.0:
		p.y = m.y - box.size.y - 12.0
	box.position = p


## In a push the corner numbers and the bottom bar dim to half so the board
## and the camp carry the fight; they come back in lulls, between nights, in build
## mode and when the mouse goes to them.
func _fade_corners(delta: float) -> void:
	var fight := false
	if game is LevelRun and game.started and game.state == "playing" and game.night_phase != "summary":
		fight = game.current_section().get("kind", "lull") != "lull"
	var m := get_viewport().get_mouse_position()
	var near: bool = top_bar.get_global_rect().has_point(m) or bottom.get_global_rect().has_point(m)
	var target := 0.5 if fight and not near and not game.build_mode else 1.0
	_corner_alpha = move_toward(_corner_alpha, target, delta * 2.5)
	# Dimmed, not see-through: the bar stays solid so the board never shows through it.
	var v := _corner_alpha
	top_bar.modulate = Color(v, v, v, 1.0)
	bottom.modulate = Color(v, v, v, 1.0)


func _tip() -> String:
	return ""  # The cursor tag carries the build line now (D-0062).


## Locked talents stay readable: the dark disabled style says "not yet", not a fade.
func _refresh_tree() -> void:
	super._refresh_tree()
	if not game.tree_open:
		return
	for key in tree_nodes:
		var b: Button = tree_nodes[key]
		if b.disabled and b.modulate.a < 0.9:
			b.modulate = Color(1, 1, 1, 0.85) if b.modulate.a > 0.3 else Color(1, 1, 1, 0.6)


## The song level ends on the card and the results: there is no "keep going".
func _refresh_end() -> void:
	end_box.visible = false  # The results screen (T-038) shows instead.



# --- The song level's panels (D-0051; restyled T-038) ----------------------------------------

var start_box: Control
var start_tab: Button
var _start_min := false
var night_box: Control
var night_ring: HudKit.Ring
var night_track: HudKit.Track
var night_gain: Label
var night_xp: Label
var night_points: Label
var night_talents: Button
var night_continue: Button
var _primary := ""  # Which morning button is the bright one.
var _fill := -1.0  # The end screen's XP fill: levels gained so far, as it animates.
var _fill_shake := 0.0


func _center_panel(width: float) -> Array:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(holder)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", HudKit.glass(0.94, 12, 24.0))
	box.custom_minimum_size = Vector2(width, 0)
	holder.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	box.add_child(v)
	return [holder, v]


## The start of a night, and the morning: XP counts up into the level ring, one
## bright button for what to do next.
func _build_level_panels() -> void:
	var made := _center_panel(560.0)
	start_box = made[0]
	var v: VBoxContainer = made[1]
	v.add_child(HudKit.label("TONIGHT", 12, HudKit.MUTED, true, 2))
	v.add_child(HudKit.label(game.night["name"], 30, Color.WHITE, true))
	v.add_child(HudKit.label("Song: %s" % game.songs[game.song_index]["name"], 13, HudKit.MUTED))
	var say := HudKit.label("WATCHMAN   \"Hey, I just work here. Hold the camp till morning.\"", 15, UiTheme.GOLD)
	say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(say)
	var body := HudKit.label("You can't build until the night starts. The sticks count you in: two bars to build, so put a wall and a tower by the camp. The camp grows outward: build near the keep or near what you have built, never by the mine.", 14, HudKit.TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var go := HudKit.key_button("Start the night", "N", "primary", HudKit.GREEN, Vector2(240, 48))
	go.pressed.connect(func(): game.start_wave())
	row.add_child(go)
	var study := HudKit.key_button("Study the map", "", "secondary", HudKit.SKY, Vector2(180, 48))
	study.pressed.connect(func(): _start_min = true)
	row.add_child(study)
	start_tab = HudKit.key_button("Start the night", "N", "primary", HudKit.GREEN, Vector2(230, 40))
	start_tab.pressed.connect(func(): game.start_wave())
	root.add_child(start_tab)
	# Morning.
	made = _center_panel(560.0)
	night_box = made[0]
	v = made[1]
	v.add_theme_constant_override("separation", 14)
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 0)
	v.add_child(head)
	head.add_child(HudKit.label("MORNING", 12, HudKit.MUTED, true, 2))
	head.add_child(HudKit.label("You held the camp.", 28, Color.WHITE, true))
	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 20)
	v.add_child(mid)
	night_ring = HudKit.Ring.new(116.0)
	night_ring.color = HudKit.SKY
	night_ring.sub = "LEVEL"
	mid.add_child(night_ring)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_child(col)
	night_gain = HudKit.label("", 26, HudKit.GREEN, true)
	col.add_child(night_gain)
	night_track = HudKit.Track.new(16.0)
	night_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(night_track)
	night_xp = HudKit.label("", 12, HudKit.MUTED)
	col.add_child(night_xp)
	night_points = HudKit.label("", 14, UiTheme.GOLD, true)
	col.add_child(night_points)
	row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	night_talents = HudKit.key_button("Spend talents", "Tab", "primary", HudKit.GREEN, Vector2(220, 46))
	night_talents.pressed.connect(func(): game.toggle_tree())
	row.add_child(night_talents)
	night_continue = HudKit.key_button("Pick your card", "", "secondary", HudKit.GREEN, Vector2(220, 46))
	night_continue.pressed.connect(func(): game.begin_card())
	row.add_child(night_continue)
	for box in [tree_dim, tree_box, draft_box, end_box, results_box]:
		if box != null:
			root.move_child(box, root.get_child_count() - 1)


func show_start() -> void:
	_start_min = false


func _set_kind(b: Button, kind: String) -> void:
	if b.get_meta("kind", "") == kind:
		return
	b.set_meta("kind", kind)
	HudKit.style_button(b, kind, HudKit.GREEN)
	var l: Label = b.get_child(0).get_node("Text")
	l.add_theme_color_override("font_color", Color("0b1016") if kind == "primary" else HudKit.TEXT)


func _refresh_level_panels() -> void:
	var before: bool = not game.started and game.state == "playing"
	start_box.visible = before and not _start_min
	start_tab.visible = before and _start_min
	start_tab.position = Vector2((root.size.x - start_tab.size.x) * 0.5, 64.0)
	# No mid-night card: lulls are the music and the watchman.
	wave_card.visible = false
	levelup_label.visible = false
	var summary: bool = game.night_phase == "summary" and game.state == "playing"
	night_box.visible = summary and not game.tree_open
	if not summary:
		_fill = -1.0
		return
	var start: Dictionary = game.xp_start()
	var gained: int = game.level - start["level"]
	if _fill < 0.0:
		_fill = 0.0
	var shown := mini(floori(_fill), gained)
	var frac: float = (_fill - shown) if shown < gained else clampf(game.xp / maxf(game.xp_to_next(), 1.0), 0.0, 1.0) * clampf(_fill - gained, 0.0, 1.0)
	var done := clampf(_fill / (gained + 1.0), 0.0, 1.0)
	night_ring.text = str(start["level"] + shown)
	night_ring.value = frac
	night_ring.glow = _fill_shake * 2.0
	night_ring.position.x = sin(_fill_shake * 60.0) * 6.0 * _fill_shake
	night_track.value = frac
	night_gain.text = "+%d XP" % roundi(game.m7_stats["xp"] * done)
	night_xp.text = ("%d levels this night" % gained if gained != 1 else "1 level this night") + ("   XP %d / %d to level %d" % [roundi(game.xp), roundi(game.xp_to_next()), game.level + 1] if done >= 1.0 else "")
	night_points.text = ("%d talent point%s to spend" % [game.points, "" if game.points == 1 else "s"]) if game.points > 0 else "No talent points waiting"
	night_talents.visible = game.points > 0
	night_continue.disabled = _fill < gained + 1.0
	_set_kind(night_talents, "primary")
	_set_kind(night_continue, "secondary" if game.points > 0 else "primary")


## The XP fill: about two-thirds of a second a level (three seconds at most), a shake and
## the chime as each lands.
func _tick_fill(delta: float) -> void:
	if not (game is LevelRun) or _fill < 0.0:
		return
	_fill_shake = maxf(0.0, _fill_shake - delta)
	var gained: int = game.level - game.xp_start()["level"]
	var before := _fill
	_fill = minf(_fill + delta * maxf(1.5, (gained + 1.0) / 3.0), gained + 1.0)  # Three seconds at most.
	if floori(_fill) > floori(before) and floori(_fill) <= gained:
		_fill_shake = 0.5
		game._sfx_level.play()


# --- The card pick (T-038) ---------------------------------------------------------------------

var draft_head: Label
var draft_tiles: Array = []  # One dictionary of parts per card button.


## Cards as tiles: rarity in the border, banner and gems (never the word), the
## bucket as a badge with a drawn glyph, the key as a keycap, the title clean.
func _build_draft() -> void:
	var dp: PanelContainer = draft_box.get_child(0)
	dp.add_theme_stylebox_override("panel", HudKit.glass(0.95, 12, 20.0))
	var dv: VBoxContainer = dp.get_child(0)
	dv.add_theme_constant_override("separation", 14)
	draft_title.visible = false
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 6)
	dv.add_child(head)
	dv.move_child(head, 0)
	draft_head = HudKit.label("", 26, Color.WHITE, true, 1)
	draft_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(draft_head)
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", HudKit.flat(Color(HudKit.SKY, 0.12), Color(HudKit.SKY, 0.5), 10, 1, 3.0))
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var pl := HudKit.label("CHOOSE ONE", 11, HudKit.SKY, true, 2)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.custom_minimum_size = Vector2(110, 0)
	pill.add_child(pl)
	head.add_child(pill)
	for b in draft_buttons:
		b.text = ""
		b.custom_minimum_size = Vector2(212, 248)
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 14
		v.offset_right = -14
		v.offset_top = 12
		v.offset_bottom = -12
		v.add_theme_constant_override("separation", 7)
		b.add_child(v)
		var top := HBoxContainer.new()
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(top)
		var key := HudKit.keycap(str(draft_buttons.find(b) + 1), 12)
		top.add_child(key)
		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(sp)
		var gems := HudKit.label("", 12, Color.WHITE, true)
		top.add_child(gems)
		var title := HudKit.label("", 17, Color.WHITE, true, 1)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(title)
		var badge := PanelContainer.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var bl := HudKit.label("", 10, Color.WHITE, true, 1)
		badge.add_child(bl)
		v.add_child(badge)
		var art := PanelContainer.new()
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.custom_minimum_size = Vector2(0, 64)
		v.add_child(art)
		var cc := CenterContainer.new()
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(cc)
		var glyph_holder := Control.new()
		glyph_holder.custom_minimum_size = Vector2(48, 48)
		glyph_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.add_child(glyph_holder)
		var text := HudKit.label("", 12, HudKit.TEXT)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(text)
		var lock := HudKit.label("", 11, HudKit.AMBER)
		lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(lock)
		draft_tiles.append({"gems": gems, "title": title, "badge": badge, "badge_text": bl, "art": art, "glyph": glyph_holder, "text": text, "lock": lock, "id": ""})
	HudKit.style_button(reroll_button, "ghost")
	reroll_button.custom_minimum_size = Vector2(180, 34)
	reroll_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _refresh_draft() -> void:
	var drafting: bool = game.get("drafting") == true
	draft_box.visible = drafting
	if not drafting:
		return
	if draft_tiles.is_empty():
		_build_draft()
	if game is LevelRun:
		draft_head.text = String(game.night["name"]).split(":")[0].to_upper() + " COMPLETE"
	else:
		draft_head.text = "WAVE %d COMPLETE" % game.wave
	var cards: Array = game.draft_cards
	for i in draft_buttons.size():
		var b := draft_buttons[i]
		b.visible = i < cards.size()
		if i >= cards.size():
			continue
		var card: Dictionary = cards[i]
		var t: Dictionary = draft_tiles[i]
		var col: Color = HudKit.RARITY.get(card["rarity"], HudKit.MUTED)
		var sig := "%s:%s" % [card["name"], card["rarity"]]
		b.modulate = Color.WHITE
		if t["id"] != sig:
			t["id"] = sig
			var rare: bool = card["rarity"] != "grey"
			var normal := HudKit.flat(Color(col, 0.07).blend(Color(HudKit.RAISED, 0.9)), Color(col, 0.75 if rare else 0.4), 10, 2 if rare else 1, 0.0)
			normal.border_width_top = 4
			normal.border_color = Color(col, 0.75 if rare else 0.45)
			if rare:
				normal.shadow_color = Color(col, 0.3 + 0.08 * HudKit.RARITY_GEMS.get(card["rarity"], 1))
				normal.shadow_size = 4 + 2 * HudKit.RARITY_GEMS.get(card["rarity"], 1)
			var hover := normal.duplicate()
			hover.bg_color = normal.bg_color.lightened(0.08)
			hover.border_color = col.lerp(Color.WHITE, 0.3)
			for st in ["normal", "disabled"]:
				b.add_theme_stylebox_override(st, normal)
			for st in ["hover", "pressed", "hover_pressed"]:
				b.add_theme_stylebox_override(st, hover)
			t["gems"].text = "◆".repeat(HudKit.RARITY_GEMS.get(card["rarity"], 1))
			t["gems"].add_theme_color_override("font_color", col)
			t["title"].text = String(card["name"]).to_upper()
			t["badge_text"].text = String(CardPool.CATEGORY_NAMES.get(card["cat"], card["cat"])).to_upper()
			t["badge_text"].add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.2))
			t["badge"].add_theme_stylebox_override("panel", HudKit.flat(Color(col, 0.14), Color(col, 0.4), 6, 1, 2.0))
			t["art"].add_theme_stylebox_override("panel", HudKit.flat(Color(col, 0.08), Color(col, 0.18), 8, 1, 4.0))
			for c in t["glyph"].get_children():
				c.queue_free()
			t["glyph"].add_child(HudKit.Glyph.new(card["cat"], col, 48.0))
			t["text"].text = card["text"]
			t["lock"].text = ("LOCKED   unlocks if you " + CardPool.CONDITIONS[card["cond"]]) if card.has("cond") else ""
			t["lock"].visible = card.has("cond")
	reroll_button.visible = true
	reroll_button.text = "Reroll   %d left" % game.rerolls_left
	reroll_button.disabled = game.rerolls_left <= 0


# --- The results (T-038) -----------------------------------------------------------------------

var results_box: Control
var res_title: Label
var res_sub: Label
var res_grade: HudKit.Ring
var res_cols: HBoxContainer
var res_strip: HudKit.Strip
var res_details: ScrollContainer
var res_details_text: Label
var res_details_btn: Button
var res_copy: Button
var res_keep: Button
var _res_shown := false
var _copied := 0.0


## The night's results: a grade, three columns of numbers, the song as a strip, and
## the full run log behind Details. Copy stays in plain view: players send it to
## Jared as feedback (his call, 2026-11-03).
func _build_results() -> void:
	var made := _center_panel(760.0)
	results_box = made[0]
	var v: VBoxContainer = made[1]
	v.add_theme_constant_override("separation", 14)
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 0)
	v.add_child(head)
	res_title = HudKit.label("", 30, Color.WHITE, true, 1)
	head.add_child(res_title)
	res_sub = HudKit.label("", 13, HudKit.MUTED)
	head.add_child(res_sub)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 26)
	v.add_child(top)
	res_grade = HudKit.Ring.new(150.0)
	res_grade.thickness = 10.0
	top.add_child(res_grade)
	res_cols = HBoxContainer.new()
	res_cols.add_theme_constant_override("separation", 26)
	res_cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(res_cols)
	res_strip = HudKit.Strip.new()
	res_strip.custom_minimum_size = Vector2(700, 46)
	v.add_child(res_strip)
	res_details = ScrollContainer.new()
	res_details.custom_minimum_size = Vector2(700, 200)
	res_details.visible = false
	res_details.add_theme_stylebox_override("panel", HudKit.flat(Color(0, 0, 0, 0.25), HudKit.EDGE, 6, 1, 8.0))
	v.add_child(res_details)
	res_details_text = HudKit.label("", 12, HudKit.TEXT)
	res_details_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	res_details_text.custom_minimum_size = Vector2(670, 0)
	res_details.add_child(res_details_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var again := HudKit.key_button("Run again", "R", "primary", HudKit.GREEN, Vector2(180, 46))
	again.pressed.connect(func(): game.reset())
	row.add_child(again)
	var menu := HudKit.key_button("Menu", "", "secondary", HudKit.SKY, Vector2(110, 46))
	menu.pressed.connect(func(): game.get_tree().change_scene_to_file("res://menu.tscn"))
	row.add_child(menu)
	res_keep = HudKit.key_button("Keep going", "N", "secondary", HudKit.SKY, Vector2(160, 46))
	res_keep.pressed.connect(func(): game.start_wave())
	row.add_child(res_keep)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	res_details_btn = Button.new()
	res_details_btn.text = "Details"
	res_details_btn.custom_minimum_size = Vector2(100, 46)
	HudKit.style_button(res_details_btn, "ghost")
	res_details_btn.pressed.connect(func(): res_details.visible = not res_details.visible)
	row.add_child(res_details_btn)
	res_copy = Button.new()
	res_copy.custom_minimum_size = Vector2(190, 46)
	HudKit.style_button(res_copy, "secondary")
	res_copy.pressed.connect(func():
		DisplayServer.clipboard_set("\n".join(game.run_lines()))
		_copied = 2.0)
	row.add_child(res_copy)
	var ask := HudKit.label("Playing the demo? Copy your stats and send them to Jared: they help tune the game.", 12, HudKit.MUTED)
	ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(ask)


static func _stat_col(title: String, rows: Array) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", 5)
	c.add_child(HudKit.label(title, 11, HudKit.MUTED, true, 2))
	for r in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		var k := HudKit.label(r[0], 13, HudKit.MUTED)
		k.custom_minimum_size = Vector2(92, 0)
		line.add_child(k)
		line.add_child(HudKit.label(r[1], 16, r[2] if r.size() > 2 else Color.WHITE, true))
		c.add_child(line)
	return c


## The grade (Claude's starting formula, Jared's call to tune): notes 45%, parries
## 35%, health kept 20%. S needs 90% and full health; a fallen camp tops out at C.
func grade() -> Array:
	var t: Dictionary = game._totals()
	var notes := float(t["hits"]) / maxf(t["notes"], 1.0) if t["notes"] > 0 else 1.0
	var parries := float(t["parried"]) / maxf(t["throws"], 1.0) if t["throws"] > 0 else 1.0
	var hp := float(game.health) / float(game.START_HEALTH)
	var score := 0.45 * notes + 0.35 * parries + 0.2 * clampf(hp, 0.0, 1.0)
	var letter := "D"
	if score >= 0.9 and game.health >= game.START_HEALTH:
		letter = "S"
	elif score >= 0.78:
		letter = "A"
	elif score >= 0.64:
		letter = "B"
	elif score >= 0.5:
		letter = "C"
	if game.state != "won" and letter in ["S", "A", "B"]:
		letter = "C"
	return [letter, score, notes]


func _refresh_results(delta: float) -> void:
	if results_box == null:
		return
	var over: bool = game.state != "playing"
	results_box.visible = over
	end_box.visible = false
	_copied = maxf(0.0, _copied - delta)
	res_copy.text = "Copied!" if _copied > 0.0 else "Copy stats to send Jared"
	if not over:
		_res_shown = false
		res_details.visible = false
		return
	if _res_shown:
		return
	_res_shown = true
	var lines: Array = game.run_lines()
	var won: bool = game.state == "won"
	var title: String = lines[0].split("   ")[0]
	res_title.text = title
	res_title.add_theme_color_override("font_color", Color.WHITE if won else HudKit.RED)
	var tail: String = lines[0].substr(title.length()).strip_edges()
	res_sub.text = "%s     %d:%02d" % [tail, int(game.run_time) / 60, int(game.run_time) % 60]
	var g := grade()
	res_grade.text = g[0]
	res_grade.sub = "%d%% NOTES" % roundi(g[2] * 100.0)
	res_grade.value = g[2]
	res_grade.color = {"S": UiTheme.GOLD, "A": HudKit.GREEN, "B": HudKit.SKY, "C": HudKit.AMBER, "D": HudKit.RED}[g[0]]
	res_grade.glow = 1.0 if g[0] == "S" else 0.5
	for c in res_cols.get_children():
		c.queue_free()
	var t: Dictionary = game._totals()
	res_cols.add_child(_stat_col("DEFENCE", [
		["Health", "%d/%d" % [game.health, game.START_HEALTH], HudKit.GREEN if game.health >= game.START_HEALTH else Color.WHITE],
		["Gold earned", "%dg" % game.gold_earned],
		["Towers locked", str(game.m4_stats["suppressed"])],
		["Shields lost", str(game.m4_stats["shields_lost"])]]))
	res_cols.add_child(_stat_col("RHYTHM", [
		["Notes", "%d/%d" % [t["hits"], t["notes"]]],
		["Perfects", str(game.stat_total("perfects")), UiTheme.GOLD],
		["Parries", "%d/%d" % [t["parried"], t["throws"]]],
		["Calls nailed", "%d/%d" % [game.phrase_stats["nailed"], game.phrase_stats["calls"]]]]))
	res_cols.add_child(_stat_col("BOSS", [
		["Bolts", str(game.m5_stats["bolts"])],
		["Breaks", str(game.m5_stats["breaks"])],
		["Counters", "%d/%d" % [t["counter_hits"], t["counters"]]],
		["Level", "%d" % game.level]]))
	res_strip.rows = game.section_rows if game is LevelRun else []
	res_strip.visible = game is LevelRun and not game.section_rows.is_empty()
	res_strip.queue_redraw()
	res_details_text.text = "\n".join(lines)
	res_keep.visible = won and not (game is LevelRun)


## The tree's frame in the HUD's glass, its title in the system's type (T-038).
func _restyle_tree_panel() -> void:
	var tp: PanelContainer = tree_box.get_child(0)
	tp.add_theme_stylebox_override("panel", HudKit.glass(0.95, 12, 18.0))
	tree_title.add_theme_color_override("font_color", Color.WHITE)
	var f := FontVariation.new()
	f.base_font = UiTheme.heading_font()
	f.spacing_glyph = 1
	tree_title.add_theme_font_override("font", f)
	var head: Node = tree_title.get_parent()
	for c in head.get_children():
		if c is Button:
			HudKit.style_button(c, "secondary")
			c.text = "Close   Tab"
	tree_dim.color = Color(0.02, 0.03, 0.05, 0.55)
	# The pause screen in the same glass.
	var pp: PanelContainer = pause_box.get_child(0).get_child(0)
	pp.add_theme_stylebox_override("panel", HudKit.glass(0.95, 12, 22.0))
	for c in pp.get_child(0).get_children():
		if c is Button:
			HudKit.style_button(c, "primary", HudKit.GREEN)
