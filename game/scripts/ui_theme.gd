class_name UiTheme
extends RefCounted
## The one Theme for every menu and the HUD (M10): dark slate panels with a bronze
## edge, Warcraft 3 / Legion TD style, Lilita One for headings and buttons.

const FONT_PATH := "res://assets/fonts/lilita_one_regular.ttf"
const PANEL := Color(0.075, 0.085, 0.11, 0.96)
const PANEL_SOFT := Color(0.075, 0.085, 0.11, 0.82)
const EDGE := Color(0.62, 0.48, 0.28)
const GOLD := Color(1.0, 0.85, 0.35)
const TEXT := Color(0.93, 0.92, 0.88)

static var _theme: Theme


static func heading_font() -> Font:
	return load(FONT_PATH) if ResourceLoader.exists(FONT_PATH) else ThemeDB.fallback_font


static func box(bg: Color, edge: Color, width := 2, radius := 6, margin := 10.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 4
	return s


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 14
	var head := heading_font()
	t.set_stylebox("panel", "PanelContainer", box(PANEL, EDGE))
	t.set_stylebox("panel", "Panel", box(PANEL, EDGE))
	t.set_color("font_color", "Label", TEXT)
	# Buttons: stone with a bronze rim; gold rim on hover, sunk when pressed.
	var normal := box(Color(0.16, 0.17, 0.21), Color(0.42, 0.34, 0.22), 2, 5, 6.0)
	var hover := box(Color(0.22, 0.23, 0.28), GOLD, 2, 5, 6.0)
	var pressed := box(Color(0.3, 0.25, 0.14), GOLD, 2, 5, 6.0)
	var disabled := box(Color(0.11, 0.12, 0.14), Color(0.25, 0.22, 0.18), 2, 5, 6.0)
	for kind in ["Button"]:
		t.set_stylebox("normal", kind, normal)
		t.set_stylebox("hover", kind, hover)
		t.set_stylebox("pressed", kind, pressed)
		t.set_stylebox("hover_pressed", kind, pressed)
		t.set_stylebox("disabled", kind, disabled)
		t.set_stylebox("focus", kind, StyleBoxEmpty.new())
		t.set_font("font", kind, head)
		t.set_font_size("font_size", kind, 15)
		t.set_color("font_color", kind, TEXT)
		t.set_color("font_hover_color", kind, Color.WHITE)
		t.set_color("font_pressed_color", kind, GOLD)
		t.set_color("font_hover_pressed_color", kind, GOLD)
		t.set_color("font_disabled_color", kind, Color(0.55, 0.55, 0.55))
	t.set_stylebox("panel", "TooltipPanel", box(Color(0.05, 0.06, 0.08, 0.97), EDGE, 1, 4, 8.0))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_stylebox("slider", "HSlider", box(Color(0.12, 0.12, 0.15), Color(0.3, 0.27, 0.2), 1, 3, 3.0))
	t.set_stylebox("grabber_area", "HSlider", box(Color(0.75, 0.6, 0.3), Color(0.75, 0.6, 0.3), 1, 3, 3.0))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(GOLD, GOLD, 1, 3, 3.0))
	_theme = t
	return t


## A heading label in the display font.
static func heading(text: String, size := 22, color := GOLD) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", heading_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	return l
