extends SceneTree
# Renders the HUD pictures (D-0045) from the 3D models: one PNG per tower type and
# creep kind into assets/icons/. Run under xvfb with the opengl3 driver; rerun when
# art.gd changes.
const SIZE := 160
var jobs := []
var vp: SubViewport
var holder: Node3D
var cam: Camera3D
var f := 0
var cur := -1
func _init():
	vp = SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 0.55
	env.environment = e
	vp.add_child(env)
	cam = Camera3D.new()
	cam.fov = 30
	vp.add_child(cam)
	for type in Art.TOWERS:
		jobs.append(["tower_" + type, type, false])
	jobs.append(["wall", "wall", false])
	for kind in Art.CREEPS:
		jobs.append(["creep_" + kind, kind, true])
func _process(_d):
	f += 1
	if f % 6 == 1:
		if cur >= 0:
			vp.get_texture().get_image().save_png("res://assets/icons/%s.png" % jobs[cur][0])
			print("ICON ", jobs[cur][0])
			holder.queue_free()
		cur += 1
		if cur >= jobs.size():
			quit()
			return false
		var j: Array = jobs[cur]
		holder = Node3D.new()
		vp.add_child(holder)
		var n: Node3D
		if j[2]:
			n = Art.character(j[1])
			var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
			if ap != null:
				var anim := "Idle" if ap.has_animation("Idle") else ""
				if j[1] in ["boss", "jammer"] and ap.has_animation("Spellcasting"):
					anim = "Spellcasting"
				if anim != "":
					ap.play(anim)
					ap.seek(0.3, true)
			var spec: Dictionary = Art.CREEPS[j[1]]
			if spec.has("tint"):
				var tm := StandardMaterial3D.new()
				tm.albedo_color = spec["tint"]
				tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				for mi in n.find_children("*", "MeshInstance3D", true, false):
					mi.material_overlay = tm
		elif j[1] == "wall":
			n = Node3D.new()
			for k in 2:
				var piece := Art.make(Art.WALL, 1.0)
				piece.position.x = (k - 0.5) * 0.9
				var mat := StandardMaterial3D.new()
				mat.albedo_color = View3D.BRICK
				for mi in piece.find_children("*", "MeshInstance3D", true, false):
					mi.material_override = mat
				n.add_child(piece)
		else:
			var spec: Dictionary = Art.TOWERS[j[1]]
			n = Art.make(spec["model"], 1.0)
			if spec.has("crystal"):
				var gem := MeshInstance3D.new()
				var pm := PrismMesh.new()
				pm.size = Vector3(0.22, 0.34, 0.22)
				gem.mesh = pm
				var mat := StandardMaterial3D.new()
				mat.albedo_color = spec["crystal"]
				mat.emission_enabled = true
				mat.emission = spec["crystal"]
				gem.material_override = mat
				gem.position.y = Art.aabb(n).end.y + 0.22
				n.add_child(gem)
		holder.add_child(n)
		var box := Art.aabb(n)
		var h := maxf(box.size.y, maxf(box.size.x, box.size.z))
		var c := box.get_center()
		var dir := Vector3(0.55, 0.45, 1.0).normalized()
		cam.position = c + dir * h * 2.3
		cam.look_at(c, Vector3.UP)
	return false
