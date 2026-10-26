class_name Hud
extends CanvasLayer
## M6c: the clickable layer (D-0036). Plain Godot Controls built in code, on
## top of the drawn board. Build bar at the bottom, tower panel at the left,
## draft cards and the run screen in the middle. Keys still work for all of it.

var game: Node2D
var build_buttons := {}  # type -> Button
var wave_button: Button
var restore_button: Button
var pause_button: Button
var panel: PanelContainer
var panel_title: Label
var panel_body: Label
var upgrade_button: Button
var sell_button: Button
var draft_box: CenterContainer
var draft_title: Label
var draft_buttons: Array[Button] = []
var end_box: CenterContainer
var end_title: Label
var end_body: Label
var endless_button: Button
var tip: Label
var _bar: HBoxContainer
var card_row: HBoxContainer
var panel_row: HBoxContainer


func _init(target: Node2D) -> void:
	game = target
	layer = 5


func _ready() -> void:
	# Build bar.
	var bar := HBoxContainer.new()
	bar.name = "BuildBar"
	bar.add_theme_constant_override("separation", 6)
	add_child(bar)
	_bar = bar
	for type in game.builds:
		var b := Button.new()
		b.custom_minimum_size = Vector2(118, 44)
		b.toggle_mode = true
		b.pressed.connect(func(): game.selected = type; game.build_mode = true; _refresh())
		bar.add_child(b)
		build_buttons[type] = b
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(16, 1)
	bar.add_child(gap)
	wave_button = _button(bar, Vector2(150, 44), func(): game.start_wave())
	restore_button = _button(bar, Vector2(130, 44), func(): game._press_restore())
	pause_button = _button(bar, Vector2(90, 44), func(): game.toggle_pause())

	# Tower panel.
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(330, 0)
	add_child(panel)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	panel_title = Label.new()
	panel_title.add_theme_font_size_override("font_size", 18)
	vb.add_child(panel_title)
	panel_body = Label.new()
	panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_body.custom_minimum_size = Vector2(310, 0)
	vb.add_child(panel_body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)
	upgrade_button = _button(row, Vector2(140, 36), _on_upgrade)
	panel_row = row
	sell_button = _button(row, Vector2(120, 36), func(): game.sell(game.selected_cell))

	# Draft.
	draft_box = CenterContainer.new()
	draft_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	draft_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(draft_box)
	var dp := PanelContainer.new()
	draft_box.add_child(dp)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 10)
	dp.add_child(dv)
	draft_title = Label.new()
	draft_title.add_theme_font_size_override("font_size", 18)
	draft_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	dv.add_child(draft_title)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	dv.add_child(cards)
	card_row = cards
	for i in 3:
		var b := Button.new()
		b.custom_minimum_size = Vector2(230, 170)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		b.pressed.connect(func(): game._pick(i))
		cards.add_child(b)
		draft_buttons.append(b)

	# Run over.
	end_box = CenterContainer.new()
	end_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(end_box)
	var ep := PanelContainer.new()
	end_box.add_child(ep)
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 8)
	ep.add_child(ev)
	end_title = Label.new()
	end_title.add_theme_font_size_override("font_size", 22)
	ev.add_child(end_title)
	end_body = Label.new()
	end_body.custom_minimum_size = Vector2(640, 0)
	end_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ev.add_child(end_body)
	var er := HBoxContainer.new()
	er.add_theme_constant_override("separation", 8)
	ev.add_child(er)
	_button(er, Vector2(150, 40), func(): game.reset()).text = "Run again  (R)"
	endless_button = _button(er, Vector2(170, 40), func(): game.start_wave())
	endless_button.text = "Keep going  (N)"
	_button(er, Vector2(110, 40), func(): game.get_tree().change_scene_to_file("res://menu.tscn")).text = "Menu"

	# One-line tip under the bar.
	tip = Label.new()
	tip.add_theme_font_size_override("font_size", 13)
	tip.modulate = Color(1, 1, 1, 0.7)
	add_child(tip)
	_refresh()


func _on_upgrade() -> void:
	game.upgrade(game.selected_cell)


func _button(parent: Control, size: Vector2, on_press: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = size
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b


## Lays the controls out for the current window: bar along the bottom right
## of the panel, tip under the bar, tower panel bottom left above the message
## line. Cheap, so it runs every frame and follows any resize.
func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	var x := maxf(340.0, game.hud_left + (view.x - game.hud_left) * 0.5 - _bar.size.x * 0.5)
	_bar.position = Vector2(x, view.y - 56)
	tip.position = Vector2(x, view.y - 10 - 16)
	panel.position = Vector2(24, view.y - 60 - panel.size.y)


func _process(_delta: float) -> void:
	_layout()
	_refresh()


func _refresh() -> void:
	_refresh_bar()
	_refresh_panel()
	_refresh_draft()
	_refresh_end()
	tip.text = _tip()


func _refresh_bar() -> void:
	var playing: bool = game.state == "playing"
	for type in build_buttons:
		var b: Button = build_buttons[type]
		var spec: Dictionary = game.builds[type]
		var key := ""
		for k in game.build_keys:
			if game.build_keys[k] == type:
				key = OS.get_keycode_string(k)
		b.text = "%s  %s  %dg" % [key, game.tower_name(type), spec["cost"]]
		b.button_pressed = game.selected == type and game.build_mode
		b.disabled = not playing or game.gold < spec["cost"]
		if type == "wall" and game.wall_limit > 0:
			b.text += "  (%d/%d)" % [game.wall_count(), game.wall_limit]
	wave_button.text = ("Wave %d  in progress" % game.wave) if game.wave_active else ("Start wave %d  (N)" % (game.wave + 1))
	wave_button.disabled = game.wave_active or not playing or game.get("drafting") == true
	restore_button.text = "Restore  (F)  %d/%d" % [game.restore_charges, game.restore_cap()]
	restore_button.disabled = not playing or game.restore_charges <= 0 or game.suppressed.is_empty()
	pause_button.text = "Resume  (P)" if game.paused else "Pause  (P)"
	pause_button.disabled = not playing


func _refresh_panel() -> void:
	var playing: bool = game.state == "playing"
	var cell: Vector2i = game.selected_cell
	var show: bool = game.structures.has(cell)
	panel.visible = show
	if show:
		var s: Dictionary = game.structures[cell]
		var type: String = s["type"]
		if type == "wall":
			panel_title.text = "Wall"
			panel_body.text = "Blocks the path. Creeps reroute live.\nSell refunds 75%."
			upgrade_button.visible = false
		else:
			var spec: Dictionary = game.tower_spec(cell)
			panel_title.text = "%s tower%s" % [game.tower_name(type), "  (upgraded)" if s.get("tier", 0) >= 1 else ""]
			var body := "Damage %.0f   Range %.1f   Every %.2f s" % [spec["damage"], spec["range"], spec["cooldown"]]
			if spec.get("splash", 0.0) > 0.0:
				body += "   Splash %.1f" % spec["splash"]
			if spec.has("slow"):
				body += "   Slows %.1f s" % spec["slow"]
			body += "\nIts note: " + note_text(type)
			if game.suppressed.has(cell):
				body += "\nLOCKED for %.1f s. F to Restore." % game.suppressed[cell]
			elif game.immune.has(cell):
				body += "\nShielded from locks for %.1f s." % game.immune[cell]
			panel_body.text = body
			upgrade_button.visible = true
			if s.get("tier", 0) >= 1:
				upgrade_button.text = "Upgraded"
				upgrade_button.disabled = true
			else:
				upgrade_button.text = "Upgrade  %dg  (U)" % game.upgrade_cost(cell)
				upgrade_button.disabled = game.gold < game.upgrade_cost(cell) or not playing
		sell_button.text = "Sell  +%dg" % int(s.get("paid", game.builds[type]["cost"]) * game.SELL_REFUND)
		sell_button.disabled = not playing


## What a tower's note does, for the panel.
func note_text(type: String) -> String:
	var notes := {"kick": "Snipe: x4 damage (x8 Perfect) at the creep nearest the Conductor, anywhere.", "bass": "Wave: x2 (x4 Perfect) on everything within 2 tiles of the target.", "slow": "Freeze: x2 (x4 Perfect) within 2 tiles and holds them a beat (two on a Perfect)."}
	return notes.get(type, "")


func _refresh_draft() -> void:
	var drafting: bool = game.get("drafting") == true
	draft_box.visible = drafting
	if drafting:
		draft_title.text = "WAVE %d CLEAR   pick one, then build and start the next wave" % game.wave
		for i in 3:
			var b := draft_buttons[i]
			b.visible = i < game.draft.size()
			if i < game.draft.size():
				var card: Dictionary = game.CARDS[game.draft[i]]
				var kind: String = "PLAIN" if card["type"] == "plain" else ("ALTERING, once per run" if card["type"] == "altering" else "LOCKED PICK")
				var text: String = "%d   %s\n%s\n\n%s" % [i + 1, card["name"], kind, card["text"]]
				if card["type"] == "conditional":
					text += "\n\nUnlocks if you " + card["condition"]
				b.text = text
				b.modulate = Color(0.85, 0.85, 0.9) if card["type"] == "plain" else (Color(1.0, 0.8, 0.5) if card["type"] == "altering" else Color(0.75, 0.8, 1.0))



func _refresh_end() -> void:
	var playing: bool = game.state == "playing"
	end_box.visible = not playing
	if not playing:
		var lines: Array = game.run_lines()
		end_title.text = lines[0]
		end_body.text = "\n".join(lines.slice(1))
		end_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3) if game.state == "won" else Color(1, 0.5, 0.5))
		endless_button.visible = game.state == "won"


func _tip() -> String:
	if game.get("drafting") == true:
		return "Pick a card: click it or press 1, 2, 3."
	if game.paused:
		return "Paused. P or the button resumes."
	if game.structures.has(game.selected_cell):
		return "Click the board to place; click a tower to inspect it; right click sells."
	if game.wave_active:
		return "Q / E on a ring, Space on a landing projectile, F to Restore. Click a tower to inspect it."
	return "Left click places %s. Click a tower to inspect it. N starts the wave." % game.selected
