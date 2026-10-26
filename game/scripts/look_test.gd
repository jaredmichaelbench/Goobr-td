extends Node3D
## M8 look test (D-0042). A throwaway 3D scene, not a game: the 26 by 16 board at one
## metre a tile, a few towers and creeps, the note rings and marks floating above
## their owners, the Conductor's keep, and switches for the things the look test
## has to answer: camera tilt, perspective or orthographic, rings above or on the
## ground, and the three-rings-in-a-row clutter case from Jared's round 3 run.
##
## Everything is built from primitives in flat colours (the low-poly read). Drop
## models into game/assets/models/ (tower.glb, creep.glb, keep.glb, rock.glb,
## wall.glb) and S swaps the primitives for them; see game/assets/README.md.

const BOARD := Vector2i(26, 16)
const TILTS := [60.0, 65.0, 70.0]
const BPM := 120.0
const MODELS := "res://assets/models/"
const ROCK_COLUMNS := [6, 10, 14, 18, 22]
const TOWERS := [Vector2i(4, 6), Vector2i(5, 6), Vector2i(6, 6), Vector2i(9, 10), Vector2i(13, 5), Vector2i(17, 10), Vector2i(20, 6), Vector2i(23, 9)]
const PATH: Array[Vector2] = [Vector2(-1, 8), Vector2(4, 8), Vector2(4, 11), Vector2(12, 11), Vector2(12, 7), Vector2(19, 7), Vector2(19, 9), Vector2(26, 9)]

var tilt_index := 1
var ortho := false
var rings_above := true
var clutter := true
var use_models := false
var models_found := false

var cam: Camera3D
var hud: Label
var ring_tex: ImageTexture
var towers: Array[Node3D] = []
var rings: Array[Dictionary] = []  # sprite, label, owner (Node3D), kind: note/lock/parry/counter, phase
var creeps: Array[Dictionary] = []  # node, dist
var keep: Node3D
var t := 0.0


func _ready() -> void:
	models_found = ResourceLoader.exists(MODELS + "tower.glb")
	ring_tex = _make_ring_texture()
	_build_world()
	_build_camera()
	_build_hud()
	_apply_camera()
	_refresh_hud()


# --- World ---------------------------------------------------------------------------

func _flat(color: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	m.metallic = 0.0
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _mesh(mesh: Mesh, color: Color, pos: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _flat(color)
	mi.position = pos
	(parent if parent != null else self).add_child(mi)
	return mi


func _tile(cell: Vector2) -> Vector3:
	return Vector3(cell.x + 0.5, 0.0, cell.y + 0.5)


func _build_world() -> void:
	# Light and sky: one sun, no shadows, soft ambient so flat colours read.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = false
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.18, 0.22)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.75, 0.85)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	# Ground and grid.
	var ground := PlaneMesh.new()
	ground.size = Vector2(BOARD.x, BOARD.y)
	_mesh(ground, Color(0.45, 0.62, 0.38), Vector3(BOARD.x * 0.5, 0.0, BOARD.y * 0.5))
	var grid := ImmediateMesh.new()
	grid.surface_begin(Mesh.PRIMITIVE_LINES)
	for x in BOARD.x + 1:
		grid.surface_add_vertex(Vector3(x, 0.01, 0))
		grid.surface_add_vertex(Vector3(x, 0.01, BOARD.y))
	for z in BOARD.y + 1:
		grid.surface_add_vertex(Vector3(0, 0.01, z))
		grid.surface_add_vertex(Vector3(BOARD.x, 0.01, z))
	grid.surface_end()
	var gm := MeshInstance3D.new()
	gm.mesh = grid
	gm.material_override = _flat(Color(1, 1, 1, 0.18), true)
	gm.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	add_child(gm)
	# Rocks: the maze's broken columns.
	for x in ROCK_COLUMNS:
		for z in BOARD.y:
			if z == 7 or z == 8 or z == 11 or (x == 14 and z in [9, 10]) or (x == 18 and z == 10) or (x == 10 and z in [9, 10]):
				continue
			_rock(Vector2i(x, z))
	# A few walls near the first bend.
	for cell in [Vector2i(3, 9), Vector2i(3, 10), Vector2i(5, 12), Vector2i(6, 12)]:
		_wall(cell)
	# Towers and their rings.
	for i in TOWERS.size():
		var tower := _tower(TOWERS[i])
		towers.append(tower)
	# The Conductor's keep at the path's end, a character inside.
	keep = _keep(Vector2i(25, 9))
	# Creeps along the path.
	for i in 7:
		var c := _creep(i == 3)
		creeps.append({"node": c, "dist": 4.0 + i * 1.6})
	# Rings: three in a row (the clutter case), a lock, the parry at the keep, a counter on a creep.
	_add_ring(towers[0], "note", Color(1.0, 0.55, 0.3), "Q", 0.0)
	_add_ring(towers[1], "note", Color(0.7, 0.45, 1.0), "E", 0.25)
	_add_ring(towers[2], "note", Color(1.0, 0.55, 0.3), "Q", 0.5)
	_add_ring(towers[4], "note", Color(1.0, 0.55, 0.3), "Q", 0.0)
	_add_ring(towers[3], "lock", Color(1.0, 0.3, 0.3), "LOCKED", 0.0)
	_add_ring(keep, "parry", Color(1.0, 0.9, 0.3), "", 0.0)
	_add_ring(creeps[5]["node"], "counter", Color(1.0, 0.9, 0.3), "TAP", 0.0)
	# Range of the first clutter tower: 3.6 tiles.
	var ring := TorusMesh.new()
	ring.inner_radius = 3.55
	ring.outer_radius = 3.65
	var rm := _mesh(ring, Color(1, 1, 1, 0.35), _tile(Vector2(TOWERS[0])) + Vector3(0, 0.02, 0))
	rm.material_override = _flat(Color(1, 1, 1, 0.35), true)
	rm.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func _model(name: String) -> Node3D:
	if not use_models or not ResourceLoader.exists(MODELS + name + ".glb"):
		return null
	var scene: PackedScene = load(MODELS + name + ".glb")
	return scene.instantiate() if scene != null else null


func _rock(cell: Vector2i) -> void:
	var root := Node3D.new()
	root.position = _tile(Vector2(cell))
	add_child(root)
	var m := _model("rock")
	if m != null:
		root.add_child(m)
		return
	var box := BoxMesh.new()
	box.size = Vector3(0.96, 0.7, 0.96)
	_mesh(box, Color(0.42, 0.36, 0.3), Vector3(0, 0.35, 0), root)


func _wall(cell: Vector2i) -> void:
	var root := Node3D.new()
	root.position = _tile(Vector2(cell))
	add_child(root)
	var m := _model("wall")
	if m != null:
		root.add_child(m)
		return
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.5, 0.9)
	_mesh(box, Color(0.55, 0.57, 0.62), Vector3(0, 0.25, 0), root)


func _tower(cell: Vector2i) -> Node3D:
	var root := Node3D.new()
	root.position = _tile(Vector2(cell))
	add_child(root)
	var m := _model("tower")
	if m != null:
		root.add_child(m)
		return root
	var base := CylinderMesh.new()
	base.top_radius = 0.4
	base.bottom_radius = 0.45
	base.height = 0.25
	_mesh(base, Color(0.5, 0.5, 0.55), Vector3(0, 0.125, 0), root)
	var body := BoxMesh.new()
	body.size = Vector3(0.5, 0.9, 0.5)
	_mesh(body, Color(0.45, 0.3, 0.18), Vector3(0, 0.7, 0), root)
	var roof := CylinderMesh.new()
	roof.top_radius = 0.0
	roof.bottom_radius = 0.48
	roof.height = 0.4
	roof.radial_segments = 4
	_mesh(roof, Color(0.2, 0.35, 0.6), Vector3(0, 1.35, 0), root)
	return root


func _keep(cell: Vector2i) -> Node3D:
	var root := Node3D.new()
	root.position = _tile(Vector2(cell))
	add_child(root)
	var m := _model("keep")
	if m != null:
		root.add_child(m)
		return root
	var body := BoxMesh.new()
	body.size = Vector3(1.4, 1.5, 1.4)
	_mesh(body, Color(0.6, 0.58, 0.55), Vector3(0, 0.75, 0), root)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.03
	pole.bottom_radius = 0.03
	pole.height = 1.2
	_mesh(pole, Color(0.3, 0.25, 0.2), Vector3(0.5, 2.1, 0.5), root)
	var flag := BoxMesh.new()
	flag.size = Vector3(0.5, 0.3, 0.02)
	_mesh(flag, Color(1.0, 0.8, 0.2), Vector3(0.75, 2.55, 0.5), root)
	# The Conductor: a small figure on the keep's top.
	var figure := CapsuleMesh.new()
	figure.radius = 0.15
	figure.height = 0.55
	_mesh(figure, Color(1.0, 0.85, 0.3), Vector3(0, 1.8, 0), root)
	return root


func _creep(shade: bool) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	var m := _model("creep")
	if m != null:
		root.add_child(m)
		return root
	var body := CapsuleMesh.new()
	body.radius = 0.2
	body.height = 0.6
	_mesh(body, Color(0.4, 0.3, 0.6) if shade else Color(0.85, 0.25, 0.25), Vector3(0, 0.35, 0), root)
	return root


# --- Rings and marks: billboards above their owner, or flat on the ground --------------

func _make_ring_texture() -> ImageTexture:
	var size := 96
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x - c + 0.5, y - c + 0.5).length()
			var a := 0.0
			if d >= c - 10.0 and d <= c - 2.0:
				a = 1.0
			elif d < c - 10.0 and d >= c - 12.0:
				a = (d - (c - 12.0)) * 0.5
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _add_ring(owner: Node3D, kind: String, color: Color, text: String, phase: float) -> void:
	var sprite := Sprite3D.new()
	sprite.texture = ring_tex
	sprite.modulate = color
	sprite.pixel_size = 0.014
	sprite.no_depth_test = true
	sprite.render_priority = 10
	owner.add_child(sprite)
	var label: Label3D = null
	if text != "":
		label = Label3D.new()
		label.text = text
		label.font_size = 64 if text.length() == 1 else 36
		label.pixel_size = 0.006
		label.modulate = Color.WHITE
		label.outline_size = 12
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.render_priority = 11
		owner.add_child(label)
	rings.append({"sprite": sprite, "label": label, "owner": owner, "kind": kind, "phase": phase})
	_place_rings()


func _place_rings() -> void:
	for r in rings:
		var s: Sprite3D = r["sprite"]
		var lift := 1.9 if r["owner"] == keep else (0.9 if r["kind"] == "counter" else 1.7)
		if rings_above:
			s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			s.rotation = Vector3.ZERO
			s.position = Vector3(0, lift, 0)
		else:
			s.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			s.rotation_degrees = Vector3(-90, 0, 0)
			s.position = Vector3(0, 0.03, 0)
		if r["label"] != null:
			r["label"].position = Vector3(0, (lift + 0.55) if rings_above else 1.9, 0)


func _process(delta: float) -> void:
	t += delta
	var beat := 60.0 / BPM
	for r in rings:
		var s: Sprite3D = r["sprite"]
		var frac: float = fmod(t / beat + r["phase"], 1.0)
		match r["kind"]:
			"note", "parry":
				s.scale = Vector3.ONE * (1.8 - 1.1 * frac)
				s.modulate.a = 0.5 + 0.5 * frac
			"counter":
				s.scale = Vector3.ONE * (0.9 + 0.3 * sin(t * 12.0))
			"lock":
				s.scale = Vector3.ONE * 0.9
				s.modulate.a = 0.6 + 0.4 * absf(sin(t * 4.0))
	if not clutter:
		for i in [1, 2]:
			rings[i]["sprite"].visible = false
			if rings[i]["label"] != null:
				rings[i]["label"].visible = false
	else:
		for i in [1, 2]:
			rings[i]["sprite"].visible = true
			if rings[i]["label"] != null:
				rings[i]["label"].visible = true
	# Creeps walk the path and wrap.
	var total := _path_length()
	for c in creeps:
		c["dist"] = fmod(c["dist"] + delta * 1.6, total)
		var n: Node3D = c["node"]
		n.position = _path_pos(c["dist"])


func _path_length() -> float:
	var l := 0.0
	for i in PATH.size() - 1:
		l += PATH[i].distance_to(PATH[i + 1])
	return l


func _path_pos(d: float) -> Vector3:
	for i in PATH.size() - 1:
		var seg: float = PATH[i].distance_to(PATH[i + 1])
		if d <= seg:
			var p: Vector2 = PATH[i].lerp(PATH[i + 1], d / seg)
			return Vector3(p.x + 0.5, 0.0, p.y + 0.5)
		d -= seg
	return Vector3(PATH[-1].x + 0.5, 0.0, PATH[-1].y + 0.5)


# --- Camera: fixed, the whole board in view -----------------------------------------------

func _build_camera() -> void:
	cam = Camera3D.new()
	cam.fov = 35.0
	add_child(cam)


func _apply_camera() -> void:
	var tilt: float = TILTS[tilt_index]
	var centre := Vector3(BOARD.x * 0.5, 0.0, BOARD.y * 0.5 + 0.6)
	var aspect := 1280.0 / 720.0
	var half_w := BOARD.x * 0.5 + 1.5
	var depth := BOARD.y * sin(deg_to_rad(tilt)) * 0.5 + 2.2
	if ortho:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = maxf(depth * 2.0, half_w * 2.0 / aspect)
		var d := 40.0
		cam.position = centre + Vector3(0, d * sin(deg_to_rad(tilt)), d * cos(deg_to_rad(tilt)))
	else:
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		var vfov := deg_to_rad(cam.fov * 0.5)
		var hfov := atan(tan(vfov) * aspect)
		var d := maxf(half_w / tan(hfov), depth / tan(vfov)) + 1.0
		cam.position = centre + Vector3(0, d * sin(deg_to_rad(tilt)), d * cos(deg_to_rad(tilt)))
	cam.look_at(centre, Vector3.UP)


# --- HUD and keys ---------------------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(16, 12)
	hud.add_theme_font_size_override("font_size", 14)
	layer.add_child(hud)


func _refresh_hud() -> void:
	hud.text = "M8 LOOK TEST   tilt %d   %s   rings %s   clutter %s   style %s%s\n1 2 3 tilt 60 65 70   P perspective/orthographic   R rings above/ground   C three rings on/off   S primitives/models   Esc menu" % [
		int(TILTS[tilt_index]), "orthographic" if ortho else "perspective", "above" if rings_above else "on ground", "on" if clutter else "off",
		"models" if use_models else "primitives", "" if models_found else "   (no models in assets/models/, see assets/README.md)"]


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1, KEY_2, KEY_3:
			tilt_index = event.keycode - KEY_1
			_apply_camera()
		KEY_P:
			ortho = not ortho
			_apply_camera()
		KEY_R:
			rings_above = not rings_above
			_place_rings()
		KEY_C:
			clutter = not clutter
		KEY_S:
			if models_found:
				use_models = not use_models
				_rebuild()
		KEY_ESCAPE:
			get_tree().change_scene_to_file("res://menu.tscn")
	_refresh_hud()


func _rebuild() -> void:
	for child in get_children():
		if child != cam and not (child is CanvasLayer):
			child.queue_free()
	towers.clear()
	rings.clear()
	creeps.clear()
	await get_tree().process_frame
	_build_world()
	_apply_camera()
