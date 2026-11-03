class_name HudKit
extends RefCounted
## The HUD's design system (T-038, Jared's go 2026-11-03): slate glass, one accent per
## tower, raised keycaps, chips and coin pills, and a few drawn parts (rings, the XP
## track, card glyphs, the song strip). The cursor card (HudCard), the top slab, the
## bottom bar and every menu are built from these so the whole interface reads as one.

const SLATE := Color("0d131a")
const EDGE := Color("1e293b")
const RAISED := Color("1c2430")
const TEXT := Color("d6dde6")
const MUTED := Color("8b97a8")
const GREEN := Color("4ade80")
const RED := Color("f87171")
const AMBER := Color("fbbf24")
const SKY := Color("38bdf8")
## Card rarity: the border and banner carry it, never the word.
const RARITY := {"grey": Color("94a3b8"), "green": Color("4ade80"), "blue": Color("60a5fa"), "purple": Color("c084fc"), "orange": Color("fb923c")}
const RARITY_GEMS := {"grey": 1, "green": 2, "blue": 3, "purple": 4, "orange": 5}


static func glass(alpha := 0.9, radius := 8, margin := 14.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(SLATE, alpha)
	s.border_color = EDGE
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 14
	s.shadow_offset = Vector2(0, 8)
	return s


static func flat(bg: Color, edge: Color, radius := 6, width := 1, margin := 6.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s


static func label(text: String, size := 13, color := TEXT, heading := false, tracking := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if heading or tracking > 0:
		var f := FontVariation.new()
		f.base_font = UiTheme.heading_font() if heading else ThemeDB.fallback_font
		f.spacing_glyph = tracking
		l.add_theme_font_override("font", f)
	return l


## A raised dark keycap: light top edge, darker lip, white glyph.
static func keycap(glyph: String, size := 11) -> PanelContainer:
	var cap := PanelContainer.new()
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cap.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var s := StyleBoxFlat.new()
	s.bg_color = RAISED
	s.border_color = Color("2c3644")
	s.set_border_width_all(1)
	s.border_width_bottom = 2
	s.set_corner_radius_all(4)
	s.content_margin_left = 5
	s.content_margin_right = 5
	s.content_margin_top = 0
	s.content_margin_bottom = 1
	cap.add_theme_stylebox_override("panel", s)
	var lip := StyleBoxFlat.new()
	lip.draw_center = false
	lip.border_color = Color("6b7a8f")
	lip.border_width_top = 1
	lip.set_corner_radius_all(4)
	var inner := PanelContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_stylebox_override("panel", lip)
	cap.add_child(inner)
	var l := label(glyph, size, Color.WHITE, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(l)
	return cap


## A button in the system: "primary" is a bright fill in the accent, "secondary" a
## raised slate cap, "ghost" a quiet outline.
static func style_button(b: Button, kind := "secondary", accent := SKY) -> void:
	b.focus_mode = Control.FOCUS_NONE
	var looks := {}
	match kind:
		"primary":
			looks = {"normal": [accent, accent.lightened(0.25)], "hover": [accent.lightened(0.12), Color.WHITE], "pressed": [accent.darkened(0.15), accent], "disabled": [Color(accent, 0.25), Color(accent, 0.35)]}
			b.add_theme_color_override("font_color", Color("0b1016"))
			b.add_theme_color_override("font_hover_color", Color("0b1016"))
			b.add_theme_color_override("font_pressed_color", Color("0b1016"))
			b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))
		"ghost":
			looks = {"normal": [Color(1, 1, 1, 0.02), EDGE.lightened(0.1)], "hover": [Color(1, 1, 1, 0.06), MUTED], "pressed": [Color(0, 0, 0, 0.2), SKY], "disabled": [Color(0, 0, 0, 0), EDGE]}
			b.add_theme_color_override("font_color", MUTED)
			b.add_theme_color_override("font_hover_color", TEXT)
		_:
			looks = {"normal": [RAISED, Color("2c3644")], "hover": [Color("263142"), Color("6b7a8f")], "pressed": [Color("141a23"), SKY], "disabled": [Color("12171e"), EDGE]}
			b.add_theme_color_override("font_color", TEXT)
			b.add_theme_color_override("font_hover_color", Color.WHITE)
			b.add_theme_color_override("font_pressed_color", SKY)
	for state in looks:
		var s := flat(looks[state][0], looks[state][1], 7, 1, 8.0)
		s.border_width_bottom = 2 if kind != "ghost" else 1
		b.add_theme_stylebox_override(state, s)
	b.add_theme_stylebox_override("hover_pressed", b.get_theme_stylebox("pressed"))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## A button with its key as a real keycap beside the text, not "(Tab)".
static func key_button(text: String, key: String, kind := "secondary", accent := SKY, size := Vector2(200, 44)) -> Button:
	var b := Button.new()
	b.custom_minimum_size = size
	style_button(b, kind, accent)
	b.add_theme_font_size_override("font_size", 15)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(row)
	if key != "":
		row.add_child(keycap(key, 11))
	var l := label(text, 15, Color("0b1016") if kind == "primary" else TEXT, true)
	l.name = "Text"
	row.add_child(l)
	return b


## A coin pill: the coin and a number, green or red.
static func coin_pill(text: String, ok := true) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tint := GREEN if ok else RED
	var s := flat(Color(tint, 0.12), Color(tint, 0.45), 10, 1, 2.0)
	s.content_margin_left = 5
	s.content_margin_right = 8
	pill.add_theme_stylebox_override("panel", s)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	pill.add_child(row)
	var coin := HudParts.Icon.new("gold")
	coin.custom_minimum_size = Vector2(16, 16)
	row.add_child(coin)
	var l := label(text, 13, tint, true)
	l.name = "Text"
	row.add_child(l)
	return pill


# --- Drawn parts ---------------------------------------------------------------------------

## A ring with a big centre glyph: the level on the morning screen, the grade on
## the results. `value` 0..1 fills the arc.
class Ring extends Control:
	var value := 0.0
	var color := Color.WHITE
	var text := ""
	var sub := ""
	var thickness := 8.0
	var glow := 0.0

	func _init(d := 120.0) -> void:
		custom_minimum_size = Vector2(d, d)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - thickness
		if glow > 0.0:
			draw_circle(c, r + thickness * 1.6, Color(color, 0.12 * glow))
		draw_circle(c, r + thickness * 0.5, Color(HudKit.SLATE, 0.95))
		draw_arc(c, r, 0, TAU, 64, Color(1, 1, 1, 0.07), thickness, true)
		if value > 0.0:
			draw_arc(c, r, -PI / 2, -PI / 2 + TAU * clampf(value, 0.0, 1.0), 64, color, thickness, true)
		var font := UiTheme.heading_font()
		var fs := int(r * (0.95 if text.length() <= 1 else 0.7))
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var y := c.y + fs * 0.36 - (6.0 if sub != "" else 0.0)
		draw_string(font, Vector2(c.x - tw * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color.lerp(Color.WHITE, 0.25))
		if sub != "":
			var ss := 11
			var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss).x
			draw_string(font, Vector2(c.x - sw * 0.5, y + 16.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, ss, HudKit.MUTED)


## The XP track: a recessed groove with a bright gradient fill and a soft sheen.
class Track extends Control:
	var value := 0.0
	var from := Color("38bdf8")
	var to := Color("a78bfa")

	func _init(h := 16.0) -> void:
		custom_minimum_size = Vector2(200, h)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var rad := size.y * 0.5
		_round(r, rad, Color("070b10"))
		_round(r.grow(-1), rad - 1, Color("0f1620"))
		draw_line(Vector2(rad, 1.5), Vector2(size.x - rad, 1.5), Color(0, 0, 0, 0.6), 2.0)  # Inner shadow: recessed.
		var w := (size.x - 4.0) * clampf(value, 0.0, 1.0)
		if w > 2.0:
			var steps := 24
			for i in steps:
				var x0 := 2.0 + w * i / steps
				var col := from.lerp(to, float(i) / steps)
				draw_rect(Rect2(x0, 3.0, w / steps + 0.5, size.y - 6.0), col)
			draw_rect(Rect2(2.0, 3.0, w, (size.y - 6.0) * 0.4), Color(1, 1, 1, 0.18))
			draw_circle(Vector2(2.0 + w, size.y * 0.5), size.y * 0.45, Color(to.lerp(Color.WHITE, 0.5), 0.35))
		_round(r, rad, Color(0, 0, 0, 0), false)

	func _round(r: Rect2, rad: float, col: Color, filled := true) -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		sb.draw_center = filled
		sb.border_color = HudKit.EDGE.lightened(0.1)
		sb.set_border_width_all(0 if filled else 1)
		sb.set_corner_radius_all(int(rad))
		draw_style_box(sb, r)


## A small drawn glyph for a card's bucket until real card art exists.
class Glyph extends Control:
	var kind := ""
	var color := Color.WHITE

	func _init(k: String, c: Color, d := 44.0) -> void:
		kind = k
		color = c
		custom_minimum_size = Vector2(d, d)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var s := minf(size.x, size.y) * 0.5
		var w := maxf(2.0, s * 0.12)
		match kind:
			"economy":
				for i in 3:
					var y := c.y + s * 0.35 - i * s * 0.28
					draw_circle(Vector2(c.x, y), s * 0.42, color.darkened(0.35))
					draw_circle(Vector2(c.x, y - 2), s * 0.38, color)
			"stats":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.7), c + Vector2(s * 0.55, -s * 0.1), c + Vector2(s * 0.2, -s * 0.1), c + Vector2(s * 0.2, s * 0.6), c + Vector2(-s * 0.2, s * 0.6), c + Vector2(-s * 0.2, -s * 0.1), c + Vector2(-s * 0.55, -s * 0.1)]), color)
			"enemy":
				draw_circle(c + Vector2(0, -s * 0.1), s * 0.55, color)
				draw_rect(Rect2(c + Vector2(-s * 0.3, s * 0.25), Vector2(s * 0.6, s * 0.35)), color)
				draw_circle(c + Vector2(-s * 0.22, -s * 0.12), s * 0.15, HudKit.SLATE)
				draw_circle(c + Vector2(s * 0.22, -s * 0.12), s * 0.15, HudKit.SLATE)
			"tower":
				draw_rect(Rect2(c + Vector2(-s * 0.35, -s * 0.3), Vector2(s * 0.7, s * 0.95)), color)
				for i in 3:
					draw_rect(Rect2(c + Vector2(-s * 0.45 + i * s * 0.33, -s * 0.6), Vector2(s * 0.24, s * 0.3)), color)
			"abilities":
				draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.15, -s * 0.75), c + Vector2(-s * 0.4, s * 0.1), c + Vector2(-s * 0.02, s * 0.1), c + Vector2(-s * 0.15, s * 0.75), c + Vector2(s * 0.4, -s * 0.1), c + Vector2(s * 0.02, -s * 0.1)]), color)
			"draft":
				for i in 3:
					var o := Vector2((i - 1) * s * 0.22, (1 - i) * s * 0.08)
					var rr := Rect2(c + o + Vector2(-s * 0.3, -s * 0.45), Vector2(s * 0.6, s * 0.85))
					draw_rect(rr, color.darkened(0.3 - i * 0.15))
					draw_rect(rr, HudKit.SLATE, false, w * 0.5)
			"lock":
				draw_arc(c + Vector2(0, -s * 0.15), s * 0.32, PI, TAU, 16, color, w)
				draw_rect(Rect2(c + Vector2(-s * 0.45, -s * 0.15), Vector2(s * 0.9, s * 0.7)), color)
			_:
				var pts := PackedVector2Array()
				for i in 10:
					var a := -PI / 2 + TAU * i / 10.0
					var rr := s * (0.7 if i % 2 == 0 else 0.3)
					pts.append(c + Vector2(cos(a), sin(a)) * rr)
				draw_colored_polygon(pts, color)


## The song as a strip of its sections, each coloured by how it went: green when the
## notes and parries landed, amber when they slipped, red when the camp took damage.
class Strip extends Control:
	var rows: Array = []  # {name, notes, offered, parried, throws, hp, boss}

	func _init() -> void:
		custom_minimum_size = Vector2(560, 46)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if rows.is_empty():
			return
		var font := UiTheme.heading_font()
		var gap := 4.0
		var w := (size.x - gap * (rows.size() - 1)) / rows.size()
		for i in rows.size():
			var r: Dictionary = rows[i]
			var x := i * (w + gap)
			var asked: int = r["offered"] + r["throws"]
			var got: int = r["notes"] + r["parried"]
			var frac := 1.0 if asked == 0 else float(got) / asked
			var col := HudKit.GREEN if frac >= 0.85 else (HudKit.AMBER if frac >= 0.6 else HudKit.RED.lerp(HudKit.AMBER, 0.3))
			if r["hp"] > 0:
				col = HudKit.RED
			if asked == 0 and r["hp"] == 0:
				col = HudKit.MUTED
			var bar := Rect2(x, 0, w, 14)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(col, 0.85)
			sb.set_corner_radius_all(4)
			draw_style_box(sb, bar)
			if r["boss"]:
				draw_rect(Rect2(x, 0, w, 3), Color(1, 1, 1, 0.6))
			var name: String = String(r["name"]).to_upper()
			var fs := 10
			var tw := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, Vector2(x + (w - tw) * 0.5, 28), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, HudKit.TEXT)
			var line := ("%d/%d" % [got, asked]) if asked > 0 else "-"
			if r["hp"] > 0:
				line += "  -%d hp" % r["hp"]
			var lw := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, Vector2(x + (w - lw) * 0.5, 42), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, HudKit.MUTED)
