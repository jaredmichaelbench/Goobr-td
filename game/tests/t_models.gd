extends SceneTree
# Asset survey: loads every staged model, prints its size and animations, and saves
# contact sheets (12 a sheet) so the picks can be made by eye. Arg: output folder.
var out := ""
var files: Array[String] = []
var page := 0
var f := 0
var holder: Node3D


func _init():
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	for dir in ["res://assets/kaykit/hex/", "res://assets/kaykit/chars/"]:
		for name in DirAccess.get_files_at(dir):
			if name.ends_with(".gltf") or name.ends_with(".glb"):
				files.append(dir + name)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.look_at_from_position(Vector3(6, 8, 14), Vector3(6, 0, 3.5))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	root.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.3, 0.35, 0.4)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.5
	root.add_child(env)
	for path in files:
		var scene: PackedScene = load(path)
		var n := scene.instantiate()
		var box := _aabb(n)
		var anims: Array = []
		var ap := n.find_child("AnimationPlayer", true, false)
		if ap != null:
			anims = ap.get_animation_list()
		print("MODEL %s size %.2f x %.2f x %.2f  min %s  anims %d %s" % [path.get_file(), box.size.x, box.size.y, box.size.z, box.position, anims.size(), anims.slice(70)])
		n.free()


func _aabb(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mi.get_aabb()
		var t: Transform3D = Transform3D.IDENTITY
		var p: Node = mi
		while p != null and p != n:
			if p is Node3D:
				t = p.transform * t
			p = p.get_parent()
		b = t * b
		box = b if first else box.merge(b)
		first = false
	return box


func _process(_d):
	f += 1
	if f % 6 == 1:
		if holder != null:
			holder.free()
		var start := page * 12
		if start >= files.size():
			quit()
			return false
		holder = Node3D.new()
		root.add_child(holder)
		for i in mini(12, files.size() - start):
			var n: Node3D = load(files[start + i]).instantiate()
			var box := _aabb(n)
			var s := 1.6 / maxf(maxf(box.size.x, box.size.z), maxf(box.size.y * 0.7, 0.01))
			n.scale = Vector3.ONE * s
			n.position = Vector3((i % 4) * 4.0, 0, (i / 4) * 3.5) - Vector3(box.get_center().x, box.position.y, box.get_center().z) * s
			holder.add_child(n)
			var l := Label3D.new()
			l.text = files[start + i].get_file().get_basename()
			l.font_size = 40
			l.pixel_size = 0.006
			l.position = Vector3((i % 4) * 4.0, 0.05, (i / 4) * 3.5 + 1.3)
			l.rotation_degrees = Vector3(-60, 0, 0)
			holder.add_child(l)
	if f % 6 == 5:
		root.get_texture().get_image().save_png(out + "/sheet_%02d.png" % page)
		page += 1
	return false
