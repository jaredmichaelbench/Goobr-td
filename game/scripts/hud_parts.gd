class_name HudParts
extends RefCounted
## Small drawn widgets for the Demo 1 HUD (readability pass D-0045, round 2 D-0046):
## the vector icons, the XP bar, the instant tooltip, and the lines of the talent
## tree. Each one reads the sim every frame and redraws itself. (The beat bar and
## the step strip were removed in round 2: Jared, "they don't serve a purpose".)


## Plain vector icons for the top bar, so the numbers say what they are.
class Icon extends Control:
	var kind := ""

	func _init(k: String) -> void:
		kind = k
		custom_minimum_size = Vector2(20, 20)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		match kind:
			"gold":
				draw_circle(c, 8, Color(0.55, 0.4, 0.1))
				draw_circle(c, 7, UiTheme.GOLD)
				draw_arc(c, 4.5, 0, TAU, 20, Color(0.75, 0.55, 0.15), 1.5)
			"health":
				var red := Color(0.95, 0.3, 0.35)
				draw_circle(c + Vector2(-3.5, -2), 4.5, red)
				draw_circle(c + Vector2(3.5, -2), 4.5, red)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -0.5), c + Vector2(8, -0.5), c + Vector2(0, 8)]), red)
			"wave":
				draw_line(c + Vector2(-5, -8), c + Vector2(-5, 8), Color(0.85, 0.8, 0.7), 2.0)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -8), c + Vector2(7, -5), c + Vector2(-4, -1)]), Color(0.95, 0.4, 0.3))
			"shield":
				var pts := PackedVector2Array([c + Vector2(0, -8), c + Vector2(7, 0), c + Vector2(0, 8), c + Vector2(-7, 0)])
				draw_colored_polygon(pts, Color(0.6, 0.85, 1.0))
				draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0, 0, 0, 0.5), 1.5)
			"restore":
				draw_arc(c, 6.5, -PI * 0.35, PI * 1.45, 24, Color(1.0, 0.9, 0.4), 2.5)
				draw_colored_polygon(PackedVector2Array([c + Vector2(3, -9), c + Vector2(8, -5), c + Vector2(2, -3)]), Color(1.0, 0.9, 0.4))
			"lock":
				draw_arc(c + Vector2(0, -2), 4, PI, TAU, 12, Color(0.8, 0.8, 0.8), 2.0)
				draw_rect(Rect2(c + Vector2(-5.5, -1), Vector2(11, 8)), Color(0.8, 0.8, 0.8))
			"talents":
				var k := size.x / 20.0
				var pts := PackedVector2Array()
				for i in 10:
					var r := (9.0 if i % 2 == 0 else 4.0) * k
					var a := -PI / 2.0 + i * PI / 5.0
					pts.append(c + Vector2(cos(a), sin(a)) * r)
				draw_colored_polygon(pts, Color(0.55, 1.0, 0.65))
				draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0, 0, 0, 0.5), 1.5)
			"start":
				var k := size.x / 20.0
				draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -8) * k, c + Vector2(8, 0) * k, c + Vector2(-5, 8) * k]), UiTheme.GOLD)
			"restore_big":
				var k := size.x / 20.0
				draw_arc(c, 6.5 * k, -PI * 0.35, PI * 1.45, 32, Color(1.0, 0.9, 0.4), 2.5 * k)
				draw_colored_polygon(PackedVector2Array([c + Vector2(3, -9) * k, c + Vector2(8, -5) * k, c + Vector2(2, -3) * k]), Color(1.0, 0.9, 0.4))


## Behind the talent buttons: each area's spine running down its column, lit as
## far as the area's points reach, with the gate on each locked step; the shared
## nodes hang between two spines.
class TreeLines extends Control:
	var sim: Node
	var spines := {}  # area -> Array of Vector2 (node centres, row 1 to capstone)
	var links := []  # [shared centre, area, area]

	func _init(target: Node) -> void:
		sim = target
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		if is_visible_in_tree():
			queue_redraw()

	func _draw() -> void:
		var font := UiTheme.heading_font()
		for area in spines:
			var pts: Array = spines[area]
			var col: Color = TalentTree.AREA_COLORS[area]
			var have: int = TalentTree.area_points(area, sim.owned)
			for i in pts.size() - 1:
				var gate: int = TalentTree.GATES[i + 1]
				var lit := have >= gate
				draw_line(pts[i], pts[i + 1], col * Color(1, 1, 1, 0.9 if lit else 0.22), 4.0 if lit else 3.0)
				if not lit:
					var m: Vector2 = (pts[i] + pts[i + 1]) * 0.5
					draw_circle(m, 11, Color(0.08, 0.09, 0.11))
					draw_arc(m, 11, 0, TAU, 20, col * Color(1, 1, 1, 0.5), 1.5)
					var t := str(gate)
					var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
					draw_string(font, m + Vector2(-tw * 0.5, 4.5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.75))
		for l in links:
			for k in [1, 2]:
				var area: String = l[k]
				if not spines.has(area):
					continue
				var to: Vector2 = l[3 + (k - 1)]
				var col: Color = TalentTree.AREA_COLORS[area]
				draw_line(l[0], to, col * Color(1, 1, 1, 0.6), 2.0)


## The XP bar, World of Warcraft style (D-0046): a long bar in twenty bubbles with
## the level and the percent on it, and a green note when a point waits.
class XPBar extends Control:
	var sim: Node
	const BUBBLES := 20

	func _init(target: Node) -> void:
		sim = target
		custom_minimum_size = Vector2(300, 16)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.03, 0.03, 0.05, 0.95))
		var frac: float = clampf(sim.xp / sim.xp_to_next(), 0.0, 1.0)
		var fill := Rect2(r.position + Vector2(1, 1), Vector2((r.size.x - 2) * frac, r.size.y - 2))
		draw_rect(fill, Color(0.42, 0.22, 0.72))
		draw_rect(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.45)), Color(0.62, 0.4, 0.95))
		for i in range(1, BUBBLES):
			var x := r.size.x * i / BUBBLES
			draw_line(Vector2(x, 2), Vector2(x, r.size.y - 2), Color(0, 0, 0, 0.55), 1.0)
		draw_rect(r, Color(0.62, 0.48, 0.28), false, 1.5)
		var font := UiTheme.heading_font()
		var text := "Level %d    %d%%" % [sim.level, floori(frac * 100.0)]
		if sim.points > 0:
			text += "    %d talent point%s (Tab)" % [sim.points, "" if sim.points == 1 else "s"]
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var pos := Vector2((r.size.x - tw) * 0.5, r.size.y * 0.5 + 4.5)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0, 0, 0, 0.9))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 1.0, 0.7) if sim.points > 0 else Color.WHITE)


## The tooltip (D-0046): shows the moment the mouse is over its control, next to
## the cursor, as BBCode from Explain. The HUD hooks controls with a function that
## returns the text, so the numbers stay live while it is open.
class RichTip extends PanelContainer:
	var label: RichTextLabel
	var source: Callable
	var owner_control: Control

	func _init() -> void:
		add_theme_stylebox_override("panel", UiTheme.box(Color(0.05, 0.06, 0.08, 0.97), UiTheme.EDGE, 1, 5, 10.0))
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		label = RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(340, 0)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("normal_font_size", 14)
		label.add_theme_font_size_override("bold_font_size", 14)
		label.add_theme_font_override("bold_font", UiTheme.heading_font())
		add_child(label)
		visible = false
		top_level = true
		z_index = 100

	func hook(c: Control, text_source: Callable) -> void:
		c.tooltip_text = ""
		c.mouse_entered.connect(func(): show_for(c, text_source))
		c.mouse_exited.connect(func(): if owner_control == c: hide_tip())

	func show_for(c: Control, text_source: Callable) -> void:
		owner_control = c
		source = text_source
		_update()
		visible = label.text != ""

	func hide_tip() -> void:
		visible = false
		owner_control = null

	func _process(_d: float) -> void:
		if not visible:
			return
		if owner_control == null or not is_instance_valid(owner_control) or not owner_control.is_visible_in_tree():
			hide_tip()
			return
		_update()

	func _update() -> void:
		var text: String = source.call()
		if text != label.text:
			label.text = text
		reset_size()
		var view := get_viewport().get_visible_rect().size
		var m := get_viewport().get_mouse_position()
		var p := m + Vector2(18, 18)
		if p.x + size.x > view.x - 6.0:
			p.x = m.x - size.x - 12.0
		if p.y + size.y > view.y - 6.0:
			p.y = m.y - size.y - 12.0
		position = Vector2(maxf(6.0, p.x), maxf(6.0, p.y))
