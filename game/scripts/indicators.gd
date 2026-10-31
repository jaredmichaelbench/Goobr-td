class_name Indicators
extends Node2D
## Demo 1 (D-0043): the marks that float above their owner, drawn in screen space over
## the 3D board so they stay crisp and always face you. Sizes are in metres at the
## owner's depth, so near and far marks keep their proportions. Note badges follow
## Jared's sketch: a filled disc with the key, the closing ring around it.

const NOTE_LIFT := 2.45  # Badge height over a tower (metres).
const CONDUCTOR_LIFT := 2.2
const ORANGE := Color(1.0, 0.55, 0.3)
const PURPLE := Color(0.7, 0.45, 1.0)
const YELLOW := Color(1.0, 0.9, 0.3)
const RED := Color(1.0, 0.3, 0.4)

var sim: RunSim
var view: View3D
var font: Font


func _ready() -> void:
	font = load("res://assets/fonts/lilita_one_regular.ttf") if ResourceLoader.exists("res://assets/fonts/lilita_one_regular.ttf") else ThemeDB.fallback_font


func _process(_delta: float) -> void:
	queue_redraw()


func _at(p: Vector3) -> Vector2:
	return view.screen_at(p)


func _ppm(p: Vector3) -> float:
	return view.px_per_m(p)


func _text(pos: Vector2, text: String, size: int, color: Color, outline := 5) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := pos + Vector2(-w * 0.5, size * 0.36)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(0, 0, 0, 0.85 * color.a))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _pips(center: Vector2, gone: int, color: Color, ppm: float) -> void:
	var r := maxf(2.5, ppm * 0.06)
	for i in 4:
		var p := center + Vector2((-1.5 + i) * r * 2.8, 0)
		draw_circle(p, r + 1.0, Color(0, 0, 0, 0.6))
		draw_circle(p, r, color if i < gone else Color(1, 1, 1, 0.3))


func _draw() -> void:
	if sim == null or view == null or view.cam == null:
		return
	var beat: float = sim.clock.beat_length()
	var bt: float = sim.beat_time()
	_draw_creep_marks(bt)
	_draw_towers()
	_draw_notes(bt)
	_draw_throws(bt, beat)
	_draw_conductor(bt, beat)
	_draw_boss(bt, beat)
	_draw_popups()


func _draw_creep_marks(_bt: float) -> void:
	for c in sim.creeps:
		if c["hp"] <= 0.0 or c.get("boss", false):
			continue
		var kind := view.creep_kind(c)
		var h: float = Art.CREEPS.get(kind, Art.CREEPS["grunt"])["height"]
		var top := View3D.world(c["pos"], h + 0.15)
		if view.is_behind(top):
			continue
		var p := _at(top)
		var ppm := _ppm(top)
		# Health bar once hurt (always for elites).
		var frac: float = clampf(c["hp"] / c["max_hp"], 0.0, 1.0)
		if frac < 0.999 or c.get("elite", false):
			var w := ppm * (0.7 if c.get("elite", false) else 0.5)
			var r := Rect2(p - Vector2(w * 0.5, 0), Vector2(w, maxf(3.0, ppm * 0.07)))
			draw_rect(r.grow(1.0), Color(0, 0, 0, 0.7))
			draw_rect(Rect2(r.position, Vector2(r.size.x * frac, r.size.y)), Color(0.45, 1.0, 0.4) if not c.get("elite", false) else Color(1.0, 0.45, 0.4))
		# A veiled Shade: the share of damage it still takes.
		if c.get("veil", false) and int(c.get("cracks", 0)) < sim.VEIL_MULTS.size() - 1:
			_text(p + Vector2(0, -ppm * 0.22), "%d%%" % roundi(sim.VEIL_MULTS[int(c.get("cracks", 0))] * 100), maxi(11, int(ppm * 0.28)), Color(0.8, 0.65, 1.0))
		# Poison stacks.
		if c.get("poison", 0.0) > 0.0 and (sim.type_branch.get("poison", 0) == 2 or c.get("poison_until", 0.0) > sim.sim_time):
			_text(p + Vector2(ppm * 0.42, 0), "%d" % roundi(c["poison"]), maxi(10, int(ppm * 0.24)), Color(0.6, 1.0, 0.45))
	# The counter window: a yellow flash and TAP on the parried enemy.
	if not sim._counter_open.is_empty() and sim.creeps.has(sim._counter_open["ref"]):
		var c: Dictionary = sim._counter_open["ref"]
		var a: float = clampf((sim._counter_open["until"] - sim.press_time()) / (sim.COUNTER_TAP_MS / 1000.0), 0.0, 1.0)
		if a > 0.0:
			var h: float = Art.CREEPS.get(view.creep_kind(c), Art.CREEPS["grunt"])["height"]
			var mid := View3D.world(c["pos"], h * 0.5)
			var p := _at(mid)
			var ppm := _ppm(mid)
			draw_arc(p, ppm * (0.6 + 0.5 * (1.0 - a)), 0, TAU, 40, Color(1.0, 0.9, 0.3, 0.3 + 0.7 * a), 4.0)
			_text(p + Vector2(0, -ppm * (h * 0.5 + 0.45)), "TAP", maxi(14, int(ppm * 0.4)), YELLOW)


func _draw_towers() -> void:
	for cell in sim.structures:
		var type: String = sim.structures[cell]["type"]
		if not sim.is_tower(type):
			continue
		var base := View3D.world(Vector2(cell), 0.0)
		var ppm := _ppm(base)
		# Rank is on the tower itself now: bands at its base (View3D, D-0045).
		# A locked tower: a red badge with a cross, and the time draining under it.
		if sim.suppressed.has(cell):
			var top := View3D.world(Vector2(cell), NOTE_LIFT - 0.3)
			var p := _at(top)
			var r := ppm * 0.26
			draw_circle(p, r + 2.0, Color(0, 0, 0, 0.7))
			draw_circle(p, r, Color(0.55, 0.08, 0.12))
			var k := r * 0.55
			draw_line(p + Vector2(-k, -k), p + Vector2(k, k), Color.WHITE, maxf(2.0, r * 0.22))
			draw_line(p + Vector2(k, -k), p + Vector2(-k, k), Color.WHITE, maxf(2.0, r * 0.22))
			var frac: float = sim.suppressed[cell] / sim.SUPPRESS_SECONDS
			var bar := Rect2(p + Vector2(-r, r + 4.0), Vector2(r * 2.0, 4.0))
			draw_rect(bar, Color(0, 0, 0, 0.6))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), RED)
		elif sim.immune.has(cell):
			var top := View3D.world(Vector2(cell), 1.2)
			var a: float = clampf(sim.immune[cell] / (sim.IMMUNE_BARS * sim.clock.bar_length()), 0.0, 1.0)
			draw_arc(_at(top), ppm * 0.62, 0, TAU, 32, Color(1.0, 0.95, 0.6, 0.25 + 0.5 * a), 3.0)


## Each open note: a disc in the note's colour with its key, over its tower, and a
## ring closing on it over the two beats before it lands.
## A call (D-0046) shows whole as soon as its first ring starts: the notes still
## to come sit as small dim discs with their order, so the sequence can be read.
func _draw_notes(bt: float) -> void:
	var lead: float = sim.RING_LEAD_STEPS * sim.step_length()
	var order := {}  # seq id -> note times in order
	for n in sim.notes:
		if n.has("seq"):
			if not order.has(n["seq"]):
				order[n["seq"]] = []
			order[n["seq"]].append(n["time"])
	for id in order:
		order[id].sort()
	for n in sim.notes:
		if n["state"] != "open" or not (n["tower"] is Vector2i) or not sim.structures.has(n["tower"]):
			continue
		var top := View3D.world(Vector2(n["tower"]), NOTE_LIFT)
		var p := _at(top)
		var ppm := _ppm(top)
		var color: Color = ORANGE if n["type"] == "kick" else PURPLE
		var num: int = (order[n["seq"]].find(n["time"]) + 1) if n.has("seq") and order[n["seq"]].size() > 1 else 0
		if n["time"] - bt > lead:
			var rs := ppm * 0.22
			draw_circle(p, rs + 2.0, Color(0.1, 0.08, 0.12, 0.6))
			draw_circle(p, rs, color * Color(1, 1, 1, 0.5))
			_text(p, sim.NOTE_NAMES[n["type"]], maxi(11, int(rs * 1.2)), Color(0.12, 0.08, 0.1, 0.8), 0)
			if num > 0:
				_text(p + Vector2(rs + 8.0, -rs - 2.0), str(num), 13, Color(1, 1, 1, 0.75), 3)
			continue
		var left: float = clampf((n["time"] - bt) / lead, 0.0, 1.0)
		var r := ppm * 0.3
		draw_arc(p, r + ppm * 1.25 * left, 0, TAU, 48, color * Color(1, 1, 1, 0.45 + 0.55 * (1.0 - left)), maxf(3.0, ppm * 0.08))
		draw_circle(p, r + 3.0, Color(0.1, 0.08, 0.12, 0.9))
		draw_circle(p, r, color)
		if left <= 0.02:
			draw_arc(p, r + 3.0, 0, TAU, 40, Color.WHITE, 3.0)
		_text(p, sim.NOTE_NAMES[n["type"]], maxi(14, int(r * 1.25)), Color(0.12, 0.08, 0.1), 0)
		if num > 0:
			_text(p + Vector2(r + 9.0, -r - 3.0), str(num), 15, Color.WHITE, 3)


## Elite throws: the target tower's ring closing over the bar, four beat pips.
func _draw_throws(bt: float, beat: float) -> void:
	for c in sim.creeps:
		if not c.get("elite", false) or c.get("pulse_at", -1.0) < 0.0:
			continue
		var frac: float = clampf((bt - c["pulse_from"]) / maxf(c["pulse_at"] - c["pulse_from"], 0.01), 0.0, 1.0)
		var gone := clampi(floori((bt - c["pulse_from"]) / beat), 0, 4)
		for cell in c["pulse_targets"]:
			if not sim.structures.has(cell):
				continue
			var mid := View3D.world(Vector2(cell), 1.0)
			var p := _at(mid)
			var ppm := _ppm(mid)
			draw_arc(p, ppm * (0.6 + 1.4 * (1.0 - frac)), 0, TAU, 48, RED * Color(1, 1, 1, 0.35 + 0.65 * frac), 2.0 + 3.0 * frac)
			draw_arc(p, ppm * 0.6, 0, TAU, 40, RED * Color(1, 1, 1, 0.95 if c["told"] else 0.5), 4.0 if c["told"] else 2.0)
			_pips(_at(View3D.world(Vector2(cell), 0.0)) + Vector2(0, ppm * 0.45), gone, RED, ppm)
	for st in sim.stomps:
		if st["state"] != "flying":
			continue
		var gone := clampi(floori((bt - st["from"]) / beat), 0, 4)
		var base := View3D.world(st["pos"], 2.6)
		_pips(_at(base), gone, Color(1, 0.35, 0.5), _ppm(base))


## The Conductor: incoming arrows and bolts close a ring on it, shields under it,
## the streak ball beside it.
func _draw_conductor(bt: float, beat: float) -> void:
	var cp := view.conductor_point()
	var p := _at(cp + Vector3(0, 0.3, 0))
	var ppm := _ppm(cp)
	var soonest := INF
	var frac := 0.0
	var gone := 0
	for a in sim.arrows:
		if a["state"] == "flying" and a["arrive"] < soonest:
			soonest = a["arrive"]
			frac = clampf((bt - a["launch"]) / maxf(a["arrive"] - a["launch"], 0.01), 0.0, 1.0)
			gone = clampi(floori((bt - a["launch"]) / beat), 0, 4)
	for b in sim.bolts:
		if b["state"] == "flying" and b["told"] and b["arrive"] < soonest:
			soonest = b["arrive"]
			frac = clampf((bt - b["launch"]) / maxf(b["arrive"] - b["launch"], 0.01), 0.0, 1.0)
			gone = -1
	if soonest < INF:
		draw_arc(p, ppm * (0.55 + 1.4 * (1.0 - frac)), 0, TAU, 48, RED * Color(1, 1, 1, 0.35 + 0.65 * frac), 2.0 + 3.0 * frac)
		draw_arc(p, ppm * 0.55, 0, TAU, 40, RED * Color(1, 1, 1, 0.9), 3.0)
		if gone >= 0:
			_pips(p + Vector2(0, -ppm * 0.95), gone, RED, ppm)
	if sim._conductor_flash["ttl"] > 0.0:
		var a: float = sim._conductor_flash["ttl"] / 0.4
		draw_arc(p, ppm * (0.6 + 1.2 * (1.0 - a)), 0, TAU, 48, sim._conductor_flash["color"] * Color(1, 1, 1, a), 5.0)
	# Shields: diamonds under the Conductor.
	var sp := _at(cp + Vector3(0, -0.9, 0.9))
	for i in sim.shield_cap:
		var q := sp + Vector2((i - (sim.shield_cap - 1) * 0.5) * 16.0, 0)
		var filled: bool = i < sim.shields
		var d := PackedVector2Array([q + Vector2(0, -7), q + Vector2(6, 0), q + Vector2(0, 7), q + Vector2(-6, 0)])
		draw_colored_polygon(d, Color(0.6, 0.85, 1.0) if filled else Color(1, 1, 1, 0.18))
		draw_polyline(d + PackedVector2Array([d[0]]), Color(0, 0, 0, 0.6), 1.5)
	# The streak ball, filling toward the next intensity step.
	var bp := p + Vector2(-ppm * 0.9, -ppm * 0.9)
	var colors := [Color(0.5, 0.5, 0.55), Color(0.9, 0.9, 0.95), Color(1.0, 0.85, 0.35), Color(1.0, 0.6, 0.2)]
	var color: Color = colors[clampi(sim.intensity, 0, colors.size() - 1)]
	var r: float = 7.0 + 3.0 * sim.intensity + (10.0 * sim._ball_pulse if sim._ball_pulse > 0.0 else 0.0)
	if sim._ball_pulse < 0.0:
		draw_circle(bp, r + 4.0 * (-sim._ball_pulse / 0.35), Color(1, 0.3, 0.3, 0.5 * (-sim._ball_pulse / 0.35)))
	if sim.intensity >= sim.INTENSITY_STEPS:
		draw_circle(bp, r + 5.0 + 2.0 * sin(bt * TAU * 2.0), color * Color(1, 1, 1, 0.25))
	draw_circle(bp, r, Color(0, 0, 0, 0.55))
	var fill: float = 1.0 if sim.intensity >= sim.INTENSITY_STEPS else float(sim.streak % sim.STREAK_PER_STEP) / sim.STREAK_PER_STEP
	if fill > 0.0:
		draw_arc(bp, r - 2.0, -PI / 2, -PI / 2 + TAU * fill, 32, color, 3.0)
	draw_circle(bp, r * 0.45, color)


func _draw_boss(bt: float, beat: float) -> void:
	if not sim.boss_alive():
		return
	var kind := view.creep_kind(sim.boss)
	var h: float = Art.CREEPS[kind]["height"]
	var mid := View3D.world(sim.boss["pos"], h * 0.55)
	var p := _at(mid)
	var ppm := _ppm(mid)
	# Wind-up tell: a ring swelling in the last beat before a launch.
	for b in sim.bolts:
		if b["state"] == "flying" and not b["told"]:
			var to_launch: float = b["launch"] - bt
			if to_launch < beat:
				var a: float = 1.0 - to_launch / beat
				draw_arc(p, ppm * (0.8 + 0.6 * a), 0, TAU, 48, Color(1, 0.5, 0.6, 0.3 + 0.6 * a), 5.0)
			break
	if sim.crescendo > 0.0:
		_text(_at(View3D.world(sim.boss["pos"], h + 0.5)), "STAGGERED", maxi(14, int(ppm * 0.35)), YELLOW)


func _draw_popups() -> void:
	# One number per target (D-0045): popups that start within half a tile of each
	# other share a spot, and only the newest of them is drawn.
	var newest := {}
	for pop in sim._popups:
		var key := Vector2i(roundi(pop["pos"].x * 2.0), roundi(pop["pos"].y * 2.0))
		if not newest.has(key) or pop["ttl"] > newest[key]["ttl"]:
			newest[key] = pop
	for pop in newest.values():
		var age: float = 1.0 - pop["ttl"] / 0.8
		var w := View3D.world(pop["pos"], 1.2 + 0.8 * age)
		if view.is_behind(w):
			continue
		var c: Color = pop["color"]
		c.a *= clampf(pop["ttl"] / 0.3, 0.0, 1.0)
		_text(_at(w), String(pop["text"]).to_upper(), int(pop["size"] * 1.0), c, 4)
