class_name HudParts
extends RefCounted
## Small drawn widgets for the Demo 1 HUD (readability pass, D-0045): the beat bar,
## a tower's step strip, the vector icons on the top bar, and the lines of the
## talent tree. Each one reads the sim every frame and redraws itself.


## The bar in the top bar: four beats, what each asks for, the live beat lit and a
## playhead sweeping across. Always on; between waves it shows the bar dimmed.
class BeatBar extends Control:
	var sim: Node
	const W := 380.0
	const H := 26.0

	func _init(target: Node) -> void:
		sim = target
		custom_minimum_size = Vector2(W, H)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if sim == null or sim.clock == null:
			return
		var font := UiTheme.heading_font()
		var beat: float = sim.clock.beat_length()
		var bt: float = sim.beat_time()
		var in_bar: float = fposmod(bt / beat, 4.0)
		var cur := floori(in_bar)
		var active: bool = sim.wave_active and sim.state == "playing"
		var labels: Array = ["1 parry", "2", "3", "4"]
		var kinds: Array = ["parry", "", "", ""]
		if sim.boss_alive():
			if sim.crescendo > 0.0:
				labels = ["CRES", "CEN", "DO", "!"]
				kinds = ["cres", "cres", "cres", "cres"]
			else:
				labels = ["1 parry", "2", "3 Q", "4"]
				kinds = ["parry", "", "kick", ""]
		else:
			for i in 3:
				var k: String = sim._wave_pattern[i] if i < String(sim._wave_pattern).length() else "."
				if k == "Q":
					labels[i + 1] = "%d Q" % (i + 2)
					kinds[i + 1] = "kick"
				elif k == "E":
					labels[i + 1] = "%d E" % (i + 2)
					kinds[i + 1] = "bass"
		var cw := (W - 12.0) / 4.0
		for i in 4:
			var r := Rect2(i * (cw + 4.0), 0, cw, H)
			var col := Color(0.55, 0.55, 0.6)
			match kinds[i]:
				"parry": col = Indicators.YELLOW
				"kick": col = Indicators.ORANGE
				"bass": col = Indicators.PURPLE
				"cres": col = Color(1.0, 0.85, 0.35)
			var lit := i == cur and active
			var a := (0.55 if lit else 0.16) * (1.0 if active else 0.6)
			draw_style_box(UiTheme.box(col * Color(1, 1, 1, a), col * Color(1, 1, 1, 0.95 if lit else 0.35), 2, 4, 0.0), r)
			var size := 15
			var tw := font.get_string_size(labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			draw_string(font, Vector2(r.position.x + (cw - tw) * 0.5, 19), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1, 1, 1, 1.0 if lit else (0.75 if active else 0.4)))
		# The playhead: where in the bar the music is right now.
		var x := in_bar / 4.0 * W
		draw_line(Vector2(x, -3), Vector2(x, H + 3), Color(1, 1, 1, 0.9 if active else 0.35), 2.0)


## A tower type's eight steps: lit where it fires, the current step outlined.
class StepStrip extends Control:
	var sim: Node
	var type := ""

	func _init(target: Node) -> void:
		sim = target
		custom_minimum_size = Vector2(8 * 15.0, 12)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		if is_visible_in_tree():
			queue_redraw()

	func _draw() -> void:
		if sim == null or type == "" or not sim.is_tower(type):
			return
		var steps: Array = sim.pattern_for(type)
		var cur := posmod(floori(sim.beat_time() / sim.step_length()), 8)
		var col: Color = sim.builds[type]["color"] if sim.builds[type].has("color") else Color(1, 0.8, 0.4)
		for i in 8:
			var r := Rect2(i * 15.0, 0, 12, 12)
			var on := steps.has(i)
			draw_rect(r, col if on else Color(1, 1, 1, 0.12))
			if i == cur:
				draw_rect(r.grow(1.5), Color.WHITE, false, 2.0)


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
