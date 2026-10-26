class_name View3D
extends Node3D
## Demo 1 (M9, D-0043, D-0044): the run drawn in 3D. It owns no rules: every frame it
## reads the sim (RunSim) and moves models to match. One metre is one tile; cell
## (x, y) is centred on (x + 0.5, 0, y + 0.5). Fixed camera at 65 degrees,
## perspective, framed so the whole board sits between the top bar and the
## bottom panel. Marks that float above things (note badges, locks, health bars,
## numbers) are drawn by Indicators in screen space; ground marks (ranges, splash
## rings, stomps, the Restore ripple) and projectiles are drawn here.

const TILT := 65.0
const FOV := 32.0
const TOP_MARGIN := 46.0  # Pixels kept clear for the top bar (D-0045: slim, see-through).
const BOTTOM_MARGIN := 138.0  # Pixels kept clear for the bottom panel.
const GRASS := Color(0.33, 0.44, 0.29)  # Calmer, darker ground so creeps and telegraphs pop (D-0045).
const GRASS_FAR := Color(0.27, 0.36, 0.24)
const DIRT := Color(0.66, 0.54, 0.38)
const BRICK := Color(0.62, 0.36, 0.24)  # Player walls: warm brick, never the grey of the rocks.
const RANK_COLORS := [Color(0.78, 0.5, 0.26), Color(0.85, 0.88, 0.93)]  # Rung 1 bronze, rung 2 silver.
const BRANCH_COLORS := [Color(0.5, 0.9, 1.0), Color(1.0, 0.6, 0.3)]  # After the fork.
const TOWER_TOP := 1.7  # Where shots leave a tower.
const BODY := 0.45  # Where shots land on a creep.

var sim: RunSim
var cam: Camera3D
var _sun: DirectionalLight3D
var _fx: MeshInstance3D  # Ground rings, tracers and glows, rebuilt every frame.
var _fx_mesh: ImmediateMesh
var _fx_top: MeshInstance3D  # Same, drawn over everything (projectiles in flight).
var _fx_top_mesh: ImmediateMesh
var _structures := {}  # cell -> {node, type, sig}
var _creeps := {}  # vid -> {node, data, ap, meshes, tint, anim, last}
var _corpses: Array[Dictionary] = []  # node, ttl
var _next_vid := 1
var _route_sig := ""
var _route_node: MultiMeshInstance3D
var _ghost: Node3D
var _ghost_type := ""
var conductor: Node3D
var _conductor_ap: AnimationPlayer
var keep: Node3D
var _tints := {}  # Color -> overlay material
var _last_view := Vector2.ZERO
var _orbs: Array[MeshInstance3D] = []
var _orb_used := 0
var _orb_mat_cache := {}
var _boss_cast_until := 0.0
var _seen_bolts := {}


func setup(target: RunSim) -> void:
	sim = target


func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_terrain()
	_build_decor()
	_build_landmarks()
	_fx_mesh = ImmediateMesh.new()
	_fx = MeshInstance3D.new()
	_fx.mesh = _fx_mesh
	_fx.material_override = _fx_material(false)
	_fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fx)
	_fx_top_mesh = ImmediateMesh.new()
	_fx_top = MeshInstance3D.new()
	_fx_top.mesh = _fx_top_mesh
	_fx_top.material_override = _fx_material(true)
	_fx_top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fx_top)
	cam = Camera3D.new()
	cam.fov = FOV
	cam.current = true
	add_child(cam)
	_frame_camera()


# --- Building the world -------------------------------------------------------------

func _build_environment() -> void:
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-52, -38, 0)
	_sun.light_energy = 0.95
	_sun.light_color = Color(1.0, 0.97, 0.9)
	_sun.shadow_enabled = true
	_sun.shadow_opacity = 0.55
	_sun.shadow_blur = 1.5
	_sun.directional_shadow_max_distance = 70.0
	add_child(_sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.53, 0.72, 0.86)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.84, 0.95)
	e.ambient_light_energy = 0.45
	env.environment = e
	add_child(env)


static func flat(color: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _fx_material(on_top: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = on_top
	m.render_priority = 5 if on_top else 1
	return m


func _mesh(mesh: Mesh, mat: Material, pos: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	(parent if parent != null else self).add_child(mi)
	return mi


static func world(p: Vector2, h := 0.0) -> Vector3:
	return Vector3(p.x + 0.5, h, p.y + 0.5)


func _build_ground() -> void:
	var size := Vector2(sim.GRID_SIZE)
	var far := PlaneMesh.new()
	far.size = Vector2(140, 100)
	_mesh(far, flat(GRASS_FAR), Vector3(size.x * 0.5, -0.02, size.y * 0.5))
	var board := PlaneMesh.new()
	board.size = size
	_mesh(board, flat(GRASS), Vector3(size.x * 0.5, 0.0, size.y * 0.5))
	# A low stone kerb round the board so its edge reads.
	var kerb := flat(Color(0.55, 0.53, 0.5))
	for side in [[Vector3(size.x * 0.5, 0.05, -0.08), Vector3(size.x + 0.32, 0.1, 0.16)], [Vector3(size.x * 0.5, 0.05, size.y + 0.08), Vector3(size.x + 0.32, 0.1, 0.16)], [Vector3(-0.08, 0.05, size.y * 0.5), Vector3(0.16, 0.1, size.y)], [Vector3(size.x + 0.08, 0.05, size.y * 0.5), Vector3(0.16, 0.1, size.y)]]:
		var box := BoxMesh.new()
		box.size = side[1]
		_mesh(box, kerb, side[0])
	# Faint grid, so cells can be counted when building.
	var grid := ImmediateMesh.new()
	grid.surface_begin(Mesh.PRIMITIVE_LINES)
	for x in sim.GRID_SIZE.x + 1:
		grid.surface_add_vertex(Vector3(x, 0.012, 0))
		grid.surface_add_vertex(Vector3(x, 0.012, size.y))
	for z in sim.GRID_SIZE.y + 1:
		grid.surface_add_vertex(Vector3(0, 0.012, z))
		grid.surface_add_vertex(Vector3(size.x, 0.012, z))
	grid.surface_end()
	var gm := MeshInstance3D.new()
	gm.mesh = grid
	gm.material_override = flat(Color(0.15, 0.3, 0.1, 0.22), true)
	gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(gm)
	# The route creeps walk, as dirt tiles, rebuilt when the maze changes.
	_route_node = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var quad := PlaneMesh.new()
	quad.size = Vector2(0.9, 0.9)
	mm.mesh = quad
	_route_node.multimesh = mm
	_route_node.material_override = flat(DIRT)
	_route_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_route_node)


## Rock cells (no walking, no building) are raised stone, so neighbouring rocks read
## as one ridge; loose rocks and the odd tree sit on top.
func _build_terrain() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var stone := [flat(Color(0.42, 0.43, 0.46)), flat(Color(0.38, 0.39, 0.42)), flat(Color(0.46, 0.46, 0.49))]
	var top := flat(Color(0.37, 0.45, 0.31))  # Moss: rocks are scenery, walls are brick.
	for cell in sim.terrain:
		var h := rng.randf_range(0.45, 0.7)
		var block := BoxMesh.new()
		block.size = Vector3(1.0, h, 1.0)
		var root := Node3D.new()
		root.position = world(Vector2(cell))
		add_child(root)
		_mesh(block, stone[rng.randi() % stone.size()], Vector3(0, h * 0.5, 0), root)
		var cap := BoxMesh.new()
		cap.size = Vector3(0.96, 0.06, 0.96)
		_mesh(cap, top, Vector3(0, h + 0.03, 0), root)
		var roll := rng.randf()
		var deco := ""
		if roll < 0.45:
			deco = Art.STONES[rng.randi() % Art.STONES.size()]
		elif roll < 0.6:
			deco = Art.TREES[rng.randi() % Art.TREES.size()]
		if deco != "":
			var m := Art.make(deco, rng.randf_range(0.5, 0.85))
			if m != null:
				m.position = Vector3(rng.randf_range(-0.2, 0.2), h + 0.04, rng.randf_range(-0.2, 0.2))
				m.rotation.y = rng.randf() * TAU
				root.add_child(m)


## Trees and hills round the board, never on it, so the board sits in a landscape.
func _build_decor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var size := Vector2(sim.GRID_SIZE)
	var placed: Array[Vector2] = []
	var tries := 0
	while placed.size() < 70 and tries < 2000:
		tries += 1
		var p := Vector2(rng.randf_range(-9.0, size.x + 9.0), rng.randf_range(-6.0, size.y + 4.0))
		var out_x := maxf(-p.x, p.x - size.x)
		var out_z := maxf(-p.y, p.y - size.y)
		var out := maxf(out_x, out_z)
		if out < 1.0:
			continue
		if absf(p.y - sim.SPAWN.y - 0.5) < 2.2 and p.x < 0.0:
			continue  # The road into the mine.
		if absf(p.y - sim.GOAL.y - 0.5) < 2.8 and p.x > size.x - 1.0:
			continue  # The castle.
		var ok := true
		for q in placed:
			if q.distance_to(p) < 1.6:
				ok = false
				break
		if not ok:
			continue
		placed.append(p)
		var path: String = Art.DECOR[rng.randi() % Art.DECOR.size()]
		var m := Art.make(path, rng.randf_range(1.6, 2.4))
		if m == null:
			continue
		m.position = Vector3(p.x, 0.0, p.y)
		m.rotation.y = rng.randf() * TAU
		add_child(m)


func _build_landmarks() -> void:
	# Spawn: creeps come out of a mine on the left edge.
	var mine := Art.make(Art.MINE, 1.9)
	if mine != null:
		mine.position = Vector3(-1.1, 0.0, sim.SPAWN.y + 0.5)
		mine.rotation.y = -PI / 2.0
		add_child(mine)
	var road := PlaneMesh.new()
	road.size = Vector2(1.6, 0.9)
	_mesh(road, flat(DIRT), Vector3(-0.6, 0.004, sim.SPAWN.y + 0.5))
	# A red gate where the creeps come in (D-0045: mark the spawn).
	var wood := flat(Color(0.32, 0.22, 0.15))
	var red := flat(Color(0.85, 0.18, 0.2))
	for side in [-1.0, 1.0]:
		var post := BoxMesh.new()
		post.size = Vector3(0.14, 1.5, 0.14)
		_mesh(post, wood, Vector3(-0.2, 0.75, sim.SPAWN.y + 0.5 + side * 0.62))
	var beam := BoxMesh.new()
	beam.size = Vector3(0.16, 0.14, 1.5)
	_mesh(beam, wood, Vector3(-0.2, 1.48, sim.SPAWN.y + 0.5))
	var cloth := BoxMesh.new()
	cloth.size = Vector3(0.04, 0.42, 1.0)
	_mesh(cloth, red, Vector3(-0.2, 1.2, sim.SPAWN.y + 0.5))
	# Goal: the Conductor's keep just past the right edge, the Conductor on its wall.
	keep = Node3D.new()
	keep.position = Vector3(sim.GRID_SIZE.x + 1.6, 0.0, sim.GOAL.y + 0.5)
	add_child(keep)
	var castle := Art.make(Art.CASTLE, 2.7)
	if castle != null:
		castle.rotation.y = PI / 2.0
		keep.add_child(castle)
	_mesh(road.duplicate(), flat(DIRT), Vector3(-1.2, 0.004, 0), keep)
	var ps := Art.scene(Art.CONDUCTOR)
	conductor = Node3D.new()
	keep.add_child(conductor)
	conductor.position = Vector3(-1.45, 0.0, 0.0)
	conductor.rotation.y = -PI / 2.0
	if ps != null:
		var mage: Node3D = ps.instantiate()
		mage.scale = Vector3.ONE * (1.5 / maxf(Art.aabb(mage).size.y, 0.01))
		conductor.add_child(mage)
		_conductor_ap = mage.find_child("AnimationPlayer", true, false)
		if _conductor_ap != null:
			for n in ["Idle", "Spellcasting", "Cheer"]:
				if _conductor_ap.has_animation(n):
					_conductor_ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
			_conductor_ap.play("Idle")


# --- Camera ---------------------------------------------------------------------------

## Fixed camera (D-0043): 65 degrees, perspective, and the board plus the mine and
## the keep fitted between the top bar and the bottom panel.
func _frame_camera() -> void:
	var view := get_viewport().get_visible_rect().size
	_last_view = view
	var size := Vector2(sim.GRID_SIZE)
	var pts := [Vector3(-1.6, 0, 0), Vector3(size.x + 2.6, 0, 0), Vector3(-1.6, 0, size.y), Vector3(size.x + 2.6, 0, size.y), Vector3(size.x + 1.3, 3.2, size.y * 0.5)]
	var area := Rect2(16.0, TOP_MARGIN, view.x - 32.0, view.y - TOP_MARGIN - BOTTOM_MARGIN)
	var target := Vector3(size.x * 0.5 + 0.5, 0.0, size.y * 0.5)
	var dir := Vector3(0, sin(deg_to_rad(TILT)), cos(deg_to_rad(TILT)))
	var d := 30.0
	# A few rounds of: fit the size, then slide the aim so the board is centred in the area.
	for round in 6:
		cam.position = target + dir * d
		cam.look_at(target, Vector3.UP)
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for p in pts:
			var s := cam.unproject_position(p)
			lo = lo.min(s)
			hi = hi.max(s)
		var scale := maxf((hi.x - lo.x) / area.size.x, (hi.y - lo.y) / area.size.y)
		d *= scale
		var mid := (lo + hi) * 0.5
		var want := area.get_center()
		target.z += (mid.y - want.y) / maxf(hi.y - lo.y, 1.0) * size.y * 0.9
	cam.position = target + dir * d
	cam.look_at(target, Vector3.UP)


## A screen point to the board cell under it (a ray to the ground plane).
func cell_from_screen(p: Vector2) -> Vector2i:
	var hit := ground_point(p)
	return Vector2i(floori(hit.x), floori(hit.z))


func ground_point(p: Vector2) -> Vector3:
	var from := cam.project_ray_origin(p)
	var dir := cam.project_ray_normal(p)
	if absf(dir.y) < 0.0001:
		return Vector3(-100, 0, -100)
	var t := -from.y / dir.y
	return from + dir * t


# --- Every frame --------------------------------------------------------------------------

func _process(delta: float) -> void:
	if sim == null:
		return
	if get_viewport().get_visible_rect().size != _last_view:
		_frame_camera()
	# The screen punch on a landed snipe: a small camera shake.
	if sim._punch > 0.0:
		var k: float = sim._punch / sim.PUNCH_SECONDS
		cam.h_offset = randf_range(-1.0, 1.0) * 0.08 * k
		cam.v_offset = randf_range(-1.0, 1.0) * 0.08 * k
	else:
		cam.h_offset = 0.0
		cam.v_offset = 0.0
	_sync_route()
	_sync_structures()
	_sync_creeps(delta)
	_sync_conductor()
	_sync_ghost()
	_draw_fx()


func _sync_route() -> void:
	var route: Array = sim.grid.route()
	var sig := str(route.size()) + str(route.hash())
	if sig == _route_sig:
		return
	_route_sig = sig
	var mm := _route_node.multimesh
	mm.instance_count = route.size()
	for i in route.size():
		mm.set_instance_transform(i, Transform3D(Basis(), world(Vector2(route[i]), 0.006)))


## Walls join to the walls beside them; towers are their type's model.
func _sync_structures() -> void:
	var seen := {}
	for cell in sim.structures:
		seen[cell] = true
		var s: Dictionary = sim.structures[cell]
		var type: String = s["type"]
		var sig := type
		if type == "wall":
			for n in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				sig += "1" if sim.structures.has(cell + n) and sim.structures[cell + n]["type"] == "wall" else "0"
		else:
			sig += "%d%d" % [sim.type_rank.get(type, 0), sim.type_branch.get(type, 0)]
		var entry: Dictionary = _structures.get(cell, {})
		if entry.is_empty() or entry["sig"] != sig:
			if not entry.is_empty():
				entry["node"].queue_free()
			var node := _make_wall(cell, sig) if type == "wall" else _make_tower(type, sim.type_rank.get(type, 0), sim.type_branch.get(type, 0))
			node.position = world(Vector2(cell))
			add_child(node)
			entry = {"node": node, "type": type, "sig": sig, "meshes": node.find_children("*", "MeshInstance3D", true, false), "tint": null}
			_structures[cell] = entry
		if type != "wall":
			# A locked tower goes dark; a fired one pops a little.
			var tint = null
			if sim.suppressed.has(cell):
				tint = Color(0.05, 0.05, 0.1, 0.65)
			elif sim._flashes.has(cell):
				tint = Color(1.0, 0.95, 0.7, 0.35 * clampf(sim._flashes[cell] / 0.3, 0.0, 1.0) + 0.1)
			_set_tint(entry, tint)
			var pop := 1.0 + (0.06 * clampf(sim._flashes.get(cell, 0.0) / 0.12, 0.0, 1.0))
			entry["node"].scale = Vector3(1.0, pop, 1.0)
	for cell in _structures.keys():
		if not seen.has(cell):
			_structures[cell]["node"].queue_free()
			_structures.erase(cell)


## A tower: its type's model, bands at the base for each rung (bronze, silver, then
## the fork's colour), and from the fork on it stands taller with a pennant
## (D-0045: rank reads on the tower, not as dots beside it).
func _make_tower(type: String, rank := 0, branch := 0) -> Node3D:
	var outer := Node3D.new()
	var model := _tower_model(type)
	outer.add_child(model)
	if rank >= 3:
		model.scale = Vector3.ONE * 1.15
	for i in rank:
		var band := TorusMesh.new()
		band.inner_radius = 0.4
		band.outer_radius = 0.47
		band.rings = 24
		band.ring_segments = 6
		var col: Color = RANK_COLORS[i] if i < 2 else BRANCH_COLORS[clampi(branch - 1, 0, 1)]
		var mat := flat(col)
		mat.emission_enabled = i >= 2
		mat.emission = col
		mat.emission_energy_multiplier = 0.35
		_mesh(band, mat, Vector3(0, 0.05 + i * 0.075, 0), outer)
	if rank >= 3:
		var top := Art.aabb(model).end.y * model.scale.y
		var pole := CylinderMesh.new()
		pole.top_radius = 0.02
		pole.bottom_radius = 0.02
		pole.height = 0.5
		_mesh(pole, flat(Color(0.3, 0.22, 0.15)), Vector3(0.0, top + 0.2, 0.0), outer)
		var flag := PrismMesh.new()
		flag.size = Vector3(0.32, 0.2, 0.02)
		var fm := _mesh(flag, flat(BRANCH_COLORS[clampi(branch - 1, 0, 1)], true), Vector3(0.17, top + 0.36, 0.0), outer)
		fm.rotation.z = -PI / 2.0
	return outer


func _tower_model(type: String) -> Node3D:
	var spec: Dictionary = Art.TOWERS.get(type, {})
	var node := Art.make(spec.get("model", ""), spec.get("fit", 0.9)) if not spec.is_empty() else null
	if node == null:
		node = Node3D.new()
		var body := CylinderMesh.new()
		body.top_radius = 0.3
		body.bottom_radius = 0.4
		body.height = 1.2
		_mesh(body, flat(sim.builds[type]["color"]), Vector3(0, 0.6, 0), node)
	if spec.has("crystal"):
		var gem := PrismMesh.new()
		gem.size = Vector3(0.22, 0.34, 0.22)
		var mat := flat(spec["crystal"])
		mat.emission_enabled = true
		mat.emission = spec["crystal"]
		mat.emission_energy_multiplier = 0.8
		var top := Art.aabb(node).end.y
		_mesh(gem, mat, Vector3(0, top + 0.22, 0), node)
	return node


func _make_wall(cell: Vector2i, sig: String) -> Node3D:
	var node := Node3D.new()
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var any := false
	for i in 4:
		if sig.substr(4 + i, 1) == "1":
			any = true
			_wall_piece(node, dirs[i], 0.5)
	if not any:
		_wall_piece(node, Vector2i(1, 0), 1.0, true)
	# A post in the middle hides the joins.
	var post := BoxMesh.new()
	post.size = Vector3(0.42, 0.62, 0.42)
	_mesh(post, _brick_mat(), Vector3(0, 0.31, 0), node)
	var cap := BoxMesh.new()
	cap.size = Vector3(0.48, 0.08, 0.48)
	_mesh(cap, flat(Color(0.74, 0.46, 0.32)), Vector3(0, 0.66, 0), node)
	return node


func _wall_piece(node: Node3D, dir: Vector2i, length: float, centred := false) -> void:
	var piece := Art.make(Art.WALL)
	if piece == null:
		var box := BoxMesh.new()
		box.size = Vector3(length, 0.5, 0.3)
		piece = Node3D.new()
		_mesh(box, flat(Color(0.6, 0.6, 0.6)), Vector3(0, 0.25, 0), piece)
	else:
		# The pack's wall is 2 m long, 1.1 high: scale it to the length, 0.55 high.
		piece.scale = Vector3(length / 2.0, 0.5, 0.45)
		for mi in piece.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = _brick_mat()
	var holder := Node3D.new()
	holder.add_child(piece)
	holder.rotation.y = -atan2(float(dir.y), float(dir.x))
	var off := 0.0 if centred else length * 0.5
	holder.position = Vector3(dir.x * off, 0, dir.y * off)
	node.add_child(holder)


var _brick: StandardMaterial3D


func _brick_mat() -> StandardMaterial3D:
	if _brick == null:
		_brick = flat(BRICK)
	return _brick


func _tint_mat(c: Color) -> StandardMaterial3D:
	if not _tints.has(c):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = c
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_tints[c] = m
	return _tints[c]


func _set_tint(entry: Dictionary, tint) -> void:
	if entry["tint"] == tint:
		return
	entry["tint"] = tint
	var mat: Material = null if tint == null else _tint_mat(tint)
	for mi in entry["meshes"]:
		if is_instance_valid(mi):
			mi.material_overlay = mat


func creep_kind(c: Dictionary) -> String:
	if c.get("boss", false):
		return "boss2" if c.get("second", false) else "boss"
	return c.get("kind", "grunt")


func _sync_creeps(delta: float) -> void:
	var seen := {}
	for c in sim.creeps:
		if not c.has("_vid"):
			c["_vid"] = _next_vid
			_next_vid += 1
		var vid: int = c["_vid"]
		seen[vid] = true
		var entry: Dictionary = _creeps.get(vid, {})
		var kind := creep_kind(c)
		if entry.is_empty() or entry["kind"] != kind:
			if not entry.is_empty():
				entry["node"].queue_free()
			entry = _make_creep(c, kind)
			_creeps[vid] = entry
		entry["data"] = c
		var node: Node3D = entry["node"]
		var pos := world(c["pos"])
		var moved: Vector3 = pos - node.position
		node.position = pos
		if moved.length() > 0.0005:
			var want := atan2(moved.x, moved.z)
			node.rotation.y = lerp_angle(node.rotation.y, want, clampf(delta * 12.0, 0.0, 1.0))
		_animate_creep(entry, c, moved.length() / maxf(delta, 0.0001))
		_set_tint(entry, _creep_tint(c, kind))
	for vid in _creeps.keys():
		if seen.has(vid):
			continue
		var entry: Dictionary = _creeps[vid]
		_creeps.erase(vid)
		var c: Dictionary = entry["data"]
		if c.get("hp", 1.0) <= 0.0 and entry["ap"] != null and entry["ap"].has_animation("Death_A"):
			entry["ap"].speed_scale = 1.4
			entry["ap"].play("Death_A")
			_set_tint(entry, null)
			_corpses.append({"node": entry["node"], "ttl": 1.6})
		else:
			entry["node"].queue_free()
	var keep_c: Array[Dictionary] = []
	for k in _corpses:
		k["ttl"] -= delta
		if k["ttl"] <= 0.0:
			k["node"].queue_free()
			continue
		if k["ttl"] < 0.5:
			k["node"].position.y -= delta * 0.8
		keep_c.append(k)
	_corpses = keep_c


func _make_creep(c: Dictionary, kind: String) -> Dictionary:
	var node := Art.character(kind)
	var ap: AnimationPlayer = null
	if node == null:
		node = Node3D.new()
		var body := CapsuleMesh.new()
		body.radius = 0.2
		body.height = 0.6
		_mesh(body, flat(Color(0.85, 0.25, 0.25)), Vector3(0, 0.35, 0), node)
	else:
		ap = node.find_child("AnimationPlayer", true, false)
	if kind == "boss2":
		var crown := CylinderMesh.new()
		crown.top_radius = 0.28
		crown.bottom_radius = 0.22
		crown.height = 0.2
		var m := flat(Color(1.0, 0.8, 0.25))
		m.metallic = 0.6
		m.roughness = 0.4
		_mesh(crown, m, Vector3(0, Art.CREEPS["boss2"]["height"] * 0.98, 0), node)
	add_child(node)
	node.position = world(c["pos"])
	return {"node": node, "kind": kind, "ap": ap, "meshes": node.find_children("*", "MeshInstance3D", true, false), "tint": null, "anim": "", "data": c}


func _play(entry: Dictionary, anim: String, speed := 1.0) -> void:
	var ap: AnimationPlayer = entry["ap"]
	if ap == null:
		return
	if not ap.has_animation(anim):
		anim = "Walking_A"
	if entry["anim"] != anim:
		entry["anim"] = anim
		ap.play(anim, 0.15)
	ap.speed_scale = speed


func _animate_creep(entry: Dictionary, c: Dictionary, speed: float) -> void:
	var spec: Dictionary = Art.CREEPS.get(entry["kind"], Art.CREEPS["grunt"])
	if c.get("frozen_until", 0.0) > sim.sim_time:
		_play(entry, entry["anim"] if entry["anim"] != "" else spec["walk"], 0.0)
		return
	if c.get("boss", false):
		if sim.crescendo > 0.0:
			_play(entry, "Hit_B", 0.35)
			return
		if sim.beat_time() < _boss_cast_until:
			_play(entry, "Spellcast_Shoot" if entry["kind"] == "boss" else "2H_Melee_Attack_Chop", 1.2)
			return
	if c.get("pulse_at", -1.0) >= 0.0:
		_play(entry, "Spellcasting", 1.0)  # A Jammer winding up its throw.
		return
	if speed < 0.05:
		_play(entry, "Idle", 1.0)
		return
	_play(entry, spec["walk"], clampf(speed / 1.2, 0.5, 2.2))


func _creep_tint(c: Dictionary, kind: String):
	if c.get("frozen_until", 0.0) > sim.sim_time:
		return Color(0.65, 0.85, 1.0, 0.55)
	if c.get("veil", false) and int(c.get("cracks", 0)) < sim.VEIL_MULTS.size() - 1:
		return Color(0.45, 0.25, 0.9, 0.5 - 0.12 * int(c.get("cracks", 0)))
	if c.get("poison", 0.0) > 0.0 and (sim.type_branch.get("poison", 0) == 2 or c.get("poison_until", 0.0) > sim.sim_time):
		return Color(0.35, 1.0, 0.3, 0.3)
	if c.get("boss", false) and sim.crescendo > 0.0:
		return Color(1.0, 0.85, 0.3, 0.35)
	if c.get("slow_until", 0.0) > sim.sim_time:
		return Color(0.5, 0.7, 1.0, 0.25)
	if kind == "warden" and not c.get("covering", false):
		return null
	return Art.CREEPS.get(kind, {}).get("tint", null)


## The Conductor casts while a throw is in the air at the keep, cheers on a wave clear.
func _sync_conductor() -> void:
	if _conductor_ap == null:
		return
	var anim := "Idle"
	var incoming := false
	for a in sim.arrows:
		if a["state"] == "flying":
			incoming = true
	for b in sim.bolts:
		if b["state"] == "flying" and b["told"]:
			incoming = true
			if not _seen_bolts.has(b["launch"]):
				_seen_bolts[b["launch"]] = true
				_boss_cast_until = sim.beat_time() + 0.45
	if _seen_bolts.size() > 64:
		_seen_bolts.clear()
	if incoming:
		anim = "Spellcasting"
	elif sim.state == "won" or sim._sting_at >= 0.0:
		anim = "Cheer"
	if _conductor_ap.current_animation != anim and _conductor_ap.has_animation(anim):
		_conductor_ap.play(anim, 0.2)


## The build ghost: a see-through model of the selected tower under the mouse.
func _sync_ghost() -> void:
	var want := ""
	var hover := cell_from_screen(get_viewport().get_mouse_position())
	var ok := sim.state == "playing" and sim.build_mode and sim.grid.in_bounds(hover) and not sim.structures.has(hover) and not sim.terrain.has(hover) and not _over_ui()
	if ok and sim.unlocked.has(sim.selected):
		want = sim.selected
	if want != _ghost_type:
		if _ghost != null:
			_ghost.queue_free()
			_ghost = null
		_ghost_type = want
		if want != "":
			_ghost = _make_wall(Vector2i.ZERO, "wall0000") if want == "wall" else _make_tower(want)
			add_child(_ghost)
			var mat := _tint_mat(Color(0.6, 1.0, 0.7, 0.45))
			for mi in _ghost.find_children("*", "MeshInstance3D", true, false):
				mi.material_overlay = mat
				mi.transparency = 0.45
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _ghost != null:
		_ghost.position = world(Vector2(hover))


func _over_ui() -> bool:
	var hud = sim.hud
	return hud != null and hud.has_method("mouse_over_ui") and hud.mouse_over_ui()


# --- Ground marks and projectiles (one immediate mesh, rebuilt each frame) ----------------

func _draw_fx() -> void:
	_fx_mesh.clear_surfaces()
	_fx_top_mesh.clear_surfaces()
	_orb_used = 0
	_fx_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_fx_top_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for m in [_fx_mesh, _fx_top_mesh]:
		for i in 3:
			_vertex(m, Color(0, 0, 0, 0), Vector3(-50, -1, -50 + i))  # Never empty.
	var beat: float = sim.clock.beat_length()
	var bt: float = sim.beat_time()
	# Hover: the cell, green or red, and the range of what would be built.
	var hover := cell_from_screen(get_viewport().get_mouse_position())
	if sim.state == "playing" and sim.grid.in_bounds(hover) and not _over_ui():
		if sim.build_mode and not sim.structures.has(hover):
			var ok: bool = sim.unlocked.has(sim.selected) and sim.gold >= sim.builds[sim.selected]["cost"] and not sim.terrain.has(hover) and sim.grid.can_block([hover], sim._creep_cells())
			_quad(world(Vector2(hover), 0.02), 0.48, Color(0.3, 1.0, 0.4, 0.35) if ok else Color(1.0, 0.3, 0.3, 0.35))
			if sim.builds[sim.selected].has("range"):
				_ring(world(Vector2(hover), 0.03), sim.type_spec(sim.selected)["range"], 0.05, Color(1, 1, 1, 0.5))
		if sim.structures.has(hover) and sim.is_tower(sim.structures[hover]["type"]):
			_ring(world(Vector2(hover), 0.03), sim.tower_spec(hover)["range"], 0.05, Color(1, 1, 1, 0.45))
	# The selected tower: a white ring at its foot and its range.
	if sim.structures.has(sim.selected_cell):
		var sp := world(Vector2(sim.selected_cell), 0.04)
		_ring(sp, 0.55, 0.06, Color(1, 1, 1, 0.95))
		if sim.is_tower(sim.structures[sim.selected_cell]["type"]):
			_ring(sp, sim.tower_spec(sim.selected_cell)["range"], 0.06, Color(1, 1, 0.8, 0.6))
			_disc(sp, sim.tower_spec(sim.selected_cell)["range"], Color(1, 1, 0.8, 0.06))
	# The spawn tile breathes red on the beat.
	var pulse := 1.0 - fposmod(bt / beat, 1.0)
	_ring(world(Vector2(sim.SPAWN), 0.03), 0.38 + 0.1 * pulse, 0.06, Color(1.0, 0.25, 0.25, 0.35 + 0.4 * pulse))
	# Warden domes.
	for c in sim.creeps:
		if c.get("covering", false) and c["hp"] > 0.0:
			var p := world(c["pos"], 0.03)
			_disc(p, sim.WARDEN_COVER, Color(0.4, 0.6, 1.0, 0.1))
			_ring(p, sim.WARDEN_COVER, 0.05, Color(0.5, 0.7, 1.0, 0.55))
	# Burning ground (Ember).
	for b in sim.burning:
		var a: float = clampf((b["until"] - sim.sim_time) / sim.clock.bar_length(), 0.0, 1.0)
		_disc(world(b["pos"], 0.025), 0.7, Color(1.0, 0.5, 0.15, 0.2 + 0.25 * a))
	# Splash and note bursts: a ring growing to the reach.
	for b in sim._bursts:
		if b.has("radius"):
			var a: float = b["ttl"] / 0.5
			_ring(world(b["pos"], 0.05), maxf(b["radius"] * (1.0 - a), 0.05), 0.14 if b["crit"] else 0.09, b["color"] * Color(1, 1, 1, a))
		else:
			var a: float = b["ttl"] / 0.35
			_ring(world(b["pos"], 0.05), 0.6 + 0.8 * (1.0 - a), 0.12 if b["crit"] else 0.07, b["color"] * Color(1, 1, 1, a))
	for w in sim._shockwaves:
		var a: float = w["ttl"] / 0.5
		_ring(world(w["pos"], 0.05), sim.SUPPRESS_RADIUS * (1.0 - a * 0.7), 0.1, w["color"] * Color(1, 1, 1, a))
	# Stomps: a red area filling over the bar; towers in reach ringed.
	for st in sim.stomps:
		if st["state"] != "flying":
			continue
		var frac: float = clampf((bt - st["from"]) / maxf(st["at"] - st["from"], 0.01), 0.0, 1.0)
		var sp := world(st["pos"], 0.04)
		_disc(sp, sim.STOMP_RADIUS * frac, Color(0.95, 0.25, 0.4, 0.15 + 0.2 * frac))
		_ring(sp, sim.STOMP_RADIUS, 0.06 if not st["told"] else 0.12, Color(1, 0.35, 0.5, 0.5 + 0.5 * frac))
		for cell in sim._stomp_targets(st["pos"]):
			_ring(world(Vector2(cell), 0.04), 0.5, 0.06, Color(1, 0.35, 0.5, 0.5 + 0.5 * frac))
	# The Restore ripple and flash.
	if sim._ripple >= 0.0:
		var gp := world(Vector2(sim.GOAL), 0.06)
		for i in 4:
			var r: float = sim._ripple - i * 0.8
			if r > 0.0:
				_ring(gp, r, 0.22 - i * 0.04, Color(1.0, 0.95, 0.6, 0.8 - i * 0.18), true)
	var size := Vector2(sim.GRID_SIZE)
	if sim._restore_flash > 0.0:
		_quad_rect(Vector3(0, 0.03, 0), Vector3(size.x, 0.03, size.y), Color(1.0, 0.9, 0.3, 0.14 * sim._restore_flash / 0.5))
	if sim.crescendo > 0.0:
		_quad_rect(Vector3(0, 0.03, 0), Vector3(size.x, 0.03, size.y), Color(1.0, 0.85, 0.3, 0.07 + 0.05 * sin(bt * TAU * 2.0)))
	# Tracers: tower shots, snipes, chain jumps.
	for s in sim.shots:
		var a := clampf(s["ttl"] / 0.12, 0.0, 1.0) if s["ttl"] < 0.12 else 1.0
		var from_cell: Vector2 = s["from"]
		var h0 := TOWER_TOP if sim.structures.has(Vector2i(from_cell.round())) else (2.0 if Vector2i(from_cell.round()) == sim.GOAL else BODY)
		var width: float = s.get("width", 2.0) * 0.035
		_ribbon(world(from_cell, h0), world(s["to"], BODY), width, s["color"] * Color(1, 1, 1, a), true)
		if s["splash"] > 0.0:
			_ring(world(s["to"], 0.05), s["splash"], 0.06, s["color"] * Color(1, 1, 1, a * 0.7))
	# Elite throws: the pulse flies from the elite to each target tower.
	for c in sim.creeps:
		if not c.get("elite", false) or c.get("pulse_at", -1.0) < 0.0:
			continue
		var frac: float = clampf((bt - c["pulse_from"]) / maxf(c["pulse_at"] - c["pulse_from"], 0.01), 0.0, 1.0)
		for cell in c["pulse_targets"]:
			if not sim.structures.has(cell):
				continue
			var a := world(c["pos"], 1.1)
			var b := world(Vector2(cell), TOWER_TOP)
			var p := a.lerp(b, frac) + Vector3(0, sin(frac * PI) * 1.2, 0)
			_ribbon(a, b, 0.025, Color(1, 0.3, 0.4, 0.25), false)
			_orb(p, 0.16 if not c["told"] else 0.22, Color(1, 0.4, 0.5))
	# Arrows: straight over the maze at the Conductor.
	var gp3 := conductor_point()
	for ar in sim.arrows:
		if ar["state"] != "flying":
			continue
		var frac: float = clampf((bt - ar["launch"]) / maxf(ar["arrive"] - ar["launch"], 0.01), 0.0, 1.0)
		var a := world(ar["from"], 1.0)
		var p := a.lerp(gp3, frac) + Vector3(0, sin(frac * PI) * 2.0, 0)
		var p2 := a.lerp(gp3, maxf(frac - 0.05, 0.0)) + Vector3(0, sin(maxf(frac - 0.05, 0.0) * PI) * 2.0, 0)
		_ribbon(p2, p, 0.07, Color(1, 0.45, 0.5), true)
		_orb(p, 0.08, Color.WHITE)
	# Boss bolts: down the path at the Conductor.
	for b in sim.bolts:
		if b["state"] != "flying" or not b["told"]:
			continue
		var gpos: Vector2 = sim._bolt_pos(b)
		var p := world(gpos, 0.9)
		if gpos.distance_to(Vector2(sim.GOAL)) < 0.6:
			p = p.lerp(gp3, 1.0 - gpos.distance_to(Vector2(sim.GOAL)) / 0.6)
		_orb(p, 0.24, Color(1, 0.45, 0.6))
		_orb(p, 0.12, Color.WHITE)
	# Ghosts (talent): a pale wisp over their target.
	for g in sim.ghosts:
		if sim.creeps.has(g["target"]):
			_orb(world(g["target"]["pos"], 1.1), 0.1, Color(0.8, 0.9, 1.0, 0.7))
	_fx_mesh.surface_end()
	_fx_top_mesh.surface_end()
	for i in range(_orb_used, _orbs.size()):
		_orbs[i].visible = false


## Where things aimed at the Conductor land.
func conductor_point() -> Vector3:
	return keep.position + Vector3(-1.45, 1.2, 0.0) if keep != null else world(Vector2(sim.GOAL), 1.0)


func _vertex(m: ImmediateMesh, c: Color, p: Vector3) -> void:
	m.surface_set_color(c)
	m.surface_add_vertex(p)


func _ring(center: Vector3, radius: float, width: float, color: Color, on_top := false) -> void:
	var m := _fx_top_mesh if on_top else _fx_mesh
	var n := clampi(int(radius * 24.0), 24, 96)
	var r0 := maxf(radius - width * 0.5, 0.0)
	var r1 := radius + width * 0.5
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		_vertex(m, color, center + d0 * r0)
		_vertex(m, color, center + d0 * r1)
		_vertex(m, color, center + d1 * r1)
		_vertex(m, color, center + d0 * r0)
		_vertex(m, color, center + d1 * r1)
		_vertex(m, color, center + d1 * r0)


func _disc(center: Vector3, radius: float, color: Color) -> void:
	if radius <= 0.01:
		return
	var n := clampi(int(radius * 24.0), 24, 96)
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		_vertex(_fx_mesh, color, center)
		_vertex(_fx_mesh, color, center + Vector3(cos(a0), 0, sin(a0)) * radius)
		_vertex(_fx_mesh, color, center + Vector3(cos(a1), 0, sin(a1)) * radius)


func _quad(center: Vector3, half: float, color: Color) -> void:
	_quad_rect(center - Vector3(half, 0, half), center + Vector3(half, 0, half), color)


func _quad_rect(lo: Vector3, hi: Vector3, color: Color) -> void:
	var y := lo.y
	var a := Vector3(lo.x, y, lo.z)
	var b := Vector3(hi.x, y, lo.z)
	var c := Vector3(hi.x, y, hi.z)
	var d := Vector3(lo.x, y, hi.z)
	for p in [a, b, c, a, c, d]:
		_vertex(_fx_mesh, color, p)


## A flat band from a to b that faces the camera: tracers and throws.
func _ribbon(a: Vector3, b: Vector3, width: float, color: Color, on_top: bool) -> void:
	var m := _fx_top_mesh if on_top else _fx_mesh
	var along := b - a
	if along.length() < 0.001:
		return
	var to_cam := (cam.global_position - a).normalized()
	var side := along.cross(to_cam).normalized() * width * 0.5
	var tail := Color(color.r, color.g, color.b, color.a * 0.3)
	_vertex(m, tail, a - side)
	_vertex(m, tail, a + side)
	_vertex(m, color, b + side)
	_vertex(m, tail, a - side)
	_vertex(m, color, b + side)
	_vertex(m, color, b - side)


## A glowing ball: pooled spheres, drawn over the scene.
func _orb(p: Vector3, radius: float, color: Color) -> void:
	if _orb_used >= _orbs.size():
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 2.0
		s.radial_segments = 12
		s.rings = 6
		mi.mesh = s
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_orbs.append(mi)
	var mi := _orbs[_orb_used]
	_orb_used += 1
	mi.visible = true
	mi.position = p
	mi.scale = Vector3.ONE * radius
	var key := color
	if not _orb_mat_cache.has(key):
		var mat := flat(color, true)
		mat.no_depth_test = true
		mat.render_priority = 6
		_orb_mat_cache[key] = mat
	mi.material_override = _orb_mat_cache[key]


## Screen position and pixels per metre at a world point, for Indicators.
func screen_at(p: Vector3) -> Vector2:
	return cam.unproject_position(p)


func px_per_m(p: Vector3) -> float:
	return cam.unproject_position(p).distance_to(cam.unproject_position(p + cam.global_transform.basis.x))


func is_behind(p: Vector3) -> bool:
	return cam.is_position_behind(p)
