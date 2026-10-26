class_name Hud7
extends Hud
## M7's HUD (D-0039): the M6 layer plus a build row of its own (seven
## buttons, locked ones say their requirement), a type panel with the ladder
## and the rung 3 fork, the talent tree, a five-card draft with a reroll, and
## a Tree button that lights up when a point is waiting.

var build_row: HBoxContainer
var tree_button: Button
var branch_button: Button
var fork_row: HBoxContainer
var fork_a_button: Button
var reroll_button: Button
var tree_box: CenterContainer
var tree_title: Label
var tree_nodes := {}  # id -> Button


func _ready() -> void:
	super._ready()
	# Build buttons move to their own row above the action bar.
	build_row = HBoxContainer.new()
	build_row.add_theme_constant_override("separation", 6)
	add_child(build_row)
	var keys: Array = game.build_keys.keys()
	keys.sort()  # Buttons in key order: 1 Wall, 2 Cannon ... 7 Light.
	for k in keys:
		var type: String = game.build_keys[k]
		var b: Button = build_buttons[type]
		b.get_parent().remove_child(b)
		build_row.add_child(b)
		b.custom_minimum_size = Vector2(106, 44)
		b.add_theme_font_size_override("font_size", 11)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	tree_button = _button(_bar, Vector2(120, 44), func(): game.toggle_tree())
	# The fork: its own row of two buttons above Upgrade / Sell, so the panel stays narrow.
	fork_row = HBoxContainer.new()
	fork_row.add_theme_constant_override("separation", 6)
	panel_row.get_parent().add_child(fork_row)
	panel_row.get_parent().move_child(fork_row, panel_row.get_index())
	fork_a_button = _button(fork_row, Vector2(150, 44), func(): game.upgrade_type(_panel_type(), 1))
	branch_button = _button(fork_row, Vector2(150, 44), func(): game.upgrade_type(_panel_type(), 2))
	upgrade_button.custom_minimum_size = Vector2(170, 44)
	upgrade_button.add_theme_font_size_override("font_size", 13)
	fork_a_button.add_theme_font_size_override("font_size", 13)
	branch_button.add_theme_font_size_override("font_size", 13)
	# Cards four and five, and the reroll.
	for i in [3, 4]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(230, 170)
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		b.pressed.connect(func(): game._pick(i))
		card_row.add_child(b)
		draft_buttons.append(b)
	for b in draft_buttons:
		b.custom_minimum_size = Vector2(200, 180)
		b.add_theme_font_size_override("font_size", 13)
	reroll_button = _button(card_row.get_parent(), Vector2(160, 36), func(): game.reroll_draft())
	# The tree.
	tree_box = CenterContainer.new()
	tree_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tree_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tree_box)
	var tp := PanelContainer.new()
	tp.add_theme_stylebox_override("panel", solid_style())
	tree_box.add_child(tp)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 8)
	tp.add_child(tv)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	tv.add_child(head)
	tree_title = Label.new()
	tree_title.add_theme_font_size_override("font_size", 18)
	tree_title.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
	tree_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tree_title)
	_button(head, Vector2(120, 32), func(): game.toggle_tree()).text = "Close  (Tab)"
	var areas := HBoxContainer.new()
	areas.add_theme_constant_override("separation", 14)
	tv.add_child(areas)
	var nodes: Dictionary = TalentTree.nodes()
	for area in TalentTree.AREAS:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		areas.add_child(col)
		var name := Label.new()
		name.text = TalentTree.AREA_NAMES[area]
		name.add_theme_font_size_override("font_size", 15)
		name.add_theme_color_override("font_color", TalentTree.AREA_COLORS[area])
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(name)
		var grid := GridContainer.new()
		grid.columns = TalentTree.COLS
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		col.add_child(grid)
		for r in TalentTree.ROWS:
			for c in TalentTree.COLS:
				var id := "%s_%d_%d" % [area, r, c]
				grid.add_child(_node_button(id, nodes[id], Vector2(74, 40)))
		col.add_child(_node_button(area + "_cap", nodes[area + "_cap"], Vector2(230, 44)))
	var foot := Label.new()
	foot.text = "A node needs one owned node in the row above it (same column or next to it). Dotted links let a neighbour area in. Hover a node for what it does."
	foot.add_theme_font_size_override("font_size", 12)
	foot.modulate = Color(1, 1, 1, 0.6)
	tv.add_child(foot)


func _node_button(id: String, node: Dictionary, size: Vector2) -> Button:
	var b := Button.new()
	b.custom_minimum_size = size
	b.text = node["name"]
	b.add_theme_font_size_override("font_size", 11)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	b.tooltip_text = "%s\n%s%s" % [node["name"], node["text"], ("\nNeeds: " + ", ".join(node["needs"].map(func(n): return TalentTree.nodes()[n]["name"]))) if not node["needs"].is_empty() else ""]
	b.pressed.connect(func(): game.take_talent(id))
	tree_nodes[id] = b
	return b


func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	var x := maxf(360.0, game.hud_left + (view.x - game.hud_left) * 0.5 - build_row.size.x * 0.5)
	x = minf(x, view.x - build_row.size.x - 8)  # Never off the right edge on a narrow window.
	_bar.position = Vector2(x, view.y - 56)
	build_row.position = Vector2(x, view.y - 56 - 50)
	tip.position = Vector2(x, view.y - 10 - 16)
	panel.position = Vector2(24, view.y - 60 - panel.size.y)


func _refresh() -> void:
	if reroll_button == null:
		return  # Base _ready() refreshes before our controls exist; _ready() below refreshes again.
	super._refresh()
	_refresh_tree()


func _refresh_bar() -> void:
	super._refresh_bar()
	var playing: bool = game.state == "playing"
	for type in build_buttons:
		var b: Button = build_buttons[type]
		if not game.unlocked.has(type):
			b.text = "%s  %s  %dg\n%s" % [_key(type), game.tower_name(type), game.builds[type]["cost"], game.unlock_text(type)]
			b.disabled = true
		elif game.type_rank.get(type, 0) > 0:
			b.text += "  r%d" % game.type_rank[type]
	tree_button.text = "Tree  (Tab)" + ("  +%d" % game.points if game.points > 0 else "")
	tree_button.modulate = Color(0.6, 1.0, 0.7) if game.points > 0 else Color.WHITE
	tree_button.disabled = not playing


func _key(type: String) -> String:
	for k in game.build_keys:
		if game.build_keys[k] == type:
			return OS.get_keycode_string(k)
	return ""


## The type the panel is about: the selected tower's, else the selected build.
func _panel_type() -> String:
	if game.structures.has(game.selected_cell):
		return game.structures[game.selected_cell]["type"]
	return game.selected if game.build_mode else ""


func _on_upgrade() -> void:
	var type := _panel_type()
	if type == "":
		return
	game.upgrade_type(type, 1 if game.type_rank.get(type, 0) == 2 else 0)


func _refresh_panel() -> void:
	var playing: bool = game.state == "playing"
	var cell: Vector2i = game.selected_cell
	var has_tower: bool = game.structures.has(cell)
	var type := _panel_type()
	if type == "" or (type == "wall" and not has_tower):
		panel.visible = false
		return
	panel.visible = true
	fork_row.visible = false
	if type == "wall":
		panel_title.text = "Wall"
		panel_body.text = "Blocks the path. Creeps reroute live.\nSell refunds 75%."
		upgrade_button.visible = false
		sell_button.visible = true
		sell_button.text = "Sell  +%dg" % int(game.structures[cell].get("paid", game.builds[type]["cost"]) * game.SELL_REFUND)
		sell_button.disabled = not playing
		return
	var rank: int = game.type_rank.get(type, 0)
	var branch: int = game.type_branch.get(type, 0)
	var spec: Dictionary = game.tower_spec(cell) if has_tower else game.type_spec(type)
	panel_title.text = "%s tower   rung %d/5%s" % [game.tower_name(type), rank, ("   " + game.BRANCHES[type][branch - 1][0]) if branch > 0 else ""]
	var body := "Damage %.0f   Range %.1f   fires on %d of 8 steps" % [spec["damage"], spec["range"], game.pattern_for(type).size()]
	if spec.get("splash", 0.0) > 0.0:
		body += "   Splash %.1f" % spec["splash"]
	if spec.has("slow"):
		body += "   Slows %.1f s" % spec["slow"]
	body += "\nIts note: " + note_text(type)
	body += "\nOn the board: %d   (upgrades apply to all of them)" % game.towers_of(type)
	if not game.unlocked.has(type):
		body += "\nLOCKED: " + game.unlock_text(type)
	if has_tower and game.suppressed.has(cell):
		body += "\nLOCKED for %.1f s. F to Restore." % game.suppressed[cell]
	elif has_tower and game.immune.has(cell):
		body += "\nShielded from locks for %.1f s." % game.immune[cell]
	upgrade_button.visible = true
	var cost: int = game.type_upgrade_cost(type)
	if not game.unlocked.has(type):
		upgrade_button.text = "Locked"
		upgrade_button.disabled = true
	elif rank >= 5:
		upgrade_button.text = "Maxed"
		upgrade_button.disabled = true
	elif rank == 2:
		var br: Array = game.BRANCHES[type]
		body += "\nThe fork: %s (%s)  or  %s (%s)" % [br[0][0], br[0][1], br[1][0], br[1][1]]
		upgrade_button.visible = false
		fork_row.visible = true
		fork_a_button.text = "%s  %dg  (U)" % [br[0][0], cost]
		fork_a_button.disabled = game.gold < cost or not playing
		branch_button.text = "%s  %dg  (I)" % [br[1][0], cost]
		branch_button.disabled = game.gold < cost or not playing
	else:
		upgrade_button.text = "Upgrade  %dg  (U)\nrung %d: %s" % [cost, rank + 1, game.rung_text(type, rank + 1)]
		upgrade_button.disabled = game.gold < cost or not playing
	panel_body.text = body
	sell_button.visible = has_tower
	if has_tower:
		sell_button.text = "Sell  +%dg" % int(game.structures[cell].get("paid", game.builds[type]["cost"]) * game.SELL_REFUND)
		sell_button.disabled = not playing


func note_text(type: String) -> String:
	var notes := {
		"kick": "Snipe: x4 damage (x8 Perfect) at the creep nearest the Conductor, anywhere.",
		"bass": "Wave: x2 (x4 Perfect) on everything within 2 tiles of the target.",
		"slow": "Freeze: x2 (x4 Perfect) within 2 tiles and holds them a beat (two on a Perfect).",
		"poison": "Spread: the target's poison (at least 3 stacks) jumps to every creep within 2 tiles.",
		"lightning": "Storm: every creep on the board takes a hit at once.",
		"light": "Chorus: every tower within 2 tiles fires once for free (twice on a Perfect).",
	}
	return notes.get(type, "")


func _refresh_draft() -> void:
	var drafting: bool = game.get("drafting") == true
	draft_box.visible = drafting
	if not drafting:
		return
	draft_title.text = "WAVE %d CLEAR   pick one card, then build and start the next wave" % game.wave
	var cards: Array = game.draft_cards
	for i in draft_buttons.size():
		var b := draft_buttons[i]
		b.visible = i < cards.size()
		if i < cards.size():
			var card: Dictionary = cards[i]
			var text: String = "%d   %s\n%s   %s\n\n%s" % [i + 1, card["name"], card["rarity"].to_upper(), CardPool.CATEGORY_NAMES[card["cat"]], card["text"]]
			if card.has("cond"):
				text += "\n\nLOCKED: unlocks if you " + CardPool.CONDITIONS[card["cond"]]
			b.text = text
			b.modulate = CardPool.RARITY_COLORS[card["rarity"]]
	reroll_button.visible = true
	reroll_button.text = "Reroll  (%d left)" % game.rerolls_left
	reroll_button.disabled = game.rerolls_left <= 0


func _refresh_tree() -> void:
	tree_box.visible = game.tree_open
	if not game.tree_open:
		return
	tree_title.text = "TALENTS   level %d   %d point%s to spend" % [game.level, game.points, "" if game.points == 1 else "s"]
	for id in tree_nodes:
		var b: Button = tree_nodes[id]
		var node: Dictionary = TalentTree.nodes()[id]
		var owned: bool = game.owned.has(id)
		var open: bool = TalentTree.available(id, game.owned)
		if owned:
			b.modulate = TalentTree.AREA_COLORS[node["area"]]
			b.disabled = true
			b.text = node["name"] + " ✓"
		elif open and game.points > 0:
			b.modulate = Color.WHITE
			b.disabled = false
			b.text = node["name"]
		else:
			b.modulate = Color(1, 1, 1, 0.45) if open else Color(1, 1, 1, 0.25)
			b.disabled = true
			b.text = node["name"]


func _tip() -> String:
	if game.tree_open:
		return "Spend talent points. Tab or Close resumes."
	if game.get("drafting") == true:
		return "Pick a card: click it or press its number."
	if game.points > 0 and not game.paused:
		return "A talent point is waiting: Tab opens the tree."
	return super._tip()
