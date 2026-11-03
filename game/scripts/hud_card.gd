class_name HudCard
extends PanelContainer
## The card by the cursor (Jared's tooltip spec, 2026-11-03): a blurred slate glass
## card lifted off the board, an accent per tower, a header with the tower's role
## and a cost pill, one line on what it does, and real keycaps for the controls.
## Used for the build tag and for the hover menu (sell / upgrade).

const SLATE := Color("0d131a")
const EDGE := Color("1e293b")
const MUTED := Color("8b97a8")
const GREEN := Color("4ade80")
const RED := Color("f87171")
const WIDTH := 300.0
## One identity colour per tower type (Frost is Jared's ice blue).
const ACCENTS := {"wall": Color("94a3b8"), "kick": Color("fb923c"), "bass": Color("a78bfa"), "slow": Color("38bdf8"), "poison": Color("4ade80"), "lightning": Color("facc15"), "light": Color("fde68a")}
const ROLES := {"wall": "Maze", "kick": "Single target", "bass": "Area damage", "slow": "Crowd control", "poison": "Damage over time", "lightning": "Chain", "light": "Support"}

const BLUR_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec2 rect_size = vec2(300.0, 100.0);
uniform float radius = 6.0;
uniform float blur = 2.5;
void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * blur;
	vec4 c = vec4(0.0);
	float w = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			float k = 1.0 / (1.0 + float(x * x + y * y));
			c += texture(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * px) * k;
			w += k;
		}
	}
	c /= w;
	vec2 p = UV * rect_size;
	vec2 q = abs(p - rect_size * 0.5) - (rect_size * 0.5 - radius);
	float d = length(max(q, vec2(0.0))) - radius;
	COLOR = vec4(c.rgb, clamp(0.5 - d, 0.0, 1.0));
}
"""

static var _shader: Shader

var _blur: ColorRect
var _glass: PanelContainer
var _accent_box: PanelContainer
var _icon_box: PanelContainer
var _icon: TextureRect
var _title: Label
var _role: Label
var _pill: PanelContainer
var _pill_text: Label
var _body: Label
var _rule_top: ColorRect
var _rule_bottom: ColorRect
var _keys: HBoxContainer
var _stats: HBoxContainer
var _stats_sig := ""
var _pill_short: Label
var _keys_sig := ""
var _accent := Color(0, 0, 0, 0)
var _accent_top: ColorRect


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	# Outer: only the soft drop shadow (0 8px 24px at 45%).
	var shadow := StyleBoxFlat.new()
	shadow.draw_center = false
	shadow.set_corner_radius_all(6)
	shadow.shadow_color = Color(0, 0, 0, 0.45)
	shadow.shadow_size = 12
	shadow.shadow_offset = Vector2(0, 8)
	add_theme_stylebox_override("panel", shadow)
	# The blurred board behind the card.
	if _shader == null:
		_shader = Shader.new()
		_shader.code = BLUR_SHADER
	_blur = ColorRect.new()
	_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	_blur.material = mat
	add_child(_blur)
	# Slate glass with the crisp 1px outer border.
	_glass = PanelContainer.new()
	_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color(SLATE, 0.88)
	glass.border_color = EDGE
	glass.set_border_width_all(1)
	glass.set_corner_radius_all(6)
	_glass.add_theme_stylebox_override("panel", glass)
	add_child(_glass)
	# The inner 1px accent highlight with a brighter top edge.
	_accent_box = PanelContainer.new()
	_accent_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glass.add_child(_accent_box)
	_accent_top = ColorRect.new()
	_accent_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_accent_top.custom_minimum_size = Vector2(0, 2)
	_accent_top.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_glass.add_child(_accent_top)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 8)
	_accent_box.add_child(v)
	# Header: icon, title and role, cost pill on the right.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 9)
	v.add_child(head)
	_icon_box = PanelContainer.new()
	_icon_box.custom_minimum_size = Vector2(34, 34)
	head.add_child(_icon_box)
	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.custom_minimum_size = Vector2(26, 26)
	_icon_box.add_child(_icon)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(names)
	_title = Label.new()
	var tracked := FontVariation.new()
	tracked.base_font = UiTheme.heading_font()
	tracked.spacing_glyph = 1
	_title.add_theme_font_override("font", tracked)
	_title.add_theme_font_size_override("font_size", 16)
	_title.add_theme_color_override("font_color", Color.WHITE)
	names.add_child(_title)
	_role = Label.new()
	var caps := FontVariation.new()
	caps.base_font = UiTheme.heading_font()
	caps.spacing_glyph = 1
	_role.add_theme_font_override("font", caps)
	_role.add_theme_font_size_override("font_size", 10)
	names.add_child(_role)
	_pill = PanelContainer.new()
	_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_pill)
	var pill_row := HBoxContainer.new()
	pill_row.add_theme_constant_override("separation", 4)
	_pill.add_child(pill_row)
	var coin := HudParts.Icon.new("gold")
	coin.custom_minimum_size = Vector2(18, 18)
	pill_row.add_child(coin)
	_pill_text = Label.new()
	_pill_text.add_theme_font_override("font", UiTheme.heading_font())
	_pill_text.add_theme_font_size_override("font_size", 14)
	pill_row.add_child(_pill_text)
	_pill_short = Label.new()  # "-5" when you are short: unmistakably an error state.
	_pill_short.add_theme_font_override("font", UiTheme.heading_font())
	_pill_short.add_theme_font_size_override("font_size", 11)
	_pill_short.add_theme_color_override("font_color", Color(RED, 0.85))
	_pill_short.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill_row.add_child(_pill_short)
	_rule_top = _rule()
	v.add_child(_rule_top)
	_stats = HBoxContainer.new()
	_stats.add_theme_constant_override("separation", 14)
	v.add_child(_stats)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(WIDTH - 24.0, 0)
	_body.add_theme_font_size_override("font_size", 13)
	_body.add_theme_color_override("font_color", Color("d6dde6"))
	v.add_child(_body)
	_rule_bottom = _rule()
	v.add_child(_rule_bottom)
	_keys = HBoxContainer.new()
	_keys.add_theme_constant_override("separation", 5)
	v.add_child(_keys)
	custom_minimum_size = Vector2(WIDTH, 0)
	set_accent(Color.WHITE)


func _rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = EDGE
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _process(_delta: float) -> void:
	if visible:
		(_blur.material as ShaderMaterial).set_shader_parameter("rect_size", size)


func set_accent(c: Color) -> void:
	if c == _accent:
		return
	_accent = c
	var hi := StyleBoxFlat.new()
	hi.draw_center = false
	hi.border_color = Color(c, 0.2)
	hi.set_border_width_all(1)
	hi.set_corner_radius_all(5)
	hi.set_content_margin_all(12)
	hi.content_margin_top = 11
	hi.content_margin_bottom = 10
	# A very soft inner glow: the accent tints the glass a touch, the top edge brighter.
	hi.draw_center = true
	hi.bg_color = Color(c, 0.045)
	_accent_box.add_theme_stylebox_override("panel", hi)
	var top_edge := Color(c, 0.85)
	hi.border_color = Color(c, 0.2)
	_accent_top.color = top_edge
	var ib := StyleBoxFlat.new()
	ib.bg_color = Color(c, 0.14)
	ib.border_color = Color(c, 0.45)
	ib.set_border_width_all(1)
	ib.set_corner_radius_all(5)
	ib.set_content_margin_all(4)
	_icon_box.add_theme_stylebox_override("panel", ib)
	_role.add_theme_color_override("font_color", Color(c.lerp(Color.WHITE, 0.15), 0.8))


func set_head(tex: Texture2D, title: String, role: String) -> void:
	_icon.texture = tex
	_icon_box.visible = tex != null
	_title.text = title.to_upper()
	_role.text = role.to_upper()
	_role.visible = role != ""


## The cost pill: a coin and the price, green when you can pay, red when short.
## A negative cost hides it.
func set_cost(cost: int, can_pay: bool, margin := 0) -> void:
	_pill.visible = cost >= 0
	if cost < 0:
		return
	var tint := GREEN if can_pay else RED
	_pill_text.text = str(cost)
	_pill_short.text = str(margin)
	_pill_short.visible = not can_pay
	_pill_text.add_theme_color_override("font_color", tint)
	var pb := StyleBoxFlat.new()
	pb.bg_color = Color(tint, 0.12)
	pb.border_color = Color(tint, 0.45)
	pb.set_border_width_all(1)
	pb.set_corner_radius_all(10)
	pb.content_margin_left = 6
	pb.content_margin_right = 9
	pb.content_margin_top = 2
	pb.content_margin_bottom = 2
	_pill.add_theme_stylebox_override("panel", pb)


func set_body(text: String) -> void:
	_body.text = text
	_body.visible = text != ""
	_rule_top.visible = _body.visible or _stats.visible


## The numbers as scannable data: [["DMG", "20"], ["RNG", "2.6"], ...].
func set_stats(entries: Array) -> void:
	var sig := str(entries)
	if sig != _stats_sig:
		_stats_sig = sig
		for c in _stats.get_children():
			c.queue_free()
		for e in entries:
			var cell := HBoxContainer.new()
			cell.add_theme_constant_override("separation", 4)
			var k := _small(e[0], MUTED)
			k.add_theme_font_override("font", UiTheme.heading_font())
			k.add_theme_font_size_override("font_size", 10)
			k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cell.add_child(k)
			var val := Label.new()
			val.text = e[1]
			val.add_theme_font_override("font", UiTheme.heading_font())
			val.add_theme_font_size_override("font_size", 15)
			val.add_theme_color_override("font_color", Color.WHITE)
			cell.add_child(val)
			_stats.add_child(cell)
	_stats.visible = not entries.is_empty()
	_rule_top.visible = _body.visible or _stats.visible


## The controls as keycaps: each entry is [[keys...], "action", optional colour].
func set_keys(entries: Array) -> void:
	var sig := str(entries)
	if sig == _keys_sig:
		return
	_keys_sig = sig
	for c in _keys.get_children():
		c.queue_free()
	var first := true
	for e in entries:
		if not first:
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(12, 0)
			_keys.add_child(gap)
		first = false
		var ks: Array = e[0]
		for i in ks.size():
			if i > 0:
				_keys.add_child(_small("+", MUTED))
			_keys.add_child(_keycap(ks[i]))
		_keys.add_child(_small(e[1], e[2] if e.size() > 2 else MUTED))
	_keys.visible = not entries.is_empty()
	_rule_bottom.visible = not entries.is_empty()


func _small(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", color)
	return l


## A raised dark keycap: a light top edge, a darker lip at the bottom, a white glyph.
func _keycap(glyph: String) -> PanelContainer:
	var cap := PanelContainer.new()
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var s := StyleBoxFlat.new()
	s.bg_color = Color("1c2430")
	s.border_color = Color("2c3644")
	s.set_border_width_all(1)
	s.border_width_bottom = 2
	s.set_corner_radius_all(4)
	s.content_margin_left = 5
	s.content_margin_right = 5
	s.content_margin_top = 0
	s.content_margin_bottom = 1
	cap.add_theme_stylebox_override("panel", s)
	var lip := StyleBoxFlat.new()  # The light top border as its own thin line.
	lip.draw_center = false
	lip.border_color = Color("6b7a8f")
	lip.border_width_top = 1
	lip.set_corner_radius_all(4)
	var inner := PanelContainer.new()
	inner.add_theme_stylebox_override("panel", lip)
	cap.add_child(inner)
	var l := Label.new()
	l.text = glyph
	l.add_theme_font_override("font", UiTheme.heading_font())
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color.WHITE)
	inner.add_child(l)
	return cap
